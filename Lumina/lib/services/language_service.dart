import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';

  Locale _currentLocale = const Locale('tr', 'TR');

  Locale get currentLocale => _currentLocale;

  final Map<String, Locale> supportedLocales = {
    'Türkçe': const Locale('tr', 'TR'),
    'English': const Locale('en', 'US'),
    'Deutsch': const Locale('de', 'DE'),
  };

  final Map<String, Map<String, String>> translations = {
    'tr': {
      'settings': 'Ayarlar',
      'profile': 'Profil',
      'language': 'Uygulama Dili',
      'notifications': 'Bildirimleri Aç',
      'dark_theme': 'Koyu Tema',
      'privacy_policy': 'Gizlilik Politikası',
      'help_support': 'Yardım ve Destek',
      'logout': 'Çıkış Yap',
      'save_changes': 'Değişiklikleri Kaydet',
      'cancel': 'İptal',
      'ok': 'Tamam',
      'loading': 'Yükleniyor...',
      'error': 'Hata',
      'success': 'Başarılı',
      'welcome': 'Hoş geldiniz',
      'profile_info': 'Profil Bilgilerim',
      'name': 'Ad',
      'surname': 'Soyad',
      'email': 'E-posta',
      'password': 'Şifre',
      'delete_account': 'Hesabı Sil',
      'delete_account_confirm':
          'Hesabınızı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
      'account_deleted': 'Hesap silme işlemi başlatıldı',
      'info_updated': 'Bilgiler başarıyla güncellendi!',
      'update_error': 'Güncelleme sırasında hata',
      'load_error': 'Kullanıcı bilgileri yüklenirken hata',
    },
    'en': {
      'settings': 'Settings',
      'profile': 'Profile',
      'language': 'Application Language',
      'notifications': 'Enable Notifications',
      'dark_theme': 'Dark Theme',
      'privacy_policy': 'Privacy Policy',
      'help_support': 'Help & Support',
      'logout': 'Logout',
      'save_changes': 'Save Changes',
      'cancel': 'Cancel',
      'ok': 'OK',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'welcome': 'Welcome',
      'profile_info': 'My Profile Information',
      'name': 'Name',
      'surname': 'Surname',
      'email': 'Email',
      'password': 'Password',
      'delete_account': 'Delete Account',
      'delete_account_confirm':
          'Are you sure you want to delete your account? This action cannot be undone.',
      'account_deleted': 'Account deletion initiated',
      'info_updated': 'Information updated successfully!',
      'update_error': 'Error during update',
      'load_error': 'Error loading user information',
    },
    'de': {
      'settings': 'Einstellungen',
      'profile': 'Profil',
      'language': 'Anwendungssprache',
      'notifications': 'Benachrichtigungen aktivieren',
      'dark_theme': 'Dunkles Thema',
      'privacy_policy': 'Datenschutzrichtlinie',
      'help_support': 'Hilfe & Support',
      'logout': 'Abmelden',
      'save_changes': 'Änderungen speichern',
      'cancel': 'Abbrechen',
      'ok': 'OK',
      'loading': 'Laden...',
      'error': 'Fehler',
      'success': 'Erfolg',
      'welcome': 'Willkommen',
      'profile_info': 'Meine Profilinformationen',
      'name': 'Name',
      'surname': 'Nachname',
      'email': 'E-Mail',
      'password': 'Passwort',
      'delete_account': 'Konto löschen',
      'delete_account_confirm':
          'Sind Sie sicher, dass Sie Ihr Konto löschen möchten? Diese Aktion kann nicht rückgängig gemacht werden.',
      'account_deleted': 'Kontolöschung eingeleitet',
      'info_updated': 'Informationen erfolgreich aktualisiert!',
      'update_error': 'Fehler beim Aktualisieren',
      'load_error': 'Fehler beim Laden der Benutzerinformationen',
    },
  };

  String getText(String key) {
    final currentLang = _currentLocale.languageCode;
    return translations[currentLang]?[key] ?? key;
  }

  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey);

    if (languageCode != null) {
      final locale = supportedLocales.values.firstWhere(
        (locale) => locale.languageCode == languageCode,
        orElse: () => const Locale('tr', 'TR'),
      );
      _currentLocale = locale;
      notifyListeners();
    }
  }

  Future<void> changeLanguage(String languageName) async {
    final newLocale = supportedLocales[languageName];
    if (newLocale != null) {
      _currentLocale = newLocale;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, newLocale.languageCode);

      notifyListeners();
    }
  }
}
