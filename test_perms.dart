import 'package:supabase/supabase.dart';

void main() async {
  final supabaseUrl = 'https://mmdrgcuaetwohflcvzou.supabase.co';
  final supabaseKey = 'sb_publishable_f4uHzztf4EK76hcL0-bS5A_Ga0G2K6p';
  final client = SupabaseClient(supabaseUrl, supabaseKey);

  final res = await client.auth.signInWithPassword(
    email: '9999999992@auth.enything.app',
    password: 'Enything9999999992#Auth2025'
  );
  
  if (res.user != null) {
    print('Logged in as ${res.user!.id}');
    try {
      final data = await client.from('delivery_partners').select('vehicle_type, vehicle_reg_number').eq('id', res.user!.id).maybeSingle();
      print('Vehicle Data: $data');
    } catch (e) {
      print('Vehicle Data Error: $e');
    }

    try {
      final data = await client.from('delivery_partners').select('aadhar_number, pan_number, driving_license').eq('id', res.user!.id).maybeSingle();
      print('Docs Data: $data');
    } catch (e) {
      print('Docs Data Error: $e');
    }
  } else {
    print('Login failed');
  }
}
