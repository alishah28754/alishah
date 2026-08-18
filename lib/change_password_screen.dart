import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_colors.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        _showSnackBar('Please login first', isError: true);
        return;
      }

      // Check if user has email
      final userEmail = user.email;
      if (userEmail == null || userEmail.isEmpty) {
        _showSnackBar(
          'You need to sign in with email & password to change password. '
              'Please sign out and sign in with email.',
          isError: true,
        );
        return;
      }

      // Check if user has password provider (not Google/Apple sign-in)
      final providerData = user.providerData;
      final isEmailProvider = providerData.any(
              (info) => info.providerId == 'password'
      );

      if (!isEmailProvider) {
        // User signed in with Google/Apple - guide them to set password
        await _handleNonEmailProvider(user, userEmail);
        return;
      }

      // Normal password change flow for email/password users
      final credential = EmailAuthProvider.credential(
        email: userEmail,
        password: _currentPasswordController.text.trim(),
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(_newPasswordController.text.trim());

      if (!mounted) return;

      _showSnackBar('Password changed successfully!');
      _clearFields();

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context);
      });

    } on FirebaseAuthException catch (e) {
      String message = 'Something went wrong. Please try again.';
      debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');

      switch (e.code) {
        case 'wrong-password':
          message = 'Current password is incorrect.';
          break;
        case 'user-not-found':
          message = 'User not found. Please login again.';
          break;
        case 'requires-recent-login':
          message = 'Please login again to change password.';
          break;
        case 'weak-password':
          message = 'New password is too weak. Use at least 6 characters.';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please try again later.';
          break;
        case 'user-mismatch':
          message = 'User mismatch. Please login again.';
          break;
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        case 'network-request-failed':
          message = 'Network error. Please check your connection.';
          break;
        case 'email-already-in-use':
          message = 'This email is already associated with another account.';
          break;
        default:
          message = e.message ?? 'Something went wrong.';
      }

      _showSnackBar(message, isError: true);
    } catch (e) {
      debugPrint('Error: $e');
      _showSnackBar('An unexpected error occurred. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Handle Google/Apple sign-in users who want to set a password
  Future<void> _handleNonEmailProvider(User user, String email) async {
    try {
      // For Google/Apple users, they can set a password
      final credential = EmailAuthProvider.credential(
        email: email,
        password: _newPasswordController.text.trim(),
      );

      // Link email/password to the existing account
      await user.linkWithCredential(credential);

      if (!mounted) return;
      _showSnackBar('Password set successfully! You can now login with email & password.');
      _clearFields();

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context);
      });

    } on FirebaseAuthException catch (e) {
      String message = 'Failed to set password.';
      debugPrint('Link error: ${e.code} - ${e.message}');

      switch (e.code) {
        case 'email-already-in-use':
          message = 'This email is already associated with another account.';
          break;
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please try again later.';
          break;
        default:
          message = e.message ?? 'Failed to set password.';
      }

      _showSnackBar(message, isError: true);
    }
  }

  void _clearFields() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Inter'),
        ),
        backgroundColor: isError ? Colors.red.shade400 : AppColors.gold,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    final hasEmail = user?.email != null && user?.email!.isNotEmpty == true;
    final isEmailProvider = user?.providerData.any(
            (info) => info.providerId == 'password'
    ) ?? false;

    final accentColor = isDark ? AppColors.gold : AppColors.primary;
    final bgColor = isDark ? Colors.black : AppColors.background;
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.primary;
    final mutedColor = isDark ? Colors.white60 : AppColors.outline;

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: accentColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Change Password',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: accentColor,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning for users without email
                if (!hasEmail) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'You signed in with Google/Apple. Password change is only available for email/password accounts. '
                                'Please sign out and sign in with email to change password.',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: isDark ? Colors.white70 : Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Info for Google users who can set password
                if (hasEmail && !isEmailProvider) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.gold.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.goldDark,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'You signed in with Google/Apple. You can set a password now to login with email & password in the future.',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: mutedColor,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Info Card
                if (hasEmail && isEmailProvider) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.gold.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.security_outlined,
                          color: AppColors.goldDark,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'For security, you will need to re-authenticate with your current password before changing it.',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: mutedColor,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],

                // Current Password Field (only for email/password users)
                if (hasEmail && isEmailProvider) ...[
                  _buildTextField(
                    controller: _currentPasswordController,
                    label: 'Current Password',
                    icon: Icons.lock_outline,
                    hintText: 'Enter your current password',
                    obscureText: _obscureCurrentPassword,
                    onToggleVisibility: () {
                      setState(() {
                        _obscureCurrentPassword = !_obscureCurrentPassword;
                      });
                    },
                    textColor: textColor,
                    cardColor: cardColor,
                    mutedColor: mutedColor,
                    accentColor: accentColor,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your current password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // New Password Field
                _buildTextField(
                  controller: _newPasswordController,
                  label: hasEmail && isEmailProvider ? 'New Password' : 'Set Password',
                  icon: Icons.lock_outline,
                  hintText: hasEmail && isEmailProvider
                      ? 'Enter new password (min 6 characters)'
                      : 'Enter password (min 6 characters)',
                  obscureText: _obscureNewPassword,
                  onToggleVisibility: () {
                    setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    });
                  },
                  textColor: textColor,
                  cardColor: cardColor,
                  mutedColor: mutedColor,
                  accentColor: accentColor,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password Field
                _buildTextField(
                  controller: _confirmPasswordController,
                  label: hasEmail && isEmailProvider ? 'Confirm New Password' : 'Confirm Password',
                  icon: Icons.lock_outline,
                  hintText: 'Confirm your password',
                  obscureText: _obscureConfirmPassword,
                  onToggleVisibility: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                  textColor: textColor,
                  cardColor: cardColor,
                  mutedColor: mutedColor,
                  accentColor: accentColor,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                // Change Password Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(double.infinity, 55),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2.5,
                      ),
                    )
                        : Text(
                      hasEmail && isEmailProvider ? 'Change Password' : 'Set Password',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Password Requirements
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: isDark
                        ? Border.all(color: Colors.white.withOpacity(0.06))
                        : null,
                    boxShadow: isDark
                        ? []
                        : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Password Requirements:',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildRequirementTile(
                        'At least 6 characters',
                        _newPasswordController.text.length >= 6,
                        textColor,
                      ),
                      _buildRequirementTile(
                        'Contains a number (optional)',
                        _newPasswordController.text.contains(RegExp(r'[0-9]')),
                        textColor,
                      ),
                      _buildRequirementTile(
                        'Contains a special character (optional)',
                        _newPasswordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
                        textColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequirementTile(String text, bool isMet, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            color: isMet ? AppColors.gold : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: isMet ? AppColors.gold : textColor.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required Color textColor,
    required Color cardColor,
    required Color mutedColor,
    required Color accentColor,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Theme.of(context).brightness == Brightness.dark
                ? Border.all(color: Colors.white.withOpacity(0.06))
                : null,
            boxShadow: Theme.of(context).brightness == Brightness.dark
                ? []
                : [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              color: textColor,
            ),
            validator: validator,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: accentColor),
              hintText: hintText,
              hintStyle: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: mutedColor.withOpacity(0.6),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: mutedColor,
                ),
                onPressed: onToggleVisibility,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              errorStyle: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: Colors.red.shade400,
              ),
            ),
          ),
        ),
      ],
    );
  }
}