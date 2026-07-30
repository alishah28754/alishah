import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'brand_pattern.dart';
import 'cart_model.dart';
import 'models.dart';
import 'widgets.dart';

class HomePage extends StatefulWidget {
  /// Called when the user taps the profile icon in the top bar.
  final VoidCallback? onProfileTap;

  const HomePage({super.key, this.onProfileTap});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  final PageController _bannerController = PageController();
  int _bannerIndex = 0;
  Timer? _bannerTimer;

  // Cache the banner timer to avoid rebuilding
  final List<BannerSlide> _banners = const [
    BannerSlide(
      title: 'Premium\nPolo Shirts',
      subtitle: 'Elevate your everyday style.',
      imageUrl:
          'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=800',
    ),
    BannerSlide(
      title: 'New Season\nArrivals',
      subtitle: 'Curated pieces, just landed.',
      imageUrl:
          'https://images.unsplash.com/photo-1441984904996-e0b6ba687e04?w=800',
    ),
    BannerSlide(
      title: 'Summer\nCollection',
      subtitle: 'Stay cool in style.',
      imageUrl:
          'https://images.unsplash.com/photo-1562157873-8182820720f1?w=800',
    ),
  ];

  final List<NewArrivalProduct> _newArrivals = const [
    NewArrivalProduct(
      name: 'Linen Blend Blazer - Beige',
      imageUrl:
          'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=400',
      price: 8999,
      soldLabel: '240 sold',
    ),
    NewArrivalProduct(
      name: 'Silk Satin Shirt - Ivory',
      imageUrl:
          'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=400',
      price: 4500,
      soldLabel: '180 sold',
    ),
    NewArrivalProduct(
      name: 'Tailored Wool Trousers - Charcoal',
      imageUrl:
          'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=400',
      price: 6500,
      soldLabel: '95 sold',
    ),
    NewArrivalProduct(
      name: 'Cashmere Crew Neck - Camel',
      imageUrl:
          'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=400',
      price: 12000,
      soldLabel: '310 sold',
      isPremium: true,
    ),
  ];

  final List<FlashSaleProduct> _flashSale = const [
    FlashSaleProduct(
      name: 'Premium Cotton Shirt',
      imageUrl:
          'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=300',
      price: 2499,
      originalPrice: 4999,
      discountPercent: 50,
    ),
    FlashSaleProduct(
      name: 'Classic Denim Jeans',
      imageUrl:
          'https://images.unsplash.com/photo-1542272604-787c3835535d?w=300',
      price: 3499,
      originalPrice: 5999,
      discountPercent: 42,
    ),
    FlashSaleProduct(
      name: 'Wool Blend Overcoat',
      imageUrl:
          'https://images.unsplash.com/photo-1539533018447-63fcce2678e3?w=300',
      price: 7999,
      originalPrice: 12999,
      discountPercent: 38,
    ),
    FlashSaleProduct(
      name: 'Linen Summer Suit',
      imageUrl:
          'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=300',
      price: 9999,
      originalPrice: 15999,
      discountPercent: 37,
    ),
  ];

  final List<ForYouProduct> _forYou = const [
    ForYouProduct(
      name: 'Premium Cotton Oxford Shirt - Slim Fit',
      imageUrl:
          'https://images.unsplash.com/photo-1620012253295-c15cc3e65df4?w=400',
      price: 2999,
      soldLabel: '1.2k sold',
    ),
    ForYouProduct(
      name: 'Classic Dark Wash Denim Jeans',
      imageUrl:
          'https://images.unsplash.com/photo-1542272604-787c3835535d?w=400',
      price: 4500,
      soldLabel: '850 sold',
    ),
    ForYouProduct(
      name: 'Merino Wool Crew Neck Sweater',
      imageUrl:
          'https://images.unsplash.com/photo-1576566588028-4147f3842f27?w=400',
      price: 6800,
      soldLabel: '530 sold',
      isPremium: true,
    ),
    ForYouProduct(
      name: 'Tailored Fit Chino Trousers - Khaki',
      imageUrl:
          'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=400',
      price: 3800,
      soldLabel: '720 sold',
    ),
  ];

  @override
  bool get wantKeepAlive => true; // Keep state when tab switches

  @override
  void initState() {
    super.initState();
    _startBannerAutoplay();
  }

