/// Representa una venta registrada de un producto. Cada venta descuenta
/// automáticamente el stock del producto y genera un movimiento de tipo
/// SALIDA en el Kardex (motivo "Venta"), de modo que el inventario y el
/// reporte de ventas siempre queden consistentes entre sí.
class Venta {
  final int? id;
  final int productId;
  final String productName; // Denormalizado: así el reporte no depende de
  // que el producto siga existiendo si se elimina más adelante.
  final int cantidad;
  final double precioUnitario;
  final double total;
  final DateTime fecha;

  Venta({
    this.id,
    required this.productId,
    required this.productName,
    required this.cantidad,
    required this.precioUnitario,
    required this.total,
    required this.fecha,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'cantidad': cantidad,
      'precioUnitario': precioUnitario,
      'total': total,
      'fecha': fecha.toIso8601String(),
    };
  }

  factory Venta.fromMap(Map<String, dynamic> map) {
    return Venta(
      id: map['id'],
      productId: map['productId'],
      productName: map['productName'],
      cantidad: map['cantidad'],
      precioUnitario: map['precioUnitario'],
      total: map['total'],
      fecha: DateTime.parse(map['fecha']),
    );
  }
}
