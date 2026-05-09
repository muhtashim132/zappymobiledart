import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../config/routes.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final _supabase = Supabase.instance.client;
  List<OrderModel> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    final auth = context.read<AuthProvider>();
    try {
      final response = await _supabase
          .from('orders')
          .select()
          .eq('customer_id', auth.currentUserId ?? '')
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'delivered': return AppColors.success;
      case 'cancelled': case 'seller_rejected': return AppColors.danger;
      case 'out_for_delivery': return AppColors.info;
      default: return AppColors.primary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'delivered': return Icons.check_circle_outline;
      case 'cancelled': case 'seller_rejected': return Icons.cancel_outlined;
      case 'out_for_delivery': return Icons.delivery_dining;
      case 'pending': return Icons.access_time;
      default: return Icons.receipt_long_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Orders')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchOrders,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      return _buildOrderCard(_orders[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final statusColor = _getStatusColor(order.status);
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.trackOrder,
        arguments: {'orderId': order.id},
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_getStatusIcon(order.status),
                      color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.id.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy, hh:mm a')
                            .format(order.createdAt),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.statusDisplay,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${order.grandTotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
                const Row(
                  children: [
                    Text(
                      'View Details',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios,
                        size: 12, color: AppColors.primary),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.receipt_long_outlined,
                  size: 60, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 24),
          const Text('No orders yet',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins')),
          const SizedBox(height: 8),
          const Text('Start ordering from nearby shops!',
              style: TextStyle(
                  color: AppColors.textSecondary, fontFamily: 'Poppins')),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.customerHome),
            icon: const Icon(Icons.shopping_bag_outlined),
            label: const Text('Order Now'),
            style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14)),
          ),
        ],
      ),
    );
  }
}
