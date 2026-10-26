from pathlib import Path
import re

p = Path(r"lib/views/customer/profile_screen.dart")
t = p.read_text(encoding="utf-8")

old_imports = """import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';"""

new_imports = """import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';"""

if old_imports in t:
    t = t.replace(old_imports, new_imports, 1)

replacement = r'''class _ProfileScreenState extends State<ProfileScreen> {
  void _showLanguageDialog() {
    final locale = Provider.of<LocaleProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            locale.t('Select Language', 'भाषा निवडा'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('मराठी', style: TextStyle(color: AppColors.textPrimary)),
                leading: Icon(
                  locale.isMarathi ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: AppColors.primary,
                ),
                onTap: () async {
                  await locale.setLanguage('mr');
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('English', style: TextStyle(color: AppColors.textPrimary)),
                leading: Icon(
                  locale.isEnglish ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: AppColors.primary,
                ),
                onTap: () async {
                  await locale.setLanguage('en');
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _getRoleLabel(UserRole role, LocaleProvider locale) {
    switch (role) {
      case UserRole.superAdmin:
        return locale.t('Super Admin', 'सुपर अॅडमिन');
      case UserRole.organizer:
        return locale.t('Organizer', 'नाट्य निर्माते');
      default:
        return locale.t('Audience', 'प्रेक्षक');
    }
  }
'''

t2, n = re.subn(
    r"class _ProfileScreenState extends State<ProfileScreen> \{.*?String _getRoleLabel\(UserRole role\) \{.*?^\  \}",
    replacement.rstrip() + "\n",
    t,
    count=1,
    flags=re.S | re.M,
)
print("role_block_replaced", n)
t = t2 if n else t

if "final locale = Provider.of<LocaleProvider>(context);" not in t:
    t = t.replace(
        "final auth = Provider.of<AuthProvider>(context);",
        "final auth = Provider.of<AuthProvider>(context);\n    final locale = Provider.of<LocaleProvider>(context);\n    final s = S(locale);",
        1,
    )

t = t.replace("_getRoleLabel(auth.role)", "_getRoleLabel(auth.role, locale)")
t = t.replace(
    "title: 'भाषा (Language)',\n              subtitle: _selectedLanguage,",
    "title: s.language,\n              subtitle: locale.isMarathi ? 'मराठी' : 'English',",
)

old_appbar = """        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('माझे प्रोफाईल (Profile Hub)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Account, Roles & Preferences',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),"""

new_appbar = """        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.profile, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(
              locale.t('Account & preferences', 'खाते व प्राधान्ये'),
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),"""

if old_appbar in t:
    t = t.replace(old_appbar, new_appbar, 1)
    print("appbar_ok")
else:
    print("appbar_miss")

# remove leftover selected language field if still present
t = t.replace("  String _selectedLanguage = 'मराठी (Marathi)';\n\n", "")

p.write_text(t, encoding="utf-8")
print("done")
