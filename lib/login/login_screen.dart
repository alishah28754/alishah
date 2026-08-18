// lib/pages/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:ktex_home/core/app_colors.dart';
import 'package:ktex_home/services/api_service.dart';
import 'package:ktex_home/models/cart_model.dart';
import 'package:ktex_home/models/favourites_model.dart';
import 'package:ktex_home/models/order_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _isSocialLoading = false;
  bool _isSubmitting = false;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    forceCodeForRefreshToken: true,
  );

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _clearGuestData() {
    try {
      final cart = CartScope.of(context);
      final favourites = FavouritesScope.of(context);
      cart.clear();
      favourites.clearAll();
    } catch (e) {
      // Ignore - scopes might not be available yet
    }
  }

  Future<void> _saveUserData(String name, String email, String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userName', name);
    await prefs.setString('userEmail', email);
    await prefs.setString('userPhone', phone);
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade400 : AppColors.gold,
      ),
    );
  }

  // ============================================================
  // GOOGLE SIGN-IN - Always show account picker
  // ============================================================
  Future<void> _signInWithGoogle() async {
    setState(() => _isSocialLoading = true);
    try {
      await _googleSignIn.signOut();
      try {
        await _googleSignIn.disconnect();
      } catch (e) {
        // Ignore disconnect errors
      }

      _clearGuestData();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final name = user.displayName ?? 'Google User';
        final email = user.email ?? '';
        const phone = '+92 300 1234567';

        // ✅ Sync this login to the backend `users` table (powers the
        // admin panel's Users page — total count, provider, last login).
        try {
          await ApiService.instance.syncUser();
        } catch (e) {
          debugPrint('User sync failed (non-fatal): $e');
        }

        // ✅ Switch to user-specific orders
        final orderModel = Provider.of<OrderModel>(context, listen: false);
        orderModel.setUserId(email);
        await orderModel.switchToUser(email);

        await _saveUserData(name, email, phone);

        if (!mounted) return;
        _showSnack('Signed in with Google!');
        Navigator.pop(context, {
          'name': name,
          'email': email,
          'phone': phone,
        });
      }
    } catch (e) {
      debugPrint('GOOGLE SIGN-IN ERROR: $e');
      _showSnack('Google Sign-In failed. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isSocialLoading = false);
    }
  }

  Future<void> signOutFromGoogle() async {
    try {
      await _googleSignIn.signOut();
      await _googleSignIn.disconnect();
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  // ============================================================
  // EMAIL/PASSWORD SUBMIT
  // ============================================================
  Future<void> _submitForm() async {
    HapticFeedback.lightImpact();
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    setState(() => _isSubmitting = true);

    try {
      if (_isLogin) {
        // LOGIN
        _clearGuestData();

        final credential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);
        final user = credential.user;
        if (user == null) return;

        await user.reload();
        final refreshed = FirebaseAuth.instance.currentUser;

        if (refreshed != null && !refreshed.emailVerified) {
          await refreshed.sendEmailVerification();
          if (!mounted) return;
          _showSnack(
            'Your email isn\'t verified yet. We\'ve re-sent the verification link.',
            isError: true,
          );
          return;
        }

        // ✅ Sync this login to the backend `users` table (powers the
        // admin panel's Users page — total count, provider, last login).
        try {
          await ApiService.instance.syncUser();
        } catch (e) {
          debugPrint('User sync failed (non-fatal): $e');
        }

        // ✅ Switch to user-specific orders
        final orderModel = Provider.of<OrderModel>(context, listen: false);
        orderModel.setUserId(email);
        await orderModel.switchToUser(email);

        final phone = '+92 300 1234567';
        await _saveUserData(refreshed?.displayName ?? 'User', email, phone);

        if (!mounted) return;
        _showSnack('Login Successful! Welcome back!');
        Navigator.pop(context, {
          'name': refreshed?.displayName ?? 'User',
          'email': email,
          'phone': phone,
        });
      } else {
        // SIGN UP
        _clearGuestData();

        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        final user = credential.user;
        if (user == null) return;

        await user.updateDisplayName(name);
        await user.sendEmailVerification();

        // ✅ Sync this signup to the backend `users` table (powers the
        // admin panel's Users page — total count, provider, last login).
        try {
          await ApiService.instance.syncUser();
        } catch (e) {
          debugPrint('User sync failed (non-fatal): $e');
        }

        // ✅ Switch to user-specific orders
        final orderModel = Provider.of<OrderModel>(context, listen: false);
        orderModel.setUserId(email);
        await orderModel.switchToUser(email);

        if (!mounted) return;
        await _showEmailVerificationDialog(email);
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('AUTH ERROR: ${e.code}');
      String message = 'Something went wrong. Please try again.';
      switch (e.code) {
        case 'email-already-in-use':
          message = 'An account already exists for this email. Try signing in.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'weak-password':
          message = 'Password is too weak.';
          break;
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          message = 'Incorrect email or password.';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please try again later.';
          break;
      }
      if (!mounted) return;
      _showSnack(message, isError: true);
    } catch (e) {
      debugPrint('AUTH ERROR: $e');
      if (!mounted) return;
      _showSnack('Something went wrong. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ============================================================
  // EMAIL VERIFICATION DIALOG
  // ============================================================
  Future<void> _showEmailVerificationDialog(String email) async {
    bool isChecking = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Verify your email',
                style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700),
              ),
              content: Text(
                'We\'ve sent a verification link to $email. Please open it, '
                    'then come back and tap "I\'ve Verified".',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.currentUser
                        ?.sendEmailVerification();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Verification email re-sent.')),
                    );
                  },
                  child: const Text('Resend Email'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: isChecking
                      ? null
                      : () async {
                    setDialogState(() => isChecking = true);
                    await FirebaseAuth.instance.currentUser?.reload();
                    final refreshed = FirebaseAuth.instance.currentUser;

                    if (refreshed != null && refreshed.emailVerified) {
                      final phone = '+92 300 1234567';
                      await _saveUserData(
                        refreshed.displayName ?? 'User',
                        refreshed.email ?? email,
                        phone,
                      );
                      if (!dialogContext.mounted) return;
                      Navigator.of(dialogContext).pop();
                      if (!mounted) return;
                      _showSnack('Account Verified & Created Successfully!');
                      Navigator.pop(context, {
                        'name': refreshed.displayName ?? 'User',
                        'email': refreshed.email ?? email,
                        'phone': phone,
                      });
                    } else {
                      setDialogState(() => isChecking = false);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Still not verified — please check your inbox.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: isChecking
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                      : const Text("I've Verified"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gold.withOpacity(0.3),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            'assets/images/ktex_logo.png',
                            width: 120,
                            height: 120,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [AppColors.gold, AppColors.goldDark],
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Center(
                                  child: Text('K-TEX',
                                    style: TextStyle(color: Colors.black, fontSize: 28, fontWeight: FontWeight.w900, fontFamily: 'Inter', letterSpacing: 2),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(_isLogin ? 'Welcome Back' : 'Create Account',
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                      const SizedBox(height: 4),
                      Text(_isLogin ? 'Sign in to continue shopping' : 'Join K-TEX and start shopping',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.outline),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                if (!_isLogin) ...[
                  _buildTextField(controller: _nameController, label: 'Full Name', icon: Icons.person_outline, hintText: 'Enter your full name',
                    validator: (value) => value == null || value.isEmpty ? 'Please enter your name' : null,
                  ),
                  const SizedBox(height: 16),
                ],
                _buildTextField(controller: _emailController, label: 'Email Address', icon: Icons.email_outlined, hintText: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your email';
                    if (!value.contains('@')) return 'Please enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(controller: _passwordController, label: 'Password', icon: Icons.lock_outline, hintText: 'Enter your password',
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.outline),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your password';
                    if (value.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                if (!_isLogin) ...[
                  _buildTextField(controller: _confirmPasswordController, label: 'Confirm Password', icon: Icons.lock_outline, hintText: 'Confirm your password',
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please confirm your password';
                      if (value != _passwordController.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                if (_isLogin) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reset Password Coming Soon!'), backgroundColor: AppColors.gold));
                      },
                      child: const Text('Forgot Password?', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.goldDark, fontWeight: FontWeight.w500)),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _isSubmitting
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : Text(_isLogin ? 'Sign In' : 'Create Account', style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_isLogin ? "Don't have an account? " : "Already have an account? ", style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.outline)),
                    GestureDetector(
                      onTap: () { HapticFeedback.lightImpact(); setState(() => _isLogin = !_isLogin); },
                      child: Text(_isLogin ? 'Sign Up' : 'Sign In', style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.goldDark)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: Divider(color: AppColors.outlineVariant.withOpacity(0.5))),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('OR', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.outline))),
                  Expanded(child: Divider(color: AppColors.outlineVariant.withOpacity(0.5))),
                ]),
                const SizedBox(height: 20),
                if (_isSocialLoading)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Center(child: CircularProgressIndicator(color: AppColors.gold)))
                else
                  Row(children: [
                    Expanded(child: _buildSocialButton(
                      iconWidget: Image.network('https://www.google.com/favicon.ico', width: 22, height: 22, errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, color: Colors.red, size: 24)),
                      label: 'Google', onTap: _signInWithGoogle,
                    )),
                  ]),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hintText,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
          child: TextFormField(
            controller: controller, keyboardType: keyboardType, obscureText: obscureText,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 15, color: AppColors.primary),
            validator: validator,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.goldDark), hintText: hintText, suffixIcon: suffixIcon,
              hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.outline.withOpacity(0.6)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.outlineVariant.withOpacity(0.3))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.outlineVariant.withOpacity(0.3))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gold, width: 2)),
              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({Widget? iconWidget, IconData? icon, required String label, Color? color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3), width: 1), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          iconWidget ?? Icon(icon, color: color, size: 24), const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.primary)),
        ]),
      ),
    );
  }
}