import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/services/supabase_service.dart';

enum UserRole {
  customer,
  organizer,
  superAdmin,
}

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _client = SupabaseService().client;

  UserRole _role = UserRole.customer;
  String _userName = '';
  String _userEmail = '';
  String _userPhone = '';
  String? _userId;
  int? _dbUserId;
  bool _isLoading = false;
  String? _authError;

  StreamSubscription<AuthState>? _authSubscription;

  UserRole get role => _role;
  String get userName => _userName.isNotEmpty ? _userName : (_userEmail.isNotEmpty ? _userEmail.split('@').first : 'Guest User');
  String get userEmail => _userEmail;
  String get userPhone => _userPhone;
  String? get userId => _userId;
  int? get dbUserId => _dbUserId;
  bool get isLoggedIn => _client.auth.currentUser != null;
  bool get isLoading => _isLoading;
  String? get authError => _authError;

  bool get isCustomer => _role == UserRole.customer;
  bool get isOrganizer => _role == UserRole.organizer;
  bool get isSuperAdmin => _role == UserRole.superAdmin;

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    // 1. Check existing session
    final currentSession = _client.auth.currentSession;
    if (currentSession != null) {
      _handleUserAuthenticated(currentSession.user);
    }

    // 2. Listen to real-time auth state changes
    _authSubscription = _client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        _handleUserAuthenticated(session.user);
      } else {
        _handleUserSignedOut();
      }
    });
  }

  Future<void> _handleUserAuthenticated(User user) async {
    _userId = user.id;
    _userEmail = user.email ?? '';
    _userName = user.userMetadata?['full_name']?.toString() ??
        user.userMetadata?['name']?.toString() ??
        _userEmail.split('@').first;
    _userPhone = user.phone ?? '';

    // Authoritative role lookup from public.users table
    await refreshProfile();
    notifyListeners();
  }

  void _handleUserSignedOut() {
    _userId = null;
    _dbUserId = null;
    _userEmail = '';
    _userName = '';
    _userPhone = '';
    _role = UserRole.customer;
    _authError = null;
    notifyListeners();
  }

  /// Authoritatively fetches user profile and role from the public.users database table.
  /// Local client state is never trusted for privilege elevation.
  Future<void> refreshProfile() async {
    final supaUser = _client.auth.currentUser;
    if (supaUser == null) return;

    try {
      final rows = await _client
          .from('users')
          .select('id, uid, email, full_name, phone_number, role, status')
          .or('uid.eq.${supaUser.id},email.eq.${supaUser.email}')
          .limit(1);

      if ((rows as List).isNotEmpty) {
        final profile = rows.first;
        _dbUserId = profile['id'] as int?;
        if (profile['full_name'] != null && profile['full_name'].toString().isNotEmpty) {
          _userName = profile['full_name'].toString();
        }
        if (profile['phone_number'] != null && profile['phone_number'].toString().isNotEmpty) {
          _userPhone = profile['phone_number'].toString();
        }

        final authoritativeRole = profile['role']?.toString().toLowerCase();
        if (authoritativeRole == 'super_admin' || authoritativeRole == 'admin') {
          _role = UserRole.superAdmin;
        } else if (authoritativeRole == 'organizer') {
          _role = UserRole.organizer;
        } else {
          _role = UserRole.customer;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading authoritative user profile: $e');
    }
  }

  /// Sign In with Email & Password
  Future<bool> signInWithPassword({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      _isLoading = false;
      if (response.user != null) {
        await _handleUserAuthenticated(response.user!);
        return true;
      }
      return false;
    } catch (e) {
      _isLoading = false;
      _authError = e.toString().replaceAll('AuthException:', '').trim();
      notifyListeners();
      return false;
    }
  }

  /// Sign Up with Email, Password & Full Name
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
          if (phone != null && phone.isNotEmpty) 'phone': phone.trim(),
        },
      );

      _isLoading = false;
      if (response.user != null) {
        await _handleUserAuthenticated(response.user!);
        return true;
      }
      return false;
    } catch (e) {
      _isLoading = false;
      _authError = e.toString().replaceAll('AuthException:', '').trim();
      notifyListeners();
      return false;
    }
  }

  /// Sign In with Magic Link / OTP
  Future<bool> signInWithOtp({required String email}) async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    try {
      await _client.auth.signInWithOtp(email: email.trim());
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _authError = e.toString().replaceAll('AuthException:', '').trim();
      notifyListeners();
      return false;
    }
  }

  /// Verify OTP token
  Future<bool> verifyOtp({
    required String email,
    required String token,
  }) async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    try {
      final response = await _client.auth.verifyOTP(
        email: email.trim(),
        token: token.trim(),
        type: OtpType.magiclink,
      );

      _isLoading = false;
      if (response.user != null) {
        await _handleUserAuthenticated(response.user!);
        return true;
      }
      return false;
    } catch (e) {
      _isLoading = false;
      _authError = e.toString().replaceAll('AuthException:', '').trim();
      notifyListeners();
      return false;
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      debugPrint('Signout error: $e');
    }
    _handleUserSignedOut();
  }

  /// Update Profile Details
  Future<bool> updateProfile({
    required String name,
    required String phone,
  }) async {
    final supaUser = _client.auth.currentUser;
    if (supaUser == null) return false;

    try {
      _userName = name;
      _userPhone = phone;

      await _client.from('users').update({
        'full_name': name,
        'phone_number': phone,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('email', _userEmail);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
