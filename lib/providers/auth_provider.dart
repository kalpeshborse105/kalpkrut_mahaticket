import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UserRole {
  customer,
  organizer,
  superAdmin,
}

class AuthProvider extends ChangeNotifier {
  UserRole _role = UserRole.customer;
  String _userName = 'कल्पेश बोरसे (Kalpesh)';
  String _userEmail = 'kalpeshborse105@gmail.com';
  String _userPhone = '+91 98765 43210';
  final bool _isLoggedIn = true;

  UserRole get role => _role;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get userPhone => _userPhone;
  bool get isLoggedIn => _isLoggedIn;

  bool get isCustomer => _role == UserRole.customer;
  bool get isOrganizer => _role == UserRole.organizer;
  bool get isSuperAdmin => _role == UserRole.superAdmin;

  AuthProvider() {
    _loadUserSession();
  }

  Future<void> _loadUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedRole = prefs.getString('user_role') ?? 'customer';
      _userName = prefs.getString('user_name') ?? _userName;
      _userEmail = prefs.getString('user_email') ?? _userEmail;
      _userPhone = prefs.getString('user_phone') ?? _userPhone;

      switch (savedRole) {
        case 'super_admin':
          _role = UserRole.superAdmin;
          break;
        case 'organizer':
          _role = UserRole.organizer;
          break;
        default:
          _role = UserRole.customer;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user session: $e');
    }
  }

  Future<bool> switchRole(UserRole newRole, {String? adminPin}) async {
    if (newRole == UserRole.superAdmin) {
      if (adminPin != 'Admin2026') {
        return false;
      }
    }

    _role = newRole;
    final prefs = await SharedPreferences.getInstance();
    String roleStr = 'customer';
    if (_role == UserRole.superAdmin) roleStr = 'super_admin';
    if (_role == UserRole.organizer) roleStr = 'organizer';
    await prefs.setString('user_role', roleStr);

    notifyListeners();
    return true;
  }

  void updateProfile({required String name, required String email, required String phone}) async {
    _userName = name;
    _userEmail = email;
    _userPhone = phone;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_email', email);
    await prefs.setString('user_phone', phone);
    notifyListeners();
  }
}
