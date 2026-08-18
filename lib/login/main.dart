import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'app_colors.dart';
import 'cart_model.dart';
import 'favourites_model.dart';
import 'main_navigation_shell.dart';
import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'order_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Draw app content behind the system status/navigation bars (edge-to-edge)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Make the system navigation bar transparent so it doesn't show
  // a solid color block behind the floating bottom nav
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarColor: Colors.transparent,
    ),
  );

  runApp(const KTexApp());
}

class KTexApp extends StatefulWidget {
  const KTexApp({super.key});

  @override
  State<KTexApp> createState() => _KTexAppState();
}

class _KTexAppState extends State<KTexApp> {
  final CartModel _cart = CartModel();
  final FavouritesModel _favourites = FavouritesModel();
  final OrderModel _orders = OrderModel();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: _orders),
      ],
      child: CartScope(
        cart: _cart,
        child: FavouritesScope(
          favourites: _favourites,
          child: Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              // ============================================================
              // LIGHT THEME
              // ============================================================
              final lightTheme = ThemeData(
                useMaterial3: true,
                fontFamily: kFont,
                brightness: Brightness.light,
                scaffoldBackgroundColor: AppColors.background,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: AppColors.gold,
                  primary: AppColors.primary,
                  background: AppColors.background,
                  brightness: Brightness.light,
                ),
              );

              // ============================================================
              // DARK THEME – Professional, black background, white text
              // ============================================================
              final darkTheme = ThemeData(
                useMaterial3: true,
                fontFamily: kFont,
                brightness: Brightness.dark,
                scaffoldBackgroundColor: Colors.black,
                colorScheme: const ColorScheme.dark(
                  primary: AppColors.gold,
                  secondary: AppColors.goldDark,
                  surface: Color(0xFF1A1A1A),
                  background: Colors.black,
                  error: Colors.red,
                  onPrimary: Colors.black,
                  onSecondary: Colors.black,
                  onSurface: Colors.white,
                  onBackground: Colors.white,
                  onError: Colors.white,
                ),
                textTheme: const TextTheme(
                  displayLarge: TextStyle(color: Colors.white),
                  displayMedium: TextStyle(color: Colors.white),
                  displaySmall: TextStyle(color: Colors.white),
                  headlineLarge: TextStyle(color: Colors.white),
                  headlineMedium: TextStyle(color: Colors.white),
                  headlineSmall: TextStyle(color: Colors.white),
                  titleLarge: TextStyle(color: Colors.white),
                  titleMedium: TextStyle(color: Colors.white),
                  titleSmall: TextStyle(color: Colors.white),
                  bodyLarge: TextStyle(color: Colors.white),
                  bodyMedium: TextStyle(color: Colors.white),
                  bodySmall: TextStyle(color: Colors.white70),
                  labelLarge: TextStyle(color: Colors.white),
                  labelMedium: TextStyle(color: Colors.white),
                  labelSmall: TextStyle(color: Colors.white70),
                ),
              );

              return MaterialApp(
                title: 'KTEX',
                debugShowCheckedModeBanner: false,
                theme: lightTheme,
                darkTheme: darkTheme,
                themeMode: themeProvider.isDarkMode
                    ? ThemeMode.dark
                    : ThemeMode.light,
                home: const MainNavigationShell(),
              );
            },
          ),
        ),
      ),
    );
  }
}