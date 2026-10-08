import 'dart:io';
import 'package:flutter/material.dart';
import 'package:app_inventario/models/producto.dart';

// Mapa de iconos por categoría para darle identidad visual a cada tipo de producto
const Map<String, IconData> _categoryIcons = {
  'Salado': Icons.lunch_dining,
  'Dulce': Icons.cake,
  'Pastelería': Icons.cookie,
  'Bebida': Icons.local_cafe,
  'Otro': Icons.bakery_dining,
};

const Map<String, Color> _categoryColors = {
  'Salado': Color(0xFFE67E22),
  'Dulce': Color(0xFFE91E8C),
  'Pastelería': Color(0xFF9C27B0),
  'Bebida': Color(0xFF5AE6DF),
  'Otro': Color(0xFF4CAF50),
};

class ProductCard extends StatelessWidget {
  final Product product;
  final bool bajoStock;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onKardex; // HU-Kardex: abre el historial de movimientos

  const ProductCard({
    super.key,
    required this.product,
    required this.bajoStock,
    required this.onEdit,
    required this.onDelete,
    required this.onKardex,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor =
        _categoryColors[product.category] ?? const Color(0xFF5AE6DF);
    final categoryIcon =
        _categoryIcons[product.category] ?? Icons.bakery_dining;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: bajoStock
              ? Colors.redAccent.withValues(alpha: 0.8)
              : categoryColor.withValues(alpha: 0.25),
          width: bajoStock ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: bajoStock
                ? Colors.redAccent.withValues(alpha: 0.15)
                : categoryColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── AVATAR / IMAGEN ──────────────────────────────────
            _buildAvatar(categoryColor, categoryIcon),

            const SizedBox(width: 12),

            // ── INFO PRINCIPAL ───────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Fila: categoría + stock
                  Row(
                    children: [
                      // Badge categoría
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(categoryIcon,
                                color: categoryColor, size: 10),
                            const SizedBox(width: 3),
                            Text(
                              product.category.toUpperCase(),
                              style: TextStyle(
                                color: categoryColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Stock con alerta si es bajo
                      Row(
                        children: [
                          if (bajoStock)
                            const Icon(Icons.warning_amber_rounded,
                                color: Colors.redAccent, size: 14),
                          if (bajoStock) const SizedBox(width: 3),
                          Text(
                            'Stock: ${product.stock}',
                            style: TextStyle(
                              color: bajoStock
                                  ? Colors.redAccent
                                  : Colors.grey[500],
                              fontSize: 12,
                              fontWeight: bajoStock
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Precio + acceso al Kardex
                  Row(
                    children: [
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFF21E408),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      // HU-Kardex: reemplaza los botones rápidos +/- por el
                      // acceso al historial de movimientos (entradas/salidas),
                      // que es donde ahora se modifica el stock.
                      TextButton.icon(
                        onPressed: onKardex,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF5AE6DF),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        icon: const Icon(Icons.receipt_long, size: 16),
                        label: const Text('Kardex',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // ── ACCIONES ─────────────────────────────────────────
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _actionButton(
                  icon: Icons.edit_note,
                  color: const Color(0xFF5AE6DF),
                  label: 'Editar',
                  onTap: onEdit,
                ),
                const SizedBox(height: 8),
                _actionButton(
                  icon: Icons.delete_outline,
                  color: Colors.redAccent,
                  label: 'Borrar',
                  onTap: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(Color categoryColor, IconData categoryIcon) {
    if (product.imagePath != null) {
      return CircleAvatar(
        radius: 28,
        backgroundImage: FileImage(File(product.imagePath!)),
      );
    }
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: categoryColor.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: categoryColor.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Icon(categoryIcon, color: categoryColor, size: 26),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 26),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
