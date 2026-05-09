class OrderModel {
  final String id;
  final String customerId;
  String status;
  final double totalAmount;
  final double deliveryCharges;
  final double multiShopSurcharge;
  final DateTime createdAt;
  List<OrderItem> items;
  String? deliveryPartnerId;
  final String? address;
  final String? deliveryNotes;

  OrderModel({
    required this.id,
    required this.customerId,
    required this.status,
    required this.totalAmount,
    required this.deliveryCharges,
    this.multiShopSurcharge = 0,
    required this.createdAt,
    this.items = const [],
    this.deliveryPartnerId,
    this.address,
    this.deliveryNotes,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] ?? '',
      customerId: map['customer_id'] ?? '',
      status: map['status'] ?? 'pending',
      totalAmount: (map['total_amount'] ?? 0.0).toDouble(),
      deliveryCharges: (map['delivery_charges'] ?? 0.0).toDouble(),
      multiShopSurcharge: (map['multi_shop_surcharge'] ?? 0.0).toDouble(),
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      deliveryPartnerId: map['delivery_partner_id'],
      address: map['address'],
      deliveryNotes: map['delivery_notes'],
    );
  }

  String get statusDisplay {
    switch (status) {
      case 'pending': return 'Pending';
      case 'seller_accepted': return 'Accepted';
      case 'partner_assigned': return 'Delivery Assigned';
      case 'picked_up': return 'Picked Up';
      case 'out_for_delivery': return 'Out for Delivery';
      case 'delivered': return 'Delivered';
      case 'cancelled': return 'Cancelled';
      case 'seller_rejected': return 'Rejected';
      default: return status;
    }
  }

  double get grandTotal => totalAmount + deliveryCharges + multiShopSurcharge;
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
