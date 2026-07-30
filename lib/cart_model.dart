import 'package:flutter/material.dart';

/// A single line in the cart. Kept intentionally decoupled from
/// FlashSaleProduct / NewArrivalProduct / ForYouProduct / Product so any
/// product card anywhere in the app can add to cart without needing a
/// shared product interface.
class CartItem {
  final String name;
  final String imageUrl;
  final int price;
  int quantity;

  CartItem({
    required this.name,
    required this.imageUrl,
    required this.price,
    this.quantity = 1,
  });

  int get lineTotal => price * quantity;
}

/// Holds the cart contents and notifies listeners (bottom nav badge,
/// cart page, etc.) whenever it changes. Swap this out for
/// Provider/Riverpod/Bloc later without touching the widgets that call
/// CartScope.of(context) — only this file and main.dart would change.
class CartModel extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  bool get isEmpty => _items.isEmpty;

  int get totalItemCount =>
      _items.fold(0, (sum, item) => sum + item.quantity);

  int get subtotal => _items.fold(0, (sum, item) => sum + item.lineTotal);

  /// Adds one unit of a product. If it's already in the cart, bumps the
  /// quantity instead of creating a duplicate line.
  void addItem({
    required String name,
    required String imageUrl,
    required int price,
  }) {
    final index = _items.indexWhere((i) => i.name == name);
    if (index >= 0) {
      _items[index].quantity += 1;
    } else {
      _items.add(CartItem(name: name, imageUrl: imageUrl, price: price));
    }
    notifyListeners();
  }

  void incrementQuantity(String name) {
    final index = _items.indexWhere((i) => i.name == name);
    if (index >= 0) {
      _items[index].quantity += 1;
      notifyListeners();
    }
  }

  /// Decrements quantity; removes the line entirely once it hits zero.
  void decrementQuantity(String name) {
    final index = _items.indexWhere((i) => i.name == name);
    if (index < 0) return;
    if (_items[index].quantity > 1) {
      _items[index].quantity -= 1;
    } else {
      _items.removeAt(index);
    }
    notifyListeners();
  }

  void removeItem(String name) {
    _items.removeWhere((i) => i.name == name);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}

/// App-wide access point: `CartScope.of(context)` from any widget below
/// the CartScope in main.dart. Rebuilds dependents automatically whenever
/// the cart calls notifyListeners() (InheritedNotifier wires that up).
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
