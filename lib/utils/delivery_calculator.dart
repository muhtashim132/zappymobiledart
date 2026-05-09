class DeliveryCalculator {
  static double calculateDeliveryCharges(double distance, double orderValue) {
    if (orderValue >= 499) return 0;
    if (distance <= 3) return 20;
    if (distance <= 5) return 25;
    if (distance <= 10) return 35;
    if (distance <= 15) return 49;
    return -1; // Out of range
  }

  static double calculateMultiShopSurcharge(List<double> interShopDistances) {
    double total = 0;
    for (double d in interShopDistances) {
      total += d.ceil() * 10;
    }
    return total;
  }

  static int estimatedDeliveryTime(double distance, int prepTimeMinutes) {
    const deliverySpeed = 25.0;
    final travelMins = (distance / deliverySpeed * 60).ceil();
    return prepTimeMinutes + travelMins;
  }
}
