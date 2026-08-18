// lib/pages/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:ktex_home/core/app_colors.dart';
import 'package:ktex_home/models/cart_model.dart';
import 'package:ktex_home/models/favourites_model.dart';
import 'package:ktex_home/pages/cart_page.dart';
import 'package:ktex_home/pages/favourites_page.dart';
import 'package:ktex_home/pages/coming_soon_page.dart';
import 'package:ktex_home/screens/edit_profile_screen.dart';
import 'package:ktex_home/login/login_screen.dart';
import 'package:ktex_home/screens/track_order_screen.dart';
import 'package:ktex_home/screens/settings_screen.dart';
import 'package:ktex_home/screens/help_support_screen.dart';
import 'package:ktex_home/screens/order_screen.dart';
import 'package:ktex_home/models/order_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'Guest User';
  String _userEmail = 'guest@ktex.com';
  String _userPhone = '+92 300 1234567';
  String? _userImage;
  bool _isLoggedIn = false;
  bool _isLoading = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUser = _auth.currentUser;

    setState(() {
      if (currentUser != null) {
        _isLoggedIn = true;
        _userName = currentUser.displayName ?? 'User';
        _userEmail = currentUser.email ?? 'user@ktex.com';
        _userPhone = '+92 300 1234567';
        _userImage = prefs.getString('profileImage');
      } else {
        _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
        if (_isLoggedIn) {
          _userName = prefs.getString('userName') ?? 'Guest User';
          _userEmail = prefs.getString('userEmail') ?? 'guest@ktex.com';
          _userPhone = prefs.getString('userPhone') ?? '+92 300 1234567';
          _userImage = prefs.getString('profileImage');
        } else {
          _userName = 'Guest User';
          _userEmail = 'guest@ktex.com';
          _userPhone = '+92 300 1234567';
          _userImage = null;
        }
      }
      _isLoading = false;
    });
  }

  Future<void> _saveUserData(String name, String email, String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userName', name);
    await prefs.setString('userEmail', email);
    await prefs.setString('userPhone', phone);
  }

  Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('userName');
    await prefs.remove('userEmail');
    await prefs.remove('userPhone');
    await prefs.remove('profileImage');
  }

  // ============================================================
  // ✅ SINGLE LOGOUT FUNCTION - Handles both Firebase & Manual
  // ============================================================
  Future<void> _logout() async {
    try {
      // Clear cart and wishlist
      final cart = CartScope.of(context);
      final favourites = FavouritesScope.of(context);
      cart.clear();
      favourites.clearAll();

      // Switch to guest orders
      final orderModel = Provider.of<OrderModel>(context, listen: false);
      await orderModel.switchToGuest();

      // Firebase logout
      try {
        await _auth.signOut();
      } catch (e) {
        // Ignore if not Firebase user
      }

      // Clear local data
      await _clearUserData();

      setState(() {
        _isLoggedIn = false;
        _userName = 'Guest User';
        _userEmail = 'guest@ktex.com';
        _userPhone = '+92 300 1234567';
        _userImage = null;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged out successfully!'),
          backgroundColor: AppColors.gold,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging out: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).colorScheme.background;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final cardColor = Theme.of(context).colorScheme.surface;
    final mutedColor = isDark ? Colors.white60 : AppColors.outline;

    final cartCount = CartScope.of(context).totalItemCount;
    final wishlistCount = FavouritesScope.of(context).count;
    final orderCount = Provider.of<OrderModel>(context).count;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor),
          onPressed: () => Navigator.pop(context, _userImage),
        ),
        title: Text(
          'Profile',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined, color: textColor),
            onPressed: () async {
              HapticFeedback.lightImpact();
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProfileScreen(
                    userName: _userName,
                    userEmail: _userEmail,
                    userPhone: _userPhone,
                    userImage: _userImage,
                    onSave: (name, email, phone, image) {
                      setState(() {
                        _userName = name;
                        _userEmail = email;
                        _userPhone = phone;
                        _userImage = image;
                      });
                      _saveUserData(name, email, phone);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profile updated successfully!'),
                          backgroundColor: AppColors.gold,
                        ),
                      );
                    },
                  ),
                ),
              );
              if (result != null && result is String) {
                Navigator.pop(context, result);
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.gold))
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Profile Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.gold.withOpacity(0.15),
                      AppColors.goldContainer.withOpacity(0.5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.gold.withOpacity(0.2), width: 1),
                ),
                child: Column(
                  children: [
                    // Avatar
                    Stack(
                      children: [
                        Container(
                          width: 100, height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: _userImage == null
                                ? const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.gold, AppColors.goldDark])
                                : null,
                            boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
                          ),
                          child: _userImage != null && _userImage!.isNotEmpty
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: Image.file(File(_userImage!), width: 100, height: 100, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.gold, AppColors.goldDark])),
                                child: const Center(child: Icon(Icons.person, color: Colors.white, size: 50)),
                              ),
                            ),
                          )
                              : const Center(child: Icon(Icons.person, color: Colors.white, size: 50)),
                        ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: GestureDetector(
                            onTap: () async {
                              HapticFeedback.lightImpact();
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditProfileScreen(
                                    userName: _userName, userEmail: _userEmail, userPhone: _userPhone, userImage: _userImage,
                                    onSave: (name, email, phone, image) {
                                      setState(() { _userName = name; _userEmail = email; _userPhone = phone; _userImage = image; });
                                      _saveUserData(name, email, phone);
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: AppColors.gold));
                                    },
                                  ),
                                ),
                              );
                              if (result != null && result is String) Navigator.pop(context, result);
                            },
                            child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle), child: const Icon(Icons.camera_alt, color: Colors.black, size: 18)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(_userName, style: TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w700, color: textColor)),
                    const SizedBox(height: 4),
                    Text(_userEmail, style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: mutedColor)),
                    const SizedBox(height: 8),
                    Text(_userPhone, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: mutedColor)),
                    const SizedBox(height: 16),

                    // Login/Logout Button
                    if (_isLoggedIn)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _logout,
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              child: const Text('Logout', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      )
                    else
                      ElevatedButton(
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                          if (result != null && result is Map<String, String>) {
                            setState(() { _isLoggedIn = true; _userName = result['name'] ?? 'User'; _userEmail = result['email'] ?? 'user@ktex.com'; _userPhone = result['phone'] ?? '+92 300 1234567'; });
                            await _saveUserData(_userName, _userEmail, _userPhone);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Welcome back! You are now logged in.'), backgroundColor: AppColors.gold));
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text('Sign In / Sign Up', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Stats Row
              Row(
                children: [
                  _buildStatCard(label: 'Orders', value: orderCount.toString(), icon: Icons.receipt_long_outlined, textColor: textColor, cardColor: cardColor, onTap: () { HapticFeedback.lightImpact(); Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderScreen())); }),
                  _buildStatCard(label: 'Wishlist', value: wishlistCount.toString(), icon: Icons.favorite_border, textColor: textColor, cardColor: cardColor, onTap: () { HapticFeedback.lightImpact(); Navigator.push(context, MaterialPageRoute(builder: (_) => const FavouritesPage())); }),
                  _buildStatCard(label: 'Cart', value: cartCount.toString(), icon: Icons.shopping_cart_outlined, textColor: textColor, cardColor: cardColor, onTap: () { HapticFeedback.lightImpact(); Navigator.push(context, MaterialPageRoute(builder: (_) => CartPage(onBack: () => Navigator.pop(context)))); }),
                ],
              ),
              const SizedBox(height: 24),

              // Menu Items
              _buildMenuItem(icon: Icons.receipt_long_outlined, title: 'My Orders', subtitle: 'Track your orders', badge: orderCount > 0 ? orderCount.toString() : null, textColor: textColor, cardColor: cardColor, mutedColor: mutedColor, onTap: () { HapticFeedback.lightImpact(); Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderScreen())); }),
              _buildMenuItem(icon: Icons.favorite_border, title: 'Wishlist', subtitle: 'Your saved items', badge: wishlistCount > 0 ? wishlistCount.toString() : null, textColor: textColor, cardColor: cardColor, mutedColor: mutedColor, onTap: () { HapticFeedback.lightImpact(); Navigator.push(context, MaterialPageRoute(builder: (_) => const FavouritesPage())); }),
              _buildMenuItem(icon: Icons.local_shipping_outlined, title: 'Track Order', subtitle: 'Track your deliveries', textColor: textColor, cardColor: cardColor, mutedColor: mutedColor, onTap: () { HapticFeedback.lightImpact(); Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackOrderScreen())); }),
              _buildMenuItem(icon: Icons.settings_outlined, title: 'Settings', subtitle: 'App preferences', textColor: textColor, cardColor: cardColor, mutedColor: mutedColor, onTap: () { HapticFeedback.lightImpact(); Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen())); }),
              _buildMenuItem(icon: Icons.help_outline, title: 'Help & Support', subtitle: 'FAQ, contact us', textColor: textColor, cardColor: cardColor, mutedColor: mutedColor, onTap: () { HapticFeedback.lightImpact(); Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen())); }),
              const SizedBox(height: 20),
              Container(padding: const EdgeInsets.symmetric(vertical: 16), alignment: Alignment.center, child: Text('K-TEX v1.0.0', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: mutedColor.withOpacity(0.6)))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({required String label, required String value, required IconData icon, required Color textColor, required Color cardColor, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), boxShadow: Theme.of(context).brightness == Brightness.dark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
          child: Column(children: [Icon(icon, color: AppColors.goldDark, size: 24), const SizedBox(height: 4), Text(value, style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: textColor)), Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: textColor.withOpacity(0.7)))]),
        ),
      ),
    );
  }

  Widget _buildMenuItem({required IconData icon, required String title, required String subtitle, required Color textColor, required Color cardColor, required Color mutedColor, required VoidCallback onTap, String? badge}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), boxShadow: Theme.of(context).brightness == Brightness.dark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: AppColors.goldDark, size: 20)),
        title: Text(title, style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
        subtitle: Text(subtitle, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: mutedColor)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (badge != null) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(12)), child: Text(badge, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black))),
          const SizedBox(width: 4), Icon(Icons.chevron_right, color: mutedColor),
        ]),
        onTap: onTap,
      ),
    );
  }
}