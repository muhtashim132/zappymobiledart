import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../../config/routes.dart';
import '../../models/shop_model.dart';
import '../../widgets/restaurant_card.dart';

class FoodHomePage extends StatefulWidget {
  const FoodHomePage({super.key});

  @override
  State<FoodHomePage> createState() => _FoodHomePageState();
}

class _FoodHomePageState extends State<FoodHomePage> {
  final _supabase = Supabase.instance.client;
  List<ShopModel> _restaurants = [];
  bool _isLoading = true;
  bool _vegOnly = false;
  int _selectedCategory = 0;

  final List<Map<String, String>> _foodCategories = [
    {'name': 'All', 'emoji': '🍽️'},
    {'name': 'Biryani', 'emoji': '🍛'},
    {'name': 'Pizza', 'emoji': '🍕'},
    {'name': 'Burger', 'emoji': '🍔'},
    {'name': 'Chinese', 'emoji': '🥡'},
    {'name': 'South Indian', 'emoji': '🫓'},
    {'name': 'Rolls', 'emoji': '🌯'},
    {'name': 'Desserts', 'emoji': '🍨'},
    {'name': 'Beverages', 'emoji': '🥤'},
  ];

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    setState(() => _isLoading = true);
    try {
      var query = _supabase
          .from('shops')
          .select()
          .eq('shop_type', 'restaurant')
          .eq('is_active', true);

      if (_vegOnly) {
        query = query.eq('is_veg_only', true);
      }

      final response = await query;
      setState(() {
        _restaurants =
            (response as List).map((s) => ShopModel.fromMap(s)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.foodRed,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                    gradient: AppColors.foodGradient),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🍔 Food Delivery',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Order from restaurants near you',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const TextField(
                            decoration: InputDecoration(
                              hintText:
                                  'Search restaurants or dishes...',
                              hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary),
                              prefixIcon:
                                  Icon(Icons.search, size: 20),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFoodCategoryTabs(),
                _buildVegFilter(),
                if (_isLoading)
                  _buildShimmerList()
                else ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      '🔥 ${_restaurants.isEmpty ? "No restaurants" : "${_restaurants.length} Restaurants"} Near You',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  _buildRestaurantList(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodCategoryTabs() {
    return SizedBox(
      height: 88,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _foodCategories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategory == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.foodRed.withOpacity(0.1)
                          : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.foodRed
                            : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _foodCategories[index]['emoji']!,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _foodCategories[index]['name']!,
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'Poppins',
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? AppColors.foodRed
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVegFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const Text(
            'Filter: ',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                fontSize: 13),
          ),
          GestureDetector(
            onTap: () {
              setState(() => _vegOnly = !_vegOnly);
              _loadRestaurants();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _vegOnly
                    ? AppColors.vegGreen.withOpacity(0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _vegOnly ? AppColors.vegGreen : AppColors.divider,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: AppColors.vegGreen, width: 2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: _vegOnly
                        ? const Center(
                            child: Icon(Icons.circle,
                                size: 7, color: AppColors.vegGreen),
                          )
                        : null,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Pure Veg',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantList() {
    if (_restaurants.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            children: [
              Text('🍽️', style: TextStyle(fontSize: 56)),
              SizedBox(height: 16),
              Text(
                'No restaurants in your area',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontFamily: 'Poppins',
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _restaurants.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: RestaurantCard(
          restaurant: _restaurants[index],
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.restaurant,
            arguments: {'shopId': _restaurants[index].id},
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(
            3,
            (_) => Container(
              margin: const EdgeInsets.only(bottom: 16),
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
