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

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _selectedLanguage = 'मराठी (Marathi)';

  String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return 'super_admin';
      case UserRole.organizer:
        return 'organizer';
      default:
        return 'customer';
    }
  }

  UserRole _stringToRole(String role) {
    switch (role) {
      case 'super_admin':
        return UserRole.superAdmin;
      case 'organizer':
        return UserRole.organizer;
      default:
        return UserRole.customer;
    }
  }

  void _showRoleSwitcherDialog() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final pinController = TextEditingController();
    String tempRole = _roleToString(auth.role);
    String? errorMessage;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('भूमिका बदला (Switch Role)', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select account operating mode:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => setDialogState(() {
                      tempRole = 'customer';
                      errorMessage = null;
                    }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            tempRole == 'customer' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          const Text('प्रेक्षक / ग्राहक (Customer / Audience)', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => setDialogState(() {
                      tempRole = 'organizer';
                      errorMessage = null;
                    }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            tempRole == 'organizer' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            color: AppColors.gold,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          const Text('नाट्य निर्माते व आयोजक (Organizer)', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => setDialogState(() {
                      tempRole = 'super_admin';
                      errorMessage = null;
                    }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            tempRole == 'super_admin' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            color: AppColors.neonGreen,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          const Text('सुपर अ‍ॅडमिन (Super Admin)', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                  if (tempRole == 'super_admin') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: pinController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Admin PIN Passcode',
                        hintText: 'Enter Admin PIN (Admin2026)',
                        errorText: errorMessage,
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('रद्द करा (Cancel)', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () async {
                    if (tempRole == 'super_admin') {
                      if (pinController.text.trim() != 'Admin2026') {
                        setDialogState(() {
                          errorMessage = 'चुकीचा पिन! (Invalid PIN - use Admin2026)';
                        });
                        return;
                      }
                    }

                    final success = await auth.switchRole(
                      _stringToRole(tempRole),
                      adminPin: pinController.text.trim(),
                    );
                    if (dialogCtx.mounted) {
                      Navigator.pop(dialogCtx);
                    }
                    if (!mounted) return;
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('भूमिका बदलली: ${_getRoleLabel(tempRole)}')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('भूमिका बदलता आली नाही (Failed to switch role)')),
                      );
                    }
                  },
                  child: const Text('लागू करा (Apply)'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('भाषा निवडा (Select Language)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('मराठी (Marathi)'),
                leading: Icon(
                  _selectedLanguage.startsWith('मराठी') ? Icons.radio_button_checked : Icons.radio_button_unchecked,
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
                  _selectedLanguage.startsWith('English') ? Icons.radio_button_checked : Icons.radio_button_unchecked,
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

  String _getRoleLabel(String role) {
    switch (role) {
      case 'super_admin':
        return 'सुपर अ‍ॅडमिन (Super Admin)';
      case 'organizer':
        return 'नाट्य निर्माते (Organizer)';
      default:
        return 'प्रेक्षक (Audience)';
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'super_admin':
        return AppColors.neonGreen;
      case 'organizer':
        return AppColors.gold;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final currentRoleStr = _roleToString(auth.role);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('माझे प्रोफाईल (Profile Hub)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Account, Roles & Preferences', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // User Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
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
                          color: _getRoleColor(currentRoleStr).withAlpha(40),
                          shape: BoxShape.circle,
                          border: Border.all(color: _getRoleColor(currentRoleStr), width: 2),
                        ),
                        child: Center(
                          child: Text(
                            auth.userName.isNotEmpty ? auth.userName[0].toUpperCase() : 'U',
                            style: TextStyle(
                              color: _getRoleColor(currentRoleStr),
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
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              auth.userPhone,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              auth.userEmail,
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
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
                            _getRoleLabel(currentRoleStr),
                            style: TextStyle(
                              color: _getRoleColor(currentRoleStr),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                        icon: const Icon(Icons.sync_alt, size: 16),
                        label: const Text('Switch Role', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        onPressed: _showRoleSwitcherDialog,
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
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MyTicketsScreen()));
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
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PostEventScreen()));
              },
            ),
            const SizedBox(height: 8),
            _buildMenuItem(
              icon: Icons.business_center,
              title: 'निर्माते कन्सोल (Organizer Console)',
              subtitle: 'View ticket sales GMV, commission & settlements',
              color: Colors.orangeAccent,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const OrganizerConsoleScreen()));
              },
            ),

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
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
                },
              ),
              const SizedBox(height: 8),
              _buildMenuItem(
                icon: Icons.qr_code_scanner,
                title: 'गेट क्यूआर स्कॅनर (Gate Pass Scanner)',
                subtitle: 'Real-time ticket validation & entry check',
                color: AppColors.cyan,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const QrGateScannerScreen()));
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
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
              },
            ),
            const SizedBox(height: 8),
            _buildMenuItem(
              icon: Icons.policy_outlined,
              title: 'अटी, गोपनीयता व परतावा धोरण (Policies)',
              subtitle: 'Terms of Service, Privacy & Cancellation rules',
              color: AppColors.textSecondary,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PolicyViewerScreen()));
              },
            ),

            const SizedBox(height: 32),

            // App Footer
            Column(
              children: [
                const Text(
                  'महाटिकिट (MahaTicket) v1.0.21',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Build 22 • com.kalpkrutinfotech.mahaticket',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Crafted with ', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    const Icon(Icons.favorite, color: AppColors.primary, size: 14),
                    const Text(' for Maharashtra Theatre Culture', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
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
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMuted),
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
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
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
                              style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
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
