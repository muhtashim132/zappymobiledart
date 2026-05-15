import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class RidersAdminPage extends StatefulWidget {
  const RidersAdminPage({super.key});

  @override
  State<RidersAdminPage> createState() => _RidersAdminPageState();
}

class _RidersAdminPageState extends State<RidersAdminPage> {
  final _db = Supabase.instance.client;
  List<Map<String, dynamic>> _riders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchRiders();
  }

  Future<void> _fetchRiders() async {
    try {
      final res = await _db.from('delivery_partners').select('*, profiles:id(full_name, phone, avatar_url)').order('created_at', ascending: false).limit(100);
      setState(() {
        _riders = List<Map<String, dynamic>>.from(res);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleStatus(String riderId, bool currentStatus) async {
    try {
      await _db.from('delivery_partners').update({'is_active': !currentStatus}).eq('id', riderId);
      _fetchRiders();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B2FC9)))
        : _riders.isEmpty
            ? Center(child: Text('No riders found', style: GoogleFonts.outfit(color: Colors.white54)))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _riders.length,
                itemBuilder: (context, index) {
                  final rider = _riders[index];
                  final profile = rider['profiles'] ?? {};
                  final isActive = rider['is_active'] == true;
                  final isOnline = rider['is_online'] == true;
                  final createdAt = rider['created_at'] != null ? DateFormat('MMM dd, yyyy').format(DateTime.parse(rider['created_at'])) : 'Unknown';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.07)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFF00BCD4).withOpacity(0.2),
                          backgroundImage: profile['avatar_url'] != null ? NetworkImage(profile['avatar_url']) : null,
                          child: profile['avatar_url'] == null ? const Icon(Icons.delivery_dining_rounded, color: Color(0xFF00BCD4)) : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(profile['full_name'] ?? 'Unknown Rider', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              Text(profile['phone'] ?? rider['vehicle_number'] ?? 'No contact info', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: isOnline ? Colors.green : Colors.grey,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(isOnline ? 'Online' : 'Offline', style: GoogleFonts.outfit(color: isOnline ? Colors.green : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 16),
                                  Icon(Icons.directions_bike_rounded, color: Colors.white38, size: 12),
                                  const SizedBox(width: 4),
                                  Text('${rider['total_deliveries'] ?? 0} deliveries', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            Switch(
                              value: isActive,
                              onChanged: (v) => _toggleStatus(rider['id'], isActive),
                              activeColor: const Color(0xFF00BCD4),
                            ),
                            Text(isActive ? 'Active' : 'Suspended', style: GoogleFonts.outfit(color: isActive ? Colors.green : Colors.red, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
  }
}
