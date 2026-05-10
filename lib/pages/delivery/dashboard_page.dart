import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/order_model.dart';
import '../../theme/app_colors.dart';
import '../../config/routes.dart';

class DeliveryDashboardPage extends StatefulWidget {
  const DeliveryDashboardPage({super.key});
  @override
  State<DeliveryDashboardPage> createState() => _DeliveryDashboardPageState();
}

class _DeliveryDashboardPageState extends State<DeliveryDashboardPage>
    with TickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  bool _isOnline = false;
  List<OrderModel> _availableOrders = [];
  List<OrderModel> _myOrders = [];
  bool _isLoading = false;

  late AnimationController _bgCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _bgAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(duration: const Duration(seconds: 5), vsync: this)
      ..repeat(reverse: true);
    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut);

    _pulseCtrl = AnimationController(duration: const Duration(milliseconds: 1400), vsync: this)
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _loadOrders();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    try {
      final available = await _supabase
          .from('orders')
          .select()
          .eq('seller_accepted', true)
          .isFilter('delivery_partner_id', null)
          .inFilter('status', ['pending', 'confirmed']);

      final myOrders = await _supabase
          .from('orders')
          .select()
          .eq('delivery_partner_id', auth.currentUserId ?? '')
          .not('status', 'in', '("delivered","cancelled","seller_rejected","partner_rejected")');

      setState(() {
        _availableOrders = (available as List).map((o) => OrderModel.fromMap(o)).toList();
        _myOrders = (myOrders as List).map((o) => OrderModel.fromMap(o)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptOrder(OrderModel order) async {
    final auth = context.read<AuthProvider>();
    try {
      final newStatus = order.sellerAccepted ? 'confirmed' : 'pending';
      await _supabase.from('orders').update({
        'delivery_partner_id': auth.currentUserId,
        'partner_accepted': true,
        'status': newStatus,
      }).eq('id', order.id);

      if (mounted) {
        final msg = order.sellerAccepted
            ? '✅ Order confirmed! Both shop & rider accepted.'
            : '✅ Saved. Waiting for shop to confirm.';
        _showSnack(msg);
      }
      _loadOrders();
    } catch (e) {
      debugPrint('Accept error: $e');
    }
  }

  Future<void> _updateStatus(OrderModel order, String status) async {
    try {
      if (status == 'arrived') {
        await _supabase.from('orders').update({
          'arrived_at_shop_time': DateTime.now().toIso8601String(),
        }).eq('id', order.id);
      } else if (status == 'reassign' || status == 'reassign_disputed') {
        double penalty = 0.0;
        if (order.arrivedAtShopTime != null) {
          final waitMinutes = DateTime.now().difference(order.arrivedAtShopTime!).inMinutes;
          final paidMinutes = math.max(0, math.min(10, waitMinutes - 10));
          penalty = paidMinutes * 1.5;
        }
        await _supabase.from('orders').update({
          'delivery_partner_id': null,
          'partner_accepted': false,
          'status': 'pending',
          'wait_time_penalty': penalty,
          'wait_time_disputed': status == 'reassign_disputed',
        }).eq('id', order.id);
      } else if (status == 'delivered') {
        // When the order is completed, lock in the final payout for the seller
        await _supabase.from('orders').update({
          'status': status,
          'seller_payout': order.sellerPayout,
        }).eq('id', order.id);
      } else {
        await _supabase.from('orders').update({'status': status}).eq('id', order.id);
      }
      _loadOrders();
    } catch (e) {
      debugPrint('Status update error: $e');
    }
  }

  void _showDisputeDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Dispute Order', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Report shop delay or missing items. You will keep your wait penalty pay and the order will be reassigned.', style: GoogleFonts.outfit()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
               Navigator.pop(ctx);
               _updateStatus(order, 'reassign_disputed');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Dispute & Reassign'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit()),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF080812) : const Color(0xFFF0F4FF),
        body: CustomScrollView(
          slivers: [
            // ── Animated Header ───────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              elevation: 0,
              backgroundColor: const Color(0xFF0D2137),
              surfaceTintColor: Colors.transparent,
              leading: const SizedBox.shrink(),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                  onPressed: _loadOrders,
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: AnimatedBuilder(
                  animation: _bgCtrl,
                  builder: (_, __) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color.lerp(const Color(0xFF0D2137), const Color(0xFF0A3260), _bgAnim.value)!,
                          Color.lerp(const Color(0xFF061222), const Color(0xFF061A36), _bgAnim.value)!,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Blobs
                        Positioned(top: -50, right: -50,
                          child: _blob(220, const Color(0xFF00B4D8), 0.12 + _bgAnim.value * 0.06)),
                        Positioned(bottom: -40, left: -40,
                          child: _blob(180, const Color(0xFF51CF66), 0.10)),
                        // Stars
                        CustomPaint(size: Size(size.width, 300), painter: _MiniStarPainter(_bgCtrl.value)),
                        // Content
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top bar
                                Row(children: [
                                  _glassAvatar(auth.user?.initials ?? 'D', const Color(0xFF00B4D8)),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text('Hi, ${auth.user?.fullName.split(' ').first ?? 'Partner'}! 🚴',
                                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                                      const SizedBox(height: 4),
                                      _badge('🛵  Delivery Partner', const Color(0xFF00B4D8)),
                                    ]),
                                  ),
                                  _iconBtn(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                                      () => themeProvider.toggleTheme()),
                                  _iconBtn(Icons.settings_outlined,
                                      () => Navigator.pushNamed(context, AppRoutes.settings)),
                                  _iconBtn(Icons.logout_rounded, () async {
                                    await auth.signOut();
                                    if (mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.roleSelect, (_) => false);
                                  }),
                                ]),
                                const SizedBox(height: 24),

                                // Online/Offline toggle card
                                ScaleTransition(
                                  scale: _isOnline ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() => _isOnline = !_isOnline);
                                      if (_isOnline) _loadOrders();
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 400),
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                      decoration: BoxDecoration(
                                        gradient: _isOnline
                                            ? const LinearGradient(colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
                                                begin: Alignment.topLeft, end: Alignment.bottomRight)
                                            : null,
                                        color: _isOnline ? null : Colors.white.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: _isOnline ? Colors.transparent : Colors.white.withOpacity(0.15),
                                          width: 1.5,
                                        ),
                                        boxShadow: _isOnline
                                            ? [BoxShadow(color: const Color(0xFF2ECC71).withOpacity(0.4),
                                                blurRadius: 20, offset: const Offset(0, 6))]
                                            : [],
                                      ),
                                      child: Row(children: [
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 400),
                                          width: 14, height: 14,
                                          decoration: BoxDecoration(
                                            color: _isOnline ? Colors.white : Colors.grey.shade400,
                                            shape: BoxShape.circle,
                                            boxShadow: _isOnline
                                                ? [const BoxShadow(color: Colors.white30, blurRadius: 8)]
                                                : [],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          Text(_isOnline ? 'YOU ARE ONLINE' : 'YOU ARE OFFLINE',
                                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 15,
                                              fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                                          Text(_isOnline ? 'Ready to accept deliveries' : 'Tap to go online',
                                            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
                                        ]),
                                        const Spacer(),
                                        Switch(
                                          value: _isOnline,
                                          onChanged: (v) {
                                            setState(() => _isOnline = v);
                                            if (v) _loadOrders();
                                          },
                                          activeTrackColor: Colors.white.withOpacity(0.3),
                                          activeThumbColor: Colors.white,
                                          inactiveTrackColor: Colors.white.withOpacity(0.15),
                                        ),
                                      ]),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),
                                // Stats row
                                Row(children: [
                                  _miniCard('${_myOrders.length}', 'Active', const Color(0xFF4C6EF5)),
                                  const SizedBox(width: 10),
                                  _miniCard('${_availableOrders.length}', 'Available', const Color(0xFFFF8C42)),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () => Navigator.pushNamed(context, AppRoutes.earnings),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                                      ),
                                      child: Row(children: [
                                        const Icon(Icons.account_balance_wallet_outlined, color: Colors.white70, size: 16),
                                        const SizedBox(width: 6),
                                        Text('Earnings', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                                      ]),
                                    ),
                                  ),
                                ]),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Content ────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Active deliveries
                  if (_myOrders.isNotEmpty) ...[
                    _sectionHeader('🚗 My Active Deliveries', '${_myOrders.length}', const Color(0xFF4C6EF5), isDark),
                    const SizedBox(height: 14),
                    ..._myOrders.map((o) => _activeOrderCard(o, isDark)),
                    const SizedBox(height: 24),
                  ],

                  // Available orders
                  _sectionHeader('📦 Available Orders', '${_availableOrders.length}', const Color(0xFFFF8C42), isDark),
                  const SizedBox(height: 14),

                  if (_isLoading)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ))
                  else if (!_isOnline)
                    _offlineState(isDark)
                  else if (_availableOrders.isEmpty)
                    _emptyState(isDark)
                  else
                    ..._availableOrders.map((o) => _availableOrderCard(o, isDark)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Card Builders ─────────────────────────────────────────────────────────

  Widget _availableOrderCard(OrderModel order, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121222) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 16, offset: const Offset(0, 6))],
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.transparent),
      ),
      child: Column(children: [
        // Header strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0D2137), Color(0xFF1A3A5C)]),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Row(children: [
            const Icon(Icons.storefront_outlined, color: Colors.white70, size: 16),
            const SizedBox(width: 8),
            Text('Order #${order.id.substring(0, 8).toUpperCase()}',
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.success.withOpacity(0.2), borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.success.withOpacity(0.5))),
              child: Text('₹${order.riderEarnings.toStringAsFixed(0)} earn',
                style: GoogleFonts.outfit(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
        // Body
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.danger),
              const SizedBox(width: 6),
              Expanded(child: Text(order.address ?? 'Address not set',
                style: GoogleFonts.outfit(color: isDark ? Colors.white60 : Colors.grey.shade600, fontSize: 13),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Text('₹${order.grandTotal.toStringAsFixed(0)}',
                style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0A0A14))),
              const Spacer(),
              ElevatedButton(
                onPressed: () => _acceptOrder(order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                  shadowColor: AppColors.success.withOpacity(0.4),
                ),
                child: Text('Accept', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 14)),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _activeOrderCard(OrderModel order, bool isDark) {
    String? nextStatus;
    String? nextLabel;
    
    // Wait-time variables
    final now = DateTime.now();
    bool showWaitTimer = false;
    int waitMinutes = 0;
    double waitPenalty = 0.0;
    bool canReassign = false;

    if (order.arrivedAtShopTime != null) {
      if (order.status == 'confirmed' || order.status == 'preparing' || order.status == 'ready_for_pickup') {
        showWaitTimer = true;
        // If shop marked ready, calculate wait time up to orderReadyTime. Else up to now.
        final endTime = order.orderReadyTime ?? now;
        waitMinutes = endTime.difference(order.arrivedAtShopTime!).inMinutes;
        final paidMinutes = math.max(0, math.min(10, waitMinutes - 10));
        waitPenalty = paidMinutes * 1.5;
        canReassign = now.difference(order.arrivedAtShopTime!).inMinutes >= 20;
      }
    }

    if (order.status == 'confirmed' || order.status == 'preparing') {
      if (order.arrivedAtShopTime == null) {
        nextStatus = 'arrived';
        nextLabel = '📍 Mark Arrived at Shop';
      } else {
        if (canReassign) {
           nextStatus = 'reassign';
           nextLabel = '⚠️ Wait Time Exceeded - Reassign';
        } else {
           nextLabel = 'Waiting for Shop to Pack...';
           nextStatus = null; // disabled
        }
      }
    } else if (order.status == 'ready_for_pickup') {
      nextStatus = 'picked_up';
      nextLabel = '✅ Confirm Received (Mark Picked Up)';
    } else if (order.status == 'picked_up') {
      nextStatus = 'out_for_delivery';
      nextLabel = '🚀 Out for Delivery';
    } else if (order.status == 'out_for_delivery') {
      nextStatus = 'delivered';
      nextLabel = '✅ Mark Delivered';
    }

    final statusGradient = order.status == 'out_for_delivery'
        ? [const Color(0xFF4C6EF5), const Color(0xFF364FC7)]
        : order.status == 'picked_up'
            ? [const Color(0xFF51CF66), const Color(0xFF2F9E44)]
            : [const Color(0xFFFF8C42), const Color(0xFFE8590C)];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121222) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: statusGradient.first.withOpacity(0.3), width: 1.5),
        boxShadow: [BoxShadow(color: statusGradient.first.withOpacity(0.15), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(children: [
        // Status strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: statusGradient),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(children: [
            Text('Order #${order.id.substring(0, 8).toUpperCase()}',
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
            const Spacer(),
            Text(order.statusDisplay,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.danger),
              const SizedBox(width: 6),
              Expanded(child: Text(order.address ?? 'Address not set',
                style: GoogleFonts.outfit(color: isDark ? Colors.white60 : Colors.grey.shade600, fontSize: 13),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
            if (showWaitTimer) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: waitMinutes >= 10 ? Colors.orange.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: waitMinutes >= 10 ? Colors.orange : Colors.blue),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer_outlined, color: waitMinutes >= 10 ? Colors.orange : Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Wait Time: $waitMinutes mins', 
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: waitMinutes >= 10 ? Colors.orange : Colors.blue)),
                          Text(order.orderReadyTime != null 
                            ? 'Timer stopped by shop'
                            : (waitMinutes < 10 
                                ? 'Grace period (10 mins)' 
                                : 'Earning ₹1.5/min delay penalty'),
                            style: GoogleFonts.outfit(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87)),
                        ],
                      ),
                    ),
                    Text('+₹${waitPenalty.toStringAsFixed(1)}',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.success)),
                  ],
                ),
              ),
            ],
            if (nextLabel != null) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: nextStatus == null ? null : () {
                     if (nextStatus == 'arrived') {
                        // Geofence mock: within 100 meters
                        _showSnack('📍 GPS verified: At Shop');
                        _updateStatus(order, nextStatus!);
                     } else if (nextStatus == 'reassign') {
                        _showDisputeDialog(order);
                     } else {
                        _updateStatus(order, nextStatus!);
                     }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: nextStatus == 'reassign' ? AppColors.danger : statusGradient.first,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: isDark ? Colors.white10 : Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(nextLabel!, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
            ],
            if (showWaitTimer) ...[
               const SizedBox(height: 8),
               TextButton.icon(
                 onPressed: () => _showDisputeDialog(order),
                 icon: const Icon(Icons.report_problem_outlined, color: AppColors.danger, size: 16),
                 label: Text(order.orderReadyTime != null ? 'Shop Lied - Items Not Received' : 'Shop Lied / Items Not Given', 
                   style: GoogleFonts.outfit(color: AppColors.danger, fontSize: 12)),
               ),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _offlineState(bool isDark) => Container(
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF121222) : Colors.white,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(children: [
      const Text('💤', style: TextStyle(fontSize: 56)),
      const SizedBox(height: 16),
      Text('You\'re Offline', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800,
        color: isDark ? Colors.white : const Color(0xFF0A0A14))),
      const SizedBox(height: 8),
      Text('Toggle the switch above to start accepting orders',
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(color: isDark ? Colors.white38 : Colors.grey.shade500, fontSize: 13)),
    ]),
  );

  Widget _emptyState(bool isDark) => Container(
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF121222) : Colors.white,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(children: [
      const Text('🕐', style: TextStyle(fontSize: 56)),
      const SizedBox(height: 16),
      Text('No orders yet', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800,
        color: isDark ? Colors.white : const Color(0xFF0A0A14))),
      const SizedBox(height: 8),
      Text('Waiting for delivery requests...', textAlign: TextAlign.center,
        style: GoogleFonts.outfit(color: isDark ? Colors.white38 : Colors.grey.shade500, fontSize: 13)),
      const SizedBox(height: 20),
      OutlinedButton.icon(
        onPressed: _loadOrders,
        icon: const Icon(Icons.refresh),
        label: Text('Refresh', style: GoogleFonts.outfit()),
        style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
    ]),
  );

  Widget _sectionHeader(String title, String count, Color color, bool isDark) => Row(children: [
    Text(title, style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w800,
      color: isDark ? Colors.white : const Color(0xFF0A0A14))),
    const SizedBox(width: 8),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(count, style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
    ),
  ]);

  Widget _glassAvatar(String initials, Color color) => Container(
    width: 52, height: 52,
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [color, color.withOpacity(0.6)]),
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 14, offset: const Offset(0, 4))],
    ),
    child: Center(child: Text(initials, style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900))),
  );

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.5))),
    child: Text(label, style: GoogleFonts.outfit(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
  );

  Widget _iconBtn(IconData icon, VoidCallback onTap) => IconButton(
    icon: Icon(icon, color: Colors.white70, size: 22),
    onPressed: onTap,
    splashRadius: 20,
  );

  Widget _miniCard(String value, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.4))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(value, style: GoogleFonts.outfit(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
      const SizedBox(width: 6),
      Text(label, style: GoogleFonts.outfit(color: color.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _blob(double size, Color color, double opacity) => Opacity(
    opacity: opacity.clamp(0.0, 1.0),
    child: Container(width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withOpacity(0)]))),
  );
}

class _MiniStarPainter extends CustomPainter {
  final double t;
  _MiniStarPainter(this.t);
  static final _rnd = math.Random(42);
  static final _stars = List.generate(25, (_) => [
    _rnd.nextDouble(), _rnd.nextDouble(),
    _rnd.nextDouble() * 1.2 + 0.4,
    _rnd.nextDouble() * math.pi * 2,
  ]);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    for (final s in _stars) {
      final tw = (math.sin(t * math.pi * 2 + s[3]) + 1) / 2;
      p.color = Colors.white.withOpacity(0.02 + tw * 0.10);
      canvas.drawCircle(Offset(s[0] * size.width, s[1] * size.height), s[2], p);
    }
  }
  @override
  bool shouldRepaint(_MiniStarPainter o) => o.t != t;
}
