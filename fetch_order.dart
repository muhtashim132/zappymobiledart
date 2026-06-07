import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final supabaseUrl = 'https://mmdrgcuaetwohflcvzou.supabase.co';
  final supabaseKey = 'sb_publishable_f4uHzztf4EK76hcL0-bS5A_Ga0G2K6p';
  final adminEmail = 'admin@enything.app';
  final adminPass = 'admin123';

  try {
    // 1. Sign in
    final authResp = await http.post(
      Uri.parse('\$supabaseUrl/auth/v1/token?grant_type=password'),
      headers: {
        'apikey': supabaseKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': adminEmail,
        'password': adminPass,
      }),
    );

    if (authResp.statusCode != 200) {
      print('Auth failed: \${authResp.body}');
      return;
    }

    final token = jsonDecode(authResp.body)['access_token'];

    // 2. Fetch order
    final queryResp = await http.get(
      Uri.parse('\$supabaseUrl/rest/v1/orders?id=ilike.1e741942%'),
      headers: {
        'apikey': supabaseKey,
        'Authorization': 'Bearer \$token',
      },
    );

    print('Orders: \${queryResp.body}');
  } catch (e) {
    print('Error: \$e');
  }
}
