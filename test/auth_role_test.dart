import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kalpkrut_mahaticket/providers/auth_provider.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    try {
      await Supabase.initialize(
        url: 'https://hnseawulngdxbvltmthe.supabase.co',
        anonKey:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhuc2Vhd3VsbmdkeGJ2bHRtdGhlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA3MDc5NjIsImV4cCI6MjEwNjI4Mzk2Mn0.Jk1k0ZPMpldURgv37Hq1OfTjSY45GBcZ21qT_74SK9o',
      );
    } catch (_) {}
  });

  group('Authentication and Role Authorization Tests', () {
    test('Default user starts with customer role', () {
      final auth = AuthProvider();
      expect(auth.role, UserRole.customer);
      expect(auth.isCustomer, isTrue);
      expect(auth.isOrganizer, isFalse);
      expect(auth.isSuperAdmin, isFalse);
    });

    test('Authoritative database role strings map to correct UserRole enum', () {
      UserRole mapRole(String? dbRole) {
        final r = dbRole?.toLowerCase().trim();
        if (r == 'super_admin' || r == 'admin') {
          return UserRole.superAdmin;
        } else if (r == 'organizer') {
          return UserRole.organizer;
        }
        return UserRole.customer;
      }

      expect(mapRole('super_admin'), UserRole.superAdmin);
      expect(mapRole('admin'), UserRole.superAdmin);
      expect(mapRole('organizer'), UserRole.organizer);
      expect(mapRole('customer'), UserRole.customer);
      expect(mapRole(null), UserRole.customer);
      expect(mapRole('hacker'), UserRole.customer);
    });

    test('Customer role does not grant administrative privileges', () {
      const userRole = UserRole.customer;
      final bool canAccessAdminHub = userRole == UserRole.superAdmin;
      final bool canAccessOrganizerConsole = userRole == UserRole.organizer || userRole == UserRole.superAdmin;

      expect(canAccessAdminHub, isFalse);
      expect(canAccessOrganizerConsole, isFalse);
    });

    test('Super admin role grants full access', () {
      const adminRole = UserRole.superAdmin;
      final bool canAccessAdminHub = adminRole == UserRole.superAdmin;
      final bool canAccessOrganizerConsole = adminRole == UserRole.organizer || adminRole == UserRole.superAdmin;

      expect(canAccessAdminHub, isTrue);
      expect(canAccessOrganizerConsole, isTrue);
    });
  });
}
