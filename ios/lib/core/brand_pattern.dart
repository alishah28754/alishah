import 'package:flutter/material.dart';
import 'package:ktex_home/core/app_colors.dart';

/// A very faint, repeating diagonal-stripe texture — echoes the chevron
/// motif in the K-TEX logo. Meant to sit behind page content at low
/// opacity so empty areas (like the strip behind the floating nav icons)
/// have some subtle brand texture instead of flat empty color.
class BrandPatternBackground extends StatelessWidget {
  const BrandPatternBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ChevronStripePainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _ChevronStripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const stripeSpacing = 34.0;
    const stripeWidth = 10.0;

    final blackPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stripeWidth;

    final goldPaint = Paint()
      ..color = AppColors.gold.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stripeWidth;

    // Diagonal lines running from bottom-left to top-right, alternating
    // a black-tinted stripe and a gold-tinted stripe, repeated across
    // the full width+height so it tiles seamlessly as content scrolls.
    final diagonalSpan = size.width + size.height;
    var i = 0;
    for (double offset = -size.height; offset < diagonalSpan; offset += stripeSpacing) {
      final paint = i.isEven ? blackPaint : goldPaint;
      canvas.drawLine(
        Offset(offset, size.height),
        Offset(offset + size.height, 0),
        paint,
      );
      i++;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
