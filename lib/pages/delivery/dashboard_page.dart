import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
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

class _DeliveryDashboardPageState extends State<DeliveryDashboardPage> {
  final _supabase = Supabase.instance.client;
  bool _isOnline = false;
  List<OrderModel> _availableOrders = [];
  List<OrderModel> _myOrders = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    try {
      final available = await _supabase
          .from('orders')
          .select()
          .eq('status', 'seller_accepted')
          .isFilter('delivery_partner_id', null);

      final myOrders = await _supabase
          .from('orders')
          .select()
          .eq('delivery_partner_id', auth.currentUserId ?? '')
          .not('status', 'in', '("delivered","cancelled")');

      setState(() {
        _availableOrders =
            (available as List).map((o) => OrderModel.fromMap(o)).toList();
        _myOrders =
            (myOrders as List).map((o) => OrderModel.fromMap(o)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptOrder(OrderModel order) async {
    final auth = context.read<AuthProvider>();
    try {
      await _supabase.from('orders').update({
        'delivery_partner_id': auth.currentUserId,
        'status': 'partner_assigned',
      }).eq('id', order.id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order accepted! 🚀'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadOrders();
    } catch (e) {
      debugPrint('Accept error: $e');
    }
  }

  Future<void> _updateStatus(String orderId, String status) async {
    try {
      await _supabase
          .from('orders')
          .update({'status': status}).eq('id', orderId);
      _loadOrders();
    } catch (e) {
      debugPrint('Status update error: $e');
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
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                    gradient: AppColors.deliveryGradient),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor:
                                  Colors.white.withOpacity(0.2),
                              child: Text(
                                auth.user?.initials ?? 'D',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hi, ${auth.user?.fullName.split(' ').first ?? 'Partner'}! 🚴',
                                    style: const TextStyle(
                                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      auth.user?.roleDisplay ?? 'Delivery Partner',
                                      style: const TextStyle(
                                        color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700,
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
                              icon: const Icon(Icons.logout,
                                  color: Colors.white),
                              onPressed: () async {
                                await auth.signOut();
                                if (mounted) {
                                  Navigator.pushNamedAndRemoveUntil(
                                      context, AppRoutes.roleSelect, (_) => false);
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Online Toggle
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _isOnline
                                      ? Colors.greenAccent
                                      : Colors.grey[300],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _isOnline
                                    ? 'You are ONLINE'
                                    : 'You are OFFLINE',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const Spacer(),
                              Switch(
                                value: _isOnline,
                                onChanged: (v) {
                                  setState(() => _isOnline = v);
                                  if (v) _loadOrders();
                                },
                                activeThumbColor: Colors.greenAccent,
                                activeTrackColor:
                                    Colors.greenAccent.withOpacity(0.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            leading: const SizedBox.shrink(),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadOrders,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // My Active Orders
                  if (_myOrders.isNotEmpty) ...[
                    Text('🚗 My Active Deliveries',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                            color: Theme.of(context).textTheme.bodyLarge?.color)),
                    const SizedBox(height: 12),
                    ..._myOrders.map((o) => _buildActiveOrderCard(o)),
                    const SizedBox(height: 20),
                  ],

                  // Available Orders
                  Row(
                    children: [
                      Text(
                        '📦 Available Orders',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                            color: Theme.of(context).textTheme.bodyLarge?.color),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_availableOrders.length}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (!_isOnline)
                    _buildOfflineState()
                  else if (_availableOrders.isEmpty)
                    _buildNoOrdersState()
                  else
                    ..._availableOrders
                        .map((o) => _buildAvailableOrderCard(o)),
                  const SizedBox(height: 24),
                  // Earnings Link
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.earnings),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: AppColors.deliveryGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.account_balance_wallet_outlined,
                              color: Colors.white, size: 28),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text('My Earnings',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Poppins',
                                        fontSize: 16)),
                                Text('View daily & weekly summary',
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontFamily: 'Poppins')),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios,
                              color: Colors.white, size: 16),
                        ],
                      ),
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

  Widget _buildAvailableOrderCard(OrderModel order) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05), 
              blurRadius: 8),
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
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontFamily: 'Poppins', color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
              Text(
                '₹${order.deliveryCharges.toStringAsFixed(0)} delivery fee',
                style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                    fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 16, color: AppColors.danger),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  order.address ?? 'Address not set',
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontFamily: 'Poppins'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '₹${order.grandTotal.toStringAsFixed(0)}',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => _acceptOrder(order),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  backgroundColor: AppColors.success,
                ),
                child: const Text('Accept',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveOrderCard(OrderModel order) {
    final nextStatus = order.status == 'partner_assigned'
        ? 'picked_up'
        : order.status == 'picked_up'
            ? 'out_for_delivery'
            : order.status == 'out_for_delivery'
                ? 'delivered'
                : null;

    final nextLabel = order.status == 'partner_assigned'
        ? 'Mark Picked Up'
        : order.status == 'picked_up'
            ? 'Out for Delivery'
            : order.status == 'out_for_delivery'
                ? 'Mark Delivered'
                : null;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withOpacity(0.1), blurRadius: 10),
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
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontFamily: 'Poppins', color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
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
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 16, color: AppColors.danger),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  order.address ?? 'Address not set',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (nextStatus != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _updateStatus(order.id, nextStatus),
                child: Text(nextLabel!,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOfflineState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            Text('💤', style: TextStyle(fontSize: 56)),
            SizedBox(height: 16),
            Text('You are Offline',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins')),
            SizedBox(height: 8),
            Text(
              'Toggle the switch above to go online and start accepting orders',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textSecondary, fontFamily: 'Poppins'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoOrdersState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Text('🕐', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            const Text('No orders available',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins')),
            const SizedBox(height: 8),
            const Text('Waiting for new delivery requests...',
                style: TextStyle(
                    color: AppColors.textSecondary, fontFamily: 'Poppins')),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _loadOrders,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}
