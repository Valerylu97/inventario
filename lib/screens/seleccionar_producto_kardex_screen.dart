import 'package:flutter/material.dart';
import 'package:app_inventario/services/database_helper.dart';
import 'package:go_router/go_router.dart';

/// Punto de entrada general al Kardex: lista todos los productos para que
/// el usuario elija de cuál quiere ver el historial de movimientos.
class SeleccionarProductoKardexScreen extends StatelessWidget {
  const SeleccionarProductoKardexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('MOVIMIENTOS KARDEX',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Product>>(
        future: DbHelper.instance.getAll(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF5AE6DF)));
          }
          final productos = snapshot.data ?? [];
          if (productos.isEmpty) {
            return const Center(
              child: Text('No hay productos registrados',
                  style: TextStyle(color: Colors.grey)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: productos.length,
            itemBuilder: (context, i) {
              final p = productos[i];
              return ListTile(
                leading: const Icon(Icons.receipt_long, color: Color(0xFF5AE6DF)),
                title: Text(p.name, style: const TextStyle(color: Colors.white)),
                subtitle: Text('Stock actual: ${p.stock}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white24),
                onTap: () => context.push('/kardex', extra: p),
              );
            },
          );
        },
      ),
    );
  }
}
