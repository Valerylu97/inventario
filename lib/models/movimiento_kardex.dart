/// HU-Kardex: Representa un movimiento de inventario (entrada, salida o
/// ajuste) asociado a un producto. Cada movimiento queda registrado de forma
/// inmutable para poder reconstruir el historial de stock de un producto
/// (control tipo Kardex), en lugar de solo guardar el valor final de stock.
class MovimientoKardex {
  final int? id;
  final int productId;

  /// 'ENTRADA' | 'SALIDA' | 'AJUSTE'
  final String tipo;

  /// Cantidad del movimiento. En ENTRADA/SALIDA es la cantidad movida;
  /// en AJUSTE es el nuevo valor absoluto de stock.
  final int cantidad;

  final int stockAnterior;
  final int stockNuevo;
  final String motivo;
  final DateTime fecha;

  MovimientoKardex({
    this.id,
    required this.productId,
    required this.tipo,
    required this.cantidad,
    required this.stockAnterior,
    required this.stockNuevo,
    this.motivo = '',
    required this.fecha,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'tipo': tipo,
      'cantidad': cantidad,
      'stockAnterior': stockAnterior,
      'stockNuevo': stockNuevo,
      'motivo': motivo,
      'fecha': fecha.toIso8601String(),
    };
  }

  factory MovimientoKardex.fromMap(Map<String, dynamic> map) {
    return MovimientoKardex(
      id: map['id'],
      productId: map['productId'],
      tipo: map['tipo'],
      cantidad: map['cantidad'],
      stockAnterior: map['stockAnterior'],
      stockNuevo: map['stockNuevo'],
      motivo: map['motivo'] ?? '',
      fecha: DateTime.parse(map['fecha']),
    );
  }
}
