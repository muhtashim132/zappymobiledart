class OrderModel {
  final String id;
  final String customerId;
  String status;
  final double totalAmount;
  final double deliveryCharges;
  final double riderEarnings;
  final double multiShopSurcharge;
  final double platformFee;
  final DateTime createdAt;
  List<OrderItem> items;
  String? deliveryPartnerId;
  final String? address;
  final String? deliveryNotes;
  // Dual-acceptance flags (stored in DB columns)
  bool sellerAccepted;
  bool partnerAccepted;

  // Wait-time compensation fields
  DateTime? arrivedAtShopTime;
  DateTime? orderReadyTime;
  double waitTimePenalty;
  bool waitTimeDisputed;

  OrderModel({
    required this.id,
    required this.customerId,
    required this.status,
    required this.totalAmount,
    required this.deliveryCharges,
    this.riderEarnings = 0.0,
    this.multiShopSurcharge = 0,
    this.platformFee = 0,
    required this.createdAt,
    this.items = const [],
    this.deliveryPartnerId,
    this.address,
    this.deliveryNotes,
    this.sellerAccepted = false,
    this.partnerAccepted = false,
    this.arrivedAtShopTime,
    this.orderReadyTime,
    this.waitTimePenalty = 0.0,
    this.waitTimeDisputed = false,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] ?? '',
      customerId: map['customer_id'] ?? '',
      status: map['status'] ?? 'pending',
      totalAmount: (map['total_amount'] ?? 0.0).toDouble(),
      deliveryCharges: (map['delivery_charges'] ?? 0.0).toDouble(),
      riderEarnings: (map['rider_earnings'] ?? (map['delivery_charges'] ?? 0.0)).toDouble(), // Fallback for legacy orders
      multiShopSurcharge: (map['multi_shop_surcharge'] ?? 0.0).toDouble(),
      platformFee: (map['platform_fee'] ?? 0.0).toDouble(),
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      deliveryPartnerId: map['delivery_partner_id'],
      address: map['address'],
      deliveryNotes: map['delivery_notes'],
      sellerAccepted: map['seller_accepted'] ?? false,
      partnerAccepted: map['partner_accepted'] ?? false,
      arrivedAtShopTime: map['arrived_at_shop_time'] != null
          ? DateTime.tryParse(map['arrived_at_shop_time'])
          : null,
      orderReadyTime: map['order_ready_time'] != null
          ? DateTime.tryParse(map['order_ready_time'])
          : null,
      waitTimePenalty: (map['wait_time_penalty'] ?? 0.0).toDouble(),
      waitTimeDisputed: map['wait_time_disputed'] ?? false,
    );
  }

  /// True when both the seller and delivery partner have accepted.
  bool get isFullyConfirmed => sellerAccepted && partnerAccepted;

  String get statusDisplay {
    switch (status) {
      case 'pending':
        if (sellerAccepted && !partnerAccepted) return 'Awaiting Rider';
        if (!sellerAccepted && partnerAccepted) return 'Awaiting Shop';
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'preparing':
        return 'Preparing';
      case 'ready_for_pickup':
        return 'Ready for Pickup';
      case 'picked_up':
        return 'Picked Up';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      case 'seller_rejected':
        return 'Rejected by Shop';
      case 'partner_rejected':
        return 'Rejected by Rider';
      // Legacy statuses (backward compat)
      case 'seller_accepted':
        return 'Shop Accepted';
      case 'partner_assigned':
        return 'Rider Assigned';
      default:
        return status;
    }
  }

  double get grandTotal =>
      totalAmount + deliveryCharges + multiShopSurcharge + platformFee;
}

class OrderItem {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final double weightKg;
  final String? specialInstructions;

  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.weightKg,
    this.specialInstructions,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] ?? '',
      productId: map['product_id'] ?? '',
      productName: map['product_name'] ?? '',
      quantity: map['quantity'] ?? 1,
      price: (map['price'] ?? 0.0).toDouble(),
      weightKg: (map['weight_kg'] ?? 0.0).toDouble(),
      specialInstructions: map['special_instructions'],
    );
  }

  double get totalPrice => price * quantity;
}
