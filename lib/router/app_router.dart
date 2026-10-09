import 'package:go_router/go_router.dart';
import 'package:app_inventario/screens/home_screen.dart';
import 'package:app_inventario/screens/inventario_screen.dart';
import 'package:app_inventario/screens/add_product_screen.dart';
import 'package:app_inventario/screens/settings_page.dart';
import 'package:app_inventario/screens/kardex_screen.dart';
import 'package:app_inventario/screens/seleccionar_producto_kardex_screen.dart';
import 'package:app_inventario/screens/registrar_venta_screen.dart';
import 'package:app_inventario/screens/reporte_ventas_screen.dart';
import 'package:app_inventario/models/producto.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/inventario',
      name: 'inventario',
      builder: (context, state) => const InventarioScreen(),
    ),
    GoRoute(
      path: '/agregar',
      name: 'agregar',
      builder: (context, state) {
        // Recibe el producto si viene en modo edición
        final producto = state.extra as Product?;
        return AddProductScreen(producto: producto);
      },
    ),
    GoRoute(
      path: '/configuracion',
      name: 'configuracion',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/kardex',
      name: 'kardex',
      builder: (context, state) {
        final producto = state.extra as Product;
        return KardexScreen(producto: producto);
      },
    ),
    GoRoute(
      path: '/kardex-selector',
      name: 'kardex-selector',
      builder: (context, state) => const SeleccionarProductoKardexScreen(),
    ),
    GoRoute(
      path: '/ventas/registrar',
      name: 'registrar-venta',
      builder: (context, state) => const RegistrarVentaScreen(),
    ),
    GoRoute(
      path: '/ventas/reporte',
      name: 'reporte-ventas',
      builder: (context, state) => const ReporteVentasScreen(),
    ),
  ],
);
