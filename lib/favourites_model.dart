// favourites_model.dart
import 'package:flutter/material.dart';
import 'models.dart';

/// Manages the user's favourite products
class FavouritesModel extends ChangeNotifier {
  final List<Product> _items = [];

  List<Product> get items => List.unmodifiable(_items);

  bool get isEmpty => _items.isEmpty;

  int get count => _items.length;

  /// Toggle a product in favourites
  void toggleFavourite(Product product) {
    final index = _items.indexWhere((item) => item.id == product.id);
    if (index >= 0) {
      _items.removeAt(index);
    } else {
      _items.add(product);
    }
    notifyListeners();
    _saveToLocal();
  }

  /// Check if a product is in favourites
  bool isFavourite(String id) {
    return _items.any((item) => item.id == id);
  }

  /// Get a product from favourites by ID
  Product? getProduct(String id) {
    try {
      return _items.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Remove a product from favourites
  void removeFavourite(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
    _saveToLocal();
  }

  /// Clear all favourites
  void clearAll() {
    _items.clear();
    notifyListeners();
    _saveToLocal();
  }

  // Local storage for offline support (future)
  void _saveToLocal() {
    // TODO: Save to SharedPreferences/Hive when implemented
  }

  // Future: Load from local storage
  void _loadFromLocal() {
    // TODO: Load from SharedPreferences/Hive when implemented
  }
}

/// App-wide access point: `FavouritesScope.of(context)`
class FavouritesScope extends InheritedNotifier<FavouritesModel> {
  const FavouritesScope({
    super.key,
    required FavouritesModel favourites,
    required super.child,
  }) : super(notifier: favourites);

  static FavouritesModel of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<FavouritesScope>();
    assert(scope != null, 'No FavouritesScope found in the widget tree');
    return scope!.notifier!;
  }
}