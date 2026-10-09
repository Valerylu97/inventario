import 'package:flutter/material.dart';
import 'package:app_inventario/services/database_helper.dart';
import 'package:app_inventario/widgets/product_card.dart';
import 'package:app_inventario/screens/add_product_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  final _searchCtrl = TextEditingController();
  String _filtroBusqueda = '';
  bool _mostrarAlertas = true;
  String _nombreLocal = 'APP INVENTARIO';

  @override
  void initState() {
    super.initState();
    _cargarPreferencias();
  }

  Future<void> _cargarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nombreLocal = prefs.getString('nombre_negocio') ?? 'APP INVENTARIO';
      _mostrarAlertas = prefs.getBool('alertas_stock') ?? true;
    });
  }

  void _notificarConDeshacer(Product p) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.delete_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text("'${p.name}' eliminado",
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _confirmarBorrado(Product p) async {
    final confirmar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.delete_forever_rounded,
            color: Colors.redAccent, size: 48),
        title: const Text(
          '¿Eliminar producto?',
          style: TextStyle(color: Colors.white, fontSize: 18),
          textAlign: TextAlign.center,
        ),
        content: Text(
          "'${p.name}' será eliminado permanentemente del inventario.",
          style: const TextStyle(color: Colors.grey, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ELIMINAR',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await DbHelper.instance.delete(p.id!);
      setState(() {});
      _notificarConDeshacer(p);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      drawer: _buildMenu(),
      appBar: AppBar(
        title: Text(
          _nombreLocal,
          style: const TextStyle(
              fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.grey),
            onPressed: () async {
              await context.push('/configuracion');
              _cargarPreferencias();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildDashboard(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Divider(color: Colors.white10, thickness: 1),
          ),
          Expanded(child: _buildLista()),
        ],
      ),
    );
  }

  // ── MENÚ GENERAL (organiza las 4 pantallas principales) ───
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

  // ── BARRA DE BÚSQUEDA ─────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) =>
            setState(() => _filtroBusqueda = v.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Buscar pan o categoría...',
          prefixIcon:
              const Icon(Icons.search, color: Color(0xFF5AE6DF)),
          suffixIcon: _filtroBusqueda.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _filtroBusqueda = '');
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Colors.white10),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide:
                const BorderSide(color: Color(0xFF5AE6DF)),
          ),
        ),
      ),
    );
  }

  // ── DASHBOARD RESUMEN ─────────────────────────────────────
  Widget _buildDashboard() {
    return FutureBuilder<List<Product>>(
      future: DbHelper.instance.getAll(),
      builder: (context, snapshot) {
        final productos = snapshot.data ?? [];
        final valorTotal =
            productos.fold(0.0, (sum, p) => sum + (p.price * p.stock));
        final bajoStock =
            productos.where((p) => p.stock < 5).length;

        return Container(
          margin:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('PRODUCTOS', '${productos.length}',
                  const Color(0xFF21E408)),
              Container(width: 1, height: 30, color: Colors.white10),
              _statItem('VALOR STOCK',
                  '\$${valorTotal.toStringAsFixed(2)}',
                  const Color(0xFF5AE6DF)),
              if (_mostrarAlertas) ...[
                Container(
                    width: 1, height: 30, color: Colors.white10),
                _statItem(
                    'ALERTAS', '$bajoStock', Colors.redAccent),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
        Text(value,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color)),
      ],
    );
  }

  // ── LISTA DE PRODUCTOS ────────────────────────────────────
  Widget _buildLista() {
    return FutureBuilder<List<Product>>(
      future: DbHelper.instance.getAll(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF5AE6DF)));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        final productos = snapshot.data!.where((p) {
          return p.name.toLowerCase().contains(_filtroBusqueda) ||
              p.category.toLowerCase().contains(_filtroBusqueda);
        }).toList();

        if (productos.isEmpty) {
          return const Center(
            child: Text('No se encontraron resultados',
                style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 100),
          itemCount: productos.length,
          itemBuilder: (context, i) {
            final p = productos[i];
            return ProductCard(
              product: p,
              bajoStock: _mostrarAlertas && p.stock < 5,
              onEdit: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          AddProductScreen(producto: p)),
                );
                setState(() {});
              },
              onDelete: () => _confirmarBorrado(p),
              // HU-Kardex: el stock ya no se toca con +/- directos; se
              // registra como movimiento en la pantalla de Kardex.
              onKardex: () async {
                await context.push('/kardex', extra: p);
                setState(() {}); // refresca stock y dashboard al volver
              },
            );
          },
        );
      },
    );
  }

  // ── ESTADO VACÍO ──────────────────────────────────────────
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bakery_dining, size: 72, color: Colors.white10),
          SizedBox(height: 16),
          Text('Sin productos aún',
              style: TextStyle(color: Colors.grey, fontSize: 16)),
          SizedBox(height: 8),
          Text('Toca REGISTRAR para agregar el primero',
              style: TextStyle(color: Colors.white24, fontSize: 12)),
        ],
      ),
    );
  }
}
