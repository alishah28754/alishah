// lib/pages/cart_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ktex_home/core/app_colors.dart';
import 'package:ktex_home/core/brand_pattern.dart';
import 'package:ktex_home/models/cart_model.dart';
import 'package:ktex_home/screens/buy_now_screen.dart';
import 'package:ktex_home/models/models.dart';
import 'package:ktex_home/screens/checkout_screen.dart';

class CartPage extends StatefulWidget {
  final VoidCallback onBack;

  const CartPage({super.key, required this.onBack});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  Map<String, bool> _selectedItems = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSelections();
    });
  }

  void _initializeSelections() {
    final cart = CartScope.of(context);
    final newSelections = <String, bool>{};
    for (var item in cart.items) {
      newSelections[item.id] = true;
    }
    setState(() {
      _selectedItems = newSelections;
    });
  }

  void _updateSelection(String id, bool selected) {
    setState(() {
      _selectedItems[id] = selected;
    });
  }

  void _toggleSelectAll() {
    setState(() {
      final allSelected = _selectedItems.isNotEmpty &&
          _selectedItems.values.every((v) => v);
      for (var key in _selectedItems.keys) {
        _selectedItems[key] = !allSelected;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).colorScheme.background;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final cardColor = Theme.of(context).colorScheme.surface;

    if (_selectedItems.length != cart.items.length && cart.items.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeSelections();
      });
    }

    for (var item in cart.items) {
      if (!_selectedItems.containsKey(item.id)) {
        _selectedItems[item.id] = true;
      }
    }

    final selectedCount = _selectedItems.values.where((v) => v).length;
    final selectedTotal = cart.items
        .where((item) => _selectedItems[item.id] ?? false)
        .fold<double>(0, (sum, item) => sum + item.lineTotal);

    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    final totalBottomSpace = bottomSafeArea;

    return Scaffold(
      backgroundColor: bgColor,
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: BrandPatternBackground()),
          ),
          SafeArea(
            child: Column(
              children: [
                _CartHeader(
                  onBack: widget.onBack,
                  textColor: textColor,
                  onClearAll: cart.items.isEmpty
                      ? null
                      : () {
                    HapticFeedback.lightImpact();
                    cart.clear();
                    setState(() {
                      _selectedItems = {};
                    });
                    _showSnack(context, 'Cart cleared');
                  },
                ),
                if (cart.items.isEmpty)
                  Expanded(
                    child: _EmptyCart(onStartShopping: widget.onBack),
                  )
                else
                  Expanded(
                    child: _CartContent(
                      cart: cart,
                      selectedItems: _selectedItems,
                      onSelectionChanged: _updateSelection,
                      onSnack: _showSnack,
                      isDark: isDark,
                      textColor: textColor,
                      cardColor: cardColor,
                      bottomPadding: totalBottomSpace + 120,
                    ),
                  ),
              ],
            ),
          ),
          if (cart.items.isNotEmpty)
            Positioned(
              bottom: totalBottomSpace,
              left: 16,
              right: 16,
              child: _CartSummaryBar(
                cart: cart,
                selectedCount: selectedCount,
                selectedTotal: selectedTotal,
                isDark: isDark,
                textColor: textColor,
                cardColor: cardColor,
                onCheckout: () {
                  if (selectedCount == 0) {
                    _showSnack(context, 'Please select at least one item');
                    return;
                  }
                  final selectedProducts = cart.items
                      .where((item) => _selectedItems[item.id] ?? false)
                      .map((item) => Product(
                    id: item.id,
                    name: item.name,
                    price: item.price,
                    imageUrl: item.imageUrl,
                    isPremium: false,
                  ))
                      .toList();

                  double total = 0;
                  for (var item in selectedProducts) {
                    final cartItem = cart.items.firstWhere(
                          (p) => p.id == item.id,
                      orElse: () => CartItem(
                        id: item.id,
                        name: item.name,
                        price: item.price,
                        imageUrl: item.imageUrl,
                        quantity: 1,
                      ),
                    );
                    total += item.price * cartItem.quantity;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CheckoutScreen(
                        products: selectedProducts,
                        total: total,
                      ),
                    ),
                  );
                },
                onSelectAll: _toggleSelectAll,
                allSelected: _selectedItems.isNotEmpty &&
                    _selectedItems.values.every((v) => v),
              ),
            ),
        ],
      ),
    );
  }

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
}

