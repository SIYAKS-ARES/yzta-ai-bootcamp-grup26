import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isEditing = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Firestore'dan kullanıcı bilgilerini al
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            _nameController.text = data['name'] ?? '';
            _surnameController.text = data['surname'] ?? '';
            _emailController.text = user.email ?? '';
            _passwordController.text = "••••••••";
            _isLoading = false;
          });
        } else {
          // Eğer Firestore'da veri yoksa varsayılan değerler
          setState(() {
            _nameController.text =
                user.displayName?.split(' ').first ?? 'Kullanıcı';
            _surnameController.text = user.displayName?.split(' ').last ?? '';
            _emailController.text = user.email ?? '';
            _passwordController.text = "••••••••";
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        final languageService = Provider.of<LanguageService>(
          context,
          listen: false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${languageService.getText('load_error')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Düzenleme modundan çıkırken şifreyi gizle
        _passwordController.text = "••••••••";
        _isPasswordVisible = false;
      }
    });
  }

  Future<void> _saveChanges() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Firestore'da kullanıcı bilgilerini güncelle
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': _nameController.text.trim(),
          'surname': _surnameController.text.trim(),
          'email': _emailController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Şifre değişikliği varsa
        if (_passwordController.text != "••••••••" &&
            _passwordController.text.isNotEmpty) {
          await user.updatePassword(_passwordController.text);

          // Firestore'da şifreyi güncelle
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'password': _passwordController.text});
        }

        if (mounted) {
          final languageService = Provider.of<LanguageService>(
            context,
            listen: false,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(languageService.getText('info_updated')),
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
          _toggleEdit();
        }
      }
    } catch (e) {
      if (mounted) {
        final languageService = Provider.of<LanguageService>(
          context,
          listen: false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${languageService.getText('update_error')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteAccountDialog() {
    final languageService = Provider.of<LanguageService>(
      context,
      listen: false,
    );
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            languageService.getText('delete_account'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(languageService.getText('delete_account_confirm')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                languageService.currentLocale.languageCode == 'tr'
                    ? "Hayır"
                    : languageService.currentLocale.languageCode == 'en'
                    ? "No"
                    : "Nein",
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    // Firestore'dan kullanıcı verilerini sil
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .delete();

                    // Firebase Auth'dan hesabı sil
                    await user.delete();

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          languageService.currentLocale.languageCode == 'tr'
                              ? "Hesabınız başarıyla silindi!"
                              : languageService.currentLocale.languageCode ==
                                    'en'
                              ? "Your account has been successfully deleted!"
                              : "Ihr Konto wurde erfolgreich gelöscht!",
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );

                    // Giriş sayfasına yönlendir
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/', (route) => false);
                  }
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        languageService.currentLocale.languageCode == 'tr'
                            ? "Hesap silme hatası: $e"
                            : languageService.currentLocale.languageCode ==
                                  'en'
                            ? "Account deletion error: $e"
                            : "Kontolöschungsfehler: $e",
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(
                languageService.currentLocale.languageCode == 'tr'
                    ? 'Evet'
                    : languageService.currentLocale.languageCode == 'en'
                    ? 'Yes'
                    : 'Ja',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF2563EB);
    final Color softBlue = const Color(0xFF60A5FA);
    final Color cardBG = Colors.white;
    final languageService = Provider.of<LanguageService>(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(languageService.getText('profile')),
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryBlue, softBlue],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  languageService.getText('loading'),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(languageService.getText('profile')),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryBlue, softBlue],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Sayfa başlığı
            Container(
              padding: const EdgeInsets.all(18),
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: cardBG,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text('👤', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Text(
                    languageService.getText('profile_info'),
                    style: TextStyle(
                      color: primaryBlue,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _toggleEdit,
                    icon: Icon(
                      _isEditing ? Icons.close : Icons.edit,
                      color: primaryBlue,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: primaryBlue.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Profil formu
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBG,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Profil avatarı
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: primaryBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: primaryBlue.withValues(alpha: 0.2),
                        width: 3,
                      ),
                    ),
                    child: Icon(Icons.person, size: 50, color: primaryBlue),
                  ),
                  const SizedBox(height: 20),

                  // Ad
                  _buildInputField(
                    label: languageService.getText('name'),
                    controller: _nameController,
                    icon: Icons.person_outline,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 16),

                  // Soyad
                  _buildInputField(
                    label: languageService.getText('surname'),
                    controller: _surnameController,
                    icon: Icons.person_outline,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 16),

                  // E-posta
                  _buildInputField(
                    label: languageService.getText('email'),
                    controller: _emailController,
                    icon: Icons.email_outlined,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 16),

                  // Şifre
                  _buildPasswordField(),
                  const SizedBox(height: 24),

                  // Kaydet butonu
                  if (_isEditing)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: Text(
                          languageService.getText('save_changes'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Hesap yönetimi
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBG,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    languageService.currentLocale.languageCode == 'tr'
                        ? "Hesap Yönetimi"
                        : languageService.currentLocale.languageCode == 'en'
                        ? "Account Management"
                        : "Kontoverwaltung",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Hesabı sil
                  _buildActionTile(
                    icon: Icons.delete_outline,
                    title: languageService.getText('delete_account'),
                    subtitle: languageService.currentLocale.languageCode == 'tr'
                        ? "Tüm verileriniz kalıcı olarak silinir"
                        : languageService.currentLocale.languageCode == 'en'
                        ? "All your data will be permanently deleted"
                        : "Alle Ihre Daten werden dauerhaft gelöscht",
                    onTap: _showDeleteAccountDialog,
                    isDestructive: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool enabled,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.blueGrey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          style: TextStyle(
            fontSize: 16,
            color: enabled ? Colors.black : Colors.blueGrey[600],
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF2563EB)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E7FF)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E7FF)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blueGrey[200]!),
            ),
            filled: true,
            fillColor: enabled ? Colors.white : Colors.blueGrey[50],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    final languageService = Provider.of<LanguageService>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          languageService.getText('password'),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.blueGrey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          enabled: _isEditing,
          obscureText: !_isPasswordVisible && _isEditing,
          style: TextStyle(
            fontSize: 16,
            color: _isEditing ? Colors.black : Colors.blueGrey[600],
          ),
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.lock_outline,
              color: Color(0xFF2563EB),
            ),
            suffixIcon: _isEditing
                ? IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: const Color(0xFF2563EB),
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E7FF)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E7FF)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blueGrey[200]!),
            ),
            filled: true,
            fillColor: _isEditing ? Colors.white : Colors.blueGrey[50],
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDestructive
                    ? Colors.red.withValues(alpha: 0.1)
                    : const Color(0xFF2563EB).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red : const Color(0xFF2563EB),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: isDestructive ? Colors.red : Colors.blueGrey[800],
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.blueGrey[600]),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.blueGrey[400],
            ),
          ],
        ),
      ),
    );
  }
}
