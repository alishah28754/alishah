// lib/services/api_service.dart
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:ktex_home/config/environment.dart';
import 'package:ktex_home/models/models.dart';
import 'package:ktex_home/models/order_model.dart';

/// Firebase authentication helpers
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signUp(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  bool isLoggedIn() {
    return _auth.currentUser != null;
  }

  String? getUserId() {
    return _auth.currentUser?.uid;
  }

  String? getUserEmail() {
    return _auth.currentUser?.email;
  }

  String? getUserName() {
    return _auth.currentUser?.displayName;
  }
}

/// API Exception
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

/// API Service
class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();

  String get baseUrl => Environment.apiBaseUrl;

  Future<String?> _getToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final token = await user.getIdToken();
    return token;
  }

  Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await _getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = baseUrl.replaceFirst(RegExp(r'/$'), '');
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$cleanPath').replace(queryParameters: query);
  }

  dynamic _unwrap(http.Response res) {
    dynamic body;
    try {
      body = jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      body = null;
    }
    final map = body is Map<String, dynamic> ? body : null;
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return map?['data'];
    }
    throw ApiException(
      map?['message'] ?? 'Request failed (${res.statusCode}).',
      res.statusCode,
    );
  }

  Future<dynamic> get(String path,
      {Map<String, String>? query, bool auth = false}) async {
    final res = await http.get(_uri(path, query), headers: await _headers(auth: auth));
    return _unwrap(res);
  }

  Future<dynamic> post(String path,
      {Map<String, dynamic>? body, bool auth = false}) async {
    final res = await http.post(_uri(path),
        headers: await _headers(auth: auth), body: jsonEncode(body ?? const {}));
    return _unwrap(res);
  }

  Future<dynamic> put(String path,
      {Map<String, dynamic>? body, bool auth = false}) async {
    final res = await http.put(_uri(path),
        headers: await _headers(auth: auth), body: jsonEncode(body ?? const {}));
    return _unwrap(res);
  }

  Future<dynamic> delete(String path, {bool auth = false}) async {
    final res = await http.delete(_uri(path), headers: await _headers(auth: auth));
    return _unwrap(res);
  }

  // ============================================================
  // CATALOG (public endpoints)
  // ============================================================

  Future<List<BannerSlide>> fetchBanners() async {
    final data = await get('/banners');
    final list = data is List ? data : const [];
    return list
        .map((e) => BannerSlide.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// ✅ FIXED: Supports all filter parameters
  Future<List<Product>> fetchProducts({
    String? search,
    String? category,
    String? parentCategory,
    bool? isPremium,
    bool? isNewArrival,
    bool? isBestSeller,
    bool? isFlashSale,
    bool? isForYou,
    int page = 1,
    int limit = 100,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (category != null && category.trim().isNotEmpty) 'category': category.trim(),
      if (parentCategory != null && parentCategory.trim().isNotEmpty)
        'parent_category': parentCategory.trim(),
      if (isPremium != null) 'is_premium': '$isPremium',
      if (isNewArrival != null) 'is_new_arrival': '$isNewArrival',
      if (isBestSeller != null) 'is_best_seller': '$isBestSeller',
      if (isFlashSale != null) 'is_flash_sale': '$isFlashSale',
      if (isForYou != null) 'is_for_you': '$isForYou',
    };
    final data = await get('/products', query: query);
    final list = data is Map<String, dynamic> ? (data['items'] ?? []) : (data ?? const []);
    return (list as List)
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// ✅ GET /api/products/flash-sale
  Future<List<Product>> fetchFlashSale() async {
    final data = await get('/products/flash-sale');
    final list = data is List ? data : const [];
    return list
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// ✅ GET /api/products/new-arrivals
  Future<List<Product>> fetchNewArrivals() async {
    final data = await get('/products/new-arrivals');
    final list = data is List ? data : const [];
    return list
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// ✅ GET /api/products/for-you
  Future<List<Product>> fetchForYou() async {
    final data = await get('/products/for-you');
    final list = data is List ? data : const [];
    return list
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// ✅ GET /api/products/best-sellers - FIXED
  Future<List<Product>> fetchBestSellers() async {
    try {
      final data = await get('/products/best-sellers');
      final list = data is List ? data : const [];
      return list
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback: try using the products endpoint with filter
      try {
        return await fetchProducts(isBestSeller: true);
      } catch (_) {
        return [];
      }
    }
  }

  /// POST /api/auth/sync
  Future<Map<String, dynamic>> syncUser() async {
    final data = await post('/auth/sync', auth: true);
    return data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> fetchCategories({String? parent}) async {
    final query = <String, String>{
      if (parent != null && parent.trim().isNotEmpty) 'parent': parent.trim(),
    };
    final data = await get('/categories', query: query.isEmpty ? null : query);
    final list = data is List ? data : const [];
    return list.cast<Map<String, dynamic>>();
  }

  // ============================================================
  // ORDERS
  // ============================================================

  Future<Order> createOrder(Map<String, dynamic> payload) async {
    final data = await post('/orders', body: payload, auth: true);
    return Order.fromJson(data as Map<String, dynamic>);
  }

  Future<Order> trackOrder(String orderNumber) async {
    final data = await get('/orders/track/$orderNumber');
    return Order.fromJson(data as Map<String, dynamic>);
  }

  Future<List<Order>> fetchMyOrders() async {
    final data = await get('/orders', auth: true);
    final list = data is List ? data : const [];
    return list
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // CART & FAVOURITES
  // ============================================================

  Future<List<dynamic>> fetchCart() async {
    final data = await get('/cart', auth: true);
    return data is List ? data : const [];
  }

  Future<dynamic> addToCart(String productId, {int quantity = 1}) async {
    return post('/cart', body: {'product_id': productId, 'quantity': quantity}, auth: true);
  }

  Future<dynamic> updateCartItem(String productId, int quantity) async {
    return put('/cart/$productId', body: {'quantity': quantity}, auth: true);
  }

  Future<dynamic> removeFromCart(String productId) async {
    return delete('/cart/$productId', auth: true);
  }

  Future<dynamic> clearCart() async {
    return delete('/cart', auth: true);
  }

  Future<List<Product>> fetchFavourites() async {
    final data = await get('/favourites', auth: true);
    final list = data is List ? data : const [];
    return list
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<dynamic> addFavourite(String productId) async {
    return post('/favourites', body: {'product_id': productId}, auth: true);
  }

  Future<dynamic> removeFavourite(String productId) async {
    return delete('/favourites/$productId', auth: true);
  }
}