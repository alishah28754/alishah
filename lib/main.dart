// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
  late final CartModel _cart;
  late final FavouritesModel _favourites;
  late final OrderModel _orders;

  @override
  void initState() {
    super.initState();
    _cart = CartModel();
    _favourites = FavouritesModel();
    _orders = OrderModel();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final userEmail = prefs.getString('userEmail');

    if (isLoggedIn && userEmail != null && userEmail.isNotEmpty) {
      await _orders.init(userId: userEmail);
    } else {
      await _orders.init(userId: 'guest');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: _cart),
        ChangeNotifierProvider.value(value: _favourites),
        ChangeNotifierProvider.value(value: _orders),
      ],
      child: CartScope(
        cart: _cart,
        child: FavouritesScope(
          favourites: _favourites,
          child: Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
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