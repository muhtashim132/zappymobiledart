import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../theme/app_colors.dart';

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
      final response = await _supabase
          .from('orders')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        _orders =
            (response as List).map((o) => OrderModel.fromMap(o)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateOrderStatus(String orderId, String status) async {
    try {
      await _supabase
          .from('orders')
          .update({'status': status}).eq('id', orderId);
      _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Order status updated to ${status.replaceAll('_', ' ')}'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      debugPrint('Update error: $e');
    }
  }

  List<OrderModel> _filterOrders(String filter) {
    switch (filter) {
      case 'pending':
        return _orders.where((o) => o.status == 'pending').toList();
      case 'active':
        return _orders
            .where((o) => [
                  'seller_accepted',
                  'partner_assigned',
                  'picked_up',
                  'out_for_delivery'
                ].contains(o.status))
            .toList();
      case 'done':
        return _orders
            .where((o) =>
                o.status == 'delivered' ||
                o.status == 'cancelled' ||
                o.status == 'seller_rejected')
            .toList();
      default:
        return _orders;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Orders'),
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
                  const Text('Pending'),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_filterOrders('pending').length}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
            const Tab(text: 'Active'),
            const Tab(text: 'Done'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadOrders),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList('pending'),
                _buildOrderList('active'),
                _buildOrderList('done'),
              ],
            ),
    );
  }

  Widget _buildOrderList(String filter) {
    final orders = _filterOrders(filter);
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📋', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              filter == 'pending'
                  ? 'No pending orders'
                  : filter == 'active'
                      ? 'No active orders'
                      : 'No completed orders',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontFamily: 'Poppins',
                fontSize: 16,
              ),
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
        itemBuilder: (context, index) =>
            _buildOrderCard(orders[index], filter),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order, String filter) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${order.id.substring(0, 8).toUpperCase()}',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
              ),
              Text(
                DateFormat('hh:mm a').format(order.createdAt),
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontFamily: 'Poppins'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('₹${order.grandTotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    fontFamily: 'Poppins',
                  )),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.statusDisplay,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          if (filter == 'pending') ...[
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateOrderStatus(
                        order.id, 'seller_rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateOrderStatus(
                        order.id, 'seller_accepted'),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ] else if (filter == 'active' &&
              order.status == 'seller_accepted') ...[
            const Divider(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _updateOrderStatus(
                    order.id, 'partner_assigned'),
                child: const Text('Mark Ready for Pickup'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
