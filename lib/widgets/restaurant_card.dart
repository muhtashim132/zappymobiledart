import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/shop_model.dart';
import '../theme/app_colors.dart';

class RestaurantCard extends StatelessWidget {
  final ShopModel restaurant;
  final VoidCallback onTap;

  const RestaurantCard(
      {super.key, required this.restaurant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: restaurant.bannerImage != null
                      ? CachedNetworkImage(
                          imageUrl: restaurant.bannerImage!,
                          width: double.infinity,
                          height: 160,
                          fit: BoxFit.cover,
                          errorWidget: (c, e, s) => _defaultBanner(),
                        )
                      : _defaultBanner(),
                ),
                // Offer badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '0% Commission',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                if (restaurant.isVegOnly)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.vegGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'PURE VEG',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  if (restaurant.cuisineType != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      restaurant.cuisineType!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Rating
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Text(
                              restaurant.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Icon(Icons.star,
                                color: Colors.white, size: 12),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${restaurant.totalOrders}+ orders',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.timer_outlined,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Text(
                        '${restaurant.prepTimeMinutes} mins',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      if (restaurant.distanceKm != null) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.location_on_outlined,
                            size: 13, color: AppColors.textSecondary),
                        Text(
                          '${restaurant.distanceKm!.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultBanner() {
    return Container(
      width: double.infinity,
      height: 160,
      decoration:
          const BoxDecoration(gradient: AppColors.foodGradient),
      child: const Center(
        child: Text('🍽️', style: TextStyle(fontSize: 72)),
      ),
    );
  }
}
