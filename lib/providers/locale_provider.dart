import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App language: show English OR Marathi — never both in one label.
class LocaleProvider extends ChangeNotifier {
  static const _prefsKey = '@mt_lang';

  String _language = 'mr'; // 'en' | 'mr'

  String get language => _language;
  bool get isMarathi => _language == 'mr';
  bool get isEnglish => _language == 'en';

  LocaleProvider() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved == 'en' || saved == 'mr') {
        _language = saved!;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Locale load: $e');
    }
  }

  Future<void> setLanguage(String code) async {
    if (code != 'en' && code != 'mr') return;
    if (_language == code) return;
    _language = code;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, code);
    } catch (e) {
      debugPrint('Locale save: $e');
    }
  }

  /// Pick one string for the active language (fallback to the other if empty).
  String t(String en, String mr) {
    if (isMarathi) {
      final m = mr.trim();
      return m.isNotEmpty ? m : en;
    }
    final e = en.trim();
    return e.isNotEmpty ? e : mr;
  }
}
