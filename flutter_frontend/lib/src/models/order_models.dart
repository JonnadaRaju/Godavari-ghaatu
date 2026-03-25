class OrderItem {
  const OrderItem({
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

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
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

class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    this.userId,
    this.updatedAt,
    this.subtotal,
    this.deliveryCharge,
    this.taxAmount,
    this.items = const [],
  });

  final String id;
  final String status;
  final double totalAmount;
  final DateTime createdAt;
  final String? userId;
  final DateTime? updatedAt;
  final double? subtotal;
  final double? deliveryCharge;
  final double? taxAmount;
  final List<OrderItem> items;

  bool get hasDetailedPricing => subtotal != null;


  OrderSummary copyWith({
    String? id,
    String? status,
    double? totalAmount,
    DateTime? createdAt,
    String? userId,
    DateTime? updatedAt,
    double? subtotal,
    double? deliveryCharge,
    double? taxAmount,
    List<OrderItem>? items,
  }) {
    return OrderSummary(
      id: id ?? this.id,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      updatedAt: updatedAt ?? this.updatedAt,
      subtotal: subtotal ?? this.subtotal,
      deliveryCharge: deliveryCharge ?? this.deliveryCharge,
      taxAmount: taxAmount ?? this.taxAmount,
      items: items ?? this.items,
    );
  }
  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? <dynamic>[];
    final itemsJson = rawItems.map((item) => Map<String, dynamic>.from(item as Map)).toList();

    return OrderSummary(
      id: json['id'].toString(),
      userId: json['user_id']?.toString(),
      status: (json['status'] as String?) ?? 'PENDING',
      subtotal: json['subtotal'] == null ? null : _asDouble(json['subtotal']),
      deliveryCharge: json['delivery_charge'] == null ? null : _asDouble(json['delivery_charge']),
      taxAmount: json['tax_amount'] == null ? null : _asDouble(json['tax_amount']),
      totalAmount: _asDouble(json['total_amount']),
      createdAt: _asDateTime(json['created_at']),
      updatedAt: json['updated_at'] == null ? null : _asDateTime(json['updated_at']),
      items: itemsJson.map(OrderItem.fromJson).toList(),
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

DateTime _asDateTime(dynamic value) {
  return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
}

