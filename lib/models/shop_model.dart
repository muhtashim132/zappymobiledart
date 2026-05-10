import 'package:latlong2/latlong.dart';

class ShopModel {
  final String id;
  final String sellerId;
  final String name;
  final String shopType;
  final String? cuisineType;
  final String? fssaiNumber;
  final int prepTimeMinutes;
  final bool isVegOnly;
  final String? openingHours;
  final String address;
  final LatLng location;
  final String category;
  final List<String> categories;
  final bool isActive;
  final double rating;
  final int totalReviews;
  final int totalOrders;
  final String? bannerImage;
  double? distanceKm;

  ShopModel({
    required this.id,
    required this.sellerId,
    required this.name,
    required this.shopType,
    this.cuisineType,
    this.fssaiNumber,
    this.prepTimeMinutes = 30,
    this.isVegOnly = false,
    this.openingHours,
    required this.address,
    required this.location,
    required this.category,
    required this.categories,
    required this.isActive,
    this.rating = 4.0,
    this.totalReviews = 0,
    this.totalOrders = 0,
    this.bannerImage,
    this.distanceKm,
  });

  factory ShopModel.fromMap(Map<String, dynamic> map) {
    double lat = 0.0, lng = 0.0;
    if (map['location'] != null) {
      try {
        final loc = map['location'].toString();
        final coords = loc
            .replaceAll('POINT(', '')
            .replaceAll(')', '')
            .split(' ');
        lng = double.tryParse(coords[0]) ?? 0.0;
        lat = double.tryParse(coords[1]) ?? 0.0;
      } catch (_) {}
    }

    return ShopModel(
      id: map['id'] ?? '',
      sellerId: map['seller_id'] ?? '',
      name: map['name'] ?? '',
      shopType: map['shop_type'] ?? 'shop',
      cuisineType: map['cuisine_type'],
      fssaiNumber: map['fssai_number'],
      prepTimeMinutes: map['prep_time_minutes'] ?? 30,
      isVegOnly: map['is_veg_only'] ?? false,
      openingHours: map['opening_hours'],
      address: map['address'] ?? '',
      location: LatLng(lat, lng),
      category: map['category'] ??
          (map['categories'] != null && (map['categories'] as List).isNotEmpty
              ? map['categories'][0]
              : 'Other'),
      categories: List<String>.from(map['categories'] ?? []),
      isActive: map['is_active'] ?? true,
      rating: (map['rating'] ?? 4.0).toDouble(),
      totalReviews: map['total_reviews'] ?? 0,
      totalOrders: map['total_orders'] ?? 0,
      bannerImage: map['banner_image'],
    );
  }
}
