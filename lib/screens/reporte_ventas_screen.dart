import 'package:flutter/material.dart';
import 'package:app_inventario/services/database_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reporte de ventas: resumen de ingresos totales, unidades vendidas y
/// número de transacciones, seguido del historial completo de ventas.
class ReporteVentasScreen extends StatefulWidget {
  const ReporteVentasScreen({super.key});

  @override
  State<ReporteVentasScreen> createState() => _ReporteVentasScreenState();
}

class _ReporteVentasScreenState extends State<ReporteVentasScreen> {
  late Future<List<Venta>> _futureVentas;
  late Future<Map<String, num>> _futureResumen;
  String _nombreLocal = 'APP INVENTARIO';

  @override
  void initState() {
    super.initState();
    _cargarPreferencias();
    _cargar();
  }

  Future<void> _cargarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nombreLocal = prefs.getString('nombre_negocio') ?? 'APP INVENTARIO';
    });
  }

  void _cargar() {
    _futureVentas = DbHelper.instance.getVentas();
    _futureResumen = DbHelper.instance.getResumenVentas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      drawer: _buildMenu(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('REPORTE DE VENTAS',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: () => setState(_cargar),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.grey),
            onPressed: () => context.pop(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildResumen(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Divider(color: Colors.white10),
          ),
          Expanded(child: _buildHistorial()),
        ],
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

  Widget _buildResumen() {
    return FutureBuilder<Map<String, num>>(
      future: _futureResumen,
      builder: (context, snapshot) {
        final totalIngresos = (snapshot.data?['totalIngresos'] ?? 0).toDouble();
        final totalUnidades = snapshot.data?['totalUnidades'] ?? 0;
        final numVentas = snapshot.data?['numVentas'] ?? 0;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('INGRESOS', '\$${totalIngresos.toStringAsFixed(2)}',
                  const Color(0xFF21E408)),
              Container(width: 1, height: 30, color: Colors.white10),
              _statItem('UNIDADES', '$totalUnidades', const Color(0xFF5AE6DF)),
              Container(width: 1, height: 30, color: Colors.white10),
              _statItem('VENTAS', '$numVentas', const Color(0xFFE67E22)),
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
                color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildHistorial() {
    return FutureBuilder<List<Venta>>(
      future: _futureVentas,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF5AE6DF)));
        }
        final ventas = snapshot.data ?? [];
        if (ventas.isEmpty) {
          return const Center(
            child: Text('Aún no se han registrado ventas',
                style: TextStyle(color: Colors.grey)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 20),
          itemCount: ventas.length,
          itemBuilder: (context, i) => _ventaTile(ventas[i]),
        );
      },
    );
  }

  Widget _ventaTile(Venta v) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF21E408).withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0x3321E408),
            child: Icon(Icons.point_of_sale, color: Color(0xFF21E408), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(v.productName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                    '${v.cantidad} und × \$${v.precioUnitario.toStringAsFixed(2)}  ·  ${_formatearFecha(v.fecha)}',
                    style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Text('\$${v.total.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: Color(0xFF21E408),
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
        ],
      ),
    );
  }

  String _formatearFecha(DateTime f) {
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(f.day)}/${dos(f.month)}/${f.year} ${dos(f.hour)}:${dos(f.minute)}';
  }
}