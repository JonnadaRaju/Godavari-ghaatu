class CartItem {
  const CartItem({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.variantId,
    this.variantLabel,
  });

  final String id;
  final String productId;
  final String? variantId;
  final String? variantLabel;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'].toString(),
      productId: json['product_id'].toString(),
      variantId: json['variant_id']?.toString(),
      variantLabel: json['variant_label'] as String?,
      quantity: _asInt(json['quantity']),
      unitPrice: _asDouble(json['unit_price']),
      lineTotal: _asDouble(json['line_total']),
    );
  }
}

class CartData {
  const CartData({
    required this.id,
    required this.items,
    required this.totalAmount,
  });

  final String id;
  final List<CartItem> items;
  final double totalAmount;

  const CartData.empty()
      : id = 'cart',
        items = const [],
        totalAmount = 0;

  bool get isEmpty => items.isEmpty;

  factory CartData.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? <dynamic>[];
    final itemsJson = rawItems.map((item) => Map<String, dynamic>.from(item as Map)).toList();

    return CartData(
      id: json['id'].toString(),
      items: itemsJson.map(CartItem.fromJson).toList(),
      totalAmount: _asDouble(json['total_amount']),
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
