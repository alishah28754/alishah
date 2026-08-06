import 'package:flutter/material.dart';

class OrderModel extends ChangeNotifier {
  List<Order> _orders = [];

  List<Order> get orders => List.unmodifiable(_orders);

  int get count => _orders.length;

  void addOrder(Order order) {
    _orders.insert(0, order); // newest first
    notifyListeners();
  }
  // order status
  void updateOrderStatus(String orderId, String newStatus) {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index != -1) {
      final updatedOrder = Order(
        id: _orders[index].id,
        date: _orders[index].date,
        items: _orders[index].items,
        total: _orders[index].total,
        status: newStatus,
        payment: _orders[index].payment,
        tracking: _orders[index].tracking,
        image: _orders[index].image,
        orderItems: _orders[index].orderItems,
      );
      _orders[index] = updatedOrder;
      notifyListeners();
    }
  }

  void clearAll() {
    _orders.clear();
    notifyListeners();
  }
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
}

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
}