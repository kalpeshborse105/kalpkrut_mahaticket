import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/config/env_config.dart';
import 'core/theme/app_theme.dart';
import 'data/services/supabase_service.dart';
import 'providers/events_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/admin_provider.dart';
import 'views/customer/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize environment configuration (.env)
  await EnvConfig.init();

  // 2. Initialize Supabase Real-Time Client
  await SupabaseService.init();

  runApp(const MahaTicketApp());
}

class MahaTicketApp extends StatelessWidget {
  const MahaTicketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EventsProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: MaterialApp(
        title: 'MahaTicket (महाटिकिट)',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
