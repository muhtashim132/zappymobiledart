import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_colors.dart';
import '../../config/routes.dart';

class SellerDashboardPage extends StatefulWidget {
  const SellerDashboardPage({super.key});

  @override
  State<SellerDashboardPage> createState() => _SellerDashboardPageState();
}

class _SellerDashboardPageState extends State<SellerDashboardPage> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic> _stats = {
    'total_orders': 0,
    'pending_orders': 0,
    'revenue': 0.0,
    'products': 0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final auth = context.read<AuthProvider>();
    try {
      final shopsResp = await _supabase
          .from('shops')
          .select('id')
          .eq('seller_id', auth.currentUserId ?? '');

      if ((shopsResp as List).isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final shopId = shopsResp.first['id'];

      final ordersResp = await _supabase
          .from('orders')
          .select()
          .not('status', 'in', '("cancelled","seller_rejected")');

      final productsResp = await _supabase
          .from('products')
          .select('id')
          .eq('shop_id', shopId);

      final pending = (ordersResp as List)
          .where((o) => o['status'] == 'pending')
          .length;

      final revenue = (ordersResp)
          .fold<double>(0, (sum, o) => sum + (o['total_amount'] ?? 0.0));

      if (mounted) {
        setState(() {
          _stats = {
            'total_orders': ordersResp.length,
            'pending_orders': pending,
            'revenue': revenue,
            'products': (productsResp as List).length,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── Premium Modern Header ─────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.primary,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, Color(0xFF071D6B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.white.withOpacity(0.1),
                              child: Text(
                                auth.user?.initials ?? 'S',
                                style: GoogleFonts.outfit(
                                  color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hi, ${auth.user?.fullName.split(' ').first ?? 'Seller'}! 👋',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  // ── Role Badge ──────────────────────────
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF4C542).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFFF4C542).withOpacity(0.5)),
                                    ),
                                    child: Text(
                                      auth.user?.roleDisplay ?? 'Seller',
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFFF4C542), fontSize: 11, fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                isDark ? Icons.light_mode : Icons.dark_mode,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                themeProvider.toggleTheme();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.settings_outlined, color: Colors.white),
                              onPressed: () {
                                Navigator.pushNamed(context, AppRoutes.settings);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.logout_rounded, color: Colors.white),
                              onPressed: () async {
                                await auth.signOut();
                                if (mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.roleSelect, (_) => false);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // ── Zero Commission Banner (Sellers only) ─────────
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.15)),
                          ),
                          child: Row(children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF51CF66), shape: BoxShape.circle)),
                            const SizedBox(width: 10),
                            Text(
                              '🎉  ZERO COMMISSION  ·  Keep 100% of your sales',
                              style: GoogleFonts.outfit(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.4,
                              ),
                            ),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),


          // ── Stats Section ──────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.3,
                      children: [
                        _buildStatCard('Revenue', '₹${(_stats['revenue'] as double).toStringAsFixed(0)}', Icons.currency_rupee_rounded, Colors.green),
                        _buildStatCard('Pending', '${_stats['pending_orders']}', Icons.pending_actions_rounded, Colors.orange),
                        _buildStatCard('Orders', '${_stats['total_orders']}', Icons.receipt_long_rounded, Colors.blue),
                        _buildStatCard('Products', '${_stats['products']}', Icons.inventory_2_rounded, Colors.purple),
                      ],
                    ),
            ),
          ),

          // ── Quick Actions ──────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),
                Text(
                  'Quick Actions',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                _buildActionTile(
                  icon: Icons.add_box_rounded,
                  color: AppColors.primary,
                  title: 'Add New Product',
                  subtitle: 'List items in your catalog',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.addProduct),
                ),
                _buildActionTile(
                  icon: Icons.inventory_2_rounded,
                  color: Colors.purple,
                  title: 'Manage Inventory',
                  subtitle: 'Update stock and prices',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.manageProducts),
                ),
                _buildActionTile(
                  icon: Icons.receipt_long_rounded,
                  color: Colors.orange,
                  title: 'Order Status',
                  subtitle: 'Accept or process orders',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.sellerOrders),
                ),
                _buildActionTile(
                  icon: Icons.insights_rounded,
                  color: Colors.green,
                  title: 'Store Analytics',
                  subtitle: 'Sales and customer trends',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.analytics),
                ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.03), 
            blurRadius: 15, 
            offset: const Offset(0, 5)
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: Theme.of(context).textTheme.bodyLarge?.color)),
              Text(title, style: GoogleFonts.outfit(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({required IconData icon, required Color color, required String title, required String subtitle, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.02), 
              blurRadius: 10, 
              offset: const Offset(0, 4)
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
                  Text(subtitle, style: GoogleFonts.outfit(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: isDark ? Colors.grey.shade500 : Colors.grey),
          ],
        ),
      ),
    );
  }
}
