import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'bottom_nav.dart';
import 'cart_model.dart';
import 'cart_page.dart';
import 'favourites_page.dart';
import 'coming_soon_page.dart';
import 'home_page.dart';
import 'categories_page.dart';
import 'profile_screen.dart';
import 'order_screen.dart';

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

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Screen Content
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(bottom: 80 + bottomInset),
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