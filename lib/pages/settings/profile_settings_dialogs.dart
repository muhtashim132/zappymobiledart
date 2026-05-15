import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';

// Helper dialogs for Profile Settings Page

void showSavedAddressesDialog(BuildContext context) {
  final auth = context.read<AuthProvider>();
  final user = auth.user;
  if (user == null) return;
  
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) {
      bool isLoading = true;
      bool fetchingLocation = false;
      int selectedIndex = 0; // 0 = Home, 1 = Work
      
      final Map<int, Map<String, TextEditingController>> ctrls = {
        0: {
          'flat': TextEditingController(),
          'address': TextEditingController(),
          'landmark': TextEditingController(),
          'pincode': TextEditingController(),
        },
        1: {
          'flat': TextEditingController(),
          'address': TextEditingController(),
          'landmark': TextEditingController(),
          'pincode': TextEditingController(),
        }
      };

      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          
          if (isLoading) {
            Supabase.instance.client.from('customers').select().eq('id', user.id).maybeSingle().then((data) {
              if (data != null && mounted) {
                final home = data['address_home'] ?? {};
                final work = data['address_work'] ?? {};
                
                ctrls[0]!['flat']!.text = home['flat'] ?? '';
                ctrls[0]!['address']!.text = home['address'] ?? data['default_address'] ?? '';
                ctrls[0]!['landmark']!.text = home['landmark'] ?? data['landmark'] ?? '';
                ctrls[0]!['pincode']!.text = home['pincode'] ?? data['pincode'] ?? '';

                ctrls[1]!['flat']!.text = work['flat'] ?? '';
                ctrls[1]!['address']!.text = work['address'] ?? '';
                ctrls[1]!['landmark']!.text = work['landmark'] ?? '';
                ctrls[1]!['pincode']!.text = work['pincode'] ?? '';
              }
              setState(() => isLoading = false);
            });
            return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
          }

          final currentCtrls = ctrls[selectedIndex]!;

          return Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Saved Addresses', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                
                // Toggle
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => selectedIndex = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selectedIndex == 0 ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: selectedIndex == 0 ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : [],
                            ),
                            child: Center(child: Text('🏠 Home', style: GoogleFonts.outfit(fontWeight: selectedIndex == 0 ? FontWeight.w700 : FontWeight.w500))),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => selectedIndex = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selectedIndex == 1 ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: selectedIndex == 1 ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : [],
                            ),
                            child: Center(child: Text('💼 Work', style: GoogleFonts.outfit(fontWeight: selectedIndex == 1 ? FontWeight.w700 : FontWeight.w500))),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                TextField(
                  controller: currentCtrls['flat'],
                  decoration: const InputDecoration(labelText: 'House / Flat Number', hintText: 'e.g. A-404'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: currentCtrls['address'],
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Delivery Address', hintText: 'Type address or tap 📍'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: fetchingLocation ? null : () async {
                        setState(() => fetchingLocation = true);
                        try {
                          final locProv = context.read<LocationProvider>();
                          bool granted = await locProv.requestLocation();
                          if (granted && context.mounted) {
                            currentCtrls['address']!.text = locProv.currentAddress;
                          }
                        } finally {
                          if (context.mounted) setState(() => fetchingLocation = false);
                        }
                      },
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(color: Theme.of(context).primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                        child: fetchingLocation
                            ? const Padding(padding: EdgeInsets.all(14), child: CircularProgressIndicator(strokeWidth: 2))
                            : Icon(Icons.my_location_rounded, color: Theme.of(context).primaryColor, size: 24),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: currentCtrls['landmark'],
                  decoration: const InputDecoration(labelText: 'Landmark', hintText: 'e.g. Near City Mall'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: currentCtrls['pincode'],
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Pincode', hintText: 'e.g. 400001'),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    final homeMap = {
                      'flat': ctrls[0]!['flat']!.text.trim(),
                      'address': ctrls[0]!['address']!.text.trim(),
                      'landmark': ctrls[0]!['landmark']!.text.trim(),
                      'pincode': ctrls[0]!['pincode']!.text.trim(),
                    };
                    final workMap = {
                      'flat': ctrls[1]!['flat']!.text.trim(),
                      'address': ctrls[1]!['address']!.text.trim(),
                      'landmark': ctrls[1]!['landmark']!.text.trim(),
                      'pincode': ctrls[1]!['pincode']!.text.trim(),
                    };
                    
                    final activeMap = selectedIndex == 0 ? homeMap : workMap;

                    await Supabase.instance.client.from('customers').update({
                      'address_home': homeMap,
                      'address_work': workMap,
                      // Sync the active toggled address to the default fields so the app logic still works seamlessly
                      'default_address': activeMap['address'],
                      'landmark': activeMap['landmark'],
                      'pincode': activeMap['pincode'],
                    }).eq('id', user.id);

                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
                  child: Text('Save & Set as Default ${selectedIndex == 0 ? "Home" : "Work"}'),
                ),
              ],
            ),
          );
        }
      );
    },
  );
}

