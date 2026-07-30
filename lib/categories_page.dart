import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'brand_pattern.dart';
import 'cart_model.dart';

/// Premium Categories page with a grid layout, featured categories,
/// and smooth animations matching the K-TEX brand aesthetic.
class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Track which single category is expanded (null = none expanded)
  String? _expandedCategory;

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
          color: Color(0xFF000000),
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

  // Sample products for each expandable category (both "Featured" and
  // "Shop by Gender" categories can expand now).
  final Map<String, List<Product>> _categoryProducts = {
    'New Arrivals': [
      Product(
        name: 'Linen Blend Blazer - Beige',
        price: 8999,
        imageUrl: 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=400',
        isPremium: true,
      ),
      Product(
        name: 'Silk Satin Shirt - Ivory',
        price: 4500,
        imageUrl: 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=400',
        isPremium: false,
      ),
      Product(
        name: 'Tailored Wool Trousers - Charcoal',
        price: 6500,
        imageUrl: 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=400',
        isPremium: false,
      ),
      Product(
        name: 'Cashmere Crew Neck - Camel',
        price: 12000,
        imageUrl: 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=400',
        isPremium: true,
      ),
    ],
    'Best Sellers': [
      Product(
        name: 'Premium Cotton Oxford Shirt',
        price: 2999,
        imageUrl: 'https://images.unsplash.com/photo-1620012253295-c15cc3e65df4?w=400',
        isPremium: false,
      ),
      Product(
        name: 'Classic Denim Jeans',
        price: 4500,
        imageUrl: 'https://images.unsplash.com/photo-1542272604-787c3835535d?w=400',
        isPremium: false,
      ),
      Product(
        name: 'Merino Wool Sweater',
        price: 6800,
        imageUrl: 'https://images.unsplash.com/photo-1576566588028-4147f3842f27?w=400',
        isPremium: true,
      ),
      Product(
        name: 'Tailored Fit Chino Trousers',
        price: 3800,
        imageUrl: 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=400',
        isPremium: false,
      ),
    ],
    'Premium Collection': [
      Product(
        name: 'Cashmere Overcoat - Camel',
        price: 24999,
        imageUrl: 'https://images.unsplash.com/photo-1539533018447-63fcce2678e3?w=400',
        isPremium: true,
      ),
      Product(
        name: 'Silk Tuxedo Jacket',
        price: 18999,
        imageUrl: 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=400',
        isPremium: true,
      ),
      Product(
        name: 'Handcrafted Leather Loafers',
        price: 15999,
        imageUrl: 'https://images.unsplash.com/photo-1620012253295-c15cc3e65df4?w=400',
        isPremium: true,
      ),
      Product(
        name: 'Merino Wool Three-Piece Suit',
        price: 29999,
        imageUrl: 'https://images.unsplash.com/photo-1539533018447-63fcce2678e3?w=400',
        isPremium: true,
      ),
    ],
    'Men': [
      Product(
        name: 'Premium Cotton Oxford Shirt',
        price: 2999,
        imageUrl: 'https://images.unsplash.com/photo-1620012253295-c15cc3e65df4?w=400',
        isPremium: true,
      ),
      Product(
        name: 'Classic Denim Jeans',
        price: 4500,
        imageUrl: 'https://images.unsplash.com/photo-1542272604-787c3835535d?w=400',
        isPremium: false,
      ),
      Product(
        name: 'Wool Blend Overcoat',
        price: 7999,
        imageUrl: 'https://images.unsplash.com/photo-1539533018447-63fcce2678e3?w=400',
        isPremium: true,
      ),
      Product(
        name: 'Tailored Fit Chino Trousers',
        price: 3800,
        imageUrl: 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=400',
        isPremium: false,
      ),
      Product(
        name: 'Merino Wool Sweater',
        price: 6800,
        imageUrl: 'https://images.unsplash.com/photo-1576566588028-4147f3842f27?w=400',
        isPremium: true,
      ),
      Product(
        name: 'Linen Summer Blazer',
        price: 8999,
        imageUrl: 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=400',
        isPremium: false,
      ),
    ],
    'Women': [
      Product(
        name: 'Silk Satin Blouse',
        price: 4500,
        imageUrl: 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=400',
        isPremium: true,
      ),
      Product(
        name: 'High-Waist Trousers',
        price: 3800,
        imageUrl: 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=400',
        isPremium: false,
      ),
      Product(
        name: 'Cashmere Sweater',
        price: 6800,
        imageUrl: 'https://images.unsplash.com/photo-1576566588028-4147f3842f27?w=400',
        isPremium: true,
      ),
      Product(
        name: 'Linen Midi Dress',
        price: 5500,
        imageUrl: 'https://images.unsplash.com/photo-1562157873-8182820720f1?w=400',
        isPremium: false,
      ),
      Product(
        name: 'Wool Blend Coat',
        price: 9999,
        imageUrl: 'https://images.unsplash.com/photo-1539533018447-63fcce2678e3?w=400',
        isPremium: true,
      ),
      Product(
        name: 'Silk Scarf Blouse',
        price: 5200,
        imageUrl: 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=400',
        isPremium: false,
      ),
    ],
    'Kids': [
      Product(
        name: 'Cotton Graphic T-Shirt',
        price: 1200,
        imageUrl: 'https://images.unsplash.com/photo-1620012253295-c15cc3e65df4?w=400',
        isPremium: false,
      ),
      Product(
        name: 'Kids Denim Jeans',
        price: 2200,
        imageUrl: 'https://images.unsplash.com/photo-1542272604-787c3835535d?w=400',
        isPremium: false,
      ),
      Product(
        name: 'Hooded Sweatshirt',
        price: 2800,
        imageUrl: 'https://images.unsplash.com/photo-1576566588028-4147f3842f27?w=400',
        isPremium: false,
      ),
      Product(
        name: 'Kids Jogger Pants',
        price: 1800,
        imageUrl: 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=400',
        isPremium: false,
      ),
      Product(
        name: 'Puffer Jacket',
        price: 3500,
        imageUrl: 'https://images.unsplash.com/photo-1539533018447-63fcce2678e3?w=400',
        isPremium: false,
      ),
      Product(
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
        content: Text(
          message,
          style: const TextStyle(fontFamily: kFont),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
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

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: BrandPatternBackground(),
            ),
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
                        const Text(
                          'Shop by Category',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            fontFamily: kFont,
                            color: AppColors.primary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Discover our latest collections',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: kFont,
                            color: AppColors.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Category Groups
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _CategoryGroupWidget(
                        group: _categoryGroups[index],
                        onCategoryTap: (categoryName) {
                          _toggleCategory(categoryName);
                        },
                        expandedCategory: _expandedCategory,
                        categoryProducts: _categoryProducts,
                        onProductTap: (productName) {
                          _showSnack('Opening $productName...');
                        },
                        onAddToCart: (product) {
                          CartScope.of(context).addItem(
                            name: product.name,
                            imageUrl: product.imageUrl,
                            price: product.price,
                          );
                          _showSnack('${product.name} added to cart');
                        },
                        onAddToFavourites: (productName) {
                          _showSnack('$productName added to favourites ❤️');
                        },
                      );
                    },
                    childCount: _categoryGroups.length,
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyTopBar() {
    return SliverAppBar(
      pinned: true,
      floating: true,
      backgroundColor: AppColors.background.withOpacity(0.95),
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: Colors.transparent,
      shadowColor: AppColors.outlineVariant,
      automaticallyImplyLeading: false,
      toolbarHeight: 0,
    );
  }
}

class Product {
  final String name;
  final int price;
  final String imageUrl;
  final bool isPremium;

  const Product({
    required this.name,
    required this.price,
    required this.imageUrl,
    this.isPremium = false,
  });
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
  final Function(String) onProductTap;
  final Function(Product) onAddToCart;
  final Function(String) onAddToFavourites;

  const _CategoryGroupWidget({
    required this.group,
    required this.onCategoryTap,
    required this.expandedCategory,
    required this.categoryProducts,
    required this.onProductTap,
    required this.onAddToCart,
    required this.onAddToFavourites,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group Header
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4),
            child: Row(
              children: [
                Icon(
                  group.icon,
                  size: 18,
                  color: AppColors.goldDark,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    group.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: kFont,
                      color: AppColors.primary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Categories Grid - Just icons with labels
          LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              final itemCount = group.categories.length;
              final crossAxisCount = itemCount == 3 ? 3 : 4;
              
              final spacing = 12.0;
              final availableWidth = totalWidth - (spacing * (crossAxisCount - 1));
              final itemWidth = availableWidth / crossAxisCount;
              // NOTE: no fixed itemHeight — SizedBox below only constrains
              // width. Height comes from the tile's own content (Column
              // mainAxisSize: min in _CategoryIcon), so the tile can never
              // be shorter than what's actually inside it, regardless of
              // screen size or text-scale setting. (Previously this was
              // `itemWidth * 0.75` — a height with no relationship to the
              // icon + 2-line label + count text actually inside it, which
              // is exactly what caused overflow on narrower screens.)

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
          // Expanded products for the single selected category — shown
          // under whichever group (Featured or Shop by Gender) it belongs to.
          if (expandedCategory != null &&
              group.categories.any((c) => c.name == expandedCategory))
            _ExpandedProductsSection(
              categoryName: expandedCategory!,
              products: categoryProducts[expandedCategory] ?? [],
              onProductTap: onProductTap,
              onAddToCart: onAddToCart,
              onAddToFavourites: onAddToFavourites,
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
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with a gold circle behind it when selected
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isExpanded
                  ? AppColors.gold.withOpacity(0.18)
                  : Colors.transparent,
            ),
            alignment: Alignment.center,
            child: Icon(
              category.icon,
              size: 32,
              color: category.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            category.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isExpanded ? FontWeight.w700 : FontWeight.w600,
              fontFamily: kFont,
              color: isExpanded ? AppColors.goldDark : AppColors.primary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${category.count} items',
            style: TextStyle(
              fontSize: 9,
              fontFamily: kFont,
              color: AppColors.outline.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandedProductsSection extends StatelessWidget {
  final String categoryName;
  final List<Product> products;
  final Function(String) onProductTap;
  final Function(Product) onAddToCart;
  final Function(String) onAddToFavourites;

  const _ExpandedProductsSection({
    required this.categoryName,
    required this.products,
    required this.onProductTap,
    required this.onAddToCart,
    required this.onAddToFavourites,
  });

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Calculate card size based on screen proportions
    final horizontalPadding = 32.0; // 16 on each side
    final spacing = 12.0;
    final availableWidth = screenWidth - horizontalPadding - spacing;
    final cardWidth = availableWidth / 2;
    
    // Responsive card height based on screen height
    // On smaller screens, use a smaller ratio
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
              child: Text(
                '${categoryName}\'s Collection',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: kFont,
                  color: AppColors.primary,
                ),
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
                return _ProductCard(
                  product: product,
                  cardWidth: cardWidth,
                  onTap: () => onProductTap(product.name),
                  onAddToCart: () => onAddToCart(product),
                  onAddToFavourites: () => onAddToFavourites(product.name),
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
  final VoidCallback onTap;
  final VoidCallback onAddToCart;
  final VoidCallback onAddToFavourites;

  const _ProductCard({
    required this.product,
    required this.cardWidth,
    required this.onTap,
    required this.onAddToCart,
    required this.onAddToFavourites,
  });

  @override
  Widget build(BuildContext context) {
    // Fixed childAspectRatio grid cell: clamp text scale so large
    // accessibility font settings can't push content past the cell's
    // fixed height (same reasoning as widgets.dart's product cards).
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: MediaQuery.of(context).textScaler.clamp(maxScaleFactor: 1.2),
      ),
      child: GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.outlineVariant.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section - takes most of the space
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: AppColors.primary),
                  ),
                  if (product.isPremium)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.goldDark,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'PREMIUM',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            fontFamily: kFont,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: _ProductMenuButton(
                      onAddToCart: onAddToCart,
                      onAddToFavourites: onAddToFavourites,
                    ),
                  ),
                ],
              ),
            ),
            // Text section with sizing based on this card's own width
            // (not the full screen — a card here is one of 2 grid columns,
            // so screen-width thresholds were the wrong signal).
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: cardWidth < 170 ? 10 : 11,
                      fontFamily: kFont,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Rs.${product.price}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: cardWidth < 170 ? 11 : 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: kFont,
                      color: AppColors.primary,
                    ),
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

class _ProductMenuButton extends StatelessWidget {
  final VoidCallback? onAddToCart;
  final VoidCallback? onAddToFavourites;

  const _ProductMenuButton({
    this.onAddToCart,
    this.onAddToFavourites,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: PopupMenuButton<String>(
        offset: const Offset(0, 10),
        onSelected: (value) {
          if (value == 'cart' && onAddToCart != null) {
            onAddToCart!();
          } else if (value == 'favourites' && onAddToFavourites != null) {
            onAddToFavourites!();
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem<String>(
            value: 'cart',
            child: Row(
              children: [
                const Icon(
                  Icons.shopping_cart_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Add to Cart',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: kFont,
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'favourites',
            child: Row(
              children: [
                const Icon(
                  Icons.favorite_border_rounded,
                  size: 18,
                  color: AppColors.saleRed,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Add to Favourites',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: kFont,
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.more_horiz,
                size: 16,
                color: Colors.black,
              ),
            ],
          ),
        ),
      ),
    );
  }
}