import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static Future<void> init() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      // Fallback if .env cannot be loaded
    }
  }

  static String get appName => dotenv.get('NEXT_PUBLIC_APP_NAME', fallback: 'MahaTicket');
  static String get defaultCity => dotenv.get('NEXT_PUBLIC_DEFAULT_CITY', fallback: 'Pune');

  static String get supabaseUrl => dotenv.get(
        'NEXT_PUBLIC_SUPABASE_URL',
        fallback: 'https://hnseawulngdxbvltmthe.supabase.co',
      );

  static String get supabaseAnonKey => dotenv.get(
        'NEXT_PUBLIC_SUPABASE_ANON_KEY',
        fallback:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhuc2Vhd3VsbmdkeGJ2bHRtdGhlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA3MDc5NjIsImV4cCI6MjEwNjI4Mzk2Mn0.Jk1k0ZPMpldURgv37Hq1OfTjSY45GBcZ21qT_74SK9o',
      );

  static String get supabaseServiceRoleKey => dotenv.get(
        'SUPABASE_SERVICE_ROLE_KEY',
        fallback:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhuc2Vhd3VsbmdkeGJ2bHRtdGhlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc5MDcwNzk2MiwiZXhwIjoyMTA2MjgzOTYyfQ.elGt4aVj4BEn3cAv7VW3QnKXJGVH3sh68XDRhmnivOA',
      );

  static String get razorpayKeyId => dotenv.get(
        'RAZORPAY_KEY_ID',
        fallback: 'rzp_test_Tqadzif5eTC5UB',
      );

  static String get razorpayKeySecret => dotenv.get(
        'RAZORPAY_KEY_SECRET',
        fallback: 'RLTu386XAyW7T5G6nZh0Twh2',
      );

  static String get ticketSecret => dotenv.get(
        'TICKET_SECRET',
        fallback: 'mahaticket_secure_signing_key_2026',
      );

  static String get adminPassword => dotenv.get(
        'ADMIN_PASSWORD',
        fallback: 'Admin2026',
      );
}
