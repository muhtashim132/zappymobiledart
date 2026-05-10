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

  /// Unique shops in the order they were first added to the cart.
  List<ShopModel> get shops {
    final seen = <String>{};
    return _items
        .where((item) => seen.add(item.shop.id))
        .map((item) => item.shop)
        .toList();
  }

  bool get meetsMinimumOrder => subtotal >= PaymentConfig.minimumOrderValue;

  double get platformFee => PaymentConfig.platformFee;

  double get smallCartFee =>
      subtotal < PaymentConfig.smallCartThreshold && subtotal > 0
          ? PaymentConfig.smallCartFee
          : 0.0;

  double calculateDeliveryDiscount(double distanceKm) {
    if (subtotal >= PaymentConfig.discountDeliveryThreshold && distanceKm <= 5.0) {
      return PaymentConfig.deliveryDiscountAmount;
    }
    return 0.0;
  }

  double get heavyOrderFee =>
      totalWeight > PaymentConfig.heavyOrderThreshold
          ? PaymentConfig.heavyOrderFee
          : 0.0;

  /// True when items come from more than one shop.
  bool get isMultiShopOrder => shops.length > 1;

  String? addItem(ProductModel product, ShopModel shop,
      {int quantity = 1}) {
    if (totalItemCount + quantity > PaymentConfig.maxItemsPerOrder) {
      return 'Maximum ${PaymentConfig.maxItemsPerOrder} items allowed per order';
    }

    final tempItem = CartItem(product: product, shop: shop, quantity: quantity);
    if (totalWeight + tempItem.weightKg > PaymentConfig.maxWeightKg) {
      return 'Maximum weight of ${PaymentConfig.maxWeightKg} kg allowed per order';
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

  // ---------------------------------------------------------------------------
  // Delivery charge helpers
  // ---------------------------------------------------------------------------

  /// Base delivery charge based on customer-to-shop distance and order value.
  double calculateDeliveryCharges(double distanceKm) {
    return DeliveryCalculator.calculateDeliveryCharges(distanceKm, subtotal);
  }

  /// Extra surcharge for ordering from multiple shops.
  ///
  /// Rules:
  ///   • 1 shop  → ₹0 surcharge
  ///   • 2nd shop → ₹10 × max(1, ceil(distance from 1st shop))
  ///   • 3rd+ shops → ₹10 × max(1, ceil(distance from nearest already-visited shop))
  double get multiShopSurcharge =>
      DeliveryCalculator.calculateMultiShopSurcharge(shops);

  /// Combined total including base delivery + inter-shop surcharge + small cart fee - discount.
  double totalDeliveryCharges(double baseDistanceKm) {
    final base = calculateDeliveryCharges(baseDistanceKm);
    final surcharge = multiShopSurcharge;
    // If base is -1 (out of range) keep it as-is
    if (base < 0) return base;
    return base + surcharge + heavyOrderFee + smallCartFee - calculateDeliveryDiscount(baseDistanceKm);
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
