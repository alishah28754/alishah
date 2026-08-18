import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'brand_pattern.dart';
import 'cart_model.dart';
import 'favourites_model.dart';
import 'models.dart';
import 'product_detail_page.dart';
import 'buy_now_screen.dart';
import 'widgets.dart';

class FlashSalePage extends StatelessWidget {
  final List<FlashSaleProduct> products;

  const FlashSalePage({
    super.key,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).colorScheme.background;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: BrandPatternBackground()),
          ),
          SafeArea(
            child: Column(
              children: [
                _FlashSaleHeader(
                  textColor: textColor,
                  isDark: isDark,
                ),
                Expanded(
                  child: _FlashSaleGrid(
                    products: products,
                    isDark: isDark,
                    textColor: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlashSaleHeader extends StatelessWidget {
  final Color textColor;
  final bool isDark;

  const _FlashSaleHeader({
    required this.textColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isDark ? Colors.white : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Flash Sale',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                fontFamily: kFont,
                color: textColor,
                letterSpacing: -0.3,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.saleRed,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'SALE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                fontFamily: kFont,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlashSaleGrid extends StatelessWidget {
  final List<FlashSaleProduct> products;
  final bool isDark;
  final Color textColor;

  const _FlashSaleGrid({
    required this.products,
    required this.isDark,
    required this.textColor,
  });

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: kFont)),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _navigateToProductDetail(BuildContext context, Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(product: product),
      ),
    );
  }

  void _navigateToBuyNow(BuildContext context, Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BuyNowScreen(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favourites = FavouritesScope.of(context);
    final cart = CartScope.of(context);
    final cardColor = Theme.of(context).colorScheme.surface;
    final mutedColor = isDark ? Colors.white60 : AppColors.outline;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.6,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final isFav = favourites.isFavourite(product.id);

        return _FlashSaleGridCard(
          product: product,
          isFavourite: isFav,
          isDark: isDark,
          textColor: textColor,
          cardColor: cardColor,
          mutedColor: mutedColor,
          onTap: () => _navigateToProductDetail(context, product.toProduct()),
          onAddToCart: () {
            HapticFeedback.lightImpact();
            cart.addItem(
              id: product.id,
              name: product.name,
              imageUrl: product.imageUrl,
              price: product.price,
            );
            _showSnack(context, '${product.name} added to cart');
          },
          onFavouriteToggle: () {
            HapticFeedback.lightImpact();
            favourites.toggleFavourite(product.toProduct());
            final isNowFav = favourites.isFavourite(product.id);
            final msg = isNowFav
                ? '${product.name} added to favourites ❤️'
                : '${product.name} removed from favourites';
            _showSnack(context, msg);
          },
          onBuyNow: () => _navigateToBuyNow(context, product.toProduct()),
        );
      },
    );
  }
}

class _FlashSaleGridCard extends StatelessWidget {
  final FlashSaleProduct product;
  final bool isFavourite;
  final bool isDark;
  final Color textColor;
  final Color cardColor;
  final Color mutedColor;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;
  final VoidCallback onFavouriteToggle;
  final VoidCallback onBuyNow;

  const _FlashSaleGridCard({
    required this.product,
    required this.isFavourite,
    required this.isDark,
    required this.textColor,
    required this.cardColor,
    required this.mutedColor,
    required this.onTap,
    required this.onAddToCart,
    required this.onFavouriteToggle,
    required this.onBuyNow,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : AppColors.outlineVariant.withOpacity(0.2)),
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: AppColors.primary),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.saleRed,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '-${product.discountPercent}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          fontFamily: kFont,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onFavouriteToggle,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800]!.withOpacity(0.9) : Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          isFavourite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFavourite ? AppColors.saleRed : mutedColor,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: _FlashSaleProductMenuButton(
                      onAddToCart: onAddToCart,
                      onBuyNow: onBuyNow,
                      isDark: isDark,
                      textColor: textColor,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      fontFamily: kFont,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Rs.${product.price}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          fontFamily: kFont,
                          color: AppColors.saleRed,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Rs.${product.originalPrice}',
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: kFont,
                          color: mutedColor,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlashSaleProductMenuButton extends StatelessWidget {
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;
  final bool isDark;
  final Color textColor;

  const _FlashSaleProductMenuButton({
    required this.onAddToCart,
    required this.onBuyNow,
    required this.isDark,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(-10, 0),
      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      onSelected: (value) {
        if (value == 'cart') {
          HapticFeedback.lightImpact();
          onAddToCart();
        } else if (value == 'buy') {
          HapticFeedback.lightImpact();
          onBuyNow();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'cart',
          child: Row(
            children: [
              const Icon(
                Icons.shopping_cart_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Text(
                'Add to Cart',
                style: TextStyle(
                  fontFamily: kFont,
                  fontSize: 13,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'buy',
          child: Row(
            children: [
              const Icon(
                Icons.flash_on_outlined,
                size: 18,
                color: AppColors.goldDark,
              ),
              const SizedBox(width: 10),
              Text(
                'Buy Now',
                style: TextStyle(
                  fontFamily: kFont,
                  fontSize: 13,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.gold,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.more_horiz,
          size: 16,
          color: Colors.black,
        ),
      ),
    );
  }
}