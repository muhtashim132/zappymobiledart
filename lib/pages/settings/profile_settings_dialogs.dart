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
  
  final addrCtrl = TextEditingController();
  final pincodeCtrl = TextEditingController();
  
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) {
      bool fetchingLocation = false;
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Saved Addresses', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: addrCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Default Delivery Address', hintText: 'Type address or tap 📍'),
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
                            addrCtrl.text = locProv.currentAddress;
                          }
                        } finally {
                          if (context.mounted) {
                            setState(() => fetchingLocation = false);
                          }
                        }
                      },
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: fetchingLocation
                            ? const Padding(padding: EdgeInsets.all(14), child: CircularProgressIndicator(strokeWidth: 2))
                            : Icon(Icons.my_location_rounded, color: Theme.of(context).primaryColor, size: 24),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pincodeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Pincode', hintText: 'e.g. 400001'),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    await Supabase.instance.client.from('customers').update({
                      'default_address': addrCtrl.text.trim(),
                      'pincode': pincodeCtrl.text.trim(),
                    }).eq('id', user.id);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
                  child: const Text('Save Address'),
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
  
  final accCtrl = TextEditingController();
  final ifscCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  
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
          Text('Bank Details (Payouts)', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Account Holder Name')),
          const SizedBox(height: 16),
          TextField(controller: accCtrl, decoration: const InputDecoration(labelText: 'Account Number'), keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          TextField(controller: ifscCtrl, decoration: const InputDecoration(labelText: 'IFSC Code')),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              await Supabase.instance.client.from(table).update({
                'bank_account_holder': nameCtrl.text.trim(),
                'bank_account_number': accCtrl.text.trim(),
                'bank_ifsc': ifscCtrl.text.trim(),
              }).eq(idField, auth.currentUserId!);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
            child: const Text('Save Bank Details'),
          ),
        ],
      ),
    ),
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
