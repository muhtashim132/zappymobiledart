import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/order_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/rating_bottom_sheet.dart';
import '../../widgets/common/notification_bell.dart';

class SellerOrdersPage extends StatefulWidget {
  const SellerOrdersPage({super.key});

  @override
  State<SellerOrdersPage> createState() => _SellerOrdersPageState();
}

class _SellerOrdersPageState extends State<SellerOrdersPage>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  List<OrderModel> _orders = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    try {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();

      final shopsResp = await _supabase
          .from('shops')
          .select('id')
          .eq('seller_id', auth.currentUserId ?? '');

      if ((shopsResp as List).isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final shopId = shopsResp.first['id'];

      final response = await _supabase
          .from('orders')
          .select('*, order_items(*)')
          .eq('shop_id', shopId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _orders = (response as List).map((o) {
            final model = OrderModel.fromMap(o);
            final rawItems = o['order_items'] as List? ?? [];
            model.items = rawItems.map((i) => OrderItem.fromMap(i)).toList();
            return model;
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Seller presses Accept:
  ///   1. Set seller_accepted = true in DB
  ///   2. If partner_accepted is already true → move to 'confirmed'
  ///   3. Otherwise stay 'pending' (displayed as "Awaiting Rider")
  Future<void> _sellerAccept(OrderModel order) async {
    try {
      // Determine what status to set
      final newStatus = order.partnerAccepted ? 'confirmed' : 'pending';

      await _supabase.from('orders').update({
        'seller_accepted': true,
        'status': newStatus,
      }).eq('id', order.id);

      if (mounted) {
        final msg = order.partnerAccepted
            ? '✅ Order confirmed! Both shop & rider accepted.'
            : '✅ Your acceptance saved. Waiting for a delivery partner.';
        _showSnack(msg, isError: false);
      }
      _loadOrders();
    } catch (e) {
      debugPrint('Seller accept error: $e');
    }
  }

  Future<void> _sellerReject(OrderModel order) async {
    try {
      await _supabase.from('orders').update({
        'status': 'seller_rejected',
        'seller_accepted': false,
      }).eq('id', order.id);
      _loadOrders();
      _showSnack('Order rejected.', isError: true);
    } catch (e) {
      debugPrint('Reject error: $e');
    }
  }

  Future<void> _updateOrderStatus(String orderId, String status) async {
    try {
      await _supabase
          .from('orders')
          .update({'status': status}).eq('id', orderId);
      _loadOrders();
      _showSnack('Status → ${status.replaceAll('_', ' ')}', isError: false);
    } catch (e) {
      debugPrint('Update error: $e');
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit()),
      backgroundColor: isError ? AppColors.danger : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showSellerRatingFlow(OrderModel order) {
    if (!mounted || order.deliveryPartnerId == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => RatingBottomSheet(
        title: 'Rate the Rider 🚴',
        subtitle: 'How punctual was the delivery partner?',
        onSubmit: (rating, review) => _submitSellerRating(
          orderId: order.id,
          rateeId: order.deliveryPartnerId!,
          rating: rating,
          review: review,
        ),
      ),
    );
  }

  Future<void> _submitSellerRating({
    required String orderId,
    required String rateeId,
    required int rating,
    required String review,
  }) async {
    try {
      final auth = context.read<AuthProvider>();
      await _supabase.from('ratings').insert({
        'order_id': orderId,
        'rater_id': auth.currentUserId,
        'ratee_id': rateeId,
        'rater_role': 'seller',
        'ratee_role': 'delivery',
        'rating': rating,
        'review': review.isEmpty ? null : review,
      });
      await _supabase.from('orders')
          .update({'has_seller_rated': true}).eq('id', orderId);
      _loadOrders();
      _showSnack('⭐ Rider rated successfully!', isError: false);
    } catch (e) {
      debugPrint('Seller rating error: $e');
    }
  }

  // ── Tab filters ────────────────────────────────────────────────────────────
  List<OrderModel> _pendingOrders() =>
      _orders.where((o) => o.status == 'pending' && !o.sellerAccepted).toList();

  List<OrderModel> _activeOrders() => _orders
      .where((o) =>
          [
            'pending', // seller accepted, awaiting partner (or vice versa)
            'confirmed',
            'preparing',
            'ready_for_pickup',
            'picked_up',
            'out_for_delivery',
          ].contains(o.status) &&
          (o.sellerAccepted || o.status != 'pending'))
      .toList();

  List<OrderModel> _doneOrders() => _orders
      .where((o) => [
            'delivered',
            'cancelled',
            'seller_rejected',
            'partner_rejected'
          ].contains(o.status))
      .toList();

  @override
  Widget build(BuildContext context) {
    final pendingCount = _pendingOrders().length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Orders',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Pending', style: GoogleFonts.outfit()),
                  if (pendingCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(10)),
                      child: Text('$pendingCount',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ],
              ),
            ),
            Tab(child: Text('Active', style: GoogleFonts.outfit())),
            Tab(child: Text('Done', style: GoogleFonts.outfit())),
          ],
        ),
        actions: [
          const NotificationBell(),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadOrders),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(_pendingOrders(), 'pending'),
                _buildList(_activeOrders(), 'active'),
                _buildList(_doneOrders(), 'done'),
              ],
            ),
    );
  }

  Widget _buildList(List<OrderModel> orders, String tab) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📋', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              tab == 'pending'
                  ? 'No new orders'
                  : tab == 'active'
                      ? 'No active orders'
                      : 'No completed orders',
              style: GoogleFonts.outfit(
                  color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) => _buildOrderCard(orders[index], tab),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order, String tab) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _statusColor(order);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
        border: order.status == 'confirmed'
            ? Border.all(color: AppColors.success, width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${order.id.substring(0, 8).toUpperCase()}',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700, fontSize: 14),
              ),
              Text(
                DateFormat('hh:mm a').format(order.createdAt),
                style: GoogleFonts.outfit(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Amount + status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${order.grandTotal.toStringAsFixed(0)}',
                style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary),
              ),
              _statusBadge(order, statusColor),
            ],
          ),

          // ── Order Items ─────────────────────────────────────────────────
          if (order.items.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Items (${order.items.length})',
                      style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, size: 5, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${item.quantity}x ${item.productName}',
                                style: GoogleFonts.outfit(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '₹${item.totalPrice.toStringAsFixed(0)}',
                              style: GoogleFonts.outfit(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],

          // Dual-acceptance progress bar (for pending-but-one-accepted)
          if (order.status == 'pending' &&
              (order.sellerAccepted || order.partnerAccepted)) ...[
            const SizedBox(height: 12),
            _buildAcceptanceProgress(order),
          ],

          // Action buttons
          if (tab == 'pending') ...[
            const Divider(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _sellerReject(order),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Reject',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _sellerAccept(order),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Accept',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ]),
          ] else if (tab == 'active' && order.status == 'confirmed') ...[
            const Divider(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _updateOrderStatus(order.id, 'preparing'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Start Preparing',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ] else if (tab == 'active' && order.status == 'preparing') ...[
            const Divider(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    _updateOrderStatus(order.id, 'ready_for_pickup'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Mark Ready for Pickup',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700, color: Colors.black)),
              ),
            ),
          ] else if (tab == 'done' &&
              order.status == 'delivered' &&
              order.deliveryPartnerId != null &&
              !order.hasSellerRated) ...[
            const Divider(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showSellerRatingFlow(order),
                icon: const Icon(Icons.star_outline_rounded, color: Colors.amber),
                label: Text('Rate Delivery Partner',
                    style: GoogleFonts.outfit(
                        color: Colors.amber, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.amber),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ] else if (tab == 'done' && order.hasSellerRated) ...[
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline,
                    color: AppColors.success, size: 16),
                const SizedBox(width: 6),
                Text('Rider Rated',
                    style: GoogleFonts.outfit(
                        color: AppColors.success,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Shows a visual progress bar: [Seller ✓] ──── [Rider ?]
  Widget _buildAcceptanceProgress(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Waiting for both parties to accept',
            style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.amber.shade800,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _acceptanceStep(
                label: 'Shop',
                icon: Icons.store_outlined,
                accepted: order.sellerAccepted,
              ),
              Expanded(
                child: Container(
                  height: 2,
                  color: (order.sellerAccepted && order.partnerAccepted)
                      ? AppColors.success
                      : Colors.grey.shade300,
                ),
              ),
              _acceptanceStep(
                label: 'Rider',
                icon: Icons.delivery_dining_outlined,
                accepted: order.partnerAccepted,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _acceptanceStep(
      {required String label, required IconData icon, required bool accepted}) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: accepted ? AppColors.success : Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: Icon(
            accepted ? Icons.check : icon,
            color: accepted ? Colors.white : Colors.grey.shade500,
            size: 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: GoogleFonts.outfit(
                fontSize: 11,
                color: accepted ? AppColors.success : AppColors.textSecondary,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _statusBadge(OrderModel order, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        order.statusDisplay,
        style: GoogleFonts.outfit(
            color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }

  Color _statusColor(OrderModel order) {
    switch (order.status) {
      case 'confirmed':
        return AppColors.success;
      case 'preparing':
        return AppColors.primary;
      case 'ready_for_pickup':
        return Colors.orange;
      case 'picked_up':
        return Colors.blue;
      case 'out_for_delivery':
        return Colors.deepPurple;
      case 'delivered':
        return AppColors.success;
      case 'seller_rejected':
      case 'partner_rejected':
      case 'cancelled':
        return AppColors.danger;
      default:
        if (order.sellerAccepted || order.partnerAccepted) {
          return Colors.amber.shade700;
        }
        return AppColors.textSecondary;
    }
  }
}
