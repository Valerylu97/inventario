import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
        title: Text(
          _nombreLocal,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Panel Principal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Selecciona un módulo para gestionar la panadería',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.05,
                  children: [
                    _buildModuleCard(
                      icon: Icons.inventory_2_outlined,
                      title: 'Inventario',
                      subtitle: 'Stock y productos',
                      onTap: () => context.push('/inventario'),
                    ),
                    _buildModuleCard(
                      icon: Icons.add_box_outlined,
                      title: 'Registro de productos',
                      subtitle: 'Agregar nuevo ítem',
                      onTap: () async {
                        await context.push('/agregar');
                        setState(() {});
                      },
                    ),
                    _buildModuleCard(
                      icon: Icons.point_of_sale,
                      title: 'Registro de ventas',
                      subtitle: 'Cobro y caja',
                      onTap: () => context.push('/ventas/registrar'),
                    ),
                    _buildModuleCard(
                      icon: Icons.bar_chart,
                      title: 'Reporte de ventas',
                      subtitle: 'Estadísticas e ingresos',
                      onTap: () => context.push('/ventas/reporte'),
                    ),
                    _buildModuleCard(
                      icon: Icons.receipt_long,
                      title: 'Movimientos Kardex',
                      subtitle: 'Entradas y salidas',
                      onTap: () => context.push('/kardex-selector'),
                    ),
                    _buildModuleCard(
                      icon: Icons.settings_outlined,
                      title: 'Configuración',
                      subtitle: 'Ajustes del local',
                      onTap: () async {
                        await context.push('/configuracion');
                        _cargarPreferencias();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tarjetas principales para la pantalla de inicio
  Widget _buildModuleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFF121212),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: const Color(0xFF5AE6DF).withOpacity(0.15),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF5AE6DF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF5AE6DF),
                  size: 26,
                ),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── MENÚ GENERAL ───
  Widget _buildMenu() {
    return Drawer(
      backgroundColor: const Color(0xFF0A0A0A),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                _nombreLocal,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(color: Colors.white10),
            _menuItem(
              icon: Icons.inventory_2_outlined,
              label: 'Inventario',
              onTap: () {
                Navigator.pop(context);
                context.push('/inventario');
              },
            ),
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
              icon: Icons.point_of_sale,
              label: 'Registro de ventas',
              onTap: () {
                Navigator.pop(context);
                context.push('/ventas/registrar');
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
              icon: Icons.settings_outlined,
              label: 'Configuración',
              onTap: () async {
                Navigator.pop(context);
                await context.push('/configuracion');
                _cargarPreferencias();
              },
            ),
          ],
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