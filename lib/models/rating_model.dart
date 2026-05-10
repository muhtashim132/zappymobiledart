class RatingModel {
  final String id;
  final String orderId;
  final String raterId;
  final String? rateeId;
  final String? shopId;
  final String raterRole;
  final String rateeRole;
  final int rating;
  final String? review;
  final DateTime createdAt;

  RatingModel({
    required this.id,
    required this.orderId,
    required this.raterId,
    this.rateeId,
    this.shopId,
    required this.raterRole,
    required this.rateeRole,
    required this.rating,
    this.review,
    required this.createdAt,
  });

  factory RatingModel.fromMap(Map<String, dynamic> map) {
    return RatingModel(
      id: map['id'],
      orderId: map['order_id'],
      raterId: map['rater_id'],
      rateeId: map['ratee_id'],
      shopId: map['shop_id'],
      raterRole: map['rater_role'],
      rateeRole: map['ratee_role'],
      rating: map['rating'] is int ? map['rating'] : int.parse(map['rating'].toString()),
      review: map['review'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'rater_id': raterId,
      'ratee_id': rateeId,
      'shop_id': shopId,
      'rater_role': raterRole,
      'ratee_role': rateeRole,
      'rating': rating,
      'review': review,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
