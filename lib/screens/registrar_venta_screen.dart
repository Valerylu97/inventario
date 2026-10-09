import 'package:flutter/material.dart';
import 'package:app_inventario/services/database_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pantalla para registrar la venta de un producto del inventario.
/// Utiliza un desplegable autocompletable para buscar por nombre o categoría.
class RegistrarVentaScreen extends StatefulWidget {
  const RegistrarVentaScreen({super.key});

  @override
  State<RegistrarVentaScreen> createState() => _RegistrarVentaScreenState();
}

class _RegistrarVentaScreenState extends State<RegistrarVentaScreen> {
  final _cantidadCtrl = TextEditingController();
  final _autocompleteCtrl = TextEditingController();

  Product? _productoSeleccionado;
  List<Product> _productos = [];

  bool _cargando = true;
  bool _guardando = false;
  String _nombreLocal = 'APP INVENTARIO';

  @override
  void initState() {
    super.initState();
    _cargarPreferencias();
    _cargarProductos();
  }

  Future<void> _cargarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nombreLocal = prefs.getString('nombre_negocio') ?? 'APP INVENTARIO';
    });
  }

  Future<void> _cargarProductos() async {
    final productos = await DbHelper.instance.getAll();
    setState(() {
      _productos = productos.where((p) => p.stock > 0).toList();
      _cargando = false;
    });
  }

  void _notificar(String msg, {bool esError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
        esError ? Colors.redAccent : const Color.fromARGB(255, 46, 214, 12),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  double get _totalCalculado {
    final cantidad = int.tryParse(_cantidadCtrl.text) ?? 0;
    if (_productoSeleccionado == null) return 0;
    return cantidad * _productoSeleccionado!.price;
  }

  Future<void> _confirmarVenta() async {
    if (_productoSeleccionado == null) {
      _notificar('Selecciona un producto del desplegable', esError: true);
      return;
    }
    final cantidad = int.tryParse(_cantidadCtrl.text);
    if (cantidad == null || cantidad <= 0) {
      _notificar('Ingresa una cantidad válida', esError: true);
      return;
    }

    setState(() => _guardando = true);
    try {
      await DbHelper.instance.registrarVenta(
        producto: _productoSeleccionado!,
        cantidad: cantidad,
      );
      if (mounted) {
        _notificar(
            'Venta registrada: $cantidad × ${_productoSeleccionado!.name}');
        setState(() {
          _cantidadCtrl.clear();
          _autocompleteCtrl.clear();
          _productoSeleccionado = null;
        });
        _cargarProductos(); // Refresca el stock disponible
      }
    } catch (e) {
      _notificar(e.toString().replaceFirst('Exception: ', ''), esError: true);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      drawer: _buildMenu(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('REGISTRAR VENTA',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.grey),
            onPressed: () => context.pop(),
          ),
        ],
      ),
      body: _cargando
          ? const Center(
          child: CircularProgressIndicator(color: Color(0xFF5AE6DF)))
          : _productos.isEmpty
          ? const Center(
        child: Text('No hay productos con stock disponible',
            style: TextStyle(color: Colors.grey)),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── DESPLEGABLE CON BÚSQUEDA Y SELECCIÓN ──────────
            const Text('Producto',
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Autocomplete<Product>(
              displayStringForOption: (Product p) =>
              '${p.name} (${p.category}) - \$${p.price.toStringAsFixed(2)}',
              optionsBuilder: (TextEditingValue textEditingValue) {
                final query = textEditingValue.text.toLowerCase().trim();
                if (query.isEmpty) {
                  return _productos;
                }
                return _productos.where((Product p) {
                  return p.name.toLowerCase().contains(query) ||
                      p.category.toLowerCase().contains(query);
                });
              },
              onSelected: (Product p) {
                setState(() {
                  _productoSeleccionado = p;
                });
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Buscar o seleccionar producto...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF5AE6DF)),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (controller.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                            onPressed: () {
                              controller.clear();
                              setState(() {
                                _productoSeleccionado = null;
                              });
                            },
                          ),
                        const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        const SizedBox(width: 8),
                      ],
                    ),
                    filled: true,
                    fillColor: const Color(0xFF121212),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF5AE6DF)),
                    ),
                  ),
                  onChanged: (text) {
                    if (_productoSeleccionado != null &&
                        !text.contains(_productoSeleccionado!.name)) {
                      setState(() {
                        _productoSeleccionado = null;
                      });
                    }
                  },
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    color: const Color(0xFF121212),
                    elevation: 4.0,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: MediaQuery.of(context).size.width - 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF121212),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        separatorBuilder: (_, __) =>
                        const Divider(color: Colors.white10, height: 1),
                        itemBuilder: (BuildContext context, int index) {
                          final Product p = options.elementAt(index);
                          return ListTile(
                            title: Text(
                              p.name,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              'Categoría: ${p.category}  ·  Stock: ${p.stock}',
                              style: const TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                            trailing: Text(
                              '\$${p.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: Color(0xFF21E408),
                                  fontWeight: FontWeight.bold),
                            ),
                            onTap: () {
                              onSelected(p);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // ── CANTIDAD A VENDER ─────────────────────────────
            const Text('Cantidad vendida',
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _cantidadCtrl,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '0',
                filled: true,
                fillColor: const Color(0xFF121212),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                    const BorderSide(color: Colors.white10)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                    const BorderSide(color: Colors.white10)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                    const BorderSide(color: Color(0xFF5AE6DF))),
              ),
            ),
            const SizedBox(height: 24),

            // ── TOTAL CALCULADO ──────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL',
                      style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold)),
                  Text('\$${_totalCalculado.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Color(0xFF21E408),
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── BOTÓN CONFIRMAR ──────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _guardando ? null : _confirmarVenta,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE67E22),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: _guardando
                    ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.point_of_sale),
                label: Text(
                  _guardando ? 'Registrando...' : 'CONFIRMAR VENTA',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => context.push('/ventas/reporte'),
                child: const Text('Ver reporte de ventas',
                    style: TextStyle(color: Color(0xFF5AE6DF))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── MENÚ GENERAL ──────────────────────────────────────────
  Widget _buildMenu() {
    return Drawer(
      backgroundColor: const Color(0xFF0A0A0A),
      child: SafeArea(
        child: FutureBuilder<SharedPreferences>(
          future: SharedPreferences.getInstance(),
          builder: (context, snapshot) {
            final prefs = snapshot.data;
            final userRole = prefs?.getString('user_role') ?? 'Operador';
            final userName = prefs?.getString('user_name') ?? 'Usuario';
            final esAdmin = userRole.toLowerCase().contains('admin');

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── ENCABEZADO CON ROL DE USUARIO ───
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nombreLocal,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Usuario: $userName ($userRole)',
                        style: const TextStyle(
                          color: Color(0xFF5AE6DF),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white10),

                // ── OPCIONES COMUNES (Cajero / Operador / Admin) ───
                _menuItem(
                  icon: Icons.inventory_2_outlined,
                  label: 'Inventario',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/inventario');
                  },
                ),
                _menuItem(
                  icon: Icons.point_of_sale,
                  label: 'Registro de ventas',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/ventas/registrar');
                  },
                ),

                // ── OPCIONES EXCLUSIVAS DEL ADMINISTRADOR ───
                if (esAdmin) ...[
                  _menuItem(
                    icon: Icons.add_box_outlined,
                    label: 'Registro de productos',
                    onTap: () async {
                      Navigator.pop(context);
                      await context.push('/agregar');
                      setState(() {});
                    },
                  ),
                  _menuItem(
                    icon: Icons.bar_chart,
                    label: 'Reporte de ventas',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/ventas/reporte');
                    },
                  ),
                  _menuItem(
                    icon: Icons.receipt_long,
                    label: 'Movimientos Kardex',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/kardex-selector');
                    },
                  ),
                  const Divider(color: Colors.white10),
                  _menuItem(
                    icon: Icons.manage_accounts_outlined,
                    label: 'Gestión de Usuarios y Roles',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/usuarios');
                    },
                  ),
                  _menuItem(
                    icon: Icons.settings_outlined,
                    label: 'Configuración',
                    onTap: () async {
                      Navigator.pop(context);
                      await context.push('/configuracion');
                      _cargarPreferencias();
                    },
                  ),
                ],

                // ── ESPACIADOR PARA EMPUJAR EL BOTÓN AL FINAL ───
                const Spacer(),
                const Divider(color: Colors.white10),

                // ── BOTÓN DE CERRAR SESIÓN ───
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text(
                    'Cerrar Sesión',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () async {
                    final p = await SharedPreferences.getInstance();
                    await p.setBool('is_logged_in', false);
                    await p.remove('user_role');
                    await p.remove('user_name');

                    if (context.mounted) {
                      Navigator.pop(context); // Cierra el Drawer
                      context.go('/login'); // Redirige al Login
                    }
                  },
                ),
                const SizedBox(height: 10),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF5AE6DF)),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }
}