import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  String? _pendingPhone; // Phone waiting for OTP verification
  String? _mockUserId;   // ID used for magic numbers

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  String? get currentUserId => _supabase.auth.currentUser?.id ?? _mockUserId;
  String? get pendingPhone => _pendingPhone;

  AuthProvider() {
    _init();
  }

  void _init() {
    _supabase.auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.signedIn) {
        _fetchProfile();
      } else if (event.event == AuthChangeEvent.signedOut) {
        _user = null;
        _mockUserId = null;
        _pendingPhone = null;
        notifyListeners();
      }
    });
    if (_supabase.auth.currentUser != null) {
      _fetchProfile();
    }
  }

  // ─── Detect all roles for a given userId ────────────────────────────────
  /// Returns list of roles the user has already signed up for.
  Future<List<String>> _detectUserRoles(String userId) async {
    final roles = <String>[];
    try {
      final customer = await _supabase
          .from('customers')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      if (customer != null) roles.add('customer');
    } catch (_) {}

    try {
      final seller = await _supabase
          .from('shops')
          .select('seller_id')
          .eq('seller_id', userId)
          .maybeSingle();
      if (seller != null) roles.add('seller');
    } catch (_) {}

    try {
      final delivery = await _supabase
          .from('delivery_partners')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      if (delivery != null) roles.add('delivery_partner');
    } catch (_) {}

    return roles;
  }

  Future<void> _fetchProfile({String? preferredRole}) async {
    try {
      final userId = _supabase.auth.currentUser?.id ?? _mockUserId;
      if (userId == null) return;

      final response =
          await _supabase.from('profiles').select().eq('id', userId).single();

      final Map<String, dynamic> data = Map<String, dynamic>.from(response);
      if (!data.containsKey('full_name') && data.containsKey('name')) {
        data['full_name'] = data['name'];
      }

      // Detect all roles across role-specific tables
      final allRoles = await _detectUserRoles(userId);
      // If no roles detected yet, fall back to the profiles.role value
      if (allRoles.isEmpty) allRoles.add(data['role'] ?? 'customer');

      final primaryRole = data['role'] ?? 'customer';
      // Prefer the requested role if valid, otherwise use primary
      final sessionRole = (preferredRole != null && allRoles.contains(preferredRole))
          ? preferredRole
          : primaryRole;

      _user = UserModel.fromMap({
        ...data,
        'email': _supabase.auth.currentUser?.email ?? '',
        'phone': _supabase.auth.currentUser?.phone ?? data['phone'] ?? '',
        'activeRoles': allRoles,
        'activeSessionRole': sessionRole,
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Profile fetch error: $e');
    }
  }

  /// Switch the active session role (user must already be registered for that role).
  void switchSessionRole(String role) {
    if (_user == null) return;
    if (!_user!.activeRoles.contains(role)) return;
    _user = _user!.copyWith(activeSessionRole: role);
    notifyListeners();
  }

  // ─── OTP Auth (Phone) ────────────────────────────────────────────────────

  /// Step 1: Send OTP to phone number (e.g. +911234567890)
  Future<String?> sendPhoneOtp(String phone) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Mock bypass for testing
    if (phone.contains('1111111111') ||
        phone.contains('2222222222') ||
        phone.contains('3333333333')) {
      _pendingPhone = phone;
      _isLoading = false;
      notifyListeners();
      return null;
    }

    try {
      await _supabase.auth.signInWithOtp(phone: phone);
      _pendingPhone = phone;
      _isLoading = false;
      notifyListeners();
      return null;
    } on AuthException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Could not send OTP. Please check the number and try again.';
    }
    _isLoading = false;
    notifyListeners();
    return _error;
  }

  /// Step 2: Verify OTP.
  /// Returns:
  ///   'existing' — user has a profile (may have multiple roles)
  ///   'new'      — no profile yet, needs role selection + setup
  ///   null       — error (check [error])
  Future<String?> verifyPhoneOtp(String phone, String otp,
      {String? preferredRole}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // ─── Magic Number Bypass ────────────────────────────────────────────────
    if (phone.contains('1111111111') ||
        phone.contains('2222222222') ||
        phone.contains('3333333333')) {
      await Future.delayed(const Duration(seconds: 1));

      String mockId =
          '00000000-0000-0000-0000-${phone.replaceAll("+", "").padLeft(12, "0")}';
      _mockUserId = mockId;

      final existing = await _supabase
          .from('profiles')
          .select('id, role')
          .eq('id', mockId)
          .maybeSingle();

      _isLoading = false;
      notifyListeners();

      if (existing != null) {
        await _fetchProfile(preferredRole: preferredRole);
        return 'existing';
      }
      return 'new';
    }
    // ─────────────────────────────────────────────────────────────────────────

    try {
      final response = await _supabase.auth.verifyOTP(
        phone: phone,
        token: otp,
        type: OtpType.sms,
      );

      if (response.user == null) {
        _error = 'Invalid OTP. Please try again.';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      final existing = await _supabase
          .from('profiles')
          .select('id, role')
          .eq('id', response.user!.id)
          .maybeSingle();

      _isLoading = false;
      notifyListeners();

      if (existing != null) {
        await _fetchProfile(preferredRole: preferredRole);
        return 'existing';
      }
      return 'new';
    } on AuthException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Verification failed. Please try again.';
    }
    _isLoading = false;
    notifyListeners();
    return null;
  }

  // ─── Create / Update Profile ─────────────────────────────────────────────
  /// One phone user can have ONE profile row AND also independent rows in
  /// sellers/customers/delivery_partners. This method upserts both.
  Future<String?> createProfile({
    required String fullName,
    required String role,
    Map<String, dynamic>? additionalData,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id ??
          '00000000-0000-0000-0000-${_pendingPhone?.replaceAll("+", "").padLeft(12, "0") ?? "000000000001"}';
      final phone = _supabase.auth.currentUser?.phone ?? _pendingPhone ?? '';

      // Upsert into profiles (uses onConflict:'id' to avoid 42P10 error)
      try {
        await _supabase.from('profiles').upsert(
          {
            'id': userId,
            'role': role,
            'full_name': fullName,
            'phone': phone,
          },
          onConflict: 'id',
        );
      } catch (profileError) {
        final s = profileError.toString();
        if (s.contains('full_name') || s.contains('PGRST204')) {
          await _supabase.from('profiles').upsert(
            {
              'id': userId,
              'role': role,
              'name': fullName,
              'phone': phone,
            },
            onConflict: 'id',
          );
        } else {
          rethrow;
        }
      }

      // Insert role-specific record — each is independent so same user can
      // have multiple rows across tables.
      if (role == 'customer') {
        final existing = await _supabase
            .from('customers')
            .select('id')
            .eq('id', userId)
            .maybeSingle();
        if (existing == null) {
          await _supabase.from('customers').insert({
            'id': userId,
            if (additionalData != null) ...additionalData,
          });
        } else if (additionalData != null) {
          await _supabase
              .from('customers')
              .update(additionalData)
              .eq('id', userId);
        }
      } else if (role == 'seller') {
        final existing = await _supabase
            .from('shops')
            .select('id')
            .eq('seller_id', userId)
            .maybeSingle();
        if (existing == null) {
          await _supabase.from('shops').insert({
            'seller_id': userId,
            if (additionalData != null) ...additionalData,
          });
        } else if (additionalData != null) {
          await _supabase
              .from('shops')
              .update(additionalData)
              .eq('seller_id', userId);
        }
      } else if (role == 'delivery_partner') {
        final existing = await _supabase
            .from('delivery_partners')
            .select('id')
            .eq('id', userId)
            .maybeSingle();
        if (existing == null) {
          await _supabase.from('delivery_partners').insert({
            'id': userId,
            if (additionalData != null) ...additionalData,
          });
        } else if (additionalData != null) {
          await _supabase
              .from('delivery_partners')
              .update(additionalData)
              .eq('id', userId);
        }
      }

      await _fetchProfile(preferredRole: role);
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _error = 'Profile setup failed: ${e.toString()}';
    }
    _isLoading = false;
    notifyListeners();
    return _error;
  }

  // ─── Legacy Email Auth ───────────────────────────────────────────────────
  Future<String?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
    Map<String, dynamic>? additionalData,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'role': role, 'phone': phone},
      );
      if (response.user != null) {
        await createProfile(
            fullName: fullName, role: role, additionalData: additionalData);
        _isLoading = false;
        notifyListeners();
        return null;
      }
      _error = 'Registration failed.';
    } on AuthException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Registration failed: ${e.toString()}';
    }
    _isLoading = false;
    notifyListeners();
    return _error;
  }

  Future<String?> signIn(
      {required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
      await _fetchProfile();
      _isLoading = false;
      notifyListeners();
      return null;
    } on AuthException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Login failed.';
    }
    _isLoading = false;
    notifyListeners();
    return _error;
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (_) {}
    _user = null;
    _pendingPhone = null;
    _mockUserId = null;
    notifyListeners();
  }
}
