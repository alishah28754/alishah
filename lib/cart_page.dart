import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'brand_pattern.dart';
import 'cart_model.dart';

/// Cart tab. Reads live from CartScope so it always reflects whatever
/// was added from Home / Categories.
class CartPage extends StatelessWidget {
  /// Called when the user taps the back arrow, or "Start Shopping" from
  /// the empty state — both just take them back to Home.
  final VoidCallback onBack;

  const CartPage({super.key, required this.onBack});

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

  @override
  Widget build(BuildContext context) {
    final cart = CartScope.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: BrandPatternBackground()),
          ),
          SafeArea(
            child: Column(
              children: [
                _CartHeader(
                  onBack: onBack,
                  onClearAll: cart.isEmpty
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          cart.clear();
                          _showSnack(context, 'Cart cleared');
                        },
                ),
                Expanded(
                  child: cart.isEmpty
                      ? _EmptyCart(onStartShopping: onBack)
                      : Column(
                          children: [
                            // Takes all the space above the fixed footer
                            // and scrolls independently of it.
                            Expanded(
                              child: _CartList(
                                cart: cart,
                                onSnack: _showSnack,
                              ),
                            ),
                            // Fixed footer — never scrolls, sits right
                            // at the bottom (no floating nav to clear).
                            CartSummaryBar(
                              cart: cart,
                              onCheckout: () => _showSnack(
                                context,
                                'Checkout not wired up yet — add your payment flow here',
                              ),
                            ),
                          ],
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

/// Simple back-arrow + title header, replacing the old sticky SliverAppBar
/// now that the page needs an explicit way back to Home.
class _CartHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback? onClearAll;

  const _CartHeader({required this.onBack, this.onClearAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            color: AppColors.primary,
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              'My Cart',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: kFont,
                color: AppColors.primary,
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (onClearAll != null)
            TextButton(
              onPressed: onClearAll,
              child: const Text(
                'Clear all',
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

class _CartList extends StatelessWidget {
  final CartModel cart;
  final void Function(BuildContext, String) onSnack;

  const _CartList({required this.cart, required this.onSnack});

  @override
  Widget build(BuildContext context) {
    final items = cart.items;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CartItemCard(
                  item: items[index],
                  onIncrement: () {
                    HapticFeedback.selectionClick();
                    cart.incrementQuantity(items[index].name);
                  },
                  onDecrement: () {
                    HapticFeedback.selectionClick();
                    cart.decrementQuantity(items[index].name);
                  },
                  onRemove: () {
                    HapticFeedback.lightImpact();
                    final name = items[index].name;
                    cart.removeItem(name);
                    onSnack(context, '$name removed from cart');
                  },
                ),
              ),
              childCount: items.length,
            ),
          ),
        ),
        // Small breathing room above the fixed footer.
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
      ],
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const _CartItemCard({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: MediaQuery.of(context).textScaler.clamp(maxScaleFactor: 1.2),
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                item.imageUrl,
                width: 76,
                height: 92,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 76,
                  height: 92,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: kFont,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: onRemove,
                        child: const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppColors.outline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Rs.${item.price}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: kFont,
                      color: AppColors.saleRed,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _QuantityStepper(
                        quantity: item.quantity,
                        onIncrement: onIncrement,
                        onDecrement: onDecrement,
                      ),
                      const Spacer(),
                      Text(
                        'Rs.${item.lineTotal}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          fontFamily: kFont,
                          color: AppColors.primary,
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

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _QuantityStepper({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove_rounded,
            onTap: onDecrement,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
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
          _StepperButton(
            icon: Icons.add_rounded,
            onTap: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
      ),
    );
  }
}

/// Fixed order-summary + checkout footer. Sits as the last item in a
/// Column alongside an Expanded, scrollable product list (see CartPage),
/// so it never scrolls with the list. The floating bottom nav is hidden
/// on this page, so it only needs to clear the device's own safe area.
class CartSummaryBar extends StatelessWidget {
  final CartModel cart;
  final VoidCallback onCheckout;

  const CartSummaryBar({
    super.key,
    required this.cart,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final subtotal = cart.subtotal;
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 14, 16, bottomSafeArea + 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text(
                'Subtotal',
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: kFont,
                  color: AppColors.outline,
                ),
              ),
              const Spacer(),
              Text(
                'Rs.$subtotal',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: kFont,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: cart.isEmpty ? null : onCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.outlineVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                'Checkout (${cart.totalItemCount})',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFamily: kFont,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  final VoidCallback onStartShopping;

  const _EmptyCart({required this.onStartShopping});

  @override
  Widget build(BuildContext context) {
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
              Icons.shopping_cart_outlined,
              size: 38,
              color: AppColors.goldDark,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: kFont,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Items you add will show up here',
            style: TextStyle(
              fontSize: 13,
              fontFamily: kFont,
              color: AppColors.outline,
            ),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: onStartShopping,
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
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
