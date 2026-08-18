// lib/main_navigation_shell.dart
import 'package:flutter/material.dart';
import 'package:ktex_home/core/app_colors.dart';
import 'package:ktex_home/navigation/bottom_nav.dart';
import 'package:ktex_home/models/cart_model.dart';
import 'package:ktex_home/pages/cart_page.dart';
import 'package:ktex_home/pages/favourites_page.dart';
import 'package:ktex_home/pages/coming_soon_page.dart';
import 'package:ktex_home/pages/home_page.dart';
import 'package:ktex_home/pages/categories_page.dart';
import 'package:ktex_home/screens/profile_screen.dart';
import 'package:ktex_home/screens/order_screen.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _navIndex = 2;
  String? _profileImage;

  void _onTabSelected(int index) {
    setState(() => _navIndex = index);
  }

  void _goToHome() {
    setState(() => _navIndex = 2);
  }

  void _openProfile() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ProfileScreen(),
      ),
    );

    if (result != null && result is String) {
      setState(() {
        _profileImage = result;
      });
    }
  }

  Widget _buildBody() {
    switch (_navIndex) {
      case 0:
        return const CategoriesPage();
      case 1:
        return CartPage(onBack: _goToHome);
      case 3:
        return OrderScreen(onGoHome: _goToHome);
      case 4:
        return FavouritesPage(onGoHome: _goToHome);
      case 2:
      default:
        return HomePage(
          onProfileTap: _openProfile,
          profileImage: _profileImage,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = CartScope.of(context).totalItemCount;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ Dark mode: Black background for bottom area
    final scaffoldBg = isDark ? Colors.black : AppColors.background;

    // Only add bottom padding for cart page
    final isCartPage = _navIndex == 1;
    final double contentBottomPadding = isCartPage ? (70.0 + 16.0 + bottomInset) : 0.0;

    return Scaffold(
      backgroundColor: scaffoldBg, // ✅ Dark mode = black, Light mode = original
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ✅ Bottom area background for dark mode (navbar ke neeche)
          if (isDark)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 90 + bottomInset,
              child: Container(
                color: Colors.black,
              ),
            ),
          // Screen Content
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(bottom: contentBottomPadding),
              child: _buildBody(),
            ),
          ),
          // Bottom Navigation
          Align(
            alignment: Alignment.bottomCenter,
            child: KTexBottomNav(
              currentIndex: _navIndex,
              cartCount: cartCount,
              onTabSelected: _onTabSelected,
            ),
          ),
        ],
      ),
    );
  }
}