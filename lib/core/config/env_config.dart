import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    // Prefer client-only env (no service-role / payment secrets). Fall back to .env for local dev.
    try {
      await dotenv.load(fileName: '.env.client');
    } catch (_) {
      try {
        await dotenv.load(fileName: '.env');
      } catch (e) {
        // Production web / --dart-define may omit dotenv files entirely.
        debugPrint('dotenv loading note: $e');
      }
    }
    _initialized = true;
  }

  /// App name
  static String get appName =>
      _resolve('NEXT_PUBLIC_APP_NAME', defaultValue: 'MahaTicket');

  /// Default city
  static String get defaultCity =>
      _resolve('NEXT_PUBLIC_DEFAULT_CITY', defaultValue: 'Pune');

  /// Supabase project URL (Client-safe public URL)
  static String get supabaseUrl =>
      _resolve('NEXT_PUBLIC_SUPABASE_URL', defaultValue: 'https://hnseawulngdxbvltmthe.supabase.co');

  /// Supabase public anonymous publishable key
  static String get supabaseAnonKey =>
      _resolve('NEXT_PUBLIC_SUPABASE_ANON_KEY', defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhuc2Vhd3VsbmdkeGJ2bHRtdGhlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA3MDc5NjIsImV4cCI6MjEwNjI4Mzk2Mn0.Jk1k0ZPMpldURgv37Hq1OfTjSY45GBcZ21qT_74SK9o');

  /// Razorpay Public Key ID (Client-safe key used for checkout modal)
  static String get razorpayKeyId =>
      _resolve('NEXT_PUBLIC_RAZORPAY_KEY_ID', defaultValue: _resolve('RAZORPAY_KEY_ID', defaultValue: 'rzp_test_Tqadzif5eTC5UB'));

  /// Authoritative Next.js API base (TicketGhar payment / PDF / email).
  /// Localhost APP_URL is remapped to production — Flutter clients cannot reach host loopback reliably.
  static String get apiBaseUrl {
    final raw = _resolve(
      'NEXT_PUBLIC_API_BASE',
      defaultValue: _resolve(
        'APP_URL',
        defaultValue: 'https://mahaticket.kalpkrutinfotech.com',
      ),
    ).trim().replaceAll(RegExp(r'/+$'), '');

    if (raw.isEmpty ||
        raw.contains('localhost') ||
        raw.contains('127.0.0.1')) {
      return 'https://mahaticket.kalpkrutinfotech.com';
    }
    return raw;
  }

  /// Helper to resolve from Dart environment definition (--dart-define) or dotenv
  static String _resolve(String key, {String defaultValue = ''}) {
    // 1. Try --dart-define compile-time variable
    final fromDefine = String.fromEnvironment(key);
    if (fromDefine.isNotEmpty) return fromDefine;

    // 2. Try dotenv if loaded
    try {
      if (dotenv.isInitialized && dotenv.isEveryDefined([key])) {
        final val = dotenv.get(key);
        if (val.isNotEmpty) return val;
      }
    } catch (_) {}

    // 3. Fallback default
    return defaultValue;
  }

  /// Check if essential client configuration is present
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Throws StateError if mandatory config is missing, failing fast safely
  static void validate() {
    if (!isConfigured) {
      throw StateError(
        'Critical configuration missing! Please provide NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY.',
      );
    }
  }
}
