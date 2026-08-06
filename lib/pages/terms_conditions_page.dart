import 'package:flutter/material.dart';
import 'package:ktex_home/app_colors.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

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
          'Terms & Conditions',
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
              title: 'General',
              content: '''
By accessing or purchasing from ktexstore.com, you agree to be bound by these Terms & Conditions. If you do not agree, please do not use our site. K-TEX reserves the right to update these terms at any time.
''',
            ),
            _buildSection(
              title: 'Products & Pricing',
              content: '''
• All prices are listed in Pakistani Rupees (PKR) and inclusive of applicable taxes
• Product images are for illustration; actual product may vary slightly
• We strive for accurate color representation, but screen variations may occur
• Prices and promotions are subject to change without prior notice
''',
            ),
            _buildSection(
              title: 'Orders & Payment',
              content: '''
• Order placement constitutes an offer to purchase; we reserve the right to accept or decline
• Payment must be completed before order processing begins
• We accept EasyPaisa, JazzCash, Bank Transfer, and Cash on Delivery
• Orders are subject to stock availability; if an item is out of stock, we will notify you
''',
            ),
            _buildSection(
              title: 'Cancellations',
              content: '''
Orders can be cancelled within 2 hours of placement. After processing has begun, cancellations may not be possible. Please contact support immediately if you need to cancel.
''',
            ),
            _buildSection(
              title: 'Intellectual Property',
              content: '''
All content on ktexstore.com — including logos, text, images, and product designs — is the property of K-TEX and may not be reproduced, distributed, or used without written permission.
''',
            ),
            _buildSection(
              title: 'Limitation of Liability',
              content: '''
K-TEX shall not be liable for any indirect, incidental, or consequential damages arising from the use of our website or products. Our total liability is limited to the purchase price of the product in question.
''',
            ),
            _buildSection(
              title: 'Governing Law',
              content: '''
These terms are governed by the laws of Pakistan. Any disputes shall be subject to the jurisdiction of courts in Rawalpindi/Islamabad, Pakistan.
''',
            ),
            _buildSection(
              title: 'Contact',
              content: '''
For questions regarding these terms, reach out at ktexstore.pk@gmail.com or via our contact page.
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