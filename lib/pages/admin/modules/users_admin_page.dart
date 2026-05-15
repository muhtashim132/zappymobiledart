import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class UsersAdminPage extends StatefulWidget {
  const UsersAdminPage({super.key});

  @override
  State<UsersAdminPage> createState() => _UsersAdminPageState();
}

class _UsersAdminPageState extends State<UsersAdminPage> {
  final _db = Supabase.instance.client;
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final res = await _db.from('profiles').select().order('created_at', ascending: false).limit(100);
      setState(() {
        _users = List<Map<String, dynamic>>.from(res);
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
        : _users.isEmpty
            ? Center(child: Text('No users found', style: GoogleFonts.outfit(color: Colors.white54)))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  final createdAt = user['created_at'] != null ? DateFormat('MMM dd, yyyy').format(DateTime.parse(user['created_at'])) : 'Unknown';

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
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFF2196F3).withOpacity(0.2),
                          backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
                          child: user['avatar_url'] == null ? const Icon(Icons.person_rounded, color: Color(0xFF2196F3)) : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user['full_name'] ?? user['name'] ?? 'Unknown User', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              Text(user['email'] ?? user['phone'] ?? 'No contact info', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded, color: Colors.white38, size: 12),
                                  const SizedBox(width: 4),
                                  Text('Joined $createdAt', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text((user['role'] ?? 'Customer').toUpperCase(), style: GoogleFonts.outfit(color: const Color(0xFF2196F3), fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  );
                },
              );
  }
}
