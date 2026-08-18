import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ktex_home/core/app_colors.dart';
import 'package:ktex_home/core/brand_pattern.dart';
import 'package:ktex_home/models/cart_model.dart';
import 'package:ktex_home/models/favourites_model.dart';
import 'package:ktex_home/models/models.dart';
import 'package:ktex_home/screens/buy_now_screen.dart';
import 'package:ktex_home/widgets/widgets.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;

  const ProductDetailPage({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  String _selectedSize = 'S';
  int _quantity = 1;
  bool _isFavourite = false;

  final List<String> _availableSizes = ['S', 'M', 'L', 'XL', 'XXL'];

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkFavouriteStatus();
  }

  void _checkFavouriteStatus() {
    try {
      final favourites = FavouritesScope.of(context);
      final isFav = favourites.isFavourite(widget.product.id);
      if (_isFavourite != isFav) {
        setState(() {
          _isFavourite = isFav;
        });
      }
    } catch (e) {
      // FavouritesScope might not be available yet
    }
  }

  void _showSnack(String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: kFont,
            color: Colors.white,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.black,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.only(
          bottom: 80 + bottomInset,
          left: 16,
          right: 16,
        ),
      ),
    );
  }

  void _showSizeGuide() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.primary;
    final mutedColor = isDark ? Colors.white60 : AppColors.outline;

    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: mutedColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Size Guide',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      fontFamily: kFont,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Find your perfect fit with our size guide',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: kFont,
                      color: mutedColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Size Table
                          _buildSizeTable(textColor, mutedColor, isDark),
                          const SizedBox(height: 24),

                          // How to Measure
                          Text(
                            'How to Measure',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              fontFamily: kFont,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildMeasurementGuide(textColor, mutedColor),
                          const SizedBox(height: 20),

                          // Tips
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.gold.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.tips_and_updates_rounded,
                                      color: AppColors.goldDark,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Tips for Best Fit',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: kFont,
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _buildTipItem('• Measure yourself wearing lightweight clothing', mutedColor),
                                _buildTipItem('• Keep the tape measure snug, not tight', mutedColor),
                                _buildTipItem('• Compare your measurements with the size chart', mutedColor),
                                _buildTipItem('• If between sizes, choose the larger size for comfort', mutedColor),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSizeTable(Color textColor, Color mutedColor, bool isDark) {
    final tableData = [
      ['Size', 'Chest (in)', 'Waist (in)', 'Hip (in)'],
      ['S', '34-36', '28-30', '34-36'],
      ['M', '38-40', '32-34', '38-40'],
      ['L', '42-44', '36-38', '42-44'],
      ['XL', '46-48', '40-42', '46-48'],
      ['XXL', '50-52', '44-46', '50-52'],
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : AppColors.outlineVariant.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: tableData[0].map((header) {
                return Expanded(
                  flex: header == 'Size' ? 1 : 1,
                  child: Text(
                    header,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamily: kFont,
                      color: Colors.black,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Table Rows
          ...tableData.skip(1).map((row) {
            final isSelected = row[0] == _selectedSize;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.gold.withOpacity(0.15)
                    : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : AppColors.outlineVariant.withOpacity(0.1),
                  ),
                ),
              ),
              child: Row(
                children: row.asMap().entries.map((entry) {
                  final isSize = entry.key == 0;
                  return Expanded(
                    flex: 1,
                    child: Text(
                      entry.value,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isSize ? 14 : 13,
                        fontWeight: isSize ? FontWeight.w700 : FontWeight.w400,
                        fontFamily: kFont,
                        color: isSelected ? AppColors.goldDark : textColor,
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMeasurementGuide(Color textColor, Color mutedColor) {
    final guideData = [
      {
        'icon': Icons.straighten_rounded,
        'title': 'Chest',
        'description': 'Measure around the fullest part of your chest, keeping the tape horizontal.',
      },
      {
        'icon': Icons.accessibility_new_rounded,
        'title': 'Waist',
        'description': 'Measure around your natural waistline, typically just above your belly button.',
      },
      {
        'icon': Icons.circle_rounded,
        'title': 'Hip',
        'description': 'Measure around the fullest part of your hips, keeping the tape horizontal.',
      },
    ];

    return Column(
      children: guideData.map((guide) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  guide['icon'] as IconData,
                  color: AppColors.goldDark,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guide['title'] as String,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontFamily: kFont,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      guide['description'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: kFont,
                        color: mutedColor,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTipItem(String text, Color mutedColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontFamily: kFont,
          color: mutedColor,
          height: 1.6,
        ),
      ),
    );
  }

  void _navigateToBuyNow() {
    final cart = CartScope.of(context);
    for (int i = 0; i < _quantity; i++) {
      cart.addItem(
        id: '${widget.product.id}-$_selectedSize',
        name: '${widget.product.name} (${_selectedSize.toUpperCase()})',
        imageUrl: widget.product.imageUrl,
        price: widget.product.price,
      );
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BuyNowScreen(product: widget.product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favourites = FavouritesScope.of(context);
    final isFav = favourites.isFavourite(widget.product.id);
    if (_isFavourite != isFav) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isFavourite = isFav;
          });
        }
      });
    }

    final product = widget.product;
    final cart = CartScope.of(context);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).colorScheme.background;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final cardColor = Theme.of(context).colorScheme.surface;
    final mutedColor = isDark ? Colors.white60 : AppColors.outline;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: BrandPatternBackground()),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(textColor, cardColor, isDark),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Image with Zoom
                        _buildProductImageWithZoom(isDark),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product Name
                              Text(
                                product.name,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: kFont,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Price Section
                              Row(
                                children: [
                                  Text(
                                    'Rs.${product.price}',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: kFont,
                                      color: textColor,
                                    ),
                                  ),
                                  if (product.originalPrice != null) ...[
                                    const SizedBox(width: 12),
                                    Text(
                                      'Rs.${product.originalPrice}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                        fontFamily: kFont,
                                        color: mutedColor,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.saleRed,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '-${product.discountPercent ?? 0}% OFF',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: kFont,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),

                              const SizedBox(height: 10),

                              // Stock status
                              SoldStockRow(
                                soldLabel: product.soldLabel,
                                stock: product.stock,
                                fontSize: 13,
                                alignment: MainAxisAlignment.start,
                              ),

                              const SizedBox(height: 16),

                              // Description
                              Text(
                                'Crafted from premium-quality fabric for unmatched comfort and breathability. Featuring a tailored fit and signature reinforced stitching for lasting durability.',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: kFont,
                                  color: mutedColor,
                                  height: 1.6,
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Color
                              Row(
                                children: [
                                  Text(
                                    'COLOR:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: kFont,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'white',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: kFont,
                                      color: mutedColor,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Size Selection
                              Row(
                                children: [
                                  Text(
                                    'SIZE:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: kFont,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _selectedSize,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: kFont,
                                      color: textColor,
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: _showSizeGuide,
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'Size Guide',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: kFont,
                                        color: AppColors.goldDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Size Chips
                              _buildSizeSelector(textColor, cardColor, isDark),
                              const SizedBox(height: 20),

                              // Quantity
                              Row(
                                children: [
                                  Text(
                                    'Qty:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: kFont,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  _buildQuantitySelector(textColor, cardColor, isDark),
                                  const Spacer(),
                                  // Wishlist Button
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      final favourites = FavouritesScope.of(context);
                                      favourites.toggleFavourite(widget.product);
                                      setState(() {
                                        _isFavourite = !_isFavourite;
                                      });
                                      final msg = _isFavourite
                                          ? 'Added to wishlist ❤️'
                                          : 'Removed from wishlist';
                                      _showSnack(msg);
                                    },
                                    child: Row(
                                      children: [
                                        Icon(
                                          _isFavourite
                                              ? Icons.favorite_rounded
                                              : Icons.favorite_border_rounded,
                                          size: 22,
                                          color: _isFavourite
                                              ? AppColors.saleRed
                                              : mutedColor,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Wishlist',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontFamily: kFont,
                                            color: _isFavourite
                                                ? AppColors.saleRed
                                                : mutedColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Action Buttons
                              _buildActionButtons(cart, textColor, isDark),
                              const SizedBox(height: 20),

                              // Category and Availability
                              Row(
                                children: [
                                  Text(
                                    'Category:',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: kFont,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'linen',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontFamily: kFont,
                                      color: mutedColor,
                                    ),
                                  ),
                                 
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'In Stock',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: kFont,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Product Details Section
                              _buildProductDetails(textColor, cardColor, mutedColor, isDark),
                              const SizedBox(height: 20),

                              // Care Instructions Section
                              _buildCareInstructions(textColor, cardColor, mutedColor, isDark),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(Color textColor, Color cardColor, bool isDark) {
    final iconColor = isDark ? Colors.white : AppColors.primary;
    final bgColor = isDark ? Colors.grey[800] : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: iconColor,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              final favourites = FavouritesScope.of(context);
              favourites.toggleFavourite(widget.product);
              setState(() {
                _isFavourite = !_isFavourite;
              });
              final msg = _isFavourite
                  ? 'Added to wishlist ❤️'
                  : 'Removed from wishlist';
              _showSnack(msg);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                boxShadow: isDark ? [] : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _isFavourite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: 24,
                color: _isFavourite ? AppColors.saleRed : (isDark ? Colors.white54 : AppColors.outline),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImageWithZoom(bool isDark) {
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    return GestureDetector(
      onTap: () {
        // Open image zoom
        _showImageZoom();
      },
      child: Container(
        height: 350,
        width: double.infinity,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Image.network(
              widget.product.imageUrl,
              width: double.infinity,
              height: 350,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: isDark ? Colors.grey[800] : AppColors.surfaceContainerHigh,
                child: Icon(
                  Icons.image_outlined,
                  size: 64,
                  color: isDark ? Colors.white54 : AppColors.outline,
                ),
              ),
            ),
            // Zoom icon overlay
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withOpacity(0.7) : Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.zoom_in_rounded,
                  size: 24,
                  color: isDark ? Colors.white : AppColors.primary,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      isDark ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageZoom() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Scaffold(
              backgroundColor: Colors.black.withOpacity(0.95),
              body: Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    widget.product.imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[800],
                      child: const Icon(
                        Icons.image_outlined,
                        size: 64,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildSizeSelector(Color textColor, Color cardColor, bool isDark) {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      children: _availableSizes.map((size) {
        final isSelected = _selectedSize == size;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _selectedSize = size;
            });
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected ? textColor : cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? textColor : (isDark ? Colors.white.withOpacity(0.2) : AppColors.outlineVariant),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected && !isDark
                  ? [
                BoxShadow(
                  color: textColor.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
                  : null,
            ),
            child: Center(
              child: Text(
                size,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontFamily: kFont,
                  color: isSelected ? (isDark ? Colors.black : Colors.white) : textColor,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuantitySelector(Color textColor, Color cardColor, bool isDark) {
    final borderColor = isDark ? Colors.white.withOpacity(0.2) : AppColors.outlineVariant.withOpacity(0.3);

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QuantityButton(
            icon: Icons.remove_rounded,
            onTap: () {
              if (_quantity > 1) {
                HapticFeedback.selectionClick();
                setState(() {
                  _quantity--;
                });
              }
            },
            iconColor: textColor,
          ),
          Container(
            width: 40,
            alignment: Alignment.center,
            child: Text(
              '$_quantity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: kFont,
                color: textColor,
              ),
            ),
          ),
          _QuantityButton(
            icon: Icons.add_rounded,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _quantity++;
              });
            },
            iconColor: textColor,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(CartModel cart, Color textColor, bool isDark) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              for (int i = 0; i < _quantity; i++) {
                cart.addItem(
                  id: '${widget.product.id}-$_selectedSize',
                  name: '${widget.product.name} (${_selectedSize.toUpperCase()})',
                  imageUrl: widget.product.imageUrl,
                  price: widget.product.price,
                );
              }
              _showSnack('${widget.product.name} (${_selectedSize}) added to cart');
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.grey[800] : AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: Text(
              'ADD TO CART',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: kFont,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              _navigateToBuyNow();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: const Text(
              'BUY IT NOW',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: kFont,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductDetails(Color textColor, Color cardColor, Color mutedColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : AppColors.outlineVariant.withOpacity(0.2)),
        boxShadow: isDark ? [] : [
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
            'Product Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: kFont,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailItem('• Classic Piqué knit texture for premium feel and breathability', mutedColor),
          _buildDetailItem('• Two-button placket with pearlized buttons', mutedColor),
          _buildDetailItem('• Reinforced stitching for lasting durability', mutedColor),
          _buildDetailItem('• SKU: KTEX-1785751638897-I1YAD', mutedColor),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String text, Color mutedColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontFamily: kFont,
          color: mutedColor,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildCareInstructions(Color textColor, Color cardColor, Color mutedColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : AppColors.outlineVariant.withOpacity(0.2)),
        boxShadow: isDark ? [] : [
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
            'Care Instructions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: kFont,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),

          // Table Header
          Row(
            children: [
              Expanded(
                flex: 1,
                child: _buildCareHeader('Machine Wash'),
              ),
              Expanded(
                flex: 1,
                child: _buildCareHeader('Detergent'),
              ),
              Expanded(
                flex: 1,
                child: _buildCareHeader('Drying'),
              ),
              Expanded(
                flex: 1,
                child: _buildCareHeader('Ironing'),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Row 1
          Row(
            children: [
              Expanded(
                flex: 1,
                child: _buildCareItem('Cold wash with\nsimilar colors', mutedColor),
              ),
              Expanded(
                flex: 1,
                child: _buildCareItem('Mild detergent,\navoid bleach', mutedColor),
              ),
              Expanded(
                flex: 1,
                child: _buildCareItem('Tumble dry low\nor air dry', mutedColor),
              ),
              Expanded(
                flex: 1,
                child: _buildCareItem('Medium heat,\navoid prints', mutedColor),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Do Not & Storage
          Row(
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Do Not',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        fontFamily: kFont,
                        color: AppColors.saleRed,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dry clean or use\nfabric softener',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: kFont,
                        color: mutedColor,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Storage',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        fontFamily: kFont,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fold neatly, avoid\nwire hangers',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: kFont,
                        color: mutedColor,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Expanded(flex: 2, child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCareHeader(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          fontFamily: kFont,
          color: AppColors.goldDark,
        ),
      ),
    );
  }

  Widget _buildCareItem(String text, Color mutedColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontFamily: kFont,
          color: mutedColor,
          height: 1.3,
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  const _QuantityButton({
    required this.icon,
    required this.onTap,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Icon(icon, size: 20, color: iconColor),
        ),
      ),
    );
  }
}