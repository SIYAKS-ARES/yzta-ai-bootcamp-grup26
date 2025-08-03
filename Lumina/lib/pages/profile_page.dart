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

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isEditing = false;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
      _animationController.forward();
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
              backgroundColor: const Color(0xFF1e40af),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFFfef2f2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.warning_rounded,
                  color: Color(0xFFdc2626),
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Text(
                languageService.getText('delete_account'),
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
            ],
          ),
          content: Text(
            languageService.getText('delete_account_confirm'),
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                languageService.currentLocale.languageCode == 'tr'
                    ? "Hayır"
                    : languageService.currentLocale.languageCode == 'en'
                    ? "No"
                    : "Nein",
                style: TextStyle(
                  color: Color(0xFF6b7280),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final currentContext = context;
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

                    if (currentContext.mounted) {
                      final currentLanguageService =
                          Provider.of<LanguageService>(
                            currentContext,
                            listen: false,
                          );
                      ScaffoldMessenger.of(currentContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            currentLanguageService.currentLocale.languageCode ==
                                    'tr'
                                ? "Hesabınız başarıyla silindi!"
                                : currentLanguageService
                                          .currentLocale
                                          .languageCode ==
                                      'en'
                                ? "Your account has been successfully deleted!"
                                : "Ihr Konto wurde erfolgreich gelöscht!",
                          ),
                          backgroundColor: Color(0xFF16a34a),
                        ),
                      );
                    }

                    // Giriş sayfasına yönlendir
                    if (currentContext.mounted) {
                      Navigator.of(
                        currentContext,
                      ).pushNamedAndRemoveUntil('/', (route) => false);
                    }
                  }
                } catch (e) {
                  if (currentContext.mounted) {
                    final currentLanguageService = Provider.of<LanguageService>(
                      currentContext,
                      listen: false,
                    );
                    ScaffoldMessenger.of(currentContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          currentLanguageService.currentLocale.languageCode ==
                                  'tr'
                              ? "Hesap silme hatası: $e"
                              : currentLanguageService
                                        .currentLocale
                                        .languageCode ==
                                    'en'
                              ? "Account deletion error: $e"
                              : "Kontolöschungsfehler: $e",
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFdc2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Builder(
                builder: (context) {
                  final currentLanguageService = Provider.of<LanguageService>(
                    context,
                    listen: false,
                  );
                  return Text(
                    currentLanguageService.currentLocale.languageCode == 'tr'
                        ? 'Evet'
                        : currentLanguageService.currentLocale.languageCode ==
                              'en'
                        ? 'Yes'
                        : 'Ja',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF1e40af);
    final Color softBlue = const Color(0xFF3b82f6);
    final Color lightBlue = const Color(0xFF60a5fa);
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
              colors: [
                primaryBlue,
                softBlue,
                lightBlue,
                Color(0xFF93c5fd),
                Color(0xFFdbeafe),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  languageService.getText('loading'),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
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
            colors: [
              primaryBlue,
              softBlue,
              lightBlue,
              Color(0xFF93c5fd),
              Color(0xFFdbeafe),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Profil başlığı
              Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cardBG.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: softBlue.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryBlue, softBlue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        languageService.getText('profile_info'),
                        style: TextStyle(
                          color: primaryBlue,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: _isEditing
                            ? Color(0xFFdc2626).withValues(alpha: 0.1)
                            : primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: _toggleEdit,
                        icon: Icon(
                          _isEditing ? Icons.close_rounded : Icons.edit_rounded,
                          color: _isEditing ? Color(0xFFdc2626) : primaryBlue,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Profil formu
              Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cardBG.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Profil avatarı
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryBlue, softBlue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Ad
                    _buildInputField(
                      label: languageService.getText('name'),
                      controller: _nameController,
                      icon: Icons.person_outline_rounded,
                      enabled: _isEditing,
                    ),
                    const SizedBox(height: 16),

                    // Soyad
                    _buildInputField(
                      label: languageService.getText('surname'),
                      controller: _surnameController,
                      icon: Icons.person_outline_rounded,
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
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF3b82f6), Color(0xFF1d4ed8)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF3b82f6).withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            languageService.getText('save_changes'),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Hesap yönetimi
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardBG.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFdbeafe), Color(0xFFbfdbfe)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.settings_rounded,
                            color: Color(0xFF1e40af),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          languageService.currentLocale.languageCode == 'tr'
                              ? "Hesap Yönetimi"
                              : languageService.currentLocale.languageCode ==
                                    'en'
                              ? "Account Management"
                              : "Kontoverwaltung",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: Color(0xFF1f2937),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Hesabı sil
                    _buildActionTile(
                      icon: Icons.delete_forever_rounded,
                      title: languageService.getText('delete_account'),
                      subtitle:
                          languageService.currentLocale.languageCode == 'tr'
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
            color: Color(0xFF374151),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF3b82f6).withValues(alpha: 0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            style: TextStyle(
              fontSize: 16,
              color: enabled ? Color(0xFF1f2937) : Color(0xFF6b7280),
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Color(0xFF3b82f6), size: 22),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFFe5e7eb), width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFF3b82f6), width: 2),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFFd1d5db), width: 1.5),
              ),
              filled: true,
              fillColor: enabled ? Colors.white : Color(0xFFf9fafb),
            ),
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
            color: Color(0xFF374151),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF3b82f6).withValues(alpha: 0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _passwordController,
            enabled: _isEditing,
            obscureText: !_isPasswordVisible && _isEditing,
            style: TextStyle(
              fontSize: 16,
              color: _isEditing ? Color(0xFF1f2937) : Color(0xFF6b7280),
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.lock_outline_rounded,
                color: Color(0xFF3b82f6),
                size: 22,
              ),
              suffixIcon: _isEditing
                  ? IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: Color(0xFF6b7280),
                        size: 22,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                      style: IconButton.styleFrom(
                        padding: EdgeInsets.all(8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFFe5e7eb), width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFF3b82f6), width: 2),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFFd1d5db), width: 1.5),
              ),
              filled: true,
              fillColor: _isEditing ? Colors.white : Color(0xFFf9fafb),
            ),
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
    return Container(
      decoration: BoxDecoration(
        color: isDestructive ? Color(0xFFfef2f2) : Color(0xFFf8fafc),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDestructive ? Color(0xFFfecaca) : Color(0xFFe2e8f0),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? Color(0xFFfecaca)
                        : Color(0xFFdbeafe),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isDestructive
                        ? Color(0xFFdc2626)
                        : Color(0xFF3b82f6),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: isDestructive
                              ? Color(0xFFdc2626)
                              : Color(0xFF1f2937),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6b7280),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Color(0xFF9ca3af),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
