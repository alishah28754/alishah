class BannerSlide {
  final String title;
  final String subtitle;
  final String imageUrl;
  const BannerSlide({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
  });
}

class FlashSaleProduct {
  final String name;
  final String imageUrl;
  final int price;
  final int originalPrice;
  final int discountPercent;

  const FlashSaleProduct({
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.originalPrice,
    required this.discountPercent,
  });
}

class NewArrivalProduct {
  final String name;
  final String imageUrl;
  final int price;
  final String soldLabel;
  final bool isPremium;

  const NewArrivalProduct({
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.soldLabel,
    this.isPremium = false,
  });
}

class ForYouProduct {
  final String name;
  final String imageUrl;
  final int price;
  final String soldLabel;
  final bool isPremium;

  const ForYouProduct({
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.soldLabel,
    this.isPremium = false,
  });
}