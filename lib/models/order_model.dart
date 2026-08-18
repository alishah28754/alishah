// lib/order_model.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ktex_home/services/api_service.dart';
import 'dart:convert';

class OrderItem {
  final String name;
  final int price;
  final int quantity;
  final String imageUrl;

  OrderItem({
    required this.name,
    required this.price,
    required this.quantity,
    required this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'price': price,
    'quantity': quantity,
    'imageUrl': imageUrl,
  };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    name: json['name'] ?? '',
    price: json['price'] ?? 0,
    quantity: json['quantity'] ?? 1,
    imageUrl: json['imageUrl'] ?? '',
  );
}

class Order {
  final String id;
  final String date;
  final int items;
  final int total;
  final String status;
  final String payment;
  final String tracking;
  final String image;
  final List<OrderItem> orderItems;

  Order({
    required this.id,
    required this.date,
    required this.items,
    required this.total,
    required this.status,
    required this.payment,
    required this.tracking,
    required this.image,
    this.orderItems = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'items': items,
    'total': total,
    'status': status,
    'payment': payment,
    'tracking': tracking,
    'image': image,
    'orderItems': orderItems.map((item) => item.toJson()).toList(),
  };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id'] ?? '',
    date: json['date'] ?? '',
    items: json['items'] ?? 0,
    total: json['total'] ?? 0,
    status: json['status'] ?? 'Processing',
    payment: json['payment'] ?? '',
    tracking: json['tracking'] ?? '',
    image: json['image'] ?? '',
    orderItems: (json['orderItems'] as List<dynamic>?)
        ?.map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
        .toList() ?? [],
  );
}

class OrderModel extends ChangeNotifier {
  final List<Order> _orders = [];
  String? _userId;
  bool _initialized = false;

  List<Order> get orders => List.unmodifiable(_orders);
  String? get userId => _userId;
  int get count => _orders.length;
  bool get isInitialized => _initialized;

  /// Initialize with user ID
  Future<void> init({required String userId}) async {
    if (_initialized && _userId != null && _userId != userId) {
      await _saveOrders();
    }

    _userId = userId;
    _orders.clear();
    await _loadOrders();
    _initialized = true;
    notifyListeners();
  }

  /// Switch to guest mode
  Future<void> switchToGuest() async {
    await init(userId: 'guest');
  }

  /// Switch to user mode. When the user is signed in with Firebase, we also
  /// pull their real orders from the backend (the source of truth).
  Future<void> switchToUser(String userEmail) async {
    await init(userId: userEmail);
    try {
      if (FirebaseAuth.instance.currentUser != null) {
        await refreshFromApi();
      }
    } catch (e) {
      debugPrint('Error syncing orders from API: $e');
    }
  }

  /// Fetches the logged-in user's orders from the backend and replaces the
  /// local list. Falls back to cached local data on error.
  Future<void> refreshFromApi() async {
    try {
      final apiOrders = await ApiService.instance.fetchMyOrders();
      _orders
        ..clear()
        ..addAll(apiOrders);
      await _saveOrders();
      _initialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('refreshFromApi failed (using local cache): $e');
    }
  }

  /// Looks an order up via the public backend tracking endpoint.
  /// Returns null if the network fails so callers can fall back to local data.
  Future<Order?> trackViaApi(String orderNumber) async {
    try {
      final order = await ApiService.instance.trackOrder(orderNumber);
      _upsertOrder(order);
      return order;
    } catch (e) {
      debugPrint('trackViaApi failed: $e');
      return null;
    }
  }

  void _upsertOrder(Order order) {
    final index = _orders.indexWhere((o) => o.id == order.id);
    if (index >= 0) {
      _orders[index] = order;
    } else {
      _orders.insert(0, order);
    }
    _saveOrders();
    notifyListeners();
  }

  Future<void> _loadOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'orders_${_userId ?? 'guest'}';
      final String? ordersJson = prefs.getString(key);

      _orders.clear();
      if (ordersJson != null && ordersJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(ordersJson);
        _orders.addAll(
            decoded.map((item) => Order.fromJson(item as Map<String, dynamic>))
        );
      }
    } catch (e) {
      debugPrint('Error loading orders: $e');
      _orders.clear();
    }
  }

  Future<void> _saveOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'orders_${_userId ?? 'guest'}';
      final String encoded = jsonEncode(
          _orders.map((order) => order.toJson()).toList()
      );
      await prefs.setString(key, encoded);
    } catch (e) {
      debugPrint('Error saving orders: $e');
    }
  }

  void setUserId(String? userId) {
    _userId = userId;
    notifyListeners();
  }

  void addOrder(Order order) {
    _orders.insert(0, order);
    _saveOrders();
    notifyListeners();
  }

  void updateOrderStatus(String orderId, String newStatus) {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index != -1) {
      final oldOrder = _orders[index];
      _orders[index] = Order(
        id: oldOrder.id,
        date: oldOrder.date,
        items: oldOrder.items,
        total: oldOrder.total,
        status: newStatus,
        payment: oldOrder.payment,
        tracking: oldOrder.tracking,
        image: oldOrder.image,
        orderItems: oldOrder.orderItems,
      );
      _saveOrders();
      notifyListeners();
    }
  }

  void clearCancelledOrders() {
    _orders.removeWhere((order) => order.status == 'Cancelled');
    _saveOrders();
    notifyListeners();
  }

  void deleteOrder(String orderId) {
    _orders.removeWhere((order) => order.id == orderId);
    _saveOrders();
    notifyListeners();
  }

  void clearAllOrders() {
    _orders.clear();
    _saveOrders();
    notifyListeners();
  }
}