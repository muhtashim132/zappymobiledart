class PaymentConfig {
  static const double platformFee = 5.0;
  // platformCommission: 0.0 = no extra platform cut on order subtotal
  static const double platformCommission = 0.00;
  // Bug #22: removed dead `sellerPayout = 1.00` — it was never used and
  // was misleadingly named (unclear if it meant ₹1.00 or 100% payout fraction).

  static const double minimumOrderValue = 1.0; // Reduced to allow small carts
  static const double discountDeliveryThreshold = 499.0;
  static const double deliveryDiscountAmount = 15.0;
  static const double smallCartThreshold = 99.0;
  static const double smallCartFee = 15.0;
  static const double maxDeliveryRadiusKm = 9.0;
  static const int maxItemsPerOrder = 50;
  static const double maxWeightKg = 15.0; // Reduced to 15 kg
  static const double heavyOrderThreshold = 10.0;
  static const double heavyOrderFee = 20.0;
  static const int sellerResponseTimeoutSeconds = 300;
  static const int partnerResponseTimeoutSeconds = 600;
}
