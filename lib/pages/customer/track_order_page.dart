import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/order_model.dart';
import '../../theme/app_colors.dart';
import '../../config/routes.dart';
import '../../widgets/common/zappy_map.dart';
import 'package:latlong2/latlong.dart';

class TrackOrderPage extends StatefulWidget {
  final String orderId;
  const TrackOrderPage({super.key, required this.orderId});

  @override
  State<TrackOrderPage> createState() => _TrackOrderPageState();
}

class _TrackOrderPageState extends State<TrackOrderPage>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  OrderModel? _order;
  bool _isLoading = true;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  RealtimeChannel? _channel;

  final List<Map<String, dynamic>> _steps = [
    {
      'status': 'pending',
      'title': 'Order Placed',
      'subtitle': 'We received your order!',
      'icon': Icons.receipt_long,
    },
    {
      'status': 'seller_accepted',
      'title': 'Order Accepted',
      'subtitle': 'Shop is preparing your order',
      'icon': Icons.restaurant,
    },
    {
      'status': 'partner_assigned',
      'title': 'Delivery Assigned',
      'subtitle': 'Delivery partner is on the way',
      'icon': Icons.delivery_dining,
    },
    {
      'status': 'out_for_delivery',
      'title': 'Out for Delivery',
      'subtitle': 'Your order is almost here!',
      'icon': Icons.local_shipping_outlined,
    },
    {
      'status': 'delivered',
      'title': 'Delivered!',
      'subtitle': 'Enjoy your order! 🎉',
      'icon': Icons.check_circle,
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _fetchOrder();
    _subscribeToOrder();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _fetchOrder() async {
    try {
      final response = await _supabase
          .from('orders')
          .select()
          .eq('id', widget.orderId)
          .single();

      setState(() {
        _order = OrderModel.fromMap(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _subscribeToOrder() {
    _channel = _supabase
        .channel('order-${widget.orderId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: widget.orderId,
          ),
          callback: (payload) {
            if (mounted && payload.newRecord.isNotEmpty) {
              setState(() {
                _order = OrderModel.fromMap(payload.newRecord);
              });
            }
          },
        )
        .subscribe();
  }

  int _getCurrentStep() {
    if (_order == null) return 0;
    switch (_order!.status) {
      case 'pending': return 0;
      case 'seller_accepted': return 1;
      case 'partner_assigned': return 2;
      case 'out_for_delivery': case 'picked_up': return 3;
      case 'delivered': return 4;
      default: return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_order == null) {
      return const Scaffold(body: Center(child: Text('Order not found')));
    }

    final currentStep = _getCurrentStep();
    final isDelivered = _order!.status == 'delivered';
    final isCancelled = _order!.status == 'cancelled' ||
        _order!.status == 'seller_rejected';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Order #${_order!.id.substring(0, 8).toUpperCase()}'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.orderHistory),
            icon: const Icon(Icons.history, size: 16),
            label: const Text('History'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Map Section
            Container(
              height: 250,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: const ZappyMap(
                  center: LatLng(28.6139, 77.2090), // Default to Delhi for demo
                  zoom: 14,
                  interactive: true,
                ),
              ),
            ),
            // Status Hero
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: isCancelled
                    ? LinearGradient(colors: [
                        AppColors.danger.withOpacity(0.8),
                        AppColors.danger,
                      ])
                    : isDelivered
                        ? LinearGradient(colors: [
                            AppColors.success.withOpacity(0.8),
                            AppColors.success,
                          ])
                        : AppColors.splashGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  ScaleTransition(
                    scale: isDelivered || isCancelled
                        ? const AlwaysStoppedAnimation(1.0)
                        : _pulseAnim,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCancelled
                            ? Icons.cancel_outlined
                            : isDelivered
                                ? Icons.check_circle_outline
                                : Icons.delivery_dining,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _order!.statusDisplay,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isDelivered
                        ? 'Enjoy your order! Thank you 🎉'
                        : isCancelled
                            ? 'Your order has been cancelled'
                            : 'Estimated delivery in 30-45 mins',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tracking Steps
            if (!isCancelled)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Tracking',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...List.generate(_steps.length, (index) {
                      final isCompleted = index <= currentStep;
                      final isCurrent = index == currentStep;
                      return _buildStep(
                        _steps[index]['title']!,
                        _steps[index]['subtitle']!,
                        _steps[index]['icon'] as IconData,
                        isCompleted,
                        isCurrent,
                        index < _steps.length - 1,
                      );
                    }),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // Order Bill
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bill Summary',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins')),
                  const SizedBox(height: 16),
                  _billRow('Subtotal',
                      '₹${_order!.totalAmount.toStringAsFixed(0)}'),
                  const SizedBox(height: 8),
                  _billRow('Delivery',
                      '₹${_order!.deliveryCharges.toStringAsFixed(0)}'),
                  const Divider(height: 20),
                  _billRow(
                    'Total Paid',
                    '₹${(_order!.totalAmount + _order!.deliveryCharges).toStringAsFixed(0)}',
                    isBold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context, AppRoutes.customerHome, (route) => false),
              icon: const Icon(Icons.home_outlined),
              label: const Text('Back to Home'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String title, String subtitle, IconData icon,
      bool isCompleted, bool isCurrent, bool hasLine) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.success
                    : isCurrent
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.background,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted
                      ? AppColors.success
                      : isCurrent
                          ? AppColors.primary
                          : AppColors.divider,
                  width: 2,
                ),
              ),
              child: Icon(
                isCompleted ? Icons.check : icon,
                color: isCompleted
                    ? Colors.white
                    : isCurrent
                        ? AppColors.primary
                        : AppColors.textLight,
                size: 18,
              ),
            ),
            if (hasLine)
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 2,
                height: 36,
                color: isCompleted ? AppColors.success : AppColors.divider,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isCompleted || isCurrent
                        ? AppColors.textPrimary
                        : AppColors.textLight,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isCompleted || isCurrent
                        ? AppColors.textSecondary
                        : AppColors.textLight,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _billRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
              color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: isBold ? 15 : 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            )),
        Text(value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              fontSize: isBold ? 16 : 13,
              color: isBold ? AppColors.primary : AppColors.textPrimary,
            )),
      ],
    );
  }
}
