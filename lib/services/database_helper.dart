import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:app_inventario/models/producto.dart';
import 'package:app_inventario/models/movimiento_kardex.dart';
import 'package:app_inventario/models/venta.dart';

export 'package:app_inventario/models/producto.dart'; // Para que el main vea a Producto
export 'package:app_inventario/models/movimiento_kardex.dart';
export 'package:app_inventario/models/venta.dart';

// ───────────────────────── MODELO DE USUARIO ─────────────────────────
class User {
  final int? id;
  final String username;
  final String password;
  final String role; // Ej: 'Administrador', 'Operador', 'Cajero', etc.

  User({
    this.id,
    required this.username,
    required this.password,
    required this.role,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'role': role,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      username: map['username'] as String,
      password: map['password'] as String,
      role: map['role'] as String,
    );
  }
}

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
    // version 2: tabla 'kardex' (historial de entradas/salidas/ajustes).
    // version 3: tabla 'ventas' (registro de ventas, ligado al Kardex).
    // version 4: tabla 'usuarios' (login de admin y gestión de roles).
    return await openDatabase(
      path,
      version: 4,
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
    await _createVentasTable(db);
    await _createUsuariosTable(db);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createKardexTable(db);
    }
    if (oldVersion < 3) {
      await _createVentasTable(db);
    }
    if (oldVersion < 4) {
      await _createUsuariosTable(db);
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

  Future _createVentasTable(Database db) async {
    await db.execute('''
      CREATE TABLE ventas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER NOT NULL,
        productName TEXT NOT NULL,
        cantidad INTEGER NOT NULL,
        precioUnitario REAL NOT NULL,
        total REAL NOT NULL,
        fecha TEXT NOT NULL,
        FOREIGN KEY (productId) REFERENCES products (id) ON DELETE CASCADE
      )
    ''');
  }

  Future _createUsuariosTable(Database db) async {
    await db.execute('''
      CREATE TABLE usuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        role TEXT NOT NULL
      )
    ''');

    // Insertar el Administrador inicial por defecto
    await db.insert('usuarios', {
      'username': 'admin',
      'password': 'admin123',
      'role': 'Administrador',
    });
  }

  // ───────────────────────── USUARIOS & ROLES ────────────────────────────

  /// Autentica un usuario contra la base de datos local SQLite.
  Future<User?> autenticar(String username, String password) async {
    final db = await instance.database;
    final maps = await db.query(
      'usuarios',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  /// Crea un nuevo usuario asignándole un rol personalizado.
  Future<int> crearUsuario(User usuario) async {
    final db = await instance.database;
    return await db.insert('usuarios', usuario.toMap());
  }

  /// Lista todos los usuarios registrados.
  Future<List<User>> getUsuarios() async {
    final db = await instance.database;
    final maps = await db.query('usuarios', orderBy: 'username ASC');
    return maps.map((m) => User.fromMap(m)).toList();
  }

  /// Elimina un usuario por su ID.
  Future<int> eliminarUsuario(int id) async {
    final db = await instance.database;
    return await db.delete('usuarios', where: 'id = ?', whereArgs: [id]);
  }

  // ───────────────────────── PRODUCTOS (CRUD) ────────────────────────────

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

  // ───────────────────────── KARDEX ──────────────────────────────────────

  /// Registra un movimiento de inventario (ENTRADA, SALIDA o AJUSTE) y
  /// actualiza el stock del producto en una sola transacción.
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

  // ───────────────────────── VENTAS ──────────────────────────────────────

  /// Registra una venta de [cantidad] unidades de [producto]: descuenta el
  /// stock, inserta el movimiento SALIDA correspondiente en el Kardex y
  /// guarda el registro de la venta dentro de una transacción atómica.
  Future<Product> registrarVenta({
    required Product producto,
    required int cantidad,
  }) async {
    if (cantidad <= 0) {
      throw Exception('La cantidad vendida debe ser mayor a cero.');
    }
    if (cantidad > producto.stock) {
      throw Exception(
          'Stock insuficiente: solo hay ${producto.stock} unidades disponibles.');
    }

    final db = await instance.database;
    final stockAnterior = producto.stock;
    final stockNuevo = stockAnterior - cantidad;
    final total = producto.price * cantidad;

    final fecha = DateTime.now();

    await db.transaction((txn) async {
      await txn.update('products', {'stock': stockNuevo},
          where: 'id = ?', whereArgs: [producto.id]);
      await txn.insert('kardex', {
        'productId': producto.id,
        'tipo': 'SALIDA',
        'cantidad': cantidad,
        'stockAnterior': stockAnterior,
        'stockNuevo': stockNuevo,
        'motivo': 'Venta',
        'fecha': fecha.toIso8601String(),
      });
      await txn.insert('ventas', {
        'productId': producto.id,
        'productName': producto.name,
        'cantidad': cantidad,
        'precioUnitario': producto.price,
        'total': total,
        'fecha': fecha.toIso8601String(),
      });
    });

    producto.stock = stockNuevo;
    return producto;
  }

  /// Todas las ventas registradas, más reciente primero.
  Future<List<Venta>> getVentas() async {
    final db = await instance.database;
    final res = await db.query('ventas', orderBy: 'fecha DESC');
    return res.map((e) => Venta.fromMap(e)).toList();
  }

  /// Resumen agregado para el reporte de ventas: total de ingresos, total
  /// de unidades vendidas y número de transacciones registradas.
  Future<Map<String, num>> getResumenVentas() async {
    final db = await instance.database;
    final res = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(total), 0) AS totalIngresos,
        COALESCE(SUM(cantidad), 0) AS totalUnidades,
        COUNT(*) AS numVentas
      FROM ventas
    ''');
    final fila = res.first;
    return {
      'totalIngresos': (fila['totalIngresos'] as num?) ?? 0,
      'totalUnidades': (fila['totalUnidades'] as num?) ?? 0,
      'numVentas': (fila['numVentas'] as num?) ?? 0,
    };
  }
}