import 'package:flutter/material.dart';
import 'package:app_inventario/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PanaderiaApp());
}

class PanaderiaApp extends StatelessWidget {
  const PanaderiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'INVENTARIO',
      routerConfig: appRouter,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF5AE6DF),
          secondary: Color(0xFFE67E22),
          surface: Color(0xFF121212),
        ),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF121212),
          border:
          OutlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
          labelStyle: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
