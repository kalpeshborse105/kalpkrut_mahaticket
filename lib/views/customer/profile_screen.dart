import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../admin/admin_dashboard_screen.dart';
import '../admin/organizer_console_screen.dart';
import '../admin/qr_gate_scanner_screen.dart';
import 'my_tickets_screen.dart';
import 'post_event_screen.dart';
import 'help_support_screen.dart';
import 'policy_viewer_screen.dart';
import 'auth_bottom_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _selectedLanguage = 'मराठी (Marathi)';

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'भाषा निवडा (Select Language)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('मराठी (Marathi)'),
                leading: Icon(
                  _selectedLanguage.startsWith('मराठी')
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: AppColors.primary,
                ),
                onTap: () {
                  setState(() => _selectedLanguage = 'मराठी (Marathi)');
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('English'),
                leading: Icon(
                  _selectedLanguage.startsWith('English')
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: AppColors.primary,
                ),
                onTap: () {
                  setState(() => _selectedLanguage = 'English');
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return 'सुपर अ‍ॅडमिन (Super Admin)';
      case UserRole.organizer:
        return 'नाट्य निर्माते (Organizer)';
      default:
        return 'प्रेक्षक (Audience)';
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return AppColors.neonGreen;
      case UserRole.organizer:
        return AppColors.gold;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('माझे प्रोफाईल (Profile Hub)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Account, Roles & Preferences',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // User Card or Guest Sign-In Banner
            if (!auth.isLoggedIn)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withAlpha(40),
                      AppColors.surface,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withAlpha(80)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(30),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 1.5),
                          ),
                          child: const Icon(Icons.person_outline, color: AppColors.primary, size: 28),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'महातिकिट मध्ये स्वागत आहे!',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'तिकिटे बुक करण्यासाठी व सेव्ह करण्यासाठी लॉग इन करा.',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.login, color: Colors.black, size: 18),
                        label: const Text(
                          'प्रवेश करा / नोंदणी करा (Sign In / Sign Up)',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        onPressed: () => AuthBottomSheet.show(context),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.surface, AppColors.surfaceLight],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: _getRoleColor(auth.role).withAlpha(40),
                            shape: BoxShape.circle,
                            border: Border.all(color: _getRoleColor(auth.role), width: 2),
                          ),
                          child: Center(
                            child: Text(
                              auth.userName.isNotEmpty ? auth.userName[0].toUpperCase() : 'U',
                              style: TextStyle(
                                color: _getRoleColor(auth.role),
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                auth.userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: Colors.white,
                                ),
                              ),
                              if (auth.userPhone.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  auth.userPhone,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 2),
                              Text(
                                auth.userEmail,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.verified_user, size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              _getRoleLabel(auth.role),
                              style: TextStyle(
                                color: _getRoleColor(auth.role),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                          icon: const Icon(Icons.logout, size: 16),
                          label: const Text(
                            'बाहेर पडा (Sign Out)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: AppColors.surface,
                                title: const Text('बाहेर पडायचे आहे का? (Sign Out)'),
                                content: const Text('Are you sure you want to sign out of MahaTicket?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('रद्द करा (Cancel)'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Sign Out'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await auth.signOut();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Navigation Sections
            _buildSectionHeader('बुकिंग्ज व पासेस (Bookings)'),
            _buildMenuItem(
              icon: Icons.confirmation_number_outlined,
              title: 'माझे तिकीट (My Bookings)',
              subtitle: 'View upcoming & past show tickets',
              color: AppColors.primary,
              onTap: () {
                if (!auth.isLoggedIn) {
                  AuthBottomSheet.show(context);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyTicketsScreen()),
                  );
                }
              },
            ),

            const SizedBox(height: 16),
            _buildSectionHeader('निर्माते व इव्हेंट व्यवस्थापन (Organizers)'),
            _buildMenuItem(
              icon: Icons.theater_comedy,
              title: 'नाटक / कार्यक्रम जोडा (Partner With Us)',
              subtitle: 'List your drama play or event on MahaTicket',
              color: AppColors.gold,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PostEventScreen()),
                );
              },
            ),

            if (auth.isOrganizer || auth.isSuperAdmin) ...[
              const SizedBox(height: 8),
              _buildMenuItem(
                icon: Icons.business_center,
                title: 'निर्माते कन्सोल (Organizer Console)',
                subtitle: 'View ticket sales GMV, commission & settlements',
                color: Colors.orangeAccent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OrganizerConsoleScreen()),
                  );
                },
              ),
            ],

            if (auth.isSuperAdmin) ...[
              const SizedBox(height: 16),
              _buildSectionHeader('सुपर अ‍ॅडमिनिस्ट्रेशन (Admin Controls)'),
              _buildMenuItem(
                icon: Icons.admin_panel_settings,
                title: 'महाटिकिट कंट्रोल हब (Admin Hub)',
                subtitle: 'Master dashboard, venues, orders, coupons & scrapers',
                color: AppColors.neonGreen,
                badge: 'ADMIN ACCESS',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildMenuItem(
                icon: Icons.qr_code_scanner,
                title: 'गेट क्यूआर स्कॅनर (Gate Pass Scanner)',
                subtitle: 'Real-time ticket validation & entry check',
                color: AppColors.cyan,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QrGateScannerScreen()),
                  );
                },
              ),
            ],

            const SizedBox(height: 16),
            _buildSectionHeader('अ‍ॅप प्राधान्ये व सहाय्य (Preferences & Support)'),
            _buildMenuItem(
              icon: Icons.language,
              title: 'भाषा (Language)',
              subtitle: _selectedLanguage,
              color: AppColors.cyan,
              onTap: _showLanguageDialog,
            ),
            const SizedBox(height: 8),
            _buildMenuItem(
              icon: Icons.support_agent,
              title: 'मदत व ग्राहक सेवा (Help & Support)',
              subtitle: 'WhatsApp concierge, phone desk & FAQs',
              color: AppColors.primary,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                );
              },
            ),
            const SizedBox(height: 8),
            _buildMenuItem(
              icon: Icons.policy_outlined,
              title: 'अटी, गोपनीयता व परतावा धोरण (Policies)',
              subtitle: 'Terms of Service, Privacy & Cancellation rules',
              color: AppColors.textSecondary,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PolicyViewerScreen()),
                );
              },
            ),

            const SizedBox(height: 32),

            // App Footer
            Column(
              children: [
                const Text(
                  'महाटिकिट (MahaTicket) v1.0.22',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Build 23 • com.kalpkrutinfotech.mahaticket',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                const SizedBox(height: 6),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Crafted with ',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    Icon(Icons.favorite, color: AppColors.primary, size: 14),
                    Text(' for Maharashtra Theatre Culture',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    String? badge,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Colors.white10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withAlpha(30),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                color: color,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
