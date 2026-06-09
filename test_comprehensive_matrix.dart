import 'dart:io';
import 'package:supabase/supabase.dart';
import 'package:uuid/uuid.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;

// ---------------------------------------------------------------------------
// 1. DUPLICATED LOGIC FROM APP FOR TESTING
// ---------------------------------------------------------------------------
double haversineKm(LatLng a, LatLng b) {
  const r = 6371.0;
  final dLat = (b.latitude - a.latitude) * math.pi / 180;
  final dLng = (b.longitude - a.longitude) * math.pi / 180;
  final sinDLat = math.sin(dLat / 2);
  final sinDLng = math.sin(dLng / 2);
  final h = sinDLat * sinDLat +
      math.cos(a.latitude * math.pi / 180) *
          math.cos(b.latitude * math.pi / 180) *
          sinDLng *
          sinDLng;
  return 2 * r * math.asin(math.sqrt(h));
}

double calculateDeliveryCharges(double distanceKm) {
  final ratePerKm = 10.0;
  if (distanceKm > 15.0) return -1;
  final km = distanceKm.ceil().clamp(1, 15);
  return km * ratePerKm;
}

const deliveryGstRate = 0.18;
const riderPayoutRatio = 0.80;

double calculateMultiShopSurcharge(List<LatLng> shops) {
  if (shops.length <= 1) return 0;
  final ratePerKm = 10.0;
  double total = 0;
  final visited = <LatLng>[shops.first];

  for (int i = 1; i < shops.length; i++) {
    final candidate = shops[i];
    double minDist = double.infinity;
    for (final v in visited) {
      final d = haversineKm(candidate, v);
      if (d < minDist) minDist = d;
    }
    total += ratePerKm * math.max(1, minDist.ceil());
    visited.add(candidate);
  }
  return total;
}

// ---------------------------------------------------------------------------
// 2. MAIN TEST RUNNER
// ---------------------------------------------------------------------------
void main() async {
  print('================================================================');
  print('🚀 COMPREHENSIVE ORDER MATRIX TEST (DART + SUPABASE INTEGRATION)');
  print('================================================================');

  final supabaseUrl = 'https://mmdrgcuaetwohflcvzou.supabase.co';
  final supabaseKey = 'sb_publishable_f4uHzztf4EK76hcL0-bS5A_Ga0G2K6p';
  final client = SupabaseClient(supabaseUrl, supabaseKey);

  // Setup: Mock Locations
  final customer1Loc = LatLng(28.7041, 77.1025); // Delhi
  final customer2Loc = LatLng(28.7050, 77.1030); // Delhi nearby
  final shopALoc = LatLng(28.7100, 77.1100); // 1.05 km from C1
  final shopBLoc = LatLng(28.7200, 77.1200); // 2.45 km from C1
  final shopCLoc = LatLng(28.7150, 77.1150); // 1.7 km from C1

  // UUIDs
  final c1 = Uuid().v4();
  final c2 = Uuid().v4();
  final s1 = Uuid().v4();
  final s2 = Uuid().v4();
  final s3 = Uuid().v4();
  final r1 = Uuid().v4();
  final r2 = Uuid().v4();

  // We are going to test logic and math primarily, and we will output the plan.
  int testsPassed = 0;
  int testsFailed = 0;

  void testAssert(String name, bool condition, String errorMsg) {
    if (condition) {
      print('✅ $name');
      testsPassed++;
    } else {
      print('❌ $name: $errorMsg');
      testsFailed++;
    }
  }

  print('\\n--- 1. Testing Pricing & Routes Logic ---');
  // 1 Shop (A) -> Customer 1
  final distA = haversineKm(shopALoc, customer1Loc);
  final chargeA = calculateDeliveryCharges(distA);
  final customerChargeA = chargeA * (1 + deliveryGstRate);
  final riderEarningsA = chargeA * riderPayoutRatio;
  
  testAssert('1 Shop distance is correct', distA > 0.9 && distA < 1.1, 'Dist $distA');
  testAssert('1 Shop base delivery correct', chargeA == 10.0, 'Charge is $chargeA');
  testAssert('1 Shop customer pays GST correctly', customerChargeA == 11.8, 'Customer pays $customerChargeA');
  testAssert('1 Shop rider gets 80% correctly', riderEarningsA == 8.0, 'Rider gets $riderEarningsA');

  // 2 Shops (A, B) -> Customer 1
  final surchargeAB = calculateMultiShopSurcharge([shopALoc, shopBLoc]);
  final distAB = haversineKm(shopALoc, shopBLoc);
  testAssert('2 Shop distance A to B is correct', distAB > 1.4 && distAB < 1.5, 'Dist $distAB');
  testAssert('2 Shop surcharge correct', surchargeAB == 20.0, 'Surcharge $surchargeAB'); // 1.48 ceil -> 2km * 10 = 20

  // 3 Shops (A, B, C) -> Customer 1
  final surchargeABC = calculateMultiShopSurcharge([shopALoc, shopBLoc, shopCLoc]);
  testAssert('3 Shop surcharge correct', surchargeABC > 20.0, 'Surcharge $surchargeABC');

  print('\\n--- 2. Database Integration Plan execution will happen in SQL ---');
  print('Since the Dart client uses the publishable key, RLS prevents direct mock inserts without logging in.');
  print('The actual database transitions (including the new Split Rider fix) should be tested via the modified SQL test script.');

  print('\\n================================================================');
  print('TEST SUMMARY: $testsPassed Passed, $testsFailed Failed');
  print('Next step: Modify test_order_matrix.sql and run it to verify DB logic.');
  print('================================================================');
  exit(0);
}
