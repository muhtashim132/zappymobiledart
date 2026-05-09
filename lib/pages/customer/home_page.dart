import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_colors.dart';
import '../../config/routes.dart';
import '../../models/product_model.dart';
import '../../models/shop_model.dart';
import '../../widgets/product_card.dart';
import '../../widgets/shop_card.dart';
import '../../widgets/common/zappy_map.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;
  int _selectedTabIndex = 0;
  int _navIndex = 0;
  bool _isLoading = true;
  List<ShopModel> _shops = [];
  List<ProductModel> _products = [];
  String _searchQuery = '';
  final _searchController = TextEditingController();

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Food', 'emoji': '🍔', 'type': 'restaurant', 'color': const Color(0xFFFFF1F1)},
    {'name': 'Grocery', 'emoji': '🛒', 'type': 'grocery', 'color': const Color(0xFFF1FFF1)},
    {'name': 'Pharmacy', 'emoji': '💊', 'type': 'pharmacy', 'color': const Color(0xFFF1F7FF)},
    {'name': 'Clothing', 'emoji': '👕', 'type': 'clothing', 'color': const Color(0xFFFFF9F1)},
    {'name': 'Electronics', 'emoji': '📱', 'type': 'electronics', 'color': const Color(0xFFF9F1FF)},
    {'name': 'More', 'emoji': '🛍️', 'type': 'other', 'color': const Color(0xFFF1FFF9)},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedTabIndex = _tabController.index);
        _loadData(_categories[_tabController.index]['name']!);
      }
    });
    _checkLocationAndLoad();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkLocationAndLoad() async {
    final locationProvider = context.read<LocationProvider>();
    if (!locationProvider.hasLocation) {
      await locationProvider.requestLocation();
    }
    _loadData(_categories[_selectedTabIndex]['name']!);
  }

  Future<void> _loadData(String category) async {
    setState(() => _isLoading = true);
    try {
      final shopsResponse = await _supabase
          .from('shops')
          .select()
          .eq('is_active', true)
          .contains('categories', [category]);

      final productsResponse = await _supabase
          .from('products')
          .select()
          .eq('is_available', true)
          .eq('category', category)
          .limit(20);

      if (mounted) {
        setState(() {
          _shops = (shopsResponse as List).map((s) => ShopModel.fromMap(s)).toList();
          _products = (productsResponse as List).map((p) => ProductModel.fromMap(p)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();
    final cartProvider = context.watch<CartProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── Premium Modern AppBar ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 140,
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding: const EdgeInsets.fromLTRB(16, 50, 16, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _showLocationSheet(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'DELIVERING TO',
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textSecondary,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.primary),
                                  ],
                                ),
                                Text(
                                  locationProvider.hasLocation
                                      ? locationProvider.currentAddress.isNotEmpty
                                          ? locationProvider.currentAddress
                                          : 'Current Location'
                                      : 'Set location...',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                        _buildCircleAction(
                          icon: Icons.notifications_none_outlined,
                          isDark: isDark,
                          onTap: () {},
                        ),
                        const SizedBox(width: 8),
                        _buildCircleAction(
                          icon: isDark ? Icons.light_mode : Icons.dark_mode,
                          isDark: isDark,
                          onTap: () => themeProvider.toggleTheme(),
                        ),
                        const SizedBox(width: 8),
                        _buildCircleAction(
                          icon: Icons.person_outline,
                          isDark: isDark,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Hero(
                  tag: 'search_bar',
                  child: Material(
                    color: Colors.transparent,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search "Milk", "Pizza" or "Medicines"',
                        hintStyle: GoogleFonts.outfit(color: isDark ? Colors.grey.shade500 : Colors.grey.shade400, fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                        filled: true,
                        fillColor: Theme.of(context).inputDecorationTheme.fillColor ?? Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Categories Horizontal List ──────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              height: 110,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedTabIndex == index;
                  return GestureDetector(
                    onTap: () {
                      _tabController.animateTo(index);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 80,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2A2A3A) : cat['color'],
                              shape: BoxShape.circle,
                              boxShadow: [
                                if (isSelected)
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                              ],
                            ),
                            child: Center(
                              child: Text(cat['emoji'], style: const TextStyle(fontSize: 26)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cat['name'],
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Main Content ──────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: !locationProvider.hasLocation
                ? SliverToBoxAdapter(child: _buildLocationRequired())
                : _isLoading
                    ? SliverToBoxAdapter(child: _buildShimmer())
                    : SliverList(
                        delegate: SliverChildListDelegate([
                          // Featured Banner
                          _buildFeaturedBanner(),
                          const SizedBox(height: 24),
                          
                          // Shops Section
                          if (_shops.isNotEmpty) ...[
                            _buildSectionTitle('Recommended for you'),
                            const SizedBox(height: 16),
                            ..._shops
                                .where((s) => _searchQuery.isEmpty || s.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                                .map((shop) => Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: ShopCard(
                                        shop: shop,
                                        onTap: () => Navigator.pushNamed(
                                          context,
                                          AppRoutes.restaurant,
                                          arguments: {'shopId': shop.id},
                                        ),
                                      ),
                                    )),
                          ],

                          // Products Section
                          if (_products.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _buildSectionTitle('Popular in your area'),
                            const SizedBox(height: 16),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.72,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                              ),
                              itemCount: _products.length,
                              itemBuilder: (context, index) => ProductCard(product: _products[index]),
                            ),
                          ],
                        ]),
                      ),
          ),
        ],
      ),
      
      // ── Floating Action Bar (Bottom Nav Replacement) ────────────────
      bottomNavigationBar: _buildFloatingBottomNav(cartProvider),
    );
  }

  Widget _buildCircleAction({required IconData icon, required bool isDark, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A3A) : Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isDark ? Colors.white : AppColors.textPrimary, size: 22),
      ),
    );
  }

  Widget _buildFeaturedBanner() {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(Icons.bolt, size: 180, color: Colors.white.withOpacity(0.1)),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'WELCOME',
                    style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.black),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Fast Delivery\nto your door!',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Supporting local sellers directly.',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          'See all',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingBottomNav(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Material(
        elevation: 20,
        shadowColor: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(30),
        color: AppColors.primaryDark,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Home'),
              _buildNavItem(1, Icons.shopping_cart_rounded, 'Cart', badge: cart.totalItemCount),
              _buildNavItem(2, Icons.receipt_long_rounded, 'Orders'),
              _buildNavItem(3, Icons.favorite_rounded, 'Favs'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, {int badge = 0}) {
    final isSelected = _navIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _navIndex = index);
        if (index == 1) Navigator.pushNamed(context, AppRoutes.cart);
        if (index == 2) Navigator.pushNamed(context, AppRoutes.orderHistory);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                if (badge > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                      child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            if (isSelected)
              Text(
                label,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRequired() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📍', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 20),
            Text(
              'Location Required',
              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              'We need your location to show nearby shops and ensure delivery is available.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => context.read<LocationProvider>().requestLocation(),
              icon: const Icon(Icons.my_location),
              label: const Text('Enable Location'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.white,
      child: Column(
        children: List.generate(3, (_) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        )),
      ),
    );
  }

  void _showLocationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text('Delivery Location', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                context.read<LocationProvider>().requestLocation();
                Navigator.pop(ctx);
              },
              icon: const Icon(Icons.my_location),
              label: const Text('Use Current Location'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
