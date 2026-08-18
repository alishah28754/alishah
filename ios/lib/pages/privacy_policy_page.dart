import 'package:flutter/material.dart';
import 'package:ktex_home/core/app_colors.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: 'Information we collect',
              content: '''
When you place an order or create an account, we collect:

• Personal details: full name, email address, phone number, shipping address
• Order data: products purchased, payment method, order history
• Communication: messages sent via our contact form or WhatsApp
• Technical data: IP address, browser type, device information for analytics
''',
            ),
            _buildSection(
              title: 'How we use your information',
              content: '''
• To process and deliver your orders
• To communicate order updates via WhatsApp, SMS, or email
• To improve our products, website, and customer experience
• To send promotional offers (only with your consent)
• To prevent fraud and ensure secure transactions
''',
            ),
            _buildSection(
              title: 'Data protection',
              content: '''
We implement industry-standard security measures including SSL encryption, secure payment gateways, and restricted data access. Your payment details are processed securely through third-party providers and are never stored on our servers.
''',
            ),
            _buildSection(
              title: 'Data sharing',
              content: '''
We do not sell, trade, or share your personal data with third parties except:

• Courier & logistics partners for order delivery
• Payment processors for transaction handling
• When required by law or to protect our legal rights
''',
            ),
            _buildSection(
              title: 'Your rights',
              content: '''
You have the right to:

• Access your personal data held by us
• Request correction of inaccurate data
• Request deletion of your data (subject to legal obligations)
• Withdraw consent for marketing communications at any time
''',
            ),
            _buildSection(
              title: 'Contact',
              content: '''
For any privacy-related inquiries, please contact us at ktexstore.pk@gmail.com or via our contact page.
''',
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
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
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppColors.outline,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}