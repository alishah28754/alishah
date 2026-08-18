// lib/pages/home_page.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ktex_home/core/app_colors.dart';
import 'package:ktex_home/core/brand_pattern.dart';
import 'package:ktex_home/models/cart_model.dart';
import 'package:ktex_home/models/favourites_model.dart';
import 'package:ktex_home/models/models.dart';
import 'package:ktex_home/pages/product_detail_page.dart';
import 'package:ktex_home/pages/new_arrivals_page.dart';
import 'package:ktex_home/pages/flash_sale_page.dart';
import 'package:ktex_home/pages/category_detail_page.dart';
import 'package:ktex_home/login/login_screen.dart';
import 'package:ktex_home/screens/buy_now_screen.dart';
import 'package:ktex_home/screens/profile_screen.dart';
import 'package:ktex_home/services/api_service.dart';
import 'package:ktex_home/widgets/widgets.dart';

class HomePage extends StatefulWidget {
  final VoidCallback? onProfileTap;
  final String? profileImage;

  const HomePage({super.key, this.onProfileTap, this.profileImage});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  final PageController _bannerController = PageController();
  int _bannerIndex = 0;
  Timer? _bannerTimer;

  bool _isLoggedIn = false;
  String _userName = 'Guest';
  String? _profileImage;

  // ============================================================
  // SEARCH STATE
  // ============================================================
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  // ============================================================
  // DATA STATE - Fetched from API
  // ============================================================
  List<BannerSlide> _banners = [];
  List<Product> _premiumCollection = [];
  List<Product> _newArrivals = [];
  List<Product> _flashSale = [];
  List<Product> _forYou = [];
  List<Product> _bestSellers = [];

  // ============================================================
  // LOADING STATES
  // ============================================================
  bool _isLoadingBanners = true;
  bool _isLoadingPremium = true;
  bool _isLoadingNewArrivals = true;
  bool _isLoadingFlashSale = true;
  bool _isLoadingForYou = true;
  bool _isLoadingBestSellers = true;

  bool _hasError = false;
  String? _errorMessage;

  // ============================================================
  // GET ALL PRODUCTS FOR SEARCH
  // ============================================================
  List<Product> get _allProducts {
    final List<Product> all = [];
    all.addAll(_newArrivals);
    all.addAll(_flashSale);
    all.addAll(_forYou);
    all.addAll(_premiumCollection);
    all.addAll(_bestSellers);
    return all;
  }

  // ============================================================
  // SEARCH FILTER
  // ============================================================
  List<Product> get _filteredProducts {
    if (_searchQuery.isEmpty) return [];
    final query = _searchQuery.toLowerCase().trim();
    return _allProducts.where((product) {
      return product.name.toLowerCase().contains(query);
    }).toList();
  }

