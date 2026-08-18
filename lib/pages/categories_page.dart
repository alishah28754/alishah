// lib/pages/categories_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ktex_home/core/app_colors.dart';
import 'package:ktex_home/core/brand_pattern.dart';
import 'package:ktex_home/models/models.dart';
import 'package:ktex_home/pages/category_detail_page.dart';
import 'package:ktex_home/services/api_service.dart';

class Category {
  final String name;
  final IconData icon;
  final Color color;
  final int count;

  const Category({
    required this.name,
    required this.icon,
    required this.color,
    this.count = 0,
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

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final List<CategoryGroup> _categoryGroups = const [
    CategoryGroup(
      title: 'Featured',
      icon: Icons.star_rounded,
      categories: [
        Category(
          name: 'New Arrivals',
          icon: Icons.new_releases_rounded,
          color: Color(0xFFD3AF64),
        ),
        Category(
          name: 'Best Sellers',
          icon: Icons.trending_up_rounded,
          color: Color(0xFFD3AF64),
        ),
        Category(
          name: 'Premium Collection',
          icon: Icons.workspace_premium_rounded,
          color: Color(0xFF8A6B1F),
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
        ),
        Category(
          name: 'Women',
          icon: Icons.woman_rounded,
          color: Color(0xFFE74C6F),
        ),
        Category(
          name: 'Kids',
          icon: Icons.face_rounded,
          color: Color(0xFF27AE60),
        ),
      ],
    ),
  ];

  Map<String, List<Product>> _categoryProducts = {};
  Map<String, bool> _loading = {};
  Map<String, String?> _errors = {};

  @override
  void initState() {
    super.initState();
    _initializeState();
    _loadAllProducts();
  }

  void _initializeState() {
    final allCategoryNames = _categoryGroups
        .expand((group) => group.categories.map((c) => c.name))
        .toList();

    for (var name in allCategoryNames) {
      _categoryProducts[name] = [];
      _loading[name] = true;
      _errors[name] = null;
    }
  }

  Future<void> _loadAllProducts() async {
    final api = ApiService.instance;

    final fetchTasks = {
      'New Arrivals': () => api.fetchNewArrivals(),
      'Best Sellers': () => api.fetchBestSellers(),
      'Premium Collection': () => api.fetchProducts(isPremium: true),
      'Men': () => api.fetchProducts(category: 'Men'),
      'Women': () => api.fetchProducts(category: 'Women'),
      'Kids': () => api.fetchProducts(category: 'Kids'),
    };

    setState(() {
      for (var name in fetchTasks.keys) {
        _loading[name] = true;
        _errors[name] = null;
      }
    });

    final futures = fetchTasks.entries.map((entry) async {
      final name = entry.key;
      final fetcher = entry.value;
      try {
        final products = await fetcher();
        if (mounted) {
          setState(() {
            _categoryProducts[name] = products;
            _loading[name] = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _categoryProducts[name] = [];
            _loading[name] = false;
            _errors[name] = e.toString();
          });
        }
      }
    });

    await Future.wait(futures);
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.lightImpact();
    await _loadAllProducts();
  }

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

  void _handleCategoryTap(BuildContext context, String categoryName) {
    if (_isLoadingForCategory(categoryName)) {
      _showSnack('Please wait, loading products…');
      return;
    }
    if (_getErrorForCategory(categoryName) != null) {
      _showSnack('Failed to load products. Pull down to refresh.');
      return;
    }

    final category = _categoryGroups
        .expand((group) => group.categories)
        .firstWhere((c) => c.name == categoryName);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoryDetailPage(
          title: category.name,
          icon: category.icon,
          products: _getProductsForCategory(categoryName),
        ),
      ),
    );
  }

  List<Product> _getProductsForCategory(String categoryName) {
    return _categoryProducts[categoryName] ?? [];
  }

  bool _isLoadingForCategory(String categoryName) {
    return _loading[categoryName] ?? true;
  }

  String? _getErrorForCategory(String categoryName) {
    return _errors[categoryName];
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
      body: RefreshIndicator(
        color: AppColors.gold,
        backgroundColor: isDark ? Colors.grey[800] : Colors.white,
        onRefresh: _handleRefresh,
        child: Stack(
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
                        final group = _categoryGroups[index];
                        return _CategoryGroupWidget(
                          group: group,
                          onCategoryTap: (categoryName) => _handleCategoryTap(context, categoryName),
                          getProducts: _getProductsForCategory,
                          isLoading: _isLoadingForCategory,
                          getError: _getErrorForCategory,
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

class _CategoryGroupWidget extends StatelessWidget {
  final CategoryGroup group;
  final Function(String) onCategoryTap;
  final List<Product> Function(String) getProducts;
  final bool Function(String) isLoading;
  final String? Function(String) getError;

  const _CategoryGroupWidget({
    required this.group,
    required this.onCategoryTap,
    required this.getProducts,
    required this.isLoading,
    required this.getError,
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
                  final products = getProducts(category.name);
                  final loading = isLoading(category.name);
                  final error = getError(category.name);

                  return SizedBox(
                    width: itemWidth,
                    child: _CategoryIcon(
                      category: category,
                      productCount: loading ? 0 : products.length,
                      isLoading: loading,
                      hasError: error != null,
                      onTap: () => onCategoryTap(category.name),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  final Category category;
  final int productCount;
  final bool isLoading;
  final bool hasError;
  final VoidCallback onTap;

  const _CategoryIcon({
    required this.category,
    required this.productCount,
    required this.isLoading,
    required this.hasError,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = isDark ? Colors.white60 : AppColors.outline;

    final iconColor = isDark ? AppColors.gold : category.color;

    String countText = '';
    if (isLoading) {
      countText = 'Loading...';
    } else if (hasError) {
      countText = 'Error!';
    } else {
      countText = '$productCount items';
    }

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
              color: Colors.transparent,
            ),
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(category.icon, size: 32, color: iconColor),
                if (isLoading)
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.gold,
                    ),
                  ),
                if (hasError && !isLoading)
                  const Icon(
                    Icons.error_outline,
                    size: 24,
                    color: Colors.red,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(category.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, fontFamily: kFont, color: textColor, height: 1.2),
          ),
          const SizedBox(height: 2),
          Text(countText,
            style: TextStyle(fontSize: 9, fontFamily: kFont, color: hasError ? Colors.red : mutedColor),
          ),
        ],
      ),
    );
  }
}