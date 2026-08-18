import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ktex_home/core/app_colors.dart';
import 'package:ktex_home/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ktex_home/pages/about_page.dart';
import 'package:ktex_home/pages/privacy_policy_page.dart';
import 'package:ktex_home/pages/terms_conditions_page.dart';
import 'package:ktex_home/services/notification_service.dart';
import 'package:ktex_home/login/change_password_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _emailUpdates = true;
  bool _offlineMode = false;
  String _language = 'English';
  String _currency = 'PKR (Rs.)';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifications = prefs.getBool('notificationsEnabled') ?? true;
      _emailUpdates = prefs.getBool('emailUpdates') ?? true;
      _offlineMode = prefs.getBool('offlineMode') ?? false;
      _language = prefs.getString('language') ?? 'English';
      _currency = prefs.getString('currency') ?? 'PKR (Rs.)';
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    // ============================================================
    // FIXED: Use Theme.of(context) for proper dark mode support
    // ============================================================
    final colorScheme = Theme.of(context).colorScheme;
    final cardColor = colorScheme.surface;
    final textColor = colorScheme.onSurface;
    final mutedColor = isDark ? Colors.white60 : AppColors.outline;
    final bgColor = colorScheme.background;
    final accentColor = isDark ? AppColors.gold : AppColors.primary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Account Section
              _sectionTitle('Account', textColor, isDark),
              const SizedBox(height: 10),
              _buildSettingsTile(
                icon: Icons.person_outline,
                title: 'Edit Profile',
                subtitle: 'Update your personal information',
                onTap: () => Navigator.pop(context),
                cardColor: cardColor,
                textColor: textColor,
                mutedColor: mutedColor,
                isDark: isDark,
              ),
              _buildSettingsTile(
                icon: Icons.lock_outline,
                title: 'Change Password',
                subtitle: 'Update your password',
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                  );
                },
                cardColor: cardColor,
                textColor: textColor,
                mutedColor: mutedColor,
                isDark: isDark,
              ),

              const SizedBox(height: 24),

              // Preferences Section
              _sectionTitle('Preferences', textColor, isDark),
              const SizedBox(height: 10),
              _buildSwitchTile(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                subtitle: 'Switch to dark theme',
                value: isDark,
                onChanged: (value) async {
                  HapticFeedback.lightImpact();
                  themeProvider.toggleTheme();
                  await _saveSetting('darkMode', value);
                },
                cardColor: cardColor,
                textColor: textColor,
                mutedColor: mutedColor,
                isDark: isDark,
              ),
              _buildSwitchTile(
                icon: Icons.notifications_outlined,
                title: 'Push Notifications',
                subtitle: 'Receive order updates',
                value: _notifications,
                onChanged: (value) async {
                  setState(() => _notifications = value);
                  await NotificationService.setNotificationsEnabled(value);
                  await _saveSetting('notificationsEnabled', value);
                  HapticFeedback.lightImpact();
                },
                cardColor: cardColor,
                textColor: textColor,
                mutedColor: mutedColor,
                isDark: isDark,
              ),
              _buildSwitchTile(
                icon: Icons.email_outlined,
                title: 'Email Updates',
                subtitle: 'Receive promotional emails',
                value: _emailUpdates,
                onChanged: (value) async {
                  setState(() => _emailUpdates = value);
                  await _saveSetting('emailUpdates', value);
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value ? 'Email updates enabled' : 'Email updates disabled',
                        style: TextStyle(
                          color: isDark ? Colors.black : Colors.white,
                        ),
                      ),
                      backgroundColor: AppColors.gold,
                    ),
                  );
                },
                cardColor: cardColor,
                textColor: textColor,
                mutedColor: mutedColor,
                isDark: isDark,
              ),

              const SizedBox(height: 24),

              // About Section
              _sectionTitle('About', textColor, isDark),
              const SizedBox(height: 10),
              _buildSettingsTile(
                icon: Icons.info_outline,
                title: 'About K-TEX',
                subtitle: 'Version 1.0.0',
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AboutPage()),
                  );
                },
                cardColor: cardColor,
                textColor: textColor,
                mutedColor: mutedColor,
                isDark: isDark,
              ),
              _buildSettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                subtitle: 'Read our privacy policy',
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
                  );
                },
                cardColor: cardColor,
                textColor: textColor,
                mutedColor: mutedColor,
                isDark: isDark,
              ),
              _buildSettingsTile(
                icon: Icons.description_outlined,
                title: 'Terms & Conditions',
                subtitle: 'Read our terms',
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TermsConditionsPage()),
                  );
                },
                cardColor: cardColor,
                textColor: textColor,
                mutedColor: mutedColor,
                isDark: isDark,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text, Color textColor, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color cardColor,
    required Color textColor,
    required Color mutedColor,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.gold.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.goldDark,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: mutedColor,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: mutedColor,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color cardColor,
    required Color textColor,
    required Color mutedColor,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.gold.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.goldDark,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: mutedColor,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.gold,
          activeTrackColor: AppColors.gold.withOpacity(0.4),
        ),
      ),
    );
  }
}