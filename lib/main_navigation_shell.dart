import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'bottom_nav.dart';
import 'cart_model.dart';
import 'cart_page.dart';
import 'coming_soon_page.dart';
import 'home_page.dart';
import 'categories_page.dart';  // ← Add this import

/// Owns the bottom nav + switches between Home and the placeholder tabs.
/// Nav bar order: 0 Categories, 1 Cart, 2 Home, 3 Orders, 4 Favourites.
/// Profile is reached only via the person icon in Home's top bar.
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _navIndex = 2; // Home is selected by default

  void _onTabSelected(int index) {
    setState(() => _navIndex = index);
  }

  void _goToHome() {
    setState(() => _navIndex = 2);
  }

  void _openProfile() {
    // Profile isn't one of the 4 bottom-nav slots — push it as its own
    // screen so the floating nav stays exactly as designed.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ComingSoonPage(
          title: 'Profile',
          icon: Icons.person_outline,
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_navIndex) {
      case 0:
        return const CategoriesPage();  // ← Now using the real Categories page
      case 1:
        return CartPage(onBack: _goToHome);
      case 3:
        return const ComingSoonPage(
            title: 'Orders', icon: Icons.receipt_long_outlined);
      case 4:
        return const FavouritesPage();
      case 2:
      default:
        return HomePage(onProfileTap: _openProfile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = CartScope.of(context).totalItemCount;
    final onCartTab = _navIndex == 1;

    return Scaffold(
      backgroundColor: const Color(0x00ffffff), // fully transparent
      extendBody: true, // lets content peek behind the floating nav
      body: _buildBody(),
      // Cart has its own back button + fixed checkout footer, so the
      // floating nav is hidden there instead of stacking two "ways back".
      bottomNavigationBar: onCartTab
          ? null
          : KTexBottomNav(
              currentIndex: _navIndex,
              cartCount: cartCount,
              onTabSelected: _onTabSelected,
            ),
    );
  }
}