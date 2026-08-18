import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:ktex_home/config/environment.dart';
import 'package:ktex_home/models/models.dart';
import 'package:ktex_home/models/order_model.dart';

/// Firebase authentication helpers (email/password + Google).
/// The Flutter shoppers app still authenticates with Firebase; the backend
/// verifies the ID token we attach in [ApiService]'s Authorization header.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign Up
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

  // Sign In
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

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get Current User
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Check if user is logged in
  bool isLoggedIn() {
    return _auth.currentUser != null;
  }

  // Get User ID
  String? getUserId() {
    return _auth.currentUser?.uid;
  }

  // Get User Email
  String? getUserEmail() {
    return _auth.currentUser?.email;
  }

  // Get User Display Name
  String? getUserName() {
    return _auth.currentUser?.displayName;
  }
}

/// Thrown by [ApiService] whenever the backend returns an error or the
/// network request fails. [message] is always user-friendly.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

/// Thin, typed HTTP client for the KTEX Node/Express backend.
///
/// Every backend route responds with the envelope
/// `{ success, message, data }`. [ApiService] unwraps it so callers receive
/// the `data` payload directly and get a friendly [ApiException] otherwise.
///
/// Protected endpoints automatically receive the current Firebase ID token
/// (`Authorization: Bearer <token>`), which the backend verifies with the
/// Firebase Admin SDK. Guest checkout (no token) is handled gracefully.
class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();

  String get baseUrl => Environment.apiBaseUrl;

  /// Resolves the current Firebase ID token, or null when signed out.
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

  /// GET /api/banners
  Future<List<BannerSlide>> fetchBanners() async {
    final data = await get('/banners');
    final list = data is List ? data : const [];
    return list
        .map((e) => BannerSlide.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/products?category=&search=&is_premium=&page=&limit=
  Future<List<Product>> fetchProducts({
    String? search,
    String? category,
    bool? isPremium,
    int page = 1,
    int limit = 100,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (category != null && category.trim().isNotEmpty) 'category': category.trim(),
      if (isPremium != null) 'is_premium': '$isPremium',
    };
    final data = await get('/products', query: query);
    final list = data is Map<String, dynamic> ? (data['items'] ?? []) : (data ?? const []);
    return (list as List)
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/products/flash-sale
  Future<List<Product>> fetchFlashSale() async {
    final data = await get('/products/flash-sale');
    final list = data is List ? data : const [];
    return list
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/products/new-arrivals
  Future<List<Product>> fetchNewArrivals() async {
    final data = await get('/products/new-arrivals');
    final list = data is List ? data : const [];
    return list
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/products/for-you
  Future<List<Product>> fetchForYou() async {
    final data = await get('/products/for-you');
    final list = data is List ? data : const [];
    return list
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/products/:id
  Future<Product> fetchProduct(String id) async {
    final data = await get('/products/$id');
    return Product.fromJson(data as Map<String, dynamic>);
  }

  /// GET /api/categories
  Future<List<Map<String, dynamic>>> fetchCategories() async {
    final data = await get('/categories');
    final list = data is List ? data : const [];
    return list.cast<Map<String, dynamic>>();
  }

  // ============================================================
  // ORDERS
  // ============================================================

  /// POST /api/orders — creates an order. Works for guests and logged-in users.
  /// Returns the persisted order (with server-assigned order_number + tracking).
  Future<Order> createOrder(Map<String, dynamic> payload) async {
    final data = await post('/orders', body: payload, auth: true);
    return Order.fromJson(data as Map<String, dynamic>);
  }

  /// GET /api/orders/track/:orderNumber — public tracking lookup.
  Future<Order> trackOrder(String orderNumber) async {
    final data = await get('/orders/track/$orderNumber');
    return Order.fromJson(data as Map<String, dynamic>);
  }

  /// GET /api/orders — the current user's orders (requires login).
  Future<List<Order>> fetchMyOrders() async {
    final data = await get('/orders', auth: true);
    final list = data is List ? data : const [];
    return list
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // CART & FAVOURITES (require login)
  // ============================================================

  /// GET /api/cart — items already match CartItem.fromJson shape.
  Future<List<dynamic>> fetchCart() async {
    final data = await get('/cart', auth: true);
    return data is List ? data : const [];
  }

  /// POST /api/cart { product_id, quantity }
  Future<dynamic> addToCart(String productId, {int quantity = 1}) async {
    return post('/cart', body: {'product_id': productId, 'quantity': quantity}, auth: true);
  }

  /// PUT /api/cart/:productId { quantity }
  Future<dynamic> updateCartItem(String productId, int quantity) async {
    return put('/cart/$productId', body: {'quantity': quantity}, auth: true);
  }

  /// DELETE /api/cart/:productId
  Future<dynamic> removeFromCart(String productId) async {
    return delete('/cart/$productId', auth: true);
  }

  /// DELETE /api/cart
  Future<dynamic> clearCart() async {
    return delete('/cart', auth: true);
  }

  /// GET /api/favourites — returns products (Product.fromJson compatible).
  Future<List<Product>> fetchFavourites() async {
    final data = await get('/favourites', auth: true);
    final list = data is List ? data : const [];
    return list
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/favourites { product_id }
  Future<dynamic> addFavourite(String productId) async {
    return post('/favourites', body: {'product_id': productId}, auth: true);
  }

  /// DELETE /api/favourites/:productId
  Future<dynamic> removeFavourite(String productId) async {
    return delete('/favourites/$productId', auth: true);
  }
}