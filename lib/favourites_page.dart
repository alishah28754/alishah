import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'brand_pattern.dart';
import 'cart_model.dart';
import 'favourites_model.dart';
import 'models.dart';
import 'main_navigation_shell.dart';

class FavouritesPage extends StatelessWidget {
  final VoidCallback? onGoHome;

  const FavouritesPage({super.key, this.onGoHome});

  @override
  Widget build(BuildContext context) {
    final favourites = FavouritesScope.of(context);
    final cart = CartScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).colorScheme.background;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final cardColor = Theme.of(context).colorScheme.surface;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor),
          onPressed: onGoHome ?? () => Navigator.of(context).pop(),
        ),
        title: Text(
          'My Wishlist',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: BrandPatternBackground()),
          ),
          SafeArea(
            top: false,
            child: Column(
              children: [
                _FavouritesHeader(
                  itemCount: favourites.count,
                  isDark: isDark,
                  textColor: textColor,
                  onClearAll: favourites.isEmpty
                      ? null
                      : () {
                    HapticFeedback.lightImpact();
                    favourites.clearAll();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'All favourites cleared',
                          style: TextStyle(fontFamily: kFont),
                        ),
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                Expanded(
                  child: favourites.isEmpty
                      ? const _EmptyFavourites()
                      : _FavouritesGrid(
                    favourites: favourites,
                    cart: cart,
                    isDark: isDark,
                    textColor: textColor,
                    cardColor: cardColor,
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

class _FavouritesHeader extends StatelessWidget {
  final int itemCount;
  final VoidCallback? onClearAll;
  final bool isDark;
  final Color textColor;

  const _FavouritesHeader({
    required this.itemCount,
    this.onClearAll,
    required this.isDark,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final mutedColor = isDark ? Colors.white60 : AppColors.outline;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'My Wishlist',
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
          if (itemCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$itemCount items',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: kFont,
                  color: AppColors.goldDark,
                ),
              ),
            ),
          const SizedBox(width: 8),
          if (onClearAll != null)
            TextButton(
              onPressed: onClearAll,
              child: const Text(
                'Clear All',
                style: TextStyle(
                  fontFamily: kFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.saleRed,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyFavourites extends StatelessWidget {
  const _EmptyFavourites();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = isDark ? Colors.white60 : AppColors.outline;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: AppColors.goldContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_border_rounded,
              size: 38,
              color: AppColors.goldDark,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No favourites yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: kFont,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Products you love will appear here',
            style: TextStyle(
              fontSize: 13,
              fontFamily: kFont,
              color: mutedColor,
            ),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const MainNavigationShell(),
                ),
                    (route) => false,
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text(
              'Start Shopping',
              style: TextStyle(
                fontSize: 13,
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

class _FavouritesGrid extends StatelessWidget {
  final FavouritesModel favourites;
  final CartModel cart;
  final bool isDark;
  final Color textColor;
  final Color cardColor;

  const _FavouritesGrid({
    required this.favourites,
    required this.cart,
    required this.isDark,
    required this.textColor,
    required this.cardColor,
  });

  void _showSnack(BuildContext context, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: kFont,
            color: Colors.white,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.black,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.only(
          bottom: 80 + bottomInset,
          left: 16,
          right: 16,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = favourites.items;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.6,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final product = items[index];
        return _FavouriteCard(
          product: product,
          isDark: isDark,
          textColor: textColor,
          cardColor: cardColor,
          onFavouriteToggle: () {
            HapticFeedback.lightImpact();
            favourites.toggleFavourite(product);
            _showSnack(context, '${product.name} removed from favourites');
          },
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
          onTap: () {
            _showSnack(context, 'Opening ${product.name}...');
          },
        );
      },
    );
  }
}

class _FavouriteCard extends StatelessWidget {
  final Product product;
  final VoidCallback onFavouriteToggle;
  final VoidCallback onAddToCart;
  final VoidCallback onTap;
  final bool isDark;
  final Color textColor;
  final Color cardColor;

  const _FavouriteCard({
    required this.product,
    required this.onFavouriteToggle,
    required this.onAddToCart,
    required this.onTap,
    required this.isDark,
    required this.textColor,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    final mutedColor = isDark ? Colors.white60 : AppColors.outline;

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
                  if (product.isPremium)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.goldDark,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'PREMIUM',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            fontFamily: kFont,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onFavouriteToggle();
                      },
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
                          Icons.favorite_rounded,
                          size: 18,
                          color: AppColors.saleRed,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onAddToCart();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
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
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 14,
                              color: Colors.black,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Add',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                fontFamily: kFont,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                  Text(
                    'Rs.${product.price}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: kFont,
                      color: textColor,
                    ),
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