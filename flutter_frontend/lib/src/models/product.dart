class Product {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stockQuantity,
    required this.category,
    required this.isVeg,
    required this.isBestseller,
    required this.isNewArrival,
    required this.isActive,
    required this.reviewCount,
    this.imageUrl,
    this.averageRating,
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final int stockQuantity;
  final String category;
  final bool isVeg;
  final bool isBestseller;
  final bool isNewArrival;
  final bool isActive;
  final String? imageUrl;
  final double? averageRating;
  final int reviewCount;

  bool get isInStock => isActive && stockQuantity > 0;
  bool get isCombo => category == 'combo';

  String get categoryLabel {
    switch (category) {
      case 'pickle':
        return 'Pickles';
      case 'spice':
        return 'Spices';
      case 'laddu':
        return 'Laddus';
      case 'combo':
        return 'Combos';
      default:
        return category;
    }
  }


  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    int? stockQuantity,
    String? category,
    bool? isVeg,
    bool? isBestseller,
    bool? isNewArrival,
    bool? isActive,
    String? imageUrl,
    double? averageRating,
    int? reviewCount,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      category: category ?? this.category,
      isVeg: isVeg ?? this.isVeg,
      isBestseller: isBestseller ?? this.isBestseller,
      isNewArrival: isNewArrival ?? this.isNewArrival,
      isActive: isActive ?? this.isActive,
      imageUrl: imageUrl ?? this.imageUrl,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      name: (json['name'] as String?) ?? 'Unnamed Product',
      description: (json['description'] as String?) ?? '',
      price: _asDouble(json['price']),
      stockQuantity: _asInt(json['stock_quantity']),
      category: (json['category'] as String?) ?? 'pickle',
      isVeg: json['is_veg'] as bool? ?? true,
      isBestseller: json['is_bestseller'] as bool? ?? false,
      isNewArrival: json['is_new_arrival'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      imageUrl: json['image_url'] as String?,
      averageRating: json['average_rating'] == null ? null : _asDouble(json['average_rating']),
      reviewCount: _asInt(json['review_count']),
    );
  }

  static List<Product> previewItems() {
    return const [
      Product(
        id: '1',
        name: 'Mango Pickle',
        description: 'Traditional Andhra mango pickle with a deep, spicy finish.',
        price: 250,
        stockQuantity: 40,
        category: 'pickle',
        isVeg: true,
        isBestseller: true,
        isNewArrival: false,
        isActive: true,
        reviewCount: 18,
        averageRating: 4.7,
      ),
      Product(
        id: '2',
        name: 'Sesame Podi',
        description: 'Roasted sesame spice powder for rice and idli.',
        price: 180,
        stockQuantity: 28,
        category: 'spice',
        isVeg: true,
        isBestseller: false,
        isNewArrival: true,
        isActive: true,
        reviewCount: 7,
        averageRating: 4.5,
      ),
      Product(
        id: '3',
        name: 'Dry Fruit Laddu',
        description: 'Handmade laddu with dates, nuts, and ghee.',
        price: 320,
        stockQuantity: 15,
        category: 'laddu',
        isVeg: true,
        isBestseller: true,
        isNewArrival: false,
        isActive: true,
        reviewCount: 12,
        averageRating: 4.8,
      ),
      Product(
        id: '4',
        name: 'Festival Combo Box',
        description: 'A curated bundle of pickles, spice powder, and festive sweets.',
        price: 799,
        stockQuantity: 12,
        category: 'combo',
        isVeg: true,
        isBestseller: true,
        isNewArrival: true,
        isActive: true,
        reviewCount: 5,
        averageRating: 4.9,
      ),
    ];
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

