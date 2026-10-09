import 'package:flutter/material.dart';
import 'package:app_inventario/services/database_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Punto de entrada general al Kardex: lista todos los productos para que
/// el usuario elija de cuál quiere ver el historial de movimientos.
class SeleccionarProductoKardexScreen extends StatefulWidget {
  const SeleccionarProductoKardexScreen({super.key});

  @override
  State<SeleccionarProductoKardexScreen> createState() =>
      _SeleccionarProductoKardexScreenState();
}

class _SeleccionarProductoKardexScreenState
    extends State<SeleccionarProductoKardexScreen> {
  final _searchCtrl = TextEditingController();
  String _filtroBusqueda = '';
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      drawer: _buildMenu(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'MOVIMIENTOS KARDEX',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.grey),
            onPressed: () => context.pop(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildListaProductos()),
        ],
      ),
    );
  }

  // ── BARRA DE BÚSQUEDA ─────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _filtroBusqueda = v.toLowerCase()),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Buscar por nombre o categoría...',
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF5AE6DF)),
          suffixIcon: _filtroBusqueda.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear, size: 20, color: Colors.grey),
            onPressed: () {
              _searchCtrl.clear();
              setState(() => _filtroBusqueda = '');
            },
          )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          filled: true,
          fillColor: const Color(0xFF121212),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Colors.white10),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Color(0xFF5AE6DF)),
          ),
        ),
      ),
    );
  }

  // ── LISTA DE PRODUCTOS FILTRADA ───────────────────────────
  Widget _buildListaProductos() {
    return FutureBuilder<List<Product>>(
      future: DbHelper.instance.getAll(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF5AE6DF)),
          );
        }
        final productos = snapshot.data ?? [];
        if (productos.isEmpty) {
          return const Center(
            child: Text(
              'No hay productos registrados',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        // Filtrado por Nombre o Categoría
        final productosFiltrados = productos.where((p) {
          final nombre = p.name.toLowerCase();
          final categoria = p.category.toLowerCase();
          return nombre.contains(_filtroBusqueda) ||
              categoria.contains(_filtroBusqueda);
        }).toList();

        if (productosFiltrados.isEmpty) {
          return const Center(
            child: Text(
              'No se encontraron coincidencias',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemCount: productosFiltrados.length,
          itemBuilder: (context, i) {
            final p = productosFiltrados[i];
            return ListTile(
              leading: const Icon(
                Icons.receipt_long,
                color: Color(0xFF5AE6DF),
              ),
              title: Text(p.name, style: const TextStyle(color: Colors.white)),
              subtitle: Text(
                'Categoría: ${p.category}  ·  Stock actual: ${p.stock}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.white24),
              onTap: () async {
                await context.push('/kardex', extra: p);
                setState(() {}); // Refresca lista al volver del Kardex
              },
            );
          },
        );
      },
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