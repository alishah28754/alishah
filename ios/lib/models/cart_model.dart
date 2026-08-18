// cart_model.dart
import 'package:flutter/material.dart';
import 'package:ktex_home/models/models.dart';  // ← ADD THIS IMPORT

/// A single line in the cart. Uses ID for unique identification.
class CartItem {
  final String id;
  final String name;
  final String imageUrl;
  final int price;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    this.quantity = 1,
  });

  int get lineTotal => price * quantity;

  /// Create a copy with updated fields
  CartItem copyWith({int? quantity}) {
    return CartItem(
      id: id,
      name: name,
      imageUrl: imageUrl,
      price: price,
      quantity: quantity ?? this.quantity,
    );
  }

  /// For future API integration
  Map<String, dynamic> toJson() {
    return {
      'product_id': id,
      'name': name,
      'image_url': imageUrl,
      'price': price,
      'quantity': quantity,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['product_id']?.toString() ?? '',
      name: json['name'] ?? '',
      imageUrl: json['image_url'] ?? '',
      price: json['price'] ?? 0,
      quantity: json['quantity'] ?? 1,
    );
  }
}

/// Holds the cart contents and notifies listeners.
class CartModel extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  bool get isEmpty => _items.isEmpty;

  int get totalItemCount =>
      _items.fold(0, (sum, item) => sum + item.quantity);

  int get subtotal => _items.fold(0, (sum, item) => sum + item.lineTotal);

  /// Adds one unit of a product using ID for uniqueness
  void addItem({
    required String id,
    required String name,
    required String imageUrl,
    required int price,
  }) {
    final index = _items.indexWhere((i) => i.id == id);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(
        quantity: _items[index].quantity + 1,
      );
    } else {
      _items.add(CartItem(
        id: id,
        name: name,
        imageUrl: imageUrl,
        price: price,
      ));
    }
    notifyListeners();
    _saveToLocal();
  }

  /// Add a product directly from a Product model
  void addProduct(Product product) {
    addItem(
      id: product.id,
      name: product.name,
      imageUrl: product.imageUrl,
      price: product.price,
    );
  }

  void incrementQuantity(String id) {
    final index = _items.indexWhere((i) => i.id == id);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(
        quantity: _items[index].quantity + 1,
      );
      notifyListeners();
      _saveToLocal();
    }
  }

  /// Decrements quantity; removes the line entirely once it hits zero.
  void decrementQuantity(String id) {
    final index = _items.indexWhere((i) => i.id == id);
    if (index < 0) return;
    if (_items[index].quantity > 1) {
      _items[index] = _items[index].copyWith(
        quantity: _items[index].quantity - 1,
      );
    } else {
      _items.removeAt(index);
    }
    notifyListeners();
    _saveToLocal();
  }

  void removeItem(String id) {
    _items.removeWhere((i) => i.id == id);
    notifyListeners();
    _saveToLocal();
  }

  void clear() {
    _items.clear();
    notifyListeners();
    _saveToLocal();
  }

  /// Returns the quantity of a specific product in cart
  int getQuantity(String id) {
    final index = _items.indexWhere((i) => i.id == id);
    return index >= 0 ? _items[index].quantity : 0;
  }

  /// Check if a product is in cart
  bool isInCart(String id) {
    return _items.any((i) => i.id == id);
  }

  // Local storage for offline support (future)
  void _saveToLocal() {
    // TODO: Save to SharedPreferences/Hive when implemented
    // For now, just a placeholder
  }

  // Future: Load from local storage
  void _loadFromLocal() {
    // TODO: Load from SharedPreferences/Hive when implemented
  }
}

/// App-wide access point: `CartScope.of(context)`
class CartScope extends InheritedNotifier<CartModel> {
  const CartScope({
    super.key,
    required CartModel cart,
    required super.child,
  }) : super(notifier: cart);

  static CartModel of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<CartScope>();
    assert(scope != null, 'No CartScope found in the widget tree');
    return scope!.notifier!;
  }
}