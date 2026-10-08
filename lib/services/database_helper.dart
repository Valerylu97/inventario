import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:app_inventario/models/producto.dart';
import 'package:app_inventario/models/movimiento_kardex.dart';

export 'package:app_inventario/models/producto.dart'; // Para que el main vea a Producto
export 'package:app_inventario/models/movimiento_kardex.dart';

class DbHelper {
  static final DbHelper instance = DbHelper._init();
  static Database? _database;
  DbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app_inventario.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    // version 2: se agrega la tabla 'kardex' para HU de control de stock
    // tipo Kardex (historial de entradas/salidas), en vez de solo editar
    // el campo stock directamente.
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        name TEXT NOT NULL, 
        stock INTEGER NOT NULL, 
        price REAL NOT NULL, 
        category TEXT NOT NULL,
        imagePath TEXT
      )
    ''');
    await _createKardexTable(db);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createKardexTable(db);
    }
  }

  Future _createKardexTable(Database db) async {
    await db.execute('''
      CREATE TABLE kardex (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER NOT NULL,
        tipo TEXT NOT NULL,
        cantidad INTEGER NOT NULL,
        stockAnterior INTEGER NOT NULL,
        stockNuevo INTEGER NOT NULL,
        motivo TEXT,
        fecha TEXT NOT NULL,
        FOREIGN KEY (productId) REFERENCES products (id) ON DELETE CASCADE
      )
    ''');
  }

  // ───────────────────────── PRODUCTOS (CRUD existente) ─────────────────

  // HU01 & HU03: Guardar y Editar
  Future<int> upsert(Product p) async {
    final db = await instance.database;
    if (p.id == null) return await db.insert('products', p.toMap());
    return await db
        .update('products', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
  }

  // HU06: Eliminación permanente
  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Product>> getAll() async {
    final db = await instance.database;
    final res = await db.query('products', orderBy: 'name ASC');
    return res.map((e) => Product.fromMap(e)).toList();
  }

  // ───────────────────────── KARDEX (nuevo) ──────────────────────────────

  /// Registra un movimiento de inventario (ENTRADA, SALIDA o AJUSTE) y
  /// actualiza el stock del producto en una sola transacción, de modo que
  /// el stock mostrado y el historial de movimientos nunca queden
  /// desincronizados.
  ///
  /// - ENTRADA: [cantidad] se SUMA al stock actual (ej: compra a proveedor).
  /// - SALIDA: [cantidad] se RESTA del stock actual (ej: venta). Lanza
  ///   [Exception] si el stock resultante sería negativo.
  /// - AJUSTE: [cantidad] reemplaza el stock actual (ej: conteo físico de
  ///   inventario que corrige una descuadre).
  Future<Product> registrarMovimiento({
    required Product producto,
    required String tipo,
    required int cantidad,
    String motivo = '',
  }) async {
    final db = await instance.database;
    final stockAnterior = producto.stock;
    int stockNuevo;

    switch (tipo) {
      case 'ENTRADA':
        stockNuevo = stockAnterior + cantidad;
        break;
      case 'SALIDA':
        stockNuevo = stockAnterior - cantidad;
        if (stockNuevo < 0) {
          throw Exception(
              'Stock insuficiente: hay $stockAnterior unidades y se intentan retirar $cantidad.');
        }
        break;
      case 'AJUSTE':
        stockNuevo = cantidad;
        break;
      default:
        throw ArgumentError('Tipo de movimiento no válido: $tipo');
    }

    await db.transaction((txn) async {
      await txn.update('products', {'stock': stockNuevo},
          where: 'id = ?', whereArgs: [producto.id]);
      await txn.insert('kardex', {
        'productId': producto.id,
        'tipo': tipo,
        'cantidad': cantidad,
        'stockAnterior': stockAnterior,
        'stockNuevo': stockNuevo,
        'motivo': motivo,
        'fecha': DateTime.now().toIso8601String(),
      });
    });

    producto.stock = stockNuevo;
    return producto;
  }

  /// Historial completo de movimientos de un producto, más reciente primero.
  Future<List<MovimientoKardex>> getKardexPorProducto(int productId) async {
    final db = await instance.database;
    final res = await db.query(
      'kardex',
      where: 'productId = ?',
      whereArgs: [productId],
      orderBy: 'fecha DESC',
    );
    return res.map((e) => MovimientoKardex.fromMap(e)).toList();
  }
}
