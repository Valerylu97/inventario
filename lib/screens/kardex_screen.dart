import 'package:flutter/material.dart';
import 'package:app_inventario/services/database_helper.dart';

/// Pantalla que muestra el historial Kardex (entradas, salidas y ajustes)
/// de un producto específico, y permite registrar nuevos movimientos.
class KardexScreen extends StatefulWidget {
  final Product producto;

  const KardexScreen({super.key, required this.producto});

  @override
  State<KardexScreen> createState() => _KardexScreenState();
}

class _KardexScreenState extends State<KardexScreen> {
  late Product _producto;
  late Future<List<MovimientoKardex>> _futureMovimientos;

  @override
  void initState() {
    super.initState();
    _producto = widget.producto;
    _cargar();
  }

  void _cargar() {
    _futureMovimientos =
        DbHelper.instance.getKardexPorProducto(_producto.id!);
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

  Future<void> _abrirDialogoMovimiento(String tipo) async {
    final cantidadCtrl = TextEditingController();
    final motivoCtrl = TextEditingController();
    final esAjuste = tipo == 'AJUSTE';

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          tipo == 'ENTRADA'
              ? 'Registrar entrada'
              : tipo == 'SALIDA'
                  ? 'Registrar salida'
                  : 'Ajustar stock (conteo físico)',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cantidadCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: esAjuste ? 'Stock real contado' : 'Cantidad',
                filled: true,
                fillColor: const Color(0xFF1B1B1B),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: motivoCtrl,
              decoration: const InputDecoration(
                labelText: 'Motivo (opcional)',
                filled: true,
                fillColor: Color(0xFF1B1B1B),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5AE6DF)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('CONFIRMAR',
                style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    final valor = int.tryParse(cantidadCtrl.text);
    if (valor == null || valor < 0) {
      _notificar('Ingresa un número válido', esError: true);
      return;
    }

    try {
      final actualizado = await DbHelper.instance.registrarMovimiento(
        producto: _producto,
        tipo: tipo,
        cantidad: valor,
        motivo: motivoCtrl.text.trim(),
      );
      setState(() {
        _producto = actualizado;
        _cargar();
      });
      _notificar('Movimiento registrado correctamente');
    } catch (e) {
      _notificar(e.toString().replaceFirst('Exception: ', ''), esError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('KARDEX · ${_producto.name}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          _buildResumenStock(),
          _buildBotonesAccion(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Divider(color: Colors.white10),
          ),
          Expanded(child: _buildListaMovimientos()),
        ],
      ),
    );
  }

  Widget _buildResumenStock() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('STOCK ACTUAL',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          Text('${_producto.stock}',
              style: const TextStyle(
                  color: Color(0xFF21E408),
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBotonesAccion() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _abrirDialogoMovimiento('ENTRADA'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF21E408)),
              icon: const Icon(Icons.arrow_downward, color: Colors.black),
              label: const Text('ENTRADA',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _abrirDialogoMovimiento('SALIDA'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent),
              icon: const Icon(Icons.arrow_upward, color: Colors.white),
              label: const Text('SALIDA',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _abrirDialogoMovimiento('AJUSTE'),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF5AE6DF))),
              icon: const Icon(Icons.tune, color: Color(0xFF5AE6DF)),
              label: const Text('AJUSTE',
                  style: TextStyle(color: Color(0xFF5AE6DF), fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaMovimientos() {
    return FutureBuilder<List<MovimientoKardex>>(
      future: _futureMovimientos,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF5AE6DF)));
        }
        final movimientos = snapshot.data ?? [];
        if (movimientos.isEmpty) {
          return const Center(
            child: Text('Sin movimientos registrados aún',
                style: TextStyle(color: Colors.grey)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 20),
          itemCount: movimientos.length,
          itemBuilder: (context, i) => _movimientoTile(movimientos[i]),
        );
      },
    );
  }

  Widget _movimientoTile(MovimientoKardex m) {
    final esEntrada = m.tipo == 'ENTRADA';
    final esAjuste = m.tipo == 'AJUSTE';
    final color = esAjuste
        ? const Color(0xFF5AE6DF)
        : (esEntrada ? const Color(0xFF21E408) : Colors.redAccent);
    final icono = esAjuste
        ? Icons.tune
        : (esEntrada ? Icons.arrow_downward : Icons.arrow_upward);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icono, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  esAjuste
                      ? 'Ajuste → ${m.stockNuevo} unidades'
                      : '${m.tipo} de ${m.cantidad} unidades',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                if (m.motivo.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(m.motivo,
                        style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '${m.stockAnterior} → ${m.stockNuevo} · ${_formatearFecha(m.fecha)}',
                    style: const TextStyle(color: Colors.white24, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatearFecha(DateTime f) {
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(f.day)}/${dos(f.month)}/${f.year} ${dos(f.hour)}:${dos(f.minute)}';
  }
}
