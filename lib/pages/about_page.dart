import 'package:flutter/material.dart';
import 'package:ktex_home/app_colors.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

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
          'About K-TEX',
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
            // Stats Row
            Row(
              children: [
                _buildStatCard('10,000+', 'HAPPY CUSTOMERS', Icons.people),
                _buildStatCard('50+', 'POLO STYLES', Icons.style),
                _buildStatCard('4.9★', 'AVERAGE RATING', Icons.star),
                _buildStatCard('3-5 Days', 'NATIONWIDE DELIVERY', Icons.local_shipping),
              ],
            ),
            const SizedBox(height: 24),

            // HOW WE STARTED
            const Text(
              'HOW WE STARTED',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
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
                  const Text(
                    'A Family Business Built on Quality',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'K-TEX started in a small workshop in Rawalpindi\'s textile district. Our founder, Khalid Mehmood, spent 15 years in Pakistan\'s garment industry before deciding to create a brand that truly prioritized the customer - not just production volume.\n\nToday, we operate with a small but passionate team of 12 people, all dedicated to crafting polo shirts that look premium, feel incredible, and last for years. We source our fabrics locally and internationally to ensure the perfect blend of comfort and durability.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: AppColors.outline,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '📞 GET IN TOUCH',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.goldDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // WHAT DRIVES US
            const Text(
              'WHAT DRIVES US',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            _buildValueCard(
              title: 'Uncompromising Quality',
              description: 'Every polo shirt goes through a 12-step quality check before it reaches your doorstep. We use only premium combed cotton that gets softer with every wash.',
              icon: Icons.verified,
            ),
            _buildValueCard(
              title: 'Made for Pakistan',
              description: 'Our fabrics are chosen specifically for Pakistan\'s climate - breathable in summer, warm enough for cool evenings. Designed here, worn everywhere.',
              icon: Icons.place,
            ),
            _buildValueCard(
              title: 'Customer First',
              description: 'We believe in building long-term relationships, not just sales. From easy size exchanges to fast responses - your satisfaction is our promise.',
              icon: Icons.people_alt,
            ),
            _buildValueCard(
              title: 'Timeless Design',
              description: 'No gimmicks, no fast-fashion trends. Our collections are rooted in classic silhouettes that stay stylish for years, not just a season.',
              icon: Icons.hourglass_empty,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 12),
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
          children: [
            Icon(icon, color: AppColors.goldDark, size: 20),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 8,
                color: AppColors.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueCard({
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.goldDark, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.outline,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}