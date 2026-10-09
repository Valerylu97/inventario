import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_inventario/services/database_helper.dart';
import 'package:go_router/go_router.dart';

class AddProductScreen extends StatefulWidget {
  final Product? producto; // Si viene con producto, es edición

  const AddProductScreen({super.key, this.producto});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();

  String? _imagePath;
  String _categoriaSeleccionada = 'Salado';
  List<String> _categorias = ['Salado', 'Dulce', 'Pastelería', 'Bebida', 'Otro'];
  bool _guardando = false;

  bool get _esEdicion => widget.producto != null;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
    if (_esEdicion) {
      final p = widget.producto!;
      _nombreCtrl.text = p.name;
      _cantidadCtrl.text = p.stock.toString();
      _precioCtrl.text = p.price.toString();
      _imagePath = p.imagePath;
      _categoriaSeleccionada = p.category;
    }
  }

  Future<void> _cargarCategorias() async {
    final prefs = await SharedPreferences.getInstance();
    final guardadas = prefs.getStringList('lista_categorias');
    if (guardadas != null) {
      setState(() {
        _categorias = guardadas;
        if (!_categorias.contains(_categoriaSeleccionada)) {
          _categoriaSeleccionada = _categorias.first;
        }
      });
    }
  }

  Future<void> _seleccionarImagen() async {
    final origen = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_camera, color: Color(0xFF5AE6DF)),
              title: const Text('Tomar foto',
                  style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: Color(0xFF5AE6DF)),
              title: const Text('Elegir de la galería',
                  style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (origen == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: origen, imageQuality: 80);
    if (picked != null) setState(() => _imagePath = picked.path);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    // En edición, el stock NO se toca aquí: se administra desde el Kardex
    // (botón "Kardex" en la tarjeta del producto) para que todo cambio de
    // cantidad quede registrado como un movimiento con historial.
    final stockInicial = _esEdicion
        ? widget.producto!.stock
        : int.parse(_cantidadCtrl.text);

    final producto = Product(
      id: widget.producto?.id,
      name: _nombreCtrl.text.trim(),
      stock: stockInicial,
      price: double.parse(_precioCtrl.text),
      category: _categoriaSeleccionada,
      imagePath: _imagePath,
    );

    final nuevoId = await DbHelper.instance.upsert(producto);

    // HU-Kardex: si es un producto nuevo con stock inicial > 0, se registra
    // automáticamente como un movimiento de ENTRADA ("Stock inicial"), para
    // que el historial Kardex quede completo desde el primer momento.
    if (!_esEdicion && stockInicial > 0) {
      final productoCreado = Product(
        id: nuevoId,
        name: producto.name,
        stock: 0, // arranca en 0 para que registrarMovimiento sume al stock
        price: producto.price,
        category: producto.category,
        imagePath: producto.imagePath,
      );
      await DbHelper.instance.registrarMovimiento(
        producto: productoCreado,
        tipo: 'ENTRADA',
        cantidad: stockInicial,
        motivo: 'Stock inicial',
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_esEdicion
              ? '${producto.name} actualizado'
              : '${producto.name} registrado con éxito'),
          backgroundColor: const Color.fromARGB(255, 46, 214, 12),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _esEdicion ? 'EDITAR PRODUCTO' : 'NUEVO PRODUCTO',
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.grey),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── IMAGEN ───────────────────────────────────────
              Center(child: _buildImagePicker()),

              const SizedBox(height: 24),

              // ── NOMBRE ───────────────────────────────────────
              _label('Nombre del producto'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nombreCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: _inputDeco('Ej: Pan de sal, Croissant...', Icons.label_outline),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'El nombre es obligatorio' : null,
              ),

              const SizedBox(height: 16),

              // ── STOCK y PRECIO ────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label(_esEdicion ? 'Stock (ver Kardex)' : 'Stock inicial'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _cantidadCtrl,
                          enabled: !_esEdicion,
                          keyboardType: TextInputType.number,
                          decoration: _inputDeco('0', Icons.inventory_2_outlined),
                          validator: (v) {
                            if (_esEdicion) return null;
                            final n = int.tryParse(v ?? '');
                            if (n == null) return 'Ingresa un número';
                            if (n < 0) return 'No puede ser negativo';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Precio (\$)'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _precioCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: _inputDeco('0.00', Icons.attach_money),
                          validator: (v) {
                            final n = double.tryParse(v ?? '');
                            if (n == null) return 'Ingresa un precio válido';
                            if (n <= 0) return 'Debe ser mayor a 0';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_esEdicion)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Para cambiar la cantidad usa el botón "Kardex" en la lista, así queda registrado el movimiento.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  ),
                ),

              const SizedBox(height: 16),

              // ── CATEGORÍA ─────────────────────────────────────
              _label('Categoría'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _categoriaSeleccionada,
                dropdownColor: const Color(0xFF121212),
                decoration: _inputDeco('', Icons.category_outlined),
                items: _categorias
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c),
                        ))
                    .toList(),
                onChanged: (val) =>
                    setState(() => _categoriaSeleccionada = val!),
              ),

              const SizedBox(height: 32),

              // ── BOTÓN GUARDAR ─────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _guardando ? null : _guardar,
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
                      : Icon(_esEdicion ? Icons.save : Icons.add_circle_outline),
                  label: Text(
                    _guardando
                        ? 'Guardando...'
                        : _esEdicion
                            ? 'GUARDAR CAMBIOS'
                            : 'REGISTRAR PRODUCTO',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),

              if (_esEdicion) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Cancelar',
                        style: TextStyle(color: Colors.grey)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── SELECTOR DE IMAGEN ────────────────────────────────────
  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _seleccionarImagen,
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          shape: BoxShape.circle,
          border: Border.all(
              color: const Color(0xFF5AE6DF).withValues(alpha: 0.5), width: 2),
        ),
        child: _imagePath == null
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined,
                      color: Color(0xFF5AE6DF), size: 30),
                  SizedBox(height: 4),
                  Text('Foto',
                      style: TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              )
            : ClipOval(
                child: Image.file(File(_imagePath!), fit: BoxFit.cover)),
      ),
    );
  }

  // ── HELPERS UI ────────────────────────────────────────────
  Widget _label(String text) {
    return Text(text,
        style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5));
  }

  InputDecoration _inputDeco(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey, size: 20),
      filled: true,
      fillColor: const Color(0xFF121212),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.white10),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.white10),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF5AE6DF)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}
