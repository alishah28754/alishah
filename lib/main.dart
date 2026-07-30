import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'cart_model.dart';
import 'main_navigation_shell.dart';

void main() {
  runApp(const KTexApp());
}

class KTexApp extends StatefulWidget {
  const KTexApp({super.key});

  @override
  State<KTexApp> createState() => _KTexAppState();
}

class _KTexAppState extends State<KTexApp> {
  // Owned once for the lifetime of the app. When you add a real backend,
  // this is the seam to swap for Provider/Riverpod/Bloc — everything
  // downstream already reads through CartScope.of(context).
  final CartModel _cart = CartModel();

  @override
  Widget build(BuildContext context) {
    return CartScope(
      cart: _cart,
      child: MaterialApp(
        title: 'K-TEX',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: kFont,
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.gold,
            primary: AppColors.primary,
            background: AppColors.background,
          ),
        ),
        home: const MainNavigationShell(),
      ),
    );
  }
}
