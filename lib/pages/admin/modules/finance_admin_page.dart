import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class FinanceAdminPage extends StatefulWidget {
  const FinanceAdminPage({super.key});

  @override
  State<FinanceAdminPage> createState() => _FinanceAdminPageState();
}

class _FinanceAdminPageState extends State<FinanceAdminPage> {
  final _db = Supabase.instance.client;
  List<Map<String, dynamic>> _transactions = [];
  bool _loading = true;
  double _totalRevenue = 0.0;
  int _totalOrders = 0;

  @override
  void initState() {
    super.initState();
    _fetchFinanceData();
  }

  Future<void> _fetchFinanceData() async {
    try {
      final res = await _db
          .from('orders')
          .select('id, total_amount, status, created_at, shops:shop_id(name)')
          .eq('status', 'delivered')
          .order('created_at', ascending: false)
          .limit(100);

      double revenue = 0;
      for (var order in res) {
        revenue += (order['total_amount'] as num?)?.toDouble() ?? 0.0;
      }

      setState(() {
        _transactions = List<Map<String, dynamic>>.from(res);
        _totalRevenue = revenue;
        _totalOrders = res.length;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFE91E63)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFE91E63), Color(0xFFC2185B)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: const Color(0xFFE91E63).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 40),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Platform Revenue', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('₹${_totalRevenue.toStringAsFixed(2)}', style: GoogleFonts.outfit(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                    Text('From $_totalOrders delivered orders', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Recent Transactions', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _transactions.isEmpty
              ? Center(child: Text('No transactions found', style: GoogleFonts.outfit(color: Colors.white54)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    final tx = _transactions[index];
                    final shopName = tx['shops']?['name'] ?? 'Unknown Shop';
                    final amount = tx['total_amount'] ?? 0;
                    final date = tx['created_at'] != null ? DateFormat('MMM dd, hh:mm a').format(DateTime.parse(tx['created_at'])) : 'Unknown';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.07)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE91E63).withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.call_received_rounded, color: Color(0xFFE91E63), size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Payout to $shopName', style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                Text('Order #${tx['id'].toString().substring(0, 8)}', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('+₹$amount', style: GoogleFonts.outfit(color: const Color(0xFF4CAF50), fontSize: 14, fontWeight: FontWeight.bold)),
                              Text(date, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