  void _startBannerAutoplay() {
    _bannerTimer?.cancel();
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

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.lightImpact();
    // TODO: re-fetch banners/flash-sale/for-you from your Laravel API here.
    await Future.delayed(const Duration(milliseconds: 900));
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(fontFamily: kFont)),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

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
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _handleRefresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  _buildStickyTopBar(),
                  SliverToBoxAdapter(child: _buildBannerCarousel()),
                  SliverToBoxAdapter(child: _buildBannerDots()),
                  SliverToBoxAdapter(child: _buildNewArrivalsHeader()),
                  SliverToBoxAdapter(child: _buildNewArrivalsList()),
                  SliverToBoxAdapter(child: _buildFlashSaleHeader()),
                  SliverToBoxAdapter(child: _buildFlashSaleList()),
                  SliverToBoxAdapter(child: _buildCouponStrip()),
                  const SliverToBoxAdapter(child: _SectionDivider(title: 'FOR YOU')),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.56,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => ForYouCard(
                          product: _forYou[index],
                          onTap: () => _showSnack('Opening ${_forYou[index].name}...'),
                          onAddToCart: () {
                            HapticFeedback.lightImpact();
                            CartScope.of(context).addItem(
                              name: _forYou[index].name,
                              imageUrl: _forYou[index].imageUrl,
                              price: _forYou[index].price,
                            );
                            _showSnack('${_forYou[index].name} added to cart');
                          },
                          onAddToFavourites: () {
                            HapticFeedback.lightImpact();
                            _showSnack('${_forYou[index].name} added to favourites ❤️');
                          },
                        ),
                        childCount: _forYou.length,
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
      toolbarHeight: 72,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/ktex_logo.png',
                width: 48,
                height: 48,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'K',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      fontFamily: kFont,
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
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.outlineVariant.withOpacity(0.4)),
                ),
                child: TextField(
                  textAlignVertical: TextAlignVertical.center,
                  style: const TextStyle(fontSize: 14, fontFamily: kFont),
                  onSubmitted: (q) {
                    if (q.trim().isEmpty) return;
                    _showSnack('Searching for "$q"...');
                  },
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    prefixIcon: Icon(
                      Icons.search,
                      size: 20,
                      color: Colors.black,
                    ),
                    hintText: 'Search K-TEX...',
                    hintStyle: TextStyle(
                      color: AppColors.outline,
                      fontSize: 14,
                      fontFamily: kFont,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: widget.onProfileTap,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.gold,
                      AppColors.goldDark,
                    ],
                  ),
                  border: Border.all(
                    color: AppColors.goldDark.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.goldDark.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerCarousel() {
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
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.gold,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) =>
                          Container(color: AppColors.primary),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            AppColors.primary.withOpacity(0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 30, 100, 20),
                      child: MediaQuery(
                        // Fixed-height decorative banner: clamp text scale
                        // so large accessibility font settings can't push
                        // this content past the 190px box (see widgets.dart
                        // for the same pattern on the product cards).
                        data: MediaQuery.of(context).copyWith(
                          textScaler: MediaQuery.of(context)
                              .textScaler
                              .clamp(maxScaleFactor: 1.2),
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
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontFamily: kFont,
                            ),
                          ),
                          const SizedBox(height: 14),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _showSnack('Opening ${b.title.replaceAll('\n', ' ')}...');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.gold,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Shop Now',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      fontFamily: kFont,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(Icons.arrow_forward,
                                      color: Colors.black, size: 14),
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

  Widget _buildNewArrivalsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          const Flexible(
            child: Text(
              'New Arrivals',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: kFont,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'NEW',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                fontFamily: kFont,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _showSnack('Opening all New Arrivals...'),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View All',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.outline,
                    fontFamily: kFont,
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: AppColors.outline),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewArrivalsList() {
    return SizedBox(
      // A few px of buffer above the card's natural content height, so
      // moderate text-scale settings (now clamped at 1.2x inside the card
      // itself, see widgets.dart) still have room to breathe without
      // this fixed-height parent clipping/overflowing them.
      height: 222,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16, right: 4),
        itemCount: _newArrivals.length,
        itemBuilder: (context, index) => NewArrivalCard(
          product: _newArrivals[index],
          onTap: () => _showSnack('Opening ${_newArrivals[index].name}...'),
          onAddToCart: () {
            HapticFeedback.lightImpact();
            CartScope.of(context).addItem(
              name: _newArrivals[index].name,
              imageUrl: _newArrivals[index].imageUrl,
              price: _newArrivals[index].price,
            );
            _showSnack('${_newArrivals[index].name} added to cart');
          },
          onAddToFavourites: () {
            HapticFeedback.lightImpact();
            _showSnack('${_newArrivals[index].name} added to favourites ❤️');
          },
        ),
      ),
    );
  }

  Widget _buildFlashSaleHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          const Flexible(
            child: Text(
              'Flash Sale',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: kFont,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const _FlashSaleCountdown(),
          const Spacer(),
          GestureDetector(
            onTap: () => _showSnack('Opening all Flash Sale items...'),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View All',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.outline,
                    fontFamily: kFont,
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: AppColors.outline),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashSaleList() {
    return SizedBox(
      height: 202,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16, right: 4),
        itemCount: _flashSale.length,
        itemBuilder: (context, index) => FlashSaleCard(
          product: _flashSale[index],
          onTap: () => _showSnack('Opening ${_flashSale[index].name}...'),
          onAddToCart: () {
            HapticFeedback.lightImpact();
            CartScope.of(context).addItem(
              name: _flashSale[index].name,
              imageUrl: _flashSale[index].imageUrl,
              price: _flashSale[index].price,
            );
            _showSnack('${_flashSale[index].name} added to cart');
          },
          onAddToFavourites: () {
            HapticFeedback.lightImpact();
            _showSnack('${_flashSale[index].name} added to favourites ❤️');
          },
        ),
      ),
    );
  }

  Widget _buildCouponStrip() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.goldContainer,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.goldDark.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.confirmation_number_outlined,
                  color: AppColors.goldDark),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rs.200 OFF Order',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      fontFamily: kFont,
                      color: AppColors.goldDark,
                    ),
                  ),
                  Text(
                    'Plus Free Delivery',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: kFont,
                      color: AppColors.goldDark,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                _showSnack('Coupon applied! Rs.200 off + free delivery.');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.goldDark,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Claim',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    fontFamily: kFont,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  final String title;
  const _SectionDivider({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: AppColors.outlineVariant.withOpacity(0.5))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
                fontFamily: kFont,
                color: AppColors.primary,
              ),
            ),
          ),
          Expanded(child: Divider(color: AppColors.outlineVariant.withOpacity(0.5))),
        ],
      ),
    );
  }
}

/// Optimized countdown widget that only rebuilds itself, not the entire page
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
      if (_timeLeft.inSeconds <= 0) {
        _timer?.cancel();
        return;
      }
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
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$h : $m : $s',
        style: const TextStyle(
          color: AppColors.onPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: kFont,
        ),
      ),
    );
  }
}