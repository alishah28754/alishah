import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ktex_home/core/app_colors.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController _messageController = TextEditingController();
  int? _expandedIndex;

  final List<Map<String, String>> _faqs = [
    {
      'question': 'How do I place an order?',
      'answer':
      'To place an order, browse products, add items to your cart, proceed to checkout, and complete payment. You will receive a confirmation email.',
    },
    {
      'question': 'What payment methods do you accept?',
      'answer':
      'We accept Credit/Debit Cards, Mobile Wallet (JazzCash, Easypaisa), Bank Transfer, and Cash on Delivery.',
    },
    {
      'question': 'How can I track my order?',
      'answer':
      'You can track your order from the "Track Order" section in your profile. Enter your order ID to get real-time updates.',
    },
    {
      'question': 'What is your return policy?',
      'answer':
      'We offer 7-day return policy on all products. Items must be unused and in original packaging. Contact our support team for returns.',
    },
    {
      'question': 'How do I contact customer support?',
      'answer':
      'You can contact us via email at support@ktex.com or call us at +92 300 1234567. Our support hours are Monday to Friday 9am-6pm.',
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  // ============================================================
  // SEND MESSAGE TO WHATSAPP
  // ============================================================
  Future<void> _sendToWhatsApp(String message) async {
    final String phoneNumber = '923269873271';
    final String encodedMessage = Uri.encodeComponent(message);

    // Try WhatsApp app first (deep link scheme)
    try {
      final Uri waIntent =
      Uri.parse('whatsapp://send?phone=$phoneNumber&text=$encodedMessage');
      if (await canLaunchUrl(waIntent)) {
        await launchUrl(waIntent, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (e) {
      // App not available, fall through
    }

    // Fallback: wa.me link (opens in WhatsApp if installed, else browser)
    try {
      final Uri url =
      Uri.parse('https://wa.me/$phoneNumber?text=$encodedMessage');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (e) {
      // Web also failed, fall through
    }

    // Final fallback: Copy to clipboard
    await Clipboard.setData(ClipboardData(text: message));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open WhatsApp. Message copied to clipboard!'),
          backgroundColor: AppColors.gold,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // ============================================================
  // SEND MESSAGE TO EMAIL
  // ============================================================
  Future<void> _sendToEmail(String message) async {
    final String email = 'touseef2698@gmail.com';
    final String subject = 'K-TEX Support Request';
    final String body = '''
Hello K-TEX Support Team,

$message

---
Sent from K-TEX App
''';

    final String encodedSubject = Uri.encodeComponent(subject);
    final String encodedBody = Uri.encodeComponent(body);

    final Uri uri =
    Uri.parse('mailto:$email?subject=$encodedSubject&body=$encodedBody');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // If email app not available, copy to clipboard
        await Clipboard.setData(
            ClipboardData(text: 'To: $email\nSubject: $subject\n\n$body'));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email app not available. Message copied to clipboard!'),
              backgroundColor: AppColors.gold,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      await Clipboard.setData(
          ClipboardData(text: 'To: $email\nSubject: $subject\n\n$body'));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e. Message copied to clipboard!'),
            backgroundColor: AppColors.gold,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // ============================================================
  // MAKE PHONE CALL
  // ============================================================
  Future<void> _makeCall() async {
    const String phoneNumber = '+923269873271';
    final Uri uri = Uri.parse('tel:$phoneNumber');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await Clipboard.setData(const ClipboardData(text: phoneNumber));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to open dialer. Number copied: +92 326 9873271'),
              backgroundColor: AppColors.gold,
            ),
          );
        }
      }
    } catch (e) {
      await Clipboard.setData(const ClipboardData(text: phoneNumber));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open dialer. Number copied: +92 326 9873271'),
            backgroundColor: AppColors.gold,
          ),
        );
      }
    }
  }

  void _sendMessage() {
    final String message = _messageController.text.trim();

    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a message'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show dialog with options
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Send Message',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'How would you like to send your message?',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
          ),
        ),
        actions: [
          // WhatsApp Button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _sendToWhatsApp(message);
              _messageController.clear();
            },
            icon: const Icon(Icons.chat, color: Colors.white),
            label: const Text(
              'WhatsApp',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Email Button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _sendToEmail(message);
              _messageController.clear();
            },
            icon: const Icon(Icons.email, color: Colors.white),
            label: const Text(
              'Email',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Cancel Button
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.outline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).colorScheme.background;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final cardColor = Theme.of(context).colorScheme.surface;
    final mutedColor = isDark ? Colors.white60 : AppColors.outline;
    final hintColor = isDark ? Colors.white38 : AppColors.outline.withOpacity(0.6);

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
          'Help & Support',
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
              // Support Header
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
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.gold.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'How can we help you?',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We\'re here to assist you with any questions or concerns',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: mutedColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildContactOption(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            isDark: isDark,
                            textColor: textColor,
                            cardColor: cardColor,
                            mutedColor: mutedColor,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _sendToEmail('Hello, I need help with...');
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildContactOption(
                            icon: Icons.phone_outlined,
                            label: 'Call',
                            isDark: isDark,
                            textColor: textColor,
                            cardColor: cardColor,
                            mutedColor: mutedColor,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _makeCall();
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildContactOption(
                            icon: Icons.chat_outlined,
                            label: 'WhatsApp',
                            isDark: isDark,
                            textColor: textColor,
                            cardColor: cardColor,
                            mutedColor: mutedColor,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _sendToWhatsApp('Hello, I need help with K-TEX.');
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // FAQ Section
              Text(
                'Frequently Asked Questions',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _faqs.length,
                itemBuilder: (context, index) {
                  return _buildFaqItem(
                    index,
                    isDark: isDark,
                    textColor: textColor,
                    cardColor: cardColor,
                    mutedColor: mutedColor,
                  );
                },
              ),

              const SizedBox(height: 24),

              // Contact Form
              Text(
                'Send us a Message',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: isDark ? Border.all(color: Colors.white.withOpacity(0.06)) : null,
                  boxShadow: isDark ? [] : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _messageController,
                      maxLines: 4,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: textColor,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type your message here...',
                        hintStyle: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: hintColor,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white.withOpacity(0.2) : AppColors.outlineVariant.withOpacity(0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white.withOpacity(0.2) : AppColors.outlineVariant.withOpacity(0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.gold,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _sendMessage,
                            icon: const Icon(Icons.send, size: 18),
                            label: const Text(
                              'Send Message',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.gold,
                              foregroundColor: Colors.black,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              if (_messageController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter a message'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              _sendToWhatsApp(_messageController.text.trim());
                              _messageController.clear();
                            },
                            icon: Icon(
                              Icons.chat,
                              size: 18,
                              color: isDark ? Colors.white : AppColors.primary,
                            ),
                            label: Text(
                              'Send via WhatsApp',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: isDark ? Colors.white : AppColors.primary,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: isDark ? Colors.white.withOpacity(0.2) : AppColors.outlineVariant,
                              ),
                              minimumSize: const Size(double.infinity, 45),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactOption({
    required IconData icon,
    required String label,
    required bool isDark,
    required Color textColor,
    required Color cardColor,
    required Color mutedColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.1) : AppColors.outlineVariant.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.goldDark, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(
      int index, {
        required bool isDark,
        required Color textColor,
        required Color cardColor,
        required Color mutedColor,
      }) {
    final faq = _faqs[index];
    final isExpanded = _expandedIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isDark ? Border.all(color: Colors.white.withOpacity(0.06)) : null,
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: isDark ? Colors.white : AppColors.primary,
          ),
        ),
        child: ExpansionTile(
          onExpansionChanged: (expanded) {
            setState(() {
              _expandedIndex = expanded ? index : null;
            });
          },
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.goldDark,
              ),
            ),
          ),
          title: Text(
            faq['question']!,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          iconColor: isDark ? Colors.white : AppColors.primary,
          collapsedIconColor: isDark ? Colors.white60 : AppColors.outline,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(60, 0, 16, 16),
              child: Text(
                faq['answer']!,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: mutedColor,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}