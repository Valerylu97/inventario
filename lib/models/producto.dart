class Product {
  final int? id;
  final String name;
  int stock;
  final double price;
  final String category;
  final String? imagePath; // HU03: Soporte para imagen

  Product({
    this.id,
    required this.name,
    required this.stock,
    required this.price,
    required this.category,
    this.imagePath,
  });

  // HU05: Conversión para persistencia local en SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'stock': stock,
      'price': price,
      'category': category,
      'imagePath': imagePath,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      stock: map['stock'],
      price: map['price'],
      category: map['category'],
      imagePath: map['imagePath'],
    );
  }
}
