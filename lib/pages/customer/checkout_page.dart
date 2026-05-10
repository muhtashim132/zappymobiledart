import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/cart_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../config/routes.dart';
import '../../widgets/common/zappy_map.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _isProcessing = false;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    setState(() => _isProcessing = true);
    final cart = context.read<CartProvider>();
    final auth = context.read<AuthProvider>();
    final location = context.read<LocationProvider>();

    try {
      final supabase = Supabase.instance.client;
      double distanceKm = 3.0;
      if (location.currentLocation != null && cart.shops.isNotEmpty) {
        distanceKm = location.distanceTo(cart.shops.first.location);
      }
      final baseDelivery = cart.calculateDeliveryCharges(distanceKm);
      final surcharge = cart.multiShopSurcharge;
      final heavyFee = cart.heavyOrderFee;
      final discount = cart.calculateDeliveryDiscount(distanceKm);
      
      final effectiveBase = baseDelivery >= 0 ? baseDelivery : 25.0;
      final riderEarnings = effectiveBase + surcharge + heavyFee;
      final totalDelivery = riderEarnings + cart.smallCartFee - discount;

      final orderResponse = await supabase.from('orders').insert({
        'customer_id': auth.currentUserId,
        'status': 'pending',
        'total_amount': cart.subtotal,
        'delivery_charges': totalDelivery,
        'rider_earnings': riderEarnings,
        'platform_fee': cart.platformFee,
        'address': location.currentAddress,
        'delivery_notes': _notesController.text.isEmpty
            ? null
            : _notesController.text,
      }).select().single();

      final orderId = orderResponse['id'];

      final itemsToInsert = cart.items
          .map((item) => {
                'order_id': orderId,
                'product_id': item.product.id,
                'product_name': item.product.name,
                'quantity': item.quantity,
                'price': item.product.price,
                'weight_kg': item.weightKg,
              })
          .toList();

      await supabase.from('order_items').insert(itemsToInsert);

      cart.clear();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.trackOrder,
          (route) => route.settings.name == AppRoutes.customerHome,
          arguments: {'orderId': orderId},
        );
      }
    } catch (e) {
      debugPrint('Order placement error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to place order. Please try again.'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final location = context.watch<LocationProvider>();
    
    double distanceKm = 3.0;
    if (location.currentLocation != null && cart.shops.isNotEmpty) {
      distanceKm = location.distanceTo(cart.shops.first.location);
    }
    
    final baseCharge = cart.calculateDeliveryCharges(distanceKm);
    final surcharge = cart.multiShopSurcharge;
    final heavyFee = cart.heavyOrderFee;
    final discount = cart.calculateDeliveryDiscount(distanceKm);
    final effectiveBase = baseCharge >= 0 ? baseCharge : 25.0;
    final totalDelivery = effectiveBase + surcharge + heavyFee + cart.smallCartFee - discount;
    final total = cart.subtotal + totalDelivery + cart.platformFee;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Delivery Address
            _sectionCard(
              title: 'Delivery Address',
              icon: Icons.location_on_outlined,
              iconColor: AppColors.danger,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.currentAddress.isEmpty
                        ? 'Location not set'
                        : location.currentAddress,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  if (location.hasLocation)
                    Container(
                      height: 120,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ZappyMap(
                          center: location.currentLocation!,
                          zoom: 15,
                          interactive: false,
                        ),
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        context.read<LocationProvider>().requestLocation(),
                    icon: const Icon(Icons.my_location, size: 16),
                    label: const Text('Update Location'),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Order Items
            _sectionCard(
              title: 'Order Summary',
              icon: Icons.receipt_long_outlined,
              iconColor: AppColors.primary,
              child: Column(
                children: [
                  ...cart.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: item.product.isVeg == true
                                    ? AppColors.vegGreen
                                    : AppColors.nonVegRed,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${item.quantity}x ${item.product.name}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Text(
                              '₹${item.totalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Delivery Notes
            _sectionCard(
              title: 'Delivery Notes',
              icon: Icons.note_alt_outlined,
              iconColor: AppColors.info,
              child: TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Add any special instructions...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Bill Details
            _sectionCard(
              title: 'Bill Details',
              icon: Icons.account_balance_wallet_outlined,
              iconColor: AppColors.success,
              child: Column(
                children: [
                  _billRow('Item Total',
                      '₹${cart.subtotal.toStringAsFixed(0)}'),
                  const SizedBox(height: 8),
                  _billRow(
                    'Delivery Fee',
                    '₹${effectiveBase.toStringAsFixed(0)}',
                  ),
                  if (discount > 0) ...[
                    const SizedBox(height: 8),
                    _billRow(
                      'Delivery Discount',
                      '-₹${discount.toStringAsFixed(0)}',
                      valueColor: AppColors.success,
                    ),
                  ],
                  if (cart.smallCartFee > 0) ...[
                    const SizedBox(height: 8),
                    _billRow(
                      'Small Cart Fee',
                      '+₹${cart.smallCartFee.toStringAsFixed(0)}',
                      hint: 'For orders under ₹99',
                      valueColor: Colors.orange.shade700,
                    ),
                  ],
                  if (heavyFee > 0) ...[
                    const SizedBox(height: 8),
                    _billRow(
                      'Heavy Order Fee',
                      '+₹${heavyFee.toStringAsFixed(0)}',
                      hint: 'For orders over 10 kg',
                      valueColor: Colors.orange.shade700,
                    ),
                  ],
                  // Multi-shop surcharge — shown only when ordering from 2+ shops
                  if (surcharge > 0) ...
                    [
                      const SizedBox(height: 8),
                      _billRow(
                        'Multi-shop fee (${cart.shops.length} shops)',
                        '+₹${surcharge.toStringAsFixed(0)}',
                        valueColor: Colors.orange.shade700,
                        hint: '₹7/km between shops',
                      ),
                    ],
                  const SizedBox(height: 8),
                  _billRow(
                    'Handling/Platform Fee',
                    '+₹${cart.platformFee.toStringAsFixed(0)}',
                    hint: 'Supports app operations',
                  ),
                  const Divider(height: 20),
                  _billRow(
                    'Grand Total',
                    '₹${total.toStringAsFixed(0)}',
                    isBold: true,
                    valueColor: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Amount',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
                Text('₹${total.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: AppColors.ctaGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        'PLACE ORDER',
                        style: TextStyle(
                            fontSize: 16, 
                            color: Colors.white,
                            fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _billRow(String label, String value,
      {bool isBold = false, Color? valueColor, String? hint}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                  color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
                  fontSize: isBold ? 15 : 13,
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
                )),
            if (hint != null)
              Text(hint,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  )),
          ],
        ),
        Text(value,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: isBold ? 17 : 13,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            )),
      ],
    );
  }
}
