import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

class KTexBottomNav extends StatelessWidget {
  final int currentIndex;
  final int cartCount;
  final ValueChanged<int> onTabSelected;

  const KTexBottomNav({
    super.key,
    required this.currentIndex,
    required this.cartCount,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Dark mode colors
    final navBgColor = isDark
        ? const Color(0xFF1A1A1A).withOpacity(0.9)
        : const Color(0xFFD3AF64).withOpacity(0.85);

    final navBorderColor = isDark
        ? Colors.white.withOpacity(0.1)
        : const Color(0xFF9C7A3A).withOpacity(0.8);

    final navShadowColor = isDark
        ? Colors.black.withOpacity(0.3)
        : Colors.black.withOpacity(0.05);

    return Padding(
      padding: EdgeInsets.fromLTRB(0, 0, 0, bottomInset + 16),
      child: SizedBox(
        height: 70,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // ---- Glass-morphism bar with dark mode support ----
            Positioned.fill(
              top: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    decoration: BoxDecoration(
                      color: navBgColor,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: navBorderColor,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: navShadowColor,
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Categories (Index 0)
                        _navItem(
                          icon: Icons.grid_view_rounded,
                          label: 'Categories',
                          isSelected: currentIndex == 0,
                          isDark: isDark,
                          onTap: () => onTabSelected(0),
                        ),
                        // Cart (Index 1) - With Badge
                        _navItem(
                          icon: Icons.shopping_cart_outlined,
                          label: 'Cart',
                          isSelected: currentIndex == 1,
                          isDark: isDark,
                          badge: cartCount > 0 ? cartCount.toString() : null,
                          onTap: () => onTabSelected(1),
                        ),
                        // Spacer for Home button
                        const SizedBox(width: 50),
                        // Orders (Index 3)
                        _navItem(
                          icon: Icons.receipt_long_outlined,
                          label: 'Orders',
                          isSelected: currentIndex == 3,
                          isDark: isDark,
                          onTap: () => onTabSelected(3),
                        ),
                        // Favourites (Index 4)
                        _navItem(
                          icon: Icons.favorite_border,
                          label: 'Wishlist',
                          isSelected: currentIndex == 4,
                          isDark: isDark,
                          onTap: () => onTabSelected(4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // ---- Floating Home Button (Center) ----
            Positioned(
              top: -8,
              child: GestureDetector(
                onTap: () => onTabSelected(2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.gold, AppColors.goldDark],
                        ),
                        border: Border.all(
                          color: isDark ? Colors.grey[800]! : Colors.white,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.home_rounded,
                        color: Colors.black,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Home',
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        color: currentIndex == 2
                            ? AppColors.goldDark
                            : (isDark ? Colors.white60 : AppColors.outline),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
    String? badge,
  }) {
    // Icon colors - white for non-active in dark mode
    final iconColor = isSelected
        ? AppColors.goldDark
        : (isDark ? Colors.white : Colors.black);

    // Label colors
    final labelColor = isSelected
        ? AppColors.goldDark
        : (isDark ? Colors.white60 : Colors.black);

    // Background circle color
    final bgColor = isSelected
        ? AppColors.gold.withOpacity(0.15)
        : Colors.transparent;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: bgColor,
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 22,
                  ),
                ),
                if (badge != null)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.saleRed,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        badge,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontFamily: 'Inter',
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: labelColor,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}