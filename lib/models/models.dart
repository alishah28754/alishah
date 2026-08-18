// models.dart

/// MySQL DECIMAL columns (price, original_price, stock, etc.) often arrive
/// as Strings (or occasionally null) rather than raw ints depending on the
/// driver config — this coerces any of those shapes into a safe int.
int _toInt(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is String) return int.tryParse(value) ?? (double.tryParse(value)?.round() ?? fallback);
  return fallback;
}

/// Same idea but returns null instead of a fallback — for optional int
/// fields like original_price / discount_percent that can legitimately
/// be absent.
int? _toIntOrNull(dynamic value) {
  if (value == null) return null;
  return _toInt(value);
}

class BannerSlide {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String? category; // Optional: links banner CTA to a category page

  const BannerSlide({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.category,
  });

  // For future API integration
  factory BannerSlide.fromJson(Map<String, dynamic> json) {
    return BannerSlide(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      imageUrl: json['image_url'] ?? '',
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'image_url': imageUrl,
      'category': category,
    };
  }
}

/// Unified Product model - used everywhere in the app
class Product {
  final String id;
  final String name;
  final String imageUrl;
  final int price;
  final int? originalPrice;      // For flash sales
  final int? discountPercent;    // For flash sales
  final String? soldLabel;       // For new arrivals/for you
  final int stock;               // Units left — drives in-stock/out-of-stock display
  final bool isPremium;
  final String? category;        // Optional categorization
  final Map<String, dynamic>? metadata; // For extra fields

  const Product({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    this.originalPrice,
    this.discountPercent,
    this.soldLabel,
    this.stock = 0,
    this.isPremium = false,
    this.category,
    this.metadata,
  });

  // For future API integration
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      imageUrl: json['image_url'] ?? '',
      price: _toInt(json['price']),
      originalPrice: _toIntOrNull(json['original_price']),
      discountPercent: _toIntOrNull(json['discount_percent']),
      soldLabel: json['sold_label']?.toString(),
      stock: _toInt(json['stock']),
      isPremium: json['is_premium'] ?? false,
      category: json['category'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
      'price': price,
      'original_price': originalPrice,
      'discount_percent': discountPercent,
      'sold_label': soldLabel,
      'stock': stock,
      'is_premium': isPremium,
      'category': category,
      'metadata': metadata,
    };
  }
}

// Keep these for backward compatibility, but they'll use Product internally

class FlashSaleProduct {
  final String id;
  final String name;
  final String imageUrl;
  final int price;
  final int originalPrice;
  final int discountPercent;
  final String? soldLabel;
  final int stock;
  final bool isPremium;

  const FlashSaleProduct({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.originalPrice,
    required this.discountPercent,
    this.soldLabel,
    this.stock = 0,
    this.isPremium = false,
  });

  Product toProduct() {
    return Product(
      id: id,
      name: name,
      price: price,
      imageUrl: imageUrl,
      soldLabel: soldLabel,
      stock: stock,
      isPremium: isPremium,
    );
  }
}

class NewArrivalProduct {
  final String id;
  final String name;
  final String imageUrl;
  final int price;
  final String soldLabel;
  final int stock;
  final bool isPremium;

  const NewArrivalProduct({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.soldLabel,
    this.stock = 0,
    this.isPremium = false,
  });

  Product toProduct() => Product(
    id: id,
    name: name,
    imageUrl: imageUrl,
    price: price,
    soldLabel: soldLabel,
    stock: stock,
    isPremium: isPremium,
  );
}

class ForYouProduct {
  final String id;
  final String name;
  final String imageUrl;
  final int price;
  final String soldLabel;
  final int stock;
  final bool isPremium;

  const ForYouProduct({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.soldLabel,
    this.stock = 0,
    this.isPremium = false,
  });

  Product toProduct() => Product(
    id: id,
    name: name,
    imageUrl: imageUrl,
    price: price,
    soldLabel: soldLabel,
    stock: stock,
    isPremium: isPremium,
  );
}