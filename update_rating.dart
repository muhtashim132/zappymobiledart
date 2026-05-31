import 'package:supabase_client/supabase_client.dart';

void main() async {
  final supabase = SupabaseClient('https://mmdrgcuaetwohflcvzou.supabase.co', 'sb_publishable_f4uHzztf4EK76hcL0-bS5A_Ga0G2K6p');
  try {
    final response = await supabase.from('products').update({'rating': 0.0}).eq('name', 'Test').select();
    print('Updated product: $response');
  } catch (e) {
    print('Error: $e');
  }
}