class _CartContent extends StatelessWidget {
  final CartModel cart;
  final Map<String, bool> selectedItems;
  final Function(String, bool) onSelectionChanged;
  final void Function(BuildContext, String) onSnack;
  final bool isDark;
  final Color textColor;
  final Color cardColor;
  final double bottomPadding;

  const _CartContent({
    required this.cart,
    required this.selectedItems,
    required this.onSelectionChanged,
    required this.onSnack,
    required this.isDark,
    required this.textColor,
    required this.cardColor,
    required this.bottomPadding,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        children: [
          _CartItemsList(
            cart: cart,
            selectedItems: selectedItems,
            onSelectionChanged: onSelectionChanged,
            onSnack: onSnack,
            isDark: isDark,
            textColor: textColor,
            cardColor: cardColor,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _CartItemsList extends StatelessWidget {
  final CartModel cart;
  final Map<String, bool> selectedItems;
  final Function(String, bool) onSelectionChanged;
  final void Function(BuildContext, String) onSnack;
  final bool isDark;
  final Color textColor;
  final Color cardColor;

  const _CartItemsList({
    required this.cart,
    required this.selectedItems,
    required this.onSelectionChanged,
    required this.onSnack,
    required this.isDark,
    required this.textColor,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    final items = cart.items;

    return Column(
      children: items.asMap().entries.map((entry) {
        final item = entry.value;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: _CartItemCard(
            item: item,
            isSelected: selectedItems[item.id] ?? true,
            isDark: isDark,
            textColor: textColor,
            cardColor: cardColor,
            onSelectionChanged: (selected) {
              onSelectionChanged(item.id, selected);
            },
            onIncrement: () {
              HapticFeedback.selectionClick();
              cart.incrementQuantity(item.id);
            },
            onDecrement: () {
              HapticFeedback.selectionClick();
              cart.decrementQuantity(item.id);
            },
            onRemove: () {
              HapticFeedback.lightImpact();
              final name = item.name;
              final id = item.id;
              cart.removeItem(id);
              onSnack(context, '$name removed from cart');
            },
          ),
        );
      }).toList(),
    );
  }
}

class _CartHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback? onClearAll;
  final Color textColor;

  const _CartHeader({
    required this.onBack,
    required this.textColor,
    this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: iconColor),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'My Cart',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: kFont,
                color: textColor,
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

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final bool isSelected;
  final bool isDark;
  final Color textColor;
  final Color cardColor;
  final Function(bool) onSelectionChanged;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const _CartItemCard({
    required this.item,
    required this.isSelected,
    required this.isDark,
    required this.textColor,
    required this.cardColor,
    required this.onSelectionChanged,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final mutedColor = isDark ? Colors.white60 : AppColors.outline;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: MediaQuery.of(context).textScaler.clamp(maxScaleFactor: 1.2),
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.gold.withOpacity(0.3)
                : (isDark ? Colors.white.withOpacity(0.1) : AppColors.outlineVariant.withOpacity(0.3)),
            width: isSelected ? 1.5 : 0.5,
          ),
          boxShadow: isDark ? [] : [
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
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: GestureDetector(
                onTap: () => onSelectionChanged(!isSelected),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.gold : (isDark ? Colors.grey[800] : Colors.white),
                    border: Border.all(
                      color: isSelected ? AppColors.gold : (isDark ? Colors.white.withOpacity(0.3) : AppColors.outlineVariant),
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 14, color: Colors.black)
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                item.imageUrl,
                width: 70,
                height: 88,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 70,
                  height: 88,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 10),
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
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: kFont,
                            color: isSelected ? textColor : mutedColor,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: onRemove,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: mutedColor,
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
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: kFont,
                      color: isSelected ? AppColors.saleRed : mutedColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _QuantityStepper(
                        quantity: item.quantity,
                        onIncrement: onIncrement,
                        onDecrement: onDecrement,
                        isDark: isDark,
                      ),
                      const Spacer(),
                      Text(
                        'Rs.${item.lineTotal}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          fontFamily: kFont,
                          color: isSelected ? textColor : mutedColor,
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
  final bool isDark;

  const _QuantityStepper({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final bgColor = isDark ? Colors.grey[800] : AppColors.surfaceContainerHigh;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove_rounded,
            onTap: onDecrement,
            isDark: isDark,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontFamily: kFont,
                color: textColor,
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.add_rounded,
            onTap: onIncrement,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _StepperButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isDark ? Colors.white : AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 16, color: iconColor),
        ),
      ),
    );
  }
}

class _CartSummaryBar extends StatelessWidget {
  final CartModel cart;
  final int selectedCount;
  final double selectedTotal;
  final VoidCallback onCheckout;
  final VoidCallback onSelectAll;
  final bool allSelected;
  final bool isDark;
  final Color textColor;
  final Color cardColor;

  const _CartSummaryBar({
    required this.cart,
    required this.selectedCount,
    required this.selectedTotal,
    required this.onCheckout,
    required this.onSelectAll,
    required this.allSelected,
    required this.isDark,
    required this.textColor,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final mutedColor = isDark ? Colors.white60 : AppColors.outline;

    double buttonWidth;
    if (screenWidth < 360) {
      buttonWidth = screenWidth * 0.85;
    } else if (screenWidth < 600) {
      buttonWidth = screenWidth * 0.65;
    } else if (screenWidth < 900) {
      buttonWidth = screenWidth * 0.5;
    } else {
      buttonWidth = 400;
    }

    final hasItems = cart.items.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : AppColors.outlineVariant.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasItems)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onSelectAll,
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: allSelected ? AppColors.gold : (isDark ? Colors.grey[800] : Colors.white),
                            border: Border.all(
                              color: allSelected ? AppColors.gold : (isDark ? Colors.white.withOpacity(0.3) : AppColors.outlineVariant),
                              width: 1.5,
                            ),
                          ),
                          child: allSelected
                              ? const Icon(Icons.check, size: 14, color: Colors.black)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Select All',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: kFont,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${selectedCount} item${selectedCount > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: kFont,
                        fontWeight: FontWeight.w600,
                        color: AppColors.goldDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (hasItems)
            Divider(
              color: isDark ? Colors.white.withOpacity(0.1) : AppColors.outlineVariant.withOpacity(0.3),
              height: 1,
            ),
          if (hasItems) const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Subtotal',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: kFont,
                  color: textColor,
                ),
              ),
              const Spacer(),
              Text(
                'Rs.${selectedTotal.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: kFont,
                  color: selectedCount > 0 ? textColor : mutedColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: SizedBox(
              width: buttonWidth,
              height: 50,
              child: ElevatedButton(
                onPressed: selectedCount == 0 ? null : onCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: isDark ? Colors.grey[800] : AppColors.outlineVariant,
                  disabledForegroundColor: isDark ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  selectedCount == 0
                      ? 'Select items to checkout'
                      : 'Checkout (${selectedCount} item${selectedCount > 1 ? 's' : ''})',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: kFont,
                  ),
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
              Icons.shopping_cart_outlined,
              size: 38,
              color: AppColors.goldDark,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: kFont,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Items you add will show up here',
            style: TextStyle(
              fontSize: 13,
              fontFamily: kFont,
              color: mutedColor,
            ),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: onStartShopping,
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