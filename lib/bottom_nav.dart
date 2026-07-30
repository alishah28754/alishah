import 'package:flutter/material.dart';
import 'app_colors.dart';

/// A premium, compact bottom navigation bar inspired by Zara, H&M, and Nike.
/// Features a sleek floating pill design with smooth animations, reduced height,
/// and a distinctive active tab indicator.
class KTexBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final int cartCount;

  static const int homeIndex = 2;

  const KTexBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    this.cartCount = 0,
  });

  // Compact height - 20% slimmer than the original
  static const double _barHeight = 72; // Increased from 68 to prevent clipping
  static const double _bubbleSize = 54;
  static const double _bubbleOverlap = 10;

  static const _items = <_NavItemData>[
    _NavItemData(icon: Icons.grid_view_rounded, label: 'Categories'),
    _NavItemData(icon: Icons.shopping_cart_outlined, label: 'Cart'),
    _NavItemData(icon: Icons.home_rounded, label: 'Home'),
    _NavItemData(icon: Icons.receipt_long_outlined, label: 'Orders'),
    _NavItemData(icon: Icons.favorite_border_rounded, label: 'Favourites'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    final items = List<_NavItemData>.generate(
      _items.length,
      (i) => i == 1 ? _items[i].copyWith(badge: cartCount) : _items[i],
    );

    final stackHeight = _barHeight + _bubbleSize / 2 - _bubbleOverlap;

    return MediaQuery(
      // Fixed-height nav chrome: clamp text scale so large accessibility
      // font settings can't grow the labels past the fixed 72px bar height
      // (same reasoning as the clamp in widgets.dart's product cards).
      data: MediaQuery.of(context).copyWith(
        textScaler: MediaQuery.of(context).textScaler.clamp(maxScaleFactor: 1.15),
      ),
      child: Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + 12),
        child: SizedBox(
          height: stackHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / items.length;
              final bubbleCenter = itemWidth * (homeIndex + 0.5);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Sleek, glass-morphism background
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: _barHeight,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Tab items with animation
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: _barHeight,
                    child: Row(
                      children: List.generate(items.length, (i) {
                        final item = items[i];
                        final isHomeSlot = i == homeIndex;
                        final isActive = i == currentIndex;
                        final color = isActive
                            ? AppColors.goldDark
                            : AppColors.outline;

                        return Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => onTabSelected(i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              padding: const EdgeInsets.only(top: 10),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Icon with smooth scale and color transition
                                  AnimatedScale(
                                    scale: isActive ? 1.0 : 0.9,
                                    duration: const Duration(milliseconds: 200),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      curve: Curves.easeInOut,
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isActive
                                            ? AppColors.gold.withOpacity(0.12)
                                            : Colors.transparent,
                                      ),
                                      child: SizedBox(
                                        height: 28,
                                        child: isHomeSlot
                                            ? null
                                            : _IconWithBadge(
                                                icon: item.icon,
                                                color: color,
                                                size: 22,
                                                badge: item.badge,
                                              ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  // Label with more space
                                  Text(
                                    item.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: kFont,
                                      fontSize: 10,
                                      fontWeight: isActive
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isActive
                                          ? AppColors.goldDark
                                          : AppColors.outline.withOpacity(0.7),
                                      letterSpacing: isActive ? 0.3 : 0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  // Floating home button with premium gradient and glow
                  Positioned(
                    left: bubbleCenter - _bubbleSize / 2,
                    bottom: _barHeight - _bubbleOverlap - _bubbleSize / 2,
                    child: GestureDetector(
                      onTap: () => onTabSelected(homeIndex),
                      child: AnimatedScale(
                        scale: currentIndex == homeIndex ? 1.0 : 0.95,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutBack,
                        child: Container(
                          width: _bubbleSize,
                          height: _bubbleSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.gold,
                                AppColors.goldDark,
                              ],
                              stops: const [0.0, 1.0],
                            ),
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.goldDark.withOpacity(0.3),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                              BoxShadow(
                                color: AppColors.gold.withOpacity(0.2),
                                blurRadius: 30,
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              items[homeIndex].icon,
                              key: ValueKey(currentIndex == homeIndex),
                              color: Colors.black,
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;
  final int? badge;
  const _NavItemData({
    required this.icon,
    required this.label,
    this.badge,
  });

  _NavItemData copyWith({int? badge}) => _NavItemData(
        icon: icon,
        label: label,
        badge: badge ?? this.badge,
      );
}

/// Icon with an optional small badge (used for the cart count).
class _IconWithBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final int? badge;
  const _IconWithBadge({
    required this.icon,
    required this.color,
    required this.size,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Icon(icon, size: size, color: color),
        if (badge != null && badge! > 0)
          Positioned(
            top: -6,
            right: -8,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: AppColors.saleRed,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                badge! > 99 ? '99+' : '$badge',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}