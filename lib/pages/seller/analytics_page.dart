import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  double _totalRevenue = 0;
  int _totalOrders = 0;
  int _deliveredOrders = 0;
  final List<FlSpot> _revenueSpots = [];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      final orders = await _supabase
          .from('orders')
          .select()
          .order('created_at', ascending: true);

      double total = 0;
      int delivered = 0;
      final List<FlSpot> spots = [];

      for (int i = 0; i < (orders as List).length && i < 7; i++) {
        total += (orders[i]['total_amount'] ?? 0.0);
        if (orders[i]['status'] == 'delivered') delivered++;
        spots.add(FlSpot(i.toDouble(), total / 100));
      }

      setState(() {
        _totalRevenue = total;
        _totalOrders = orders.length;
        _deliveredOrders = delivered;
        _revenueSpots.addAll(spots);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Analytics')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Stats
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          'Total Revenue',
                          '₹${_totalRevenue.toStringAsFixed(0)}',
                          Icons.currency_rupee,
                          AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          'Total Orders',
                          '$_totalOrders',
                          Icons.receipt_long_outlined,
                          AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          'Delivered',
                          '$_deliveredOrders',
                          Icons.check_circle_outline,
                          AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          'Success Rate',
                          _totalOrders > 0
                              ? '${(_deliveredOrders / _totalOrders * 100).toStringAsFixed(0)}%'
                              : '0%',
                          Icons.trending_up,
                          AppColors.info,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Chart
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
                          'Revenue Trend',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 200,
                          child: _revenueSpots.isEmpty
                              ? const Center(
                                  child: Text('No data yet',
                                      style: TextStyle(
                                          color: AppColors.textSecondary)))
                              : LineChart(
                                  LineChartData(
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                      getDrawingHorizontalLine: (v) => const FlLine(
                                        color: AppColors.divider,
                                        strokeWidth: 1,
                                      ),
                                    ),
                                    titlesData: FlTitlesData(
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (v, meta) => Text(
                                            'D${v.toInt() + 1}',
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color:
                                                    AppColors.textSecondary),
                                          ),
                                        ),
                                      ),
                                      leftTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                            showTitles: false),
                                      ),
                                      topTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                            showTitles: false),
                                      ),
                                      rightTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                            showTitles: false),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: _revenueSpots.isEmpty
                                            ? [const FlSpot(0, 0)]
                                            : _revenueSpots,
                                        isCurved: true,
                                        color: AppColors.primary,
                                        barWidth: 3,
                                        belowBarData: BarAreaData(
                                          show: true,
                                          color: AppColors.primary
                                              .withOpacity(0.1),
                                        ),
                                        dotData: FlDotData(
                                          show: true,
                                          getDotPainter:
                                              (spot, percent, bar, index) =>
                                                  FlDotCirclePainter(
                                            radius: 4,
                                            color: AppColors.primary,
                                            strokeWidth: 2,
                                            strokeColor: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _statCard(
      String title, String value, IconData icon, Color color) {
    return Container(
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
                fontFamily: 'Poppins',
              )),
          Text(title,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontFamily: 'Poppins',
              )),
        ],
      ),
    );
  }
}
