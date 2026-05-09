import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';

class EarningsPage extends StatefulWidget {
  const EarningsPage({super.key});

  @override
  State<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  double _todayEarnings = 0;
  double _weekEarnings = 0;
  double _totalEarnings = 0;
  int _totalDeliveries = 0;
  late TabController _tabController;
  List<Map<String, dynamic>> _recentDeliveries = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEarnings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEarnings() async {
    final auth = context.read<AuthProvider>();
    try {
      final now = DateTime.now();
      final todayStart =
          DateTime(now.year, now.month, now.day).toIso8601String();
      final weekStart =
          DateTime(now.year, now.month, now.day - 7).toIso8601String();

      final allDeliveries = await _supabase
          .from('orders')
          .select()
          .eq('delivery_partner_id', auth.currentUserId ?? '')
          .eq('status', 'delivered')
          .order('created_at', ascending: false);

      final deliveries = allDeliveries as List;
      double today = 0, week = 0, total = 0;

      for (final d in deliveries) {
        final charge = (d['delivery_charges'] ?? 0.0).toDouble();
        final createdAt =
            DateTime.tryParse(d['created_at'] ?? '') ?? DateTime(2000);
        total += charge;
        if (createdAt.isAfter(DateTime.parse(weekStart))) week += charge;
        if (createdAt.isAfter(DateTime.parse(todayStart))) today += charge;
      }

      if (mounted) {
        setState(() {
          _todayEarnings = today;
          _weekEarnings = week;
          _totalEarnings = total;
          _totalDeliveries = deliveries.length;
          _recentDeliveries = deliveries.take(20).map((d) {
            return {
              'id': d['id'],
              'amount': (d['delivery_charges'] ?? 0.0).toDouble(),
              'date': d['created_at'],
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFE),
      appBar: AppBar(
        title: Text('Earnings',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: _loadEarnings,
              icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEarnings,
              child: CustomScrollView(
                slivers: [
                  // ── Hero Earnings Card ─────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, Color(0xFF071D6B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              'TOTAL EARNINGS',
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₹${_totalEarnings.toStringAsFixed(0)}',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatItem(
                                      'Today', '₹${_todayEarnings.toInt()}'),
                                  Container(
                                      width: 1,
                                      height: 30,
                                      color: Colors.white24),
                                  _buildStatItem('Orders', '$_totalDeliveries'),
                                  Container(
                                      width: 1,
                                      height: 30,
                                      color: Colors.white24),
                                  _buildStatItem('Rating', '4.9 ⭐'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Withdrawal Section ─────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildQuickAction(
                              icon: Icons.account_balance_wallet_rounded,
                              label: 'Withdraw',
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildQuickAction(
                              icon: Icons.analytics_rounded,
                              label: 'Insights',
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 32)),

                  // ── Recent Activity ────────────────────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Activity',
                            style: GoogleFonts.outfit(
                                fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'View all',
                            style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  _recentDeliveries.isEmpty
                      ? const SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: Text('No recent deliveries found.'),
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = _recentDeliveries[index];
                              final date =
                                  DateTime.tryParse(item['date'] ?? '') ??
                                      DateTime.now();
                              return Container(
                                margin:
                                    const EdgeInsets.fromLTRB(20, 0, 20, 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.02),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4)),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color:
                                            AppColors.primary.withOpacity(0.05),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                          Icons.delivery_dining_rounded,
                                          color: AppColors.primary),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Order #${item['id'].toString().substring(0, 8)}',
                                            style: GoogleFonts.outfit(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15),
                                          ),
                                          Text(
                                            DateFormat('MMM dd, hh:mm a')
                                                .format(date),
                                            style: GoogleFonts.outfit(
                                                color: AppColors.textSecondary,
                                                fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '+₹${item['amount'].toStringAsFixed(0)}',
                                      style: GoogleFonts.outfit(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            childCount: _recentDeliveries.length,
                          ),
                        ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(label,
            style: GoogleFonts.outfit(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildQuickAction(
      {required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(label,
              style: GoogleFonts.outfit(
                  color: color, fontWeight: FontWeight.w700, fontSize: 14)),
        ],
      ),
    );
  }
}
