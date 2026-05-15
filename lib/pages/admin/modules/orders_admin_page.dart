import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class OrdersAdminPage extends StatefulWidget {
  const OrdersAdminPage({super.key});

  @override
  State<OrdersAdminPage> createState() => _OrdersAdminPageState();
}

class _OrdersAdminPageState extends State<OrdersAdminPage> {
  final _db = Supabase.instance.client;
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      final res = await _db.from('orders').select('*, profiles:user_id(full_name), shops:shop_id(name)').order('created_at', ascending: false).limit(50);
      setState(() {
        _orders = List<Map<String, dynamic>>.from(res);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B2FC9)))
        : _orders.isEmpty
            ? Center(child: Text('No orders found', style: GoogleFonts.outfit(color: Colors.white54)))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _orders.length,
                itemBuilder: (context, index) {
                  final order = _orders[index];
                  final profile = order['profiles'] ?? {};
                  final shop = order['shops'] ?? {};
                  final status = order['status'] ?? 'unknown';
                  final amount = order['total_amount'] ?? 0;
                  final createdAt = order['created_at'] != null ? DateFormat('MMM dd, hh:mm a').format(DateTime.parse(order['created_at'])) : 'Unknown';

                  Color statusColor = Colors.grey;
                  if (status == 'delivered') statusColor = Colors.green;
                  if (status == 'cancelled') statusColor = Colors.red;
                  if (status == 'preparing') statusColor = Colors.orange;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.07)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.receipt_long_rounded, color: statusColor),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Order #${order['id'].toString().substring(0, 8)}', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              Text('${profile['full_name'] ?? 'Unknown'} • ${shop['name'] ?? 'Unknown'}', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(createdAt, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('₹$amount', style: GoogleFonts.outfit(color: const Color(0xFF8B2FC9), fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(status.toString().toUpperCase(), style: GoogleFonts.outfit(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
  }
}
