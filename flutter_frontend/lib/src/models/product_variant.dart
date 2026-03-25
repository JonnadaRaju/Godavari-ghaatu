class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.productId,
    required this.label,
    required this.price,
    required this.stockQuantity,
    required this.isActive,
  });

  final String id;
  final String productId;
  final String label;
  final double price;
  final int stockQuantity;
  final bool isActive;


  ProductVariant copyWith({
    String? id,
    String? productId,
    String? label,
    double? price,
    int? stockQuantity,
    bool? isActive,
  }) {
    return ProductVariant(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      label: label ?? this.label,
      price: price ?? this.price,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isActive: isActive ?? this.isActive,
    );
  }
  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'].toString(),
      productId: json['product_id'].toString(),
      label: (json['label'] as String?) ?? '',
      price: _asDouble(json['price']),
      stockQuantity: _asInt(json['stock_quantity']),
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

double _asDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _asInt(dynamic value) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

