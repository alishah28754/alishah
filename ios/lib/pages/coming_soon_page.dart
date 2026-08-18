// coming_soon_page.dart
import 'package:flutter/material.dart';
import 'package:ktex_home/core/app_colors.dart';

/// Generic placeholder used for every tab that isn't built yet
/// (Categories, Cart, Orders, Profile). Swap each usage for a real
/// screen as you build it — the shell already wires up navigation.
class ComingSoonPage extends StatelessWidget {
  final String title;
  final IconData icon;

  const ComingSoonPage({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.goldContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 38, color: AppColors.goldDark),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: kFont,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Coming soon',
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: kFont,
                  color: AppColors.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// REMOVED: FavouritesPage class - now using from favourites_page.dart