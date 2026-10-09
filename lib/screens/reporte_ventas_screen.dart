import 'package:flutter/material.dart';
import 'package:app_inventario/services/database_helper.dart';

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

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    _futureVentas = DbHelper.instance.getVentas();
    _futureResumen = DbHelper.instance.getResumenVentas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
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
