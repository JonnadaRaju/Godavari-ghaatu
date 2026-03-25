class ComboItem {
  const ComboItem({
    required this.id,
    required this.comboProductId,
    required this.componentProductId,
    required this.quantity,
    required this.componentName,
    required this.componentPrice,
    this.componentImageUrl,
  });

  final String id;
  final String comboProductId;
  final String componentProductId;
  final int quantity;
  final String componentName;
  final double componentPrice;
  final String? componentImageUrl;


  ComboItem copyWith({
    String? id,
    String? comboProductId,
    String? componentProductId,
    int? quantity,
    String? componentName,
    double? componentPrice,
    String? componentImageUrl,
  }) {
    return ComboItem(
      id: id ?? this.id,
      comboProductId: comboProductId ?? this.comboProductId,
      componentProductId: componentProductId ?? this.componentProductId,
      quantity: quantity ?? this.quantity,
      componentName: componentName ?? this.componentName,
      componentPrice: componentPrice ?? this.componentPrice,
      componentImageUrl: componentImageUrl ?? this.componentImageUrl,
    );
  }
  factory ComboItem.fromJson(Map<String, dynamic> json) {
    return ComboItem(
      id: json['id'].toString(),
      comboProductId: json['combo_product_id'].toString(),
      componentProductId: json['component_product_id'].toString(),
      quantity: _asInt(json['quantity']),
      componentName: (json['component_name'] as String?) ?? 'Component',
      componentPrice: _asDouble(json['component_price']),
      componentImageUrl: json['component_image_url'] as String?,
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