void showBusinessHoursDialog(BuildContext context) {
  final auth = context.read<AuthProvider>();
  if (auth.currentUserId == null) return;
  
  final openCtrl = TextEditingController(text: '09:00 AM');
  final closeCtrl = TextEditingController(text: '10:00 PM');
  
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Business Hours', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          TextField(controller: openCtrl, decoration: const InputDecoration(labelText: 'Opening Time', hintText: 'e.g. 09:00 AM')),
          const SizedBox(height: 16),
          TextField(controller: closeCtrl, decoration: const InputDecoration(labelText: 'Closing Time', hintText: 'e.g. 10:00 PM')),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              await Supabase.instance.client.from('shops').update({'opening_time': openCtrl.text.trim(), 'closing_time': closeCtrl.text.trim()}).eq('seller_id', auth.currentUserId!);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
            child: const Text('Save Hours'),
          ),
        ],
      ),
    ),
  );
}

void showPayoutSettingsDialog(BuildContext context, String table, String idField) {
  final auth = context.read<AuthProvider>();
  if (auth.currentUserId == null) return;
  
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) {
      return FutureBuilder(
        future: Supabase.instance.client.from(table).select('bank_account_holder, bank_account_number, bank_ifsc').eq(idField, auth.currentUserId!).maybeSingle(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()));
          }
          
          final data = snapshot.data as Map<String, dynamic>? ?? {};
          final holder = data['bank_account_holder'] ?? 'Not set';
          final acc = data['bank_account_number'] ?? 'Not set';
          final ifsc = data['bank_ifsc'] ?? 'Not set';

          return Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bank Details (Payouts)', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'These details were verified during signup and cannot be edited. Please contact support to change your payout settings.',
                          style: GoogleFonts.outfit(fontSize: 12, color: Colors.blue.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(controller: TextEditingController(text: holder), readOnly: true, decoration: const InputDecoration(labelText: 'Account Holder Name', filled: true, fillColor: Color(0xFFF5F5F5))),
                const SizedBox(height: 16),
                TextField(controller: TextEditingController(text: acc), readOnly: true, decoration: const InputDecoration(labelText: 'Account Number', filled: true, fillColor: Color(0xFFF5F5F5))),
                const SizedBox(height: 16),
                TextField(controller: TextEditingController(text: ifsc), readOnly: true, decoration: const InputDecoration(labelText: 'IFSC Code', filled: true, fillColor: Color(0xFFF5F5F5))),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56), backgroundColor: Colors.grey.shade200, foregroundColor: Colors.black87),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        }
      );
    },
  );
}

void showDocumentsDialog(BuildContext context) {
  final auth = context.read<AuthProvider>();
  if (auth.currentUserId == null) return;
  
  final aadharCtrl = TextEditingController();
  final panCtrl = TextEditingController();
  
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('KYC Documents', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          TextField(controller: aadharCtrl, decoration: const InputDecoration(labelText: 'Aadhar Number')),
          const SizedBox(height: 16),
          TextField(controller: panCtrl, decoration: const InputDecoration(labelText: 'PAN/Insurance Number')),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              await Supabase.instance.client.from('delivery_partners').update({
                'aadhar_number': aadharCtrl.text.trim(),
                'insurance_number': panCtrl.text.trim(),
              }).eq('id', auth.currentUserId!);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
            child: const Text('Save Documents'),
          ),
        ],
      ),
    ),
  );
}

void showGenericInfoDialog(BuildContext context, String title, String content) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
      content: Text(content),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))
      ],
    ),
  );
}