  bool get _hasSearchResults => _filteredProducts.isNotEmpty;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _startBannerAutoplay();
    _checkLoginStatus();
    _loadProfileImage();
    _loadAllData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _isSearching = _searchQuery.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD ALL DATA FROM API
  // ============================================================
  Future<void> _loadAllData() async {
    final api = ApiService.instance;

    setState(() {
      _isLoadingBanners = true;
      _isLoadingPremium = true;
      _isLoadingNewArrivals = true;
      _isLoadingFlashSale = true;
      _isLoadingForYou = true;
      _isLoadingBestSellers = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      await Future.wait([
        _fetchBanners(api),
        _fetchPremium(api),
        _fetchNewArrivals(api),
        _fetchFlashSale(api),
        _fetchForYou(api),
        _fetchBestSellers(api),
      ]);
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoadingBanners = false;
        _isLoadingPremium = false;
        _isLoadingNewArrivals = false;
        _isLoadingFlashSale = false;
        _isLoadingForYou = false;
        _isLoadingBestSellers = false;
      });
    }
  }

  Future<void> _fetchBanners(ApiService api) async {
    try {
      final banners = await api.fetchBanners();
      if (mounted) {
        setState(() {
          _banners = banners.isNotEmpty ? banners : _getFallbackBanners();
          _isLoadingBanners = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _banners = _getFallbackBanners();
          _isLoadingBanners = false;
        });
      }
    }
  }

  Future<void> _fetchPremium(ApiService api) async {
    try {
      final products = await api.fetchProducts(isPremium: true);
      if (mounted) {
        setState(() {
          _premiumCollection = products;
          _isLoadingPremium = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _premiumCollection = [];
          _isLoadingPremium = false;
        });
      }
    }
  }

  Future<void> _fetchNewArrivals(ApiService api) async {
    try {
      final products = await api.fetchNewArrivals();
      if (mounted) {
        setState(() {
          _newArrivals = products;
          _isLoadingNewArrivals = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _newArrivals = [];
          _isLoadingNewArrivals = false;
        });
      }
    }
  }

  Future<void> _fetchFlashSale(ApiService api) async {
    try {
      final products = await api.fetchFlashSale();
      if (mounted) {
        setState(() {
          _flashSale = products;
          _isLoadingFlashSale = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _flashSale = [];
          _isLoadingFlashSale = false;
        });
      }
    }
  }

  Future<void> _fetchForYou(ApiService api) async {
    try {
      final products = await api.fetchForYou();
      if (mounted) {
        setState(() {
          _forYou = products;
          _isLoadingForYou = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _forYou = [];
          _isLoadingForYou = false;
        });
      }
    }
  }

  Future<void> _fetchBestSellers(ApiService api) async {
    try {
      final products = await api.fetchBestSellers();
      if (mounted) {
        setState(() {
          _bestSellers = products;
          _isLoadingBestSellers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _bestSellers = [];
          _isLoadingBestSellers = false;
        });
      }
    }
  }

  // ============================================================
  // FALLBACK BANNERS
  // ============================================================
  List<BannerSlide> _getFallbackBanners() {
    return const [
      BannerSlide(
        id: 'banner-1',
        title: 'Premium\nCollection',
        subtitle: 'Elevate your everyday style.',
        imageUrl: 'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=800',
        category: 'Premium Collection',
      ),
      BannerSlide(
        id: 'banner-2',
        title: 'New \nArrivals',
        subtitle: 'Curated pieces, just landed.',
        imageUrl: 'https://images.unsplash.com/photo-1441984904996-e0b6ba687e04?w=800',
        category: 'New Arrivals',
      ),
      BannerSlide(
        id: 'banner-3',
        title: 'Best Seller\nCollection',
        subtitle: 'Shop our most loved styles.',
        imageUrl: 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=800',
        category: 'Best Sellers',
      ),
    ];
  }

  // ============================================================
  // LOGIN / PROFILE
  // ============================================================
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      _userName = prefs.getString('userName') ?? 'Guest';
    });
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profileImage');
    setState(() {
      _profileImage = imagePath;
    });
  }

  // ============================================================
  // BANNER AUTOPLAY
  // ============================================================
  void _startBannerAutoplay() {
    _bannerTimer?.cancel();
    if (_banners.isEmpty) return;
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_bannerController.hasClients) return;
      final next = (_bannerIndex + 1) % _banners.length;
      _bannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  // ============================================================
  // REFRESH
  // ============================================================
  Future<void> _handleRefresh() async {
    HapticFeedback.lightImpact();
    await Future.wait([
      _checkLoginStatus(),
      _loadProfileImage(),
      _loadAllData(),
    ]);
  }

  // ============================================================
  // NAVIGATION
  // ============================================================
  void _showSnack(String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(fontFamily: kFont, color: Colors.white),
          ),
          backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.black,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.only(bottom: 80 + bottomInset, left: 16, right: 16),
        ),
      );
  }

  void _navigateToProductDetail(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailPage(product: product)),
    );
  }

  void _navigateToCategory(String categoryName, List<Product> products, IconData icon) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoryDetailPage(
          title: categoryName,
          icon: icon,
          products: products,
        ),
      ),
    );
  }

  void _navigateToBuyNow(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BuyNowScreen(product: product)),
    );
  }

  void _navigateToLogin() async {
    HapticFeedback.lightImpact();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );

    if (result != null && result is Map<String, String>) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userName', result['name'] ?? 'User');
      await prefs.setString('userEmail', result['email'] ?? '');
      await prefs.setString('userPhone', result['phone'] ?? '');

      setState(() {
        _isLoggedIn = true;
        _userName = result['name'] ?? 'User';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Welcome! You are now logged in.'),
          backgroundColor: AppColors.gold,
        ),
      );
    }
  }

  void _navigateToProfile() async {
    HapticFeedback.lightImpact();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
    await _loadProfileImage();
    await _checkLoginStatus();
  }

  // ============================================================
  // PROFILE AVATAR
  // ============================================================
  Widget _buildProfileAvatar() {
    final hasImage = _profileImage != null && _profileImage!.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (hasImage) {
      final file = File(_profileImage!);
      if (file.existsSync()) {
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.file(
              file,
              width: 36,
              height: 36,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildSimpleProfileIcon(),
            ),
          ),
        );
      }
    }
    return _buildSimpleProfileIcon();
  }

  Widget _buildSimpleProfileIcon() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gold, AppColors.goldDark],
        ),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: const Icon(Icons.person, color: Colors.white, size: 20),
    );
  }

  // ============================================================
  // BUILD METHODS
  // ============================================================
  @override
  Widget build(BuildContext context) {
    super.build(context);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).colorScheme.background;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: BrandPatternBackground()),
          ),
          SafeArea(
            top: false,
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _handleRefresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  _buildStickyTopBar(),
                  SliverToBoxAdapter(child: _buildBannerCarousel()),
                  SliverToBoxAdapter(child: _buildBannerDots()),
                  SliverToBoxAdapter(
                    child: _isSearching ? _buildSearchResults() : const SizedBox.shrink(),
                  ),
                  SliverToBoxAdapter(
                    child: !_isSearching ? _buildNewArrivalsHeader() : const SizedBox.shrink(),
                  ),
                  SliverToBoxAdapter(
                    child: !_isSearching ? _buildNewArrivalsList() : const SizedBox.shrink(),
                  ),
                  SliverToBoxAdapter(
                    child: !_isSearching ? _buildFlashSaleHeader() : const SizedBox.shrink(),
                  ),
                  SliverToBoxAdapter(
                    child: !_isSearching ? _buildFlashSaleList() : const SizedBox.shrink(),
                  ),
                  SliverToBoxAdapter(
                    child: !_isSearching ? _buildCouponStrip() : const SizedBox.shrink(),
                  ),
                  SliverToBoxAdapter(
                    child: _buildForYouSection(),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STICKY TOP BAR
  // ============================================================
  Widget _buildStickyTopBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final searchBg = isDark ? Colors.grey[800] : Colors.white.withOpacity(0.8);

    final topBarBg = isDark
        ? const Color(0xFF1A1A1A).withOpacity(0.9)
        : const Color(0xFFD3AF64).withOpacity(1);

    final topBarBorder = isDark
        ? Colors.white.withOpacity(0.1)
        : const Color(0xFFB8944A).withOpacity(0.6);

    return SliverAppBar(
      pinned: true,
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: isDark ? Colors.white.withOpacity(0.05) : AppColors.outlineVariant,
      automaticallyImplyLeading: false,
      toolbarHeight: 72,
      titleSpacing: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          color: topBarBg,
          border: Border(bottom: BorderSide(color: topBarBorder, width: 1.5)),
          boxShadow: [BoxShadow(color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4))],
        ),
      ),
      title: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.5), width: 1.5),
                boxShadow: [BoxShadow(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  color: Colors.white,
                  child: Image.asset(
                    'assets/images/ktex_logo.png',
                    width: 48,
                    height: 48,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                      alignment: Alignment.center,
                      child: const Text('K', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 22, fontFamily: kFont)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: searchBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.3)),
                ),
                child: TextField(
                  controller: _searchController,
                  textAlignVertical: TextAlignVertical.center,
                  style: TextStyle(fontSize: 14, fontFamily: kFont, color: textColor),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _isSearching = value.isNotEmpty;
                    });
                  },
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search, size: 20, color: isDark ? Colors.white : AppColors.goldDark),
                    hintText: 'Search K-TEX...',
                    hintStyle: TextStyle(color: isDark ? Colors.white60 : AppColors.goldDark.withOpacity(0.6), fontSize: 14, fontFamily: kFont),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? GestureDetector(
                      onTap: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                          _isSearching = false;
                        });
                      },
                      child: Icon(Icons.clear, size: 18, color: isDark ? Colors.white54 : AppColors.outline),
                    )
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _isLoggedIn
                ? GestureDetector(
              onTap: _navigateToProfile,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.5), width: 1.5),
                ),
                child: _buildProfileAvatar(),
              ),
            )
                : GestureDetector(
              onTap: _navigateToLogin,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.5), width: 1.5),
                ),
                child: Center(
                  child: Icon(Icons.person_outline, color: isDark ? Colors.white : AppColors.goldDark, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BANNER CAROUSEL
  // ============================================================
  Widget _buildBannerCarousel() {
    if (_banners.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 190,
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n is ScrollStartNotification) _bannerTimer?.cancel();
            if (n is ScrollEndNotification) _startBannerAutoplay();
            return false;
          },
          child: PageView.builder(
            controller: _bannerController,
            itemCount: _banners.length,
            onPageChanged: (i) => setState(() => _bannerIndex = i),
            itemBuilder: (context, index) {
              final b = _banners[index];
              return ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      b.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: AppColors.surfaceContainerHigh,
                          child: const Center(child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2)),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(color: AppColors.primary),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [AppColors.primary.withOpacity(0.8), Colors.transparent],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 30, 100, 20),
                      child: MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          textScaler: MediaQuery.of(context).textScaler.clamp(maxScaleFactor: 1.2),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.onPrimary,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                                fontFamily: kFont,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              b.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: kFont),
                            ),
                            const SizedBox(height: 14),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                final category = b.category ?? '';
                                if (category == 'Premium Collection') {
                                  _navigateToCategory('Premium Collection', _premiumCollection, Icons.workspace_premium_rounded);
                                } else if (category == 'New Arrivals') {
                                  _navigateToCategory('New Arrivals', _newArrivals, Icons.new_releases_rounded);
                                } else if (category == 'Best Sellers') {
                                  _navigateToCategory('Best Sellers', _bestSellers, Icons.trending_up_rounded);
                                } else {
                                  _showSnack('Opening ${b.title.replaceAll('\n', ' ')}...');
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(24)),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Shop Now', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 13, fontFamily: kFont)),
                                    SizedBox(width: 6),
                                    Icon(Icons.arrow_forward, color: Colors.black, size: 14),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBannerDots() {
    if (_banners.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_banners.length, (i) {
          final active = i == _bannerIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: active ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: active ? AppColors.gold : AppColors.outlineVariant,
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE WIDGET
  // ============================================================
  Widget _buildEmptyState(String title, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = isDark ? Colors.white60 : AppColors.outline;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30),
      width: double.infinity,
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: mutedColor.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontFamily: kFont,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: TextStyle(
              fontFamily: kFont,
              fontSize: 13,
              color: mutedColor,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOADING SKELETON - Simple built-in loading (NO SHIMMER)
  // ============================================================
  Widget _buildLoadingSkeleton({bool isHorizontal = true, bool isSmall = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    if (isHorizontal) {
      return SizedBox(
        height: isSmall ? 202 : 222,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(left: 16, right: 4),
          itemCount: 4,
          itemBuilder: (context, index) {
            return Container(
              width: isSmall ? 120 : 140,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              // Simple pulsing animation
              child: _PulsingContainer(
                color: bgColor,
              ),
            );
          },
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.6,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: _PulsingContainer(
            color: bgColor,
          ),
        );
      },
    );
  }

  // ============================================================
  // SEARCH RESULTS
  // ============================================================
  Widget _buildSearchResults() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = isDark ? Colors.white60 : AppColors.outline;

    if (_searchQuery.isEmpty) return const SizedBox.shrink();

    if (_filteredProducts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 64, color: mutedColor.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'No products found for "$_searchQuery"',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: kFont, fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: TextStyle(fontFamily: kFont, fontSize: 13, color: mutedColor),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              Text('Search Results', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: kFont, color: textColor)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: Text('${_filteredProducts.length} items', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: kFont, color: AppColors.goldDark)),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.6,
            ),
            itemCount: _filteredProducts.length,
            itemBuilder: (context, index) {
              final product = _filteredProducts[index];
              final isFav = FavouritesScope.of(context).isFavourite(product.id);
              return _SearchResultCard(
                product: product,
                isFavourite: isFav,
                onTap: () => _navigateToProductDetail(product),
                onAddToCart: () {
                  HapticFeedback.lightImpact();
                  CartScope.of(context).addItem(
                    id: product.id,
                    name: product.name,
                    imageUrl: product.imageUrl,
                    price: product.price,
                  );
                  _showSnack('${product.name} added to cart');
                },
                onFavouriteToggle: () {
                  HapticFeedback.lightImpact();
                  final favourites = FavouritesScope.of(context);
                  favourites.toggleFavourite(product);
                  final msg = isFav ? '${product.name} removed from favourites' : '${product.name} added to favourites ❤️';
                  _showSnack(msg);
                },
                onBuyNow: () => _navigateToBuyNow(product),
              );
            },
          ),
        ),
      ],
    );
  }

  // ============================================================
  // NEW ARRIVALS SECTION
  // ============================================================
  Widget _buildNewArrivalsHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = isDark ? Colors.white60 : AppColors.outline;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          Flexible(
            child: Text(
              'New Arrivals',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: kFont, color: textColor),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(4)),
            child: const Text('NEW', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, fontFamily: kFont, color: Colors.white, letterSpacing: 0.5)),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              if (_newArrivals.isNotEmpty) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => NewArrivalsPage(products: _newArrivals.map((p) => NewArrivalProduct(
                    id: p.id,
                    name: p.name,
                    imageUrl: p.imageUrl,
                    price: p.price,
                    soldLabel: p.soldLabel ?? '',
                    stock: p.stock,
                    isPremium: p.isPremium,
                  )).toList())),
                );
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('View All', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: mutedColor, fontFamily: kFont, fontWeight: FontWeight.w700)),
                Icon(Icons.chevron_right, size: 18, color: mutedColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewArrivalsList() {
    if (_isLoadingNewArrivals) {
      return _buildLoadingSkeleton(isHorizontal: true);
    }

    if (_newArrivals.isEmpty) {
      return _buildEmptyState('No New Arrivals', 'Check back later for fresh styles');
    }

    final favourites = FavouritesScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).colorScheme.surface;

    return SizedBox(
      height: 222,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16, right: 4),
        itemCount: _newArrivals.length,
        itemBuilder: (context, index) {
          final product = _newArrivals[index];
          final isFav = favourites.isFavourite(product.id);

          return _NewArrivalCard(
            product: product,
            isFavourite: isFav,
            cardColor: cardColor,
            onTap: () => _navigateToProductDetail(product),
            onAddToCart: () {
              HapticFeedback.lightImpact();
              CartScope.of(context).addItem(
                id: product.id,
                name: product.name,
                imageUrl: product.imageUrl,
                price: product.price,
              );
              _showSnack('${product.name} added to cart');
            },
            onFavouriteToggle: () {
              HapticFeedback.lightImpact();
              favourites.toggleFavourite(product);
              final msg = isFav ? '${product.name} removed from favourites' : '${product.name} added to favourites ❤️';
              _showSnack(msg);
            },
            onBuyNow: () => _navigateToBuyNow(product),
          );
        },
      ),
    );
  }

  // ============================================================
  // FLASH SALE SECTION
  // ============================================================
  Widget _buildFlashSaleHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = isDark ? Colors.white60 : AppColors.outline;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Flexible(
            child: Text(
              'Flash Sale',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: kFont, color: textColor),
            ),
          ),
          const SizedBox(width: 10),
          const _FlashSaleCountdown(),
          const Spacer(),
          GestureDetector(
            onTap: () {
              if (_flashSale.isNotEmpty) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => FlashSalePage(products: _flashSale.map((p) => FlashSaleProduct(
                    id: p.id,
                    name: p.name,
                    imageUrl: p.imageUrl,
                    price: p.price,
                    originalPrice: p.originalPrice ?? p.price,
                    discountPercent: p.discountPercent ?? 0,
                    soldLabel: p.soldLabel,
                    stock: p.stock,
                    isPremium: p.isPremium,
                  )).toList())),
                );
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('View All', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: mutedColor, fontFamily: kFont, fontWeight: FontWeight.w700)),
                Icon(Icons.chevron_right, size: 18, color: mutedColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashSaleList() {
    if (_isLoadingFlashSale) {
      return _buildLoadingSkeleton(isHorizontal: true, isSmall: true);
    }

    if (_flashSale.isEmpty) {
      return _buildEmptyState('No Flash Sales', 'Check back later for great deals');
    }

    final favourites = FavouritesScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).colorScheme.surface;

    return SizedBox(
      height: 202,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16, right: 4),
        itemCount: _flashSale.length,
        itemBuilder: (context, index) {
          final product = _flashSale[index];
          final isFav = favourites.isFavourite(product.id);

          return _FlashSaleCard(
            product: product,
            isFavourite: isFav,
            cardColor: cardColor,
            onTap: () => _navigateToProductDetail(product),
            onAddToCart: () {
              HapticFeedback.lightImpact();
              CartScope.of(context).addItem(
                id: product.id,
                name: product.name,
                imageUrl: product.imageUrl,
                price: product.price,
              );
              _showSnack('${product.name} added to cart');
            },
            onFavouriteToggle: () {
              HapticFeedback.lightImpact();
              favourites.toggleFavourite(product);
              final msg = isFav ? '${product.name} removed from favourites' : '${product.name} added to favourites ❤️';
              _showSnack(msg);
            },
            onBuyNow: () => _navigateToBuyNow(product),
          );
        },
      ),
    );
  }

  // ============================================================
  // COUPON STRIP
  // ============================================================
  Widget _buildCouponStrip() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? Colors.white60 : AppColors.outline;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : AppColors.goldContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : AppColors.gold.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.goldDark.withOpacity(0.12), shape: BoxShape.circle),
              child: const Icon(Icons.confirmation_number_outlined, color: AppColors.goldDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Free Delivery', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, fontFamily: kFont, color: isDark ? Colors.white : AppColors.goldDark)),
                  Text('On orders over Rs. 5000', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontFamily: kFont, color: mutedColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FOR YOU SECTION
  // ============================================================
  Widget _buildForYouSection() {
    if (_isSearching) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;

    if (_isLoadingForYou) {
      return Column(
        children: [
          const _SectionDivider(title: 'FOR YOU'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            child: _buildLoadingSkeleton(isHorizontal: false),
          ),
        ],
      );
    }

    if (_forYou.isEmpty) {
      return Column(
        children: [
          const _SectionDivider(title: 'FOR YOU'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            child: _buildEmptyState('No Recommendations', 'Products will appear here based on your preferences'),
          ),
        ],
      );
    }

    return Column(
      children: [
        const _SectionDivider(title: 'FOR YOU'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.6,
            ),
            itemCount: _forYou.length,
            itemBuilder: (context, index) {
              final product = _forYou[index];
              final isFav = FavouritesScope.of(context).isFavourite(product.id);

              return _HomeProductCard(
                product: product,
                isFavourite: isFav,
                onTap: () => _navigateToProductDetail(product),
                onAddToCart: () {
                  HapticFeedback.lightImpact();
                  CartScope.of(context).addItem(
                    id: product.id,
                    name: product.name,
                    imageUrl: product.imageUrl,
                    price: product.price,
                  );
                  _showSnack('${product.name} added to cart');
                },
                onFavouriteToggle: () {
                  HapticFeedback.lightImpact();
                  final favourites = FavouritesScope.of(context);
                  favourites.toggleFavourite(product);
                  final msg = isFav ? '${product.name} removed from favourites' : '${product.name} added to favourites ❤️';
                  _showSnack(msg);
                },
                onBuyNow: () => _navigateToBuyNow(product),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ============================================================
// PULSING CONTAINER - Simple loading animation (NO SHIMMER)
// ============================================================
class _PulsingContainer extends StatefulWidget {
  final Color color;

  const _PulsingContainer({required this.color});

  @override
  State<_PulsingContainer> createState() => _PulsingContainerState();
}

class _PulsingContainerState extends State<_PulsingContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 0.8).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// SEARCH RESULT CARD
// ============================================================
class _SearchResultCard extends StatelessWidget {
  final Product product;
  final bool isFavourite;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;
  final VoidCallback onFavouriteToggle;
  final VoidCallback onBuyNow;

  const _SearchResultCard({
    required this.product,
    required this.isFavourite,
    required this.onTap,
    required this.onAddToCart,
    required this.onFavouriteToggle,
    required this.onBuyNow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final cardColor = Theme.of(context).colorScheme.surface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : AppColors.outlineVariant.withOpacity(0.2)),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(aspectRatio: 1, child: Image.network(product.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.primary))),
                if (product.isPremium)
                  Positioned(
                    top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.goldDark, borderRadius: BorderRadius.circular(4)),
                      child: const Text('PREMIUM', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700, fontFamily: kFont, letterSpacing: 0.3)),
                    ),
                  ),
                Positioned(
                  top: 8, right: 8,
                  child: GestureDetector(
                    onTap: onFavouriteToggle,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800]!.withOpacity(0.9) : Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
                      ),
                      child: Icon(isFavourite ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: isFavourite ? AppColors.saleRed : AppColors.outline, size: 18),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8, right: 8,
                  child: _HomeProductMenuButton(onAddToCart: onAddToCart, onBuyNow: onBuyNow),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, fontFamily: kFont, color: textColor)),
                  const SizedBox(height: 4),
                  Text('Rs.${product.price}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, fontFamily: kFont, color: textColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// NEW ARRIVAL CARD
// ============================================================
class _NewArrivalCard extends StatelessWidget {
  final Product product;
  final bool isFavourite;
  final Color cardColor;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;
  final VoidCallback onFavouriteToggle;
  final VoidCallback onBuyNow;

  const _NewArrivalCard({
    required this.product,
    required this.isFavourite,
    required this.cardColor,
    required this.onTap,
    required this.onAddToCart,
    required this.onFavouriteToggle,
    required this.onBuyNow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = isDark ? Colors.white60 : AppColors.outline;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : AppColors.outlineVariant.withOpacity(0.2)),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.network(product.imageUrl, height: 130, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 130, color: AppColors.primary)),
                Positioned(
                  top: 6, left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(4)),
                    child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700, fontFamily: kFont, letterSpacing: 0.5)),
                  ),
                ),
                Positioned(
                  top: 6, right: 6,
                  child: GestureDetector(
                    onTap: onFavouriteToggle,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800]!.withOpacity(0.9) : Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
                      ),
                      child: Icon(isFavourite ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: isFavourite ? AppColors.saleRed : AppColors.outline, size: 16),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8, right: 8,
                  child: _HomeProductMenuButton(onAddToCart: onAddToCart, onBuyNow: onBuyNow),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontFamily: kFont, fontWeight: FontWeight.w500, color: textColor)),
                  const SizedBox(height: 4),
                  Text('Rs.${product.price}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, fontFamily: kFont, color: textColor)),
                  const SizedBox(height: 3),
                  SoldStockRow(soldLabel: product.soldLabel, stock: product.stock, fontSize: 9, alignment: MainAxisAlignment.start),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// FLASH SALE CARD
// ============================================================
class _FlashSaleCard extends StatelessWidget {
  final Product product;
  final bool isFavourite;
  final Color cardColor;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;
  final VoidCallback onFavouriteToggle;
  final VoidCallback onBuyNow;

  const _FlashSaleCard({
    required this.product,
    required this.isFavourite,
    required this.cardColor,
    required this.onTap,
    required this.onAddToCart,
    required this.onFavouriteToggle,
    required this.onBuyNow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = isDark ? Colors.white60 : AppColors.outline;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : AppColors.outlineVariant.withOpacity(0.2)),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.network(product.imageUrl, height: 110, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 110, color: AppColors.primary)),
                Positioned(
                  top: 6, left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.saleRed, borderRadius: BorderRadius.circular(4)),
                    child: Text('-${product.discountPercent ?? 0}%', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700, fontFamily: kFont)),
                  ),
                ),
                Positioned(
                  top: 6, right: 6,
                  child: GestureDetector(
                    onTap: onFavouriteToggle,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800]!.withOpacity(0.9) : Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
                      ),
                      child: Icon(isFavourite ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: isFavourite ? AppColors.saleRed : AppColors.outline, size: 16),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 6, right: 6,
                  child: _HomeProductMenuButton(onAddToCart: onAddToCart, onBuyNow: onBuyNow),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontFamily: kFont, fontWeight: FontWeight.w500, color: textColor)),
                  const SizedBox(height: 4),
                  Text('Rs.${product.price}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, fontFamily: kFont, color: AppColors.saleRed)),
                  Text('Rs.${product.originalPrice ?? product.price}', style: TextStyle(fontSize: 10, fontFamily: kFont, color: mutedColor, decoration: TextDecoration.lineThrough)),
                  const SizedBox(height: 3),
                  SoldStockRow(soldLabel: product.soldLabel, stock: product.stock, alignment: MainAxisAlignment.start),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// HOME PRODUCT CARD
// ============================================================
class _HomeProductCard extends StatelessWidget {
  final Product product;
  final bool isFavourite;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;
  final VoidCallback onFavouriteToggle;
  final VoidCallback onBuyNow;

  const _HomeProductCard({
    required this.product,
    required this.isFavourite,
    required this.onTap,
    required this.onAddToCart,
    required this.onFavouriteToggle,
    required this.onBuyNow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final cardColor = Theme.of(context).colorScheme.surface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : AppColors.outlineVariant.withOpacity(0.2)),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(aspectRatio: 1, child: Image.network(product.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.primary))),
                if (product.isPremium)
                  Positioned(
                    top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.goldDark, borderRadius: BorderRadius.circular(4)),
                      child: const Text('PREMIUM', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700, fontFamily: kFont, letterSpacing: 0.3)),
                    ),
                  ),
                Positioned(
                  top: 8, right: 8,
                  child: GestureDetector(
                    onTap: onFavouriteToggle,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800]!.withOpacity(0.9) : Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
                      ),
                      child: Icon(isFavourite ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: isFavourite ? AppColors.saleRed : AppColors.outline, size: 18),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8, right: 8,
                  child: _HomeProductMenuButton(onAddToCart: onAddToCart, onBuyNow: onBuyNow),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, fontFamily: kFont, color: textColor)),
                  const SizedBox(height: 4),
                  Text('Rs.${product.price}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, fontFamily: kFont, color: textColor)),
                  const SizedBox(height: 3),
                  SoldStockRow(soldLabel: product.soldLabel, stock: product.stock, alignment: MainAxisAlignment.start),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// HOME PRODUCT MENU BUTTON
// ============================================================
class _HomeProductMenuButton extends StatelessWidget {
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;

  const _HomeProductMenuButton({
    required this.onAddToCart,
    required this.onBuyNow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopupMenuButton<String>(
      offset: const Offset(-10, 0),
      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      onSelected: (value) {
        if (value == 'cart') { HapticFeedback.lightImpact(); onAddToCart(); }
        else if (value == 'buy') { HapticFeedback.lightImpact(); onBuyNow(); }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'cart',
          child: Row(
            children: [
              const Icon(Icons.shopping_cart_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 10),
              Text('Add to Cart', style: TextStyle(fontFamily: kFont, fontSize: 13, color: isDark ? Colors.white : AppColors.primary)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'buy',
          child: Row(
            children: [
              const Icon(Icons.flash_on_outlined, size: 18, color: AppColors.goldDark),
              const SizedBox(width: 10),
              Text('Buy Now', style: TextStyle(fontFamily: kFont, fontSize: 13, color: isDark ? Colors.white : AppColors.primary)),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.gold,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: const Icon(Icons.more_horiz, size: 16, color: Colors.black),
      ),
    );
  }
}

// ============================================================
// SECTION DIVIDER
// ============================================================
class _SectionDivider extends StatelessWidget {
  final String title;
  const _SectionDivider({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final dividerColor = isDark ? Colors.white.withOpacity(0.1) : AppColors.outlineVariant.withOpacity(0.5);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: dividerColor)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1, fontFamily: kFont, color: textColor)),
          ),
          Expanded(child: Divider(color: dividerColor)),
        ],
      ),
    );
  }
}

// ============================================================
// FLASH SALE COUNTDOWN
// ============================================================
class _FlashSaleCountdown extends StatefulWidget {
  const _FlashSaleCountdown();

  @override
  State<_FlashSaleCountdown> createState() => _FlashSaleCountdownState();
}

class _FlashSaleCountdownState extends State<_FlashSaleCountdown> {
  Duration _timeLeft = const Duration(hours: 2, minutes: 14, seconds: 59);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_timeLeft.inSeconds <= 0) { _timer?.cancel(); return; }
      setState(() => _timeLeft -= const Duration(seconds: 1));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final h = _two(_timeLeft.inHours);
    final m = _two(_timeLeft.inMinutes.remainder(60));
    final s = _two(_timeLeft.inSeconds.remainder(60));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
      child: Text('$h : $m : $s', style: const TextStyle(color: AppColors.onPrimary, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: kFont)),
    );
  }
}