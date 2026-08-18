// lib/pages/categories_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ktex_home/core/app_colors.dart';
import 'package:ktex_home/core/brand_pattern.dart';
import 'package:ktex_home/models/cart_model.dart';
import 'package:ktex_home/models/favourites_model.dart';
import 'package:ktex_home/models/models.dart';
import 'package:ktex_home/pages/product_detail_page.dart';
import 'package:ktex_home/screens/buy_now_screen.dart';
import 'package:ktex_home/services/api_service.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String? _expandedCategory;

  // ✅ FALLBACK DATA - Will be replaced by API
  final List<CategoryGroup> _categoryGroups = const [
    CategoryGroup(
      title: 'Featured',
      icon: Icons.star_rounded,
      categories: [
        Category(
          name: 'New Arrivals',
          icon: Icons.new_releases_rounded,
          color: Color(0xFFD3AF64),
          count: 142,
        ),
        Category(
          name: 'Best Sellers',
          icon: Icons.trending_up_rounded,
          color: Color(0xFFD3AF64),
          count: 89,
        ),
        Category(
          name: 'Premium Collection',
          icon: Icons.workspace_premium_rounded,
          color: Color(0xFF8A6B1F),
          count: 56,
        ),
      ],
    ),
    CategoryGroup(
      title: 'Shop by Gender',
      icon: Icons.people_rounded,
      categories: [
        Category(
          name: 'Men',
          icon: Icons.man_rounded,
          color: Color(0xFF2C3E50),
          count: 320,
        ),
        Category(
          name: 'Women',
          icon: Icons.woman_rounded,
          color: Color(0xFFE74C6F),
          count: 415,
        ),
        Category(
          name: 'Kids',
          icon: Icons.face_rounded,
          color: Color(0xFF27AE60),
          count: 178,
        ),
      ],
    ),
  ];

  // ✅ FALLBACK DATA - Will be replaced by API
  final Map<String, List<Product>> _categoryProducts = {
    'New Arrivals': [
      Product(
        id: 'cat-new-001',
        name: 'Linen Blend Blazer - Beige',
        price: 8999,
        imageUrl: 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=400',
        isPremium: true,
      ),
      Product(
        id: 'cat-new-002',
        name: 'Silk Satin Shirt - Ivory',
        price: 4500,
        imageUrl: 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=400',
        isPremium: false,
      ),
      Product(
        id: 'cat-new-003',
        name: 'Tailored Wool Trousers - Charcoal',
        price: 6500,
        imageUrl: 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=400',
        isPremium: false,
      ),
      Product(
        id: 'cat-new-004',
        name: 'Cashmere Crew Neck - Camel',
        price: 12000,
        imageUrl: 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=400',
        isPremium: true,
      ),
    ],
    'Best Sellers': [
      Product(
        id: 'cat-best-001',
        name: 'Premium Cotton Oxford Shirt',
        price: 2999,
        imageUrl: 'https://images.unsplash.com/photo-1620012253295-c15cc3e65df4?w=400',
        isPremium: false,
      ),
      Product(
        id: 'cat-best-002',
        name: 'Classic Denim Jeans',
        price: 4500,
        imageUrl: 'https://images.unsplash.com/photo-1542272604-787c3835535d?w=400',
        isPremium: false,
      ),
      Product(
        id: 'cat-best-003',
        name: 'Merino Wool Sweater',
        price: 6800,
        imageUrl: 'https://images.unsplash.com/photo-1576566588028-4147f3842f27?w=400',
        isPremium: true,
      ),
      Product(
        id: 'cat-best-004',
        name: 'Tailored Fit Chino Trousers',
        price: 3800,
        imageUrl: 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=400',
        isPremium: false,
      ),
    ],
    'Premium Collection': [
      Product(
        id: 'cat-prem-001',
        name: 'Cashmere Overcoat - Camel',
        price: 24999,
        imageUrl: 'https://images.unsplash.com/photo-1539533018447-63fcce2678e3?w=400',
        isPremium: true,
      ),
      Product(
        id: 'cat-prem-002',
        name: 'Silk Tuxedo Jacket',
        price: 18999,
        imageUrl: 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=400',
        isPremium: true,
      ),
      Product(
        id: 'cat-prem-003',
        name: 'Handcrafted Leather Loafers',
        price: 15999,
        imageUrl: 'https://images.unsplash.com/photo-1620012253295-c15cc3e65df4?w=400',
        isPremium: true,
      ),
      Product(
        id: 'cat-prem-004',
        name: 'Merino Wool Three-Piece Suit',
        price: 29999,
        imageUrl: 'https://images.unsplash.com/photo-1539533018447-63fcce2678e3?w=400',
        isPremium: true,
      ),
    ],
    'Men': [
      Product(
        id: 'cat-men-001',
        name: 'Premium Cotton Oxford Shirt',
        price: 2999,
        imageUrl: 'https://images.unsplash.com/photo-1620012253295-c15cc3e65df4?w=400',
        isPremium: true,
      ),
      Product(
        id: 'cat-men-002',
        name: 'Classic Denim Jeans',
        price: 4500,
        imageUrl: 'https://images.unsplash.com/photo-1542272604-787c3835535d?w=400',
        isPremium: false,
      ),
      Product(
        id: 'cat-men-003',
        name: 'Wool Blend Overcoat',
        price: 7999,
        imageUrl: 'https://images.unsplash.com/photo-1539533018447-63fcce2678e3?w=400',
        isPremium: true,
      ),
      Product(
        id: 'cat-men-004',
        name: 'Tailored Fit Chino Trousers',
        price: 3800,
        imageUrl: 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=400',
        isPremium: false,
      ),
      Product(
        id: 'cat-men-005',
        name: 'Merino Wool Sweater',
        price: 6800,
        imageUrl: 'https://images.unsplash.com/photo-1576566588028-4147f3842f27?w=400',
        isPremium: true,
      ),
      Product(
        id: 'cat-men-006',
        name: 'Linen Summer Blazer',
        price: 8999,
        imageUrl: 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=400',
        isPremium: false,
      ),
    ],
    'Women': [
      Product(
        id: 'cat-women-001',
        name: 'Silk Satin Blouse',
        price: 4500,
        imageUrl: 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=400',
        isPremium: true,
      ),
      Product(
        id: 'cat-women-002',
        name: 'High-Waist Trousers',
        price: 3800,
        imageUrl: 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=400',
        isPremium: false,
      ),
      Product(
        id: 'cat-women-003',
        name: 'Cashmere Sweater',
        price: 6800,
        imageUrl: 'https://images.unsplash.com/photo-1576566588028-4147f3842f27?w=400',
        isPremium: true,
      ),
      Product(
        id: 'cat-women-004',
        name: 'Linen Midi Dress',
        price: 5500,
        imageUrl: 'https://images.unsplash.com/photo-1562157873-8182820720f1?w=400',
        isPremium: false,
      ),
      Product(
        id: 'cat-women-005',
        name: 'Wool Blend Coat',
        price: 9999,
        imageUrl: 'https://images.unsplash.com/photo-1539533018447-63fcce2678e3?w=400',
        isPremium: true,
      ),
      Product(
        id: 'cat-women-006',
        name: 'Silk Scarf Blouse',
        price: 5200,
        imageUrl: 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=400',
        isPremium: false,
      ),
    ],
    'Kids': [
      Product(
        id: 'cat-kids-001',
        name: 'Cotton Graphic T-Shirt',
        price: 1200,
        imageUrl: 'https://images.unsplash.com/photo-1620012253295-c15cc3e65df4?w=400',
        isPremium: false,
      ),
      Product(
        id: 'cat-kids-002',
        name: 'Kids Denim Jeans',
        price: 2200,
        imageUrl: 'https://images.unsplash.com/photo-1542272604-787c3835535d?w=400',
        isPremium: false,
      ),
      Product(
        id: 'cat-kids-003',
        name: 'Hooded Sweatshirt',
        price: 2800,
        imageUrl: 'https://images.unsplash.com/photo-1576566588028-4147f3842f27?w=400',
        isPremium: false,
      ),
      Product(
        id: 'cat-kids-004',
        name: 'Kids Jogger Pants',
        price: 1800,
        imageUrl: 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=400',
        isPremium: false,
      ),
      Product(
        id: 'cat-kids-005',
        name: 'Puffer Jacket',
        price: 3500,
        imageUrl: 'https://images.unsplash.com/photo-1539533018447-63fcce2678e3?w=400',
        isPremium: false,
      ),
      Product(
        id: 'cat-kids-006',
        name: 'Polo Shirt',
        price: 1500,
        imageUrl: 'https://images.unsplash.com/photo-1620012253295-c15cc3e65df4?w=400',
        isPremium: false,
      ),
    ],
  };

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: kFont)),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _toggleCategory(String categoryName) {
    setState(() {
      if (_expandedCategory == categoryName) {
        _expandedCategory = null;
      } else {
        _expandedCategory = categoryName;
      }
    });
  }

  void _navigateToProductDetail(BuildContext context, Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailPage(product: product)),
    );
  }

  void _navigateToBuyNow(BuildContext context, Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BuyNowScreen(product: product)),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).colorScheme.background;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = isDark ? Colors.white60 : AppColors.outline;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: BrandPatternBackground()),
          ),
          SafeArea(
            top: false,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildStickyTopBar(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Shop by Category',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, fontFamily: kFont, color: textColor, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 6),
                        Text('Discover our latest collections',
                          style: TextStyle(fontSize: 14, fontFamily: kFont, color: mutedColor),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      return _CategoryGroupWidget(
                        group: _categoryGroups[index],
                        onCategoryTap: (categoryName) => _toggleCategory(categoryName),
                        expandedCategory: _expandedCategory,
                        categoryProducts: _categoryProducts,
                        onProductTap: (product) => _navigateToProductDetail(context, product),
                        onAddToCart: (product) {
                          CartScope.of(context).addItem(id: product.id, name: product.name, imageUrl: product.imageUrl, price: product.price);
                          _showSnack('${product.name} added to cart');
                        },
                        onAddToFavourites: (product) {
                          final favourites = FavouritesScope.of(context);
                          favourites.toggleFavourite(product);
                          final isFav = favourites.isFavourite(product.id);
                          _showSnack(isFav ? '${product.name} added to favourites ❤️' : '${product.name} removed from favourites');
                        },
                        onBuyNow: (product) => _navigateToBuyNow(context, product),
                      );
                    },
                    childCount: _categoryGroups.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyTopBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).colorScheme.background;

    return SliverAppBar(
      pinned: true,
      floating: true,
      backgroundColor: bgColor.withOpacity(0.95),
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: Colors.transparent,
      shadowColor: isDark ? Colors.white.withOpacity(0.05) : AppColors.outlineVariant,
      automaticallyImplyLeading: false,
      toolbarHeight: 0,
    );
  }
}

class Category {
  final String name;
  final IconData icon;
  final Color color;
  final int count;

  const Category({
    required this.name,
    required this.icon,
    required this.color,
    required this.count,
  });
}

class CategoryGroup {
  final String title;
  final IconData icon;
  final List<Category> categories;

  const CategoryGroup({
    required this.title,
    required this.icon,
    required this.categories,
  });
}

class _CategoryGroupWidget extends StatelessWidget {
  final CategoryGroup group;
  final Function(String) onCategoryTap;
  final String? expandedCategory;
  final Map<String, List<Product>> categoryProducts;
  final Function(Product) onProductTap;
  final Function(Product) onAddToCart;
  final Function(Product) onAddToFavourites;
  final Function(Product) onBuyNow;

  const _CategoryGroupWidget({
    required this.group,
    required this.onCategoryTap,
    required this.expandedCategory,
    required this.categoryProducts,
    required this.onProductTap,
    required this.onAddToCart,
    required this.onAddToFavourites,
    required this.onBuyNow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4),
            child: Row(
              children: [
                Icon(group.icon, size: 18, color: AppColors.goldDark),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(group.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: kFont, color: textColor, letterSpacing: 0.3),
                  ),
                ),
              ],
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              final itemCount = group.categories.length;
              final crossAxisCount = itemCount == 3 ? 3 : 4;
              final spacing = 12.0;
              final availableWidth = totalWidth - (spacing * (crossAxisCount - 1));
              final itemWidth = availableWidth / crossAxisCount;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: List.generate(itemCount, (index) {
                  final category = group.categories[index];
                  return SizedBox(
                    width: itemWidth,
                    child: _CategoryIcon(
                      category: category,
                      isExpanded: expandedCategory == category.name,
                      onTap: () => onCategoryTap(category.name),
                    ),
                  );
                }),
              );
            },
          ),
          if (expandedCategory != null && group.categories.any((c) => c.name == expandedCategory))
            _ExpandedProductsSection(
              categoryName: expandedCategory!,
              products: categoryProducts[expandedCategory] ?? [],
              onProductTap: onProductTap,
              onAddToCart: onAddToCart,
              onAddToFavourites: onAddToFavourites,
              onBuyNow: onBuyNow,
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  final Category category;
  final bool isExpanded;
  final VoidCallback onTap;

  const _CategoryIcon({
    required this.category,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = isDark ? Colors.white60 : AppColors.outline;

    final iconColor = isDark ? AppColors.gold : category.color;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56, height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isExpanded ? AppColors.gold.withOpacity(0.18) : Colors.transparent,
            ),
            alignment: Alignment.center,
            child: Icon(category.icon, size: 32, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(category.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, fontWeight: isExpanded ? FontWeight.w700 : FontWeight.w600, fontFamily: kFont, color: isExpanded ? AppColors.goldDark : textColor, height: 1.2),
          ),
          const SizedBox(height: 2),
          Text('${category.count} items',
            style: TextStyle(fontSize: 9, fontFamily: kFont, color: mutedColor),
          ),
        ],
      ),
    );
  }
}

