import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../models/shop_model.dart';
import '../config/payment_config.dart';
import '../utils/delivery_calculator.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;

  int get totalItemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalWeight =>
      _items.fold(0.0, (sum, item) => sum + item.weightKg);

  double get subtotal =>
      _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  List<ShopModel> get shops {
    final seen = <String>{};
    return _items
        .where((item) => seen.add(item.shop.id))
        .map((item) => item.shop)
        .toList();
  }

  bool get meetsMinimumOrder => subtotal >= PaymentConfig.minimumOrderValue;

  String? addItem(ProductModel product, ShopModel shop,
      {int quantity = 1}) {
    if (totalItemCount + quantity > PaymentConfig.maxItemsPerOrder) {
      return 'Maximum ${PaymentConfig.maxItemsPerOrder} items allowed per order';
    }

    final existingIdx = _items.indexWhere(
        (item) => item.product.id == product.id);

    if (existingIdx == -1) {
      _items.add(CartItem(
        product: product,
        shop: shop,
        quantity: quantity,
      ));
    } else {
      _items[existingIdx].quantity += quantity;
    }

    notifyListeners();
    return null;
  }

  void removeItem(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    final idx = _items.indexWhere((item) => item.product.id == productId);
    if (idx != -1) {
      if (quantity <= 0) {
        _items.removeAt(idx);
      } else {
        _items[idx].quantity = quantity;
      }
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  double calculateDeliveryCharges(double distanceKm) {
    return DeliveryCalculator.calculateDeliveryCharges(distanceKm, subtotal);
  }

  int getItemQuantity(String productId) {
    try {
      return _items
          .firstWhere((item) => item.product.id == productId)
          .quantity;
    } catch (_) {
      return 0;
    }
  }
}
