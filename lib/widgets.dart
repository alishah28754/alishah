import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'models.dart';

/// Compact cards below (Flash Sale, New Arrivals, For You) have a fixed
/// width and/or height dictated by their parent (a fixed-height horizontal
/// list, or a fixed childAspectRatio grid). Letting system text-scale
/// settings (accessibility "larger text") apply at full strength here is
/// what causes RenderFlex overflow on some devices but not others — the
/// card size doesn't change, but the text inside it does. Clamping the
/// scale to a sane max keeps these cards legible without letting them
/// blow past a box size we don't control from here.
Widget _clampedTextScale(BuildContext context, Widget child) {
  return MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: MediaQuery.of(context).textScaler.clamp(maxScaleFactor: 1.2),
    ),
    child: child,
  );
}

/// Horizontal flash-sale card — image, discount badge, price + strikethrough.
class FlashSaleCard extends StatelessWidget {
  final FlashSaleProduct product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onAddToFavourites;

  const FlashSaleCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
    this.onAddToFavourites,
  });

  @override
  Widget build(BuildContext context) {
    return _clampedTextScale(
      context,
      GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.network(
                  product.imageUrl,
                  height: 110,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(height: 110, color: AppColors.primary),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.saleRed,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '-${product.discountPercent}%',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        fontFamily: kFont,
                      ),
                    ),
                  ),
                ),
                // Three dots menu - Gold pill with black dots
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: _ProductMenuButton(
                    onAddToCart: onAddToCart,
                    onAddToFavourites: onAddToFavourites,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontFamily: kFont),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rs.${product.price}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: kFont,
                      color: AppColors.saleRed,
                    ),
                  ),
                  Text(
                    'Rs.${product.originalPrice}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontFamily: kFont,
                      color: AppColors.outline,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

/// New Arrival horizontal card with "NEW" badge and three-dots menu
class NewArrivalCard extends StatelessWidget {
  final NewArrivalProduct product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onAddToFavourites;

  const NewArrivalCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
    this.onAddToFavourites,
  });

  @override
  Widget build(BuildContext context) {
    return _clampedTextScale(
      context,
      GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.network(
                  product.imageUrl,
                  height: 130,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(height: 130, color: AppColors.primary),
                ),
                // "NEW" badge
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'NEW',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        fontFamily: kFont,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                // Premium badge if applicable
                if (product.isPremium)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                          fontFamily: kFont,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                // Three dots menu - Gold pill with black dots
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: _ProductMenuButton(
                    onAddToCart: onAddToCart,
                    onAddToFavourites: onAddToFavourites,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: kFont,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Flexible + ellipsis: without this, a long price
                      // (e.g. Rs.120000) plus a long sold label together
                      // can be wider than the 140px card, causing a
                      // horizontal RenderFlex overflow on some data/devices
                      // even though it looked fine with shorter sample data.
                      Flexible(
                        child: Text(
                          'Rs.${product.price}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            fontFamily: kFont,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          product.soldLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 9,
                            fontFamily: kFont,
                            color: AppColors.outline,
                          ),
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
      ),
    );
  }
}

/// 2-column grid product card with three-dots menu + optional "Premium" tag.
class ForYouCard extends StatelessWidget {
  final ForYouProduct product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onAddToFavourites;

  const ForYouCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
    this.onAddToFavourites,
  });

  @override
  Widget build(BuildContext context) {
    return _clampedTextScale(
      context,
      GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.outlineVariant.withOpacity(0.2)),
          boxShadow: [
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
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 3 / 4,
                  child: Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: AppColors.primary),
                  ),
                ),
                if (product.isPremium)
                  Positioned(
                    top: 6,
                    left: 6,
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
                // Three dots menu - Gold pill with black dots
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: _ProductMenuButton(
                    onAddToCart: onAddToCart,
                    onAddToFavourites: onAddToFavourites,
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontFamily: kFont),
                    ),
                    Row(
                      children: [
                        // Flexible + ellipsis on both sides: with
                        // mainAxisAlignment.spaceBetween and no Flexible,
                        // a long price next to a long sold-count label can
                        // together exceed the narrow 2-column grid cell
                        // width, especially at larger text-scale settings.
                        Flexible(
                          child: Text(
                            'Rs.${product.price}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              fontFamily: kFont,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            product.soldLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 9,
                              fontFamily: kFont,
                              color: AppColors.outline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

/// Three dots menu button in a gold pill with black dots
class _ProductMenuButton extends StatelessWidget {
  final VoidCallback? onAddToCart;
  final VoidCallback? onAddToFavourites;

  const _ProductMenuButton({
    this.onAddToCart,
    this.onAddToFavourites,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: PopupMenuButton<String>(
        offset: const Offset(0, 10),
        onSelected: (value) {
          if (value == 'cart' && onAddToCart != null) {
            onAddToCart!();
          } else if (value == 'favourites' && onAddToFavourites != null) {
            onAddToFavourites!();
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
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Add to Cart',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: kFont,
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'favourites',
            child: Row(
              children: [
                const Icon(
                  Icons.favorite_border_rounded,
                  size: 18,
                  color: AppColors.saleRed,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Add to Favourites',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: kFont,
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.more_horiz,
                size: 16,
                color: Colors.black,
              ),
            ],
          ),
        ),
      ),
    );
  }
}