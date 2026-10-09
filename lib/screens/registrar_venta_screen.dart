import 'package:flutter/material.dart';
import 'package:app_inventario/services/database_helper.dart';
import 'package:go_router/go_router.dart';

/// Pantalla para registrar la venta de un producto del inventario.
/// Internamente usa DbHelper.registrarVenta(), que descuenta el stock y
/// deja constancia del movimiento en el Kardex de forma automática.
class RegistrarVentaScreen extends StatefulWidget {
  const RegistrarVentaScreen({super.key});

  @override
  State<RegistrarVentaScreen> createState() => _RegistrarVentaScreenState();
}

class _RegistrarVentaScreenState extends State<RegistrarVentaScreen> {
  final _cantidadCtrl = TextEditingController();
  Product? _productoSeleccionado;
  List<Product> _productos = [];
  bool _cargando = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
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
      _notificar('Selecciona un producto', esError: true);
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
          _productoSeleccionado = null;
        });
        _cargarProductos(); // refresca el stock disponible
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('REGISTRAR VENTA',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF5AE6DF)))
          : _productos.isEmpty
              ? const Center(
                  child: Text('No hay productos con stock disponible',
                      style: TextStyle(color: Colors.grey)),
                )
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Producto',
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<Product>(
                        initialValue: _productoSeleccionado,
                        dropdownColor: const Color(0xFF121212),
                        decoration: InputDecoration(
                          hintText: 'Selecciona un producto',
                          filled: true,
                          fillColor: const Color(0xFF121212),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: Colors.white10)),
                        ),
                        items: _productos
                            .map((p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(
                                      '${p.name} (stock: ${p.stock}) · \$${p.price.toStringAsFixed(2)}'),
                                ))
                            .toList(),
                        onChanged: (p) =>
                            setState(() => _productoSeleccionado = p),
                      ),
                      const SizedBox(height: 20),
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
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: Colors.white10)),
                        ),
                      ),
                      const SizedBox(height: 24),
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
                          label: Text(_guardando
                              ? 'Registrando...'
                              : 'CONFIRMAR VENTA'),
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
}