class _ExpandedProductsSection extends StatelessWidget {
  final String categoryName;
  final List<Product> products;
  final Function(Product) onProductTap;
  final Function(Product) onAddToCart;
  final Function(Product) onAddToFavourites;
  final Function(Product) onBuyNow;

  const _ExpandedProductsSection({
    required this.categoryName,
    required this.products,
    required this.onProductTap,
    required this.onAddToCart,
    required this.onAddToFavourites,
    required this.onBuyNow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final horizontalPadding = 32.0;
    final spacing = 12.0;
    final availableWidth = screenWidth - horizontalPadding - spacing;
    final cardWidth = availableWidth / 2;
    final heightRatio = screenHeight < 700 ? 1.5 : 1.65;
    final cardHeight = cardWidth * heightRatio;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text("${categoryName}'s Collection",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: kFont, color: textColor),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: cardWidth / cardHeight,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                final isFav = FavouritesScope.of(context).isFavourite(product.id);
                return _ProductCard(
                  product: product,
                  cardWidth: cardWidth,
                  isFavourite: isFav,
                  onTap: () => onProductTap(product),
                  onAddToCart: () => onAddToCart(product),
                  onAddToFavourites: () => onAddToFavourites(product),
                  onBuyNow: () => onBuyNow(product),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final double cardWidth;
  final bool isFavourite;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;
  final VoidCallback onAddToFavourites;
  final VoidCallback onBuyNow;

  const _ProductCard({
    required this.product,
    required this.cardWidth,
    required this.isFavourite,
    required this.onTap,
    required this.onAddToCart,
    required this.onAddToFavourites,
    required this.onBuyNow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = isDark ? Colors.white60 : AppColors.outline;
    final cardColor = Theme.of(context).colorScheme.surface;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: MediaQuery.of(context).textScaler.clamp(maxScaleFactor: 1.2)),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : AppColors.outlineVariant.withOpacity(0.2)),
            boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(product.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.primary)),
                    if (product.isPremium)
                      Positioned(
                        top: 6, left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.goldDark, borderRadius: BorderRadius.circular(4)),
                          child: const Text('PREMIUM', maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.5, fontFamily: kFont),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 6, right: 6,
                      child: GestureDetector(
                        onTap: () { HapticFeedback.lightImpact(); onAddToFavourites(); },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800]!.withOpacity(0.9) : Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
                          ),
                          child: Icon(isFavourite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: isFavourite ? AppColors.saleRed : mutedColor, size: 16),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 6, right: 6,
                      child: _CategoryProductMenuButton(onAddToCart: onAddToCart, onBuyNow: onBuyNow),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: cardWidth < 170 ? 10 : 11, fontFamily: kFont, fontWeight: FontWeight.w500, color: textColor),
                    ),
                    const SizedBox(height: 2),
                    Text('Rs.${product.price}', maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: cardWidth < 170 ? 11 : 12, fontWeight: FontWeight.w700, fontFamily: kFont, color: textColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryProductMenuButton extends StatelessWidget {
  final VoidCallback? onAddToCart;
  final VoidCallback? onBuyNow;

  const _CategoryProductMenuButton({this.onAddToCart, this.onBuyNow});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return PopupMenuButton<String>(
      offset: const Offset(-10, 0),
      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      onSelected: (value) {
        if (value == 'cart' && onAddToCart != null) { HapticFeedback.lightImpact(); onAddToCart!(); }
        else if (value == 'buy' && onBuyNow != null) { HapticFeedback.lightImpact(); onBuyNow!(); }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(value: 'cart', child: Row(children: [const Icon(Icons.shopping_cart_outlined, size: 18, color: AppColors.primary), const SizedBox(width: 10), Text('Add to Cart', style: TextStyle(fontFamily: kFont, fontSize: 13, color: textColor))])),
        PopupMenuItem<String>(value: 'buy', child: Row(children: [const Icon(Icons.flash_on_outlined, size: 18, color: AppColors.goldDark), const SizedBox(width: 10), Text('Buy Now', style: TextStyle(fontFamily: kFont, fontSize: 13, color: textColor))])),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 2))]),
        child: const Icon(Icons.more_horiz, size: 16, color: Colors.black),
      ),
    );
  }
}