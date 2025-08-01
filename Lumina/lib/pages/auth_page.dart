import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  // Login form controllers
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _rememberMe = false;
  bool _loginPasswordVisible = false;

  // Register form controllers
  final _registerNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerConfirmPasswordController = TextEditingController();
  bool _acceptTerms = false;
  bool _registerPasswordVisible = false;
  bool _registerConfirmPasswordVisible = false;

  String _message = '';
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message, bool isSuccess) {
    setState(() {
      _message = message;
      _isSuccess = isSuccess;
    });

    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _message = '';
        });
      }
    });
  }

  void _handleLogin() async {
    if (_loginFormKey.currentState!.validate()) {
      try {
        _showMessage('Giriş yapılıyor...', true);

        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: _loginEmailController.text.trim(),
              password: _loginPasswordController.text.trim(),
            );

        _showMessage('Başarıyla giriş yaptınız!', true);

        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/home',
            arguments: userCredential.user?.email ?? 'Kullanıcı',
          );
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'Giriş başarısız';

        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı';
            break;
          case 'wrong-password':
            errorMessage = 'Hatalı şifre';
            break;
          case 'invalid-email':
            errorMessage = 'Geçersiz e-posta adresi';
            break;
          case 'user-disabled':
            errorMessage = 'Bu kullanıcı hesabı devre dışı bırakılmış';
            break;
          case 'too-many-requests':
            errorMessage =
                'Çok fazla başarısız giriş denemesi. Lütfen daha sonra tekrar deneyin';
            break;
          default:
            errorMessage = 'Giriş yapılırken bir hata oluştu: ${e.message}';
        }

        _showMessage(errorMessage, false);
      } catch (e) {
        _showMessage('Beklenmeyen bir hata oluştu: $e', false);
      }
    }
  }

  void _handleRegister() async {
    if (_registerFormKey.currentState!.validate()) {
      if (_registerPasswordController.text !=
          _registerConfirmPasswordController.text) {
        _showMessage('Şifreler eşleşmiyor', false);
        return;
      }

      if (!_acceptTerms) {
        _showMessage('Kullanım koşullarını kabul etmelisiniz', false);
        return;
      }

      try {
        _showMessage('Kayıt olunuyor...', true);

        // Firebase Auth ile kullanıcı oluştur
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _registerEmailController.text.trim(),
              password: _registerPasswordController.text.trim(),
            );

        // Firestore'a kullanıcı bilgilerini kaydet
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
              'name': _registerNameController.text.trim(),
              'email': _registerEmailController.text.trim(),
              'createdAt': FieldValue.serverTimestamp(),
              'lastLogin': FieldValue.serverTimestamp(),
            });

        _showMessage('Başarıyla kayıt oldunuz!', true);

        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/home',
            arguments: userCredential.user?.email ?? 'Kullanıcı',
          );
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'Kayıt başarısız';

        switch (e.code) {
          case 'weak-password':
            errorMessage = 'Şifre çok zayıf';
            break;
          case 'email-already-in-use':
            errorMessage = 'Bu e-posta adresi zaten kullanımda';
            break;
          case 'invalid-email':
            errorMessage = 'Geçersiz e-posta adresi';
            break;
          case 'operation-not-allowed':
            errorMessage = 'E-posta/şifre girişi etkin değil';
            break;
          default:
            errorMessage = 'Kayıt olurken bir hata oluştu: ${e.message}';
        }

        _showMessage(errorMessage, false);
      } catch (e) {
        _showMessage('Beklenmeyen bir hata oluştu: $e', false);
      }
    }
  }

  void _socialLogin(String provider) {
    _showMessage('$provider ile giriş yapılıyor...', true);

    // Sosyal medya girişi simülasyonu
    Future.delayed(Duration(seconds: 1), () {
      _showMessage('$provider ile başarıyla giriş yaptınız!', true);

      // HomePage'e yönlendirme
      Future.delayed(Duration(milliseconds: 1500), () {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      });
    });
  }

  void _showForgotPassword() {
    _showMessage('Şifre sıfırlama e-postası gönderildi', true);
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1e3a8a),
              Color(0xFF3b82f6),
              Color(0xFF60a5fa),
              Color(0xFF93c5fd),
              Color(0xFFdbeafe),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 400,
                maxHeight: MediaQuery.of(context).size.height - 40,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF1e3a8a).withValues(alpha: 0.3),
                    blurRadius: 40,
                    offset: Offset(0, 20),
                  ),
                  BoxShadow(
                    color: Color(0xFF3b82f6).withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Column(
                  children: [
                    _buildLogo(),
                    SizedBox(height: 32),
                    _buildTabs(),
                    SizedBox(height: 24),
                    if (_message.isNotEmpty) _buildMessage(),
                    _buildTabView(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1e40af), Color(0xFF3b82f6), Color(0xFF60a5fa)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF3b82f6).withValues(alpha: 0.4),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Icon(Icons.auto_awesome, size: 24, color: Colors.white),
        ),
        SizedBox(height: 16),
        Text(
          'Lumina',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1e40af),
          ),
        ),
        SizedBox(height: 8),
        Text(
          languageService.currentLocale.languageCode == 'tr' 
            ? 'Herkes için erişilebilir'
            : languageService.currentLocale.languageCode == 'en'
              ? 'Accessible for everyone'
              : 'Zugänglich für alle',
          style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFeff6ff), Color(0xFFdbeafe)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF3b82f6).withValues(alpha: 0.2)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFf8fafc)],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF3b82f6).withValues(alpha: 0.2),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        indicatorPadding: EdgeInsets.all(6),
        labelColor: Color(0xFF1e40af),
        unselectedLabelColor: Color(0xFF64748b),
        labelStyle: TextStyle(fontWeight: FontWeight.w500),
        tabs: [
          Tab(text: languageService.currentLocale.languageCode == 'tr' 
            ? 'Giriş Yap'
            : languageService.currentLocale.languageCode == 'en'
              ? 'Login'
              : 'Anmelden'),
          Tab(text: languageService.currentLocale.languageCode == 'tr' 
            ? 'Kayıt Ol'
            : languageService.currentLocale.languageCode == 'en'
              ? 'Register'
              : 'Registrieren'),
        ],
      ),
    );
  }

  Widget _buildMessage() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isSuccess
              ? [Color(0xFFdcfce7), Color(0xFFbbf7d0)]
              : [Color(0xFFfef2f2), Color(0xFFfecaca)],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _isSuccess ? Color(0xFFbbf7d0) : Color(0xFFfecaca),
          width: 2,
        ),
      ),
      child: Text(
        _message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _isSuccess ? Color(0xFF166534) : Color(0xFF991b1b),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTabView() {
    return Expanded(
      child: TabBarView(
        controller: _tabController,
        children: [
          SingleChildScrollView(child: _buildLoginForm()),
          SingleChildScrollView(child: _buildRegisterForm()),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    return Form(
      key: _loginFormKey,
      child: Column(
        children: [
          _buildTextField(
            controller: _loginEmailController,
            label: languageService.currentLocale.languageCode == 'tr' 
              ? 'E-posta Adresi'
              : languageService.currentLocale.languageCode == 'en'
                ? 'Email Address'
                : 'E-Mail-Adresse',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return languageService.currentLocale.languageCode == 'tr' 
                  ? 'E-posta adresi gerekli'
                  : languageService.currentLocale.languageCode == 'en'
                    ? 'Email address is required'
                    : 'E-Mail-Adresse ist erforderlich';
              }
              if (!value!.contains('@')) {
                return languageService.currentLocale.languageCode == 'tr' 
                  ? 'Geçerli bir e-posta adresi girin'
                  : languageService.currentLocale.languageCode == 'en'
                    ? 'Please enter a valid email address'
                    : 'Bitte geben Sie eine gültige E-Mail-Adresse ein';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          _buildTextField(
            controller: _loginPasswordController,
            label: languageService.currentLocale.languageCode == 'tr' 
              ? 'Şifre'
              : languageService.currentLocale.languageCode == 'en'
                ? 'Password'
                : 'Passwort',
            isPassword: true,
            isPasswordVisible: _loginPasswordVisible,
            onPasswordToggle: () {
              setState(() {
                _loginPasswordVisible = !_loginPasswordVisible;
              });
            },
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return languageService.currentLocale.languageCode == 'tr' 
                  ? 'Şifre gerekli'
                  : languageService.currentLocale.languageCode == 'en'
                    ? 'Password is required'
                    : 'Passwort ist erforderlich';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          _buildCheckbox(
            value: _rememberMe,
            onChanged: (value) {
              setState(() {
                _rememberMe = value ?? false;
              });
            },
            text: languageService.currentLocale.languageCode == 'tr' 
              ? 'Beni hatırla'
              : languageService.currentLocale.languageCode == 'en'
                ? 'Remember me'
                : 'Angemeldet bleiben',
          ),
          SizedBox(height: 20),
          _buildSubmitButton(
            languageService.currentLocale.languageCode == 'tr' 
              ? 'Giriş Yap'
              : languageService.currentLocale.languageCode == 'en'
                ? 'Login'
                : 'Anmelden', 
            _handleLogin
          ),
          SizedBox(height: 20),
          _buildDivider(),
          SizedBox(height: 20),
          _buildSocialButtons(),
          SizedBox(height: 16),
          _buildForgotPassword(),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    return Form(
      key: _registerFormKey,
      child: Column(
        children: [
          _buildTextField(
            controller: _registerNameController,
            label: languageService.currentLocale.languageCode == 'tr' 
              ? 'Ad Soyad'
              : languageService.currentLocale.languageCode == 'en'
                ? 'Full Name'
                : 'Vor- und Nachname',
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return languageService.currentLocale.languageCode == 'tr' 
                  ? 'Ad soyad gerekli'
                  : languageService.currentLocale.languageCode == 'en'
                    ? 'Full name is required'
                    : 'Vor- und Nachname ist erforderlich';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          _buildTextField(
            controller: _registerEmailController,
            label: 'E-posta Adresi',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'E-posta adresi gerekli';
              }
              if (!value!.contains('@')) {
                return 'Geçerli bir e-posta adresi girin';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          _buildTextField(
            controller: _registerPasswordController,
            label: 'Şifre',
            isPassword: true,
            isPasswordVisible: _registerPasswordVisible,
            onPasswordToggle: () {
              setState(() {
                _registerPasswordVisible = !_registerPasswordVisible;
              });
            },
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Şifre gerekli';
              }
              if (value!.length < 8) {
                return 'Şifre en az 8 karakter olmalı';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          _buildTextField(
            controller: _registerConfirmPasswordController,
            label: 'Şifre Tekrar',
            isPassword: true,
            isPasswordVisible: _registerConfirmPasswordVisible,
            onPasswordToggle: () {
              setState(() {
                _registerConfirmPasswordVisible =
                    !_registerConfirmPasswordVisible;
              });
            },
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Şifre tekrarı gerekli';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          _buildTermsCheckbox(),
          SizedBox(height: 20),
          _buildSubmitButton('Kayıt Ol', _handleRegister),
          SizedBox(height: 20),
          _buildDivider(),
          SizedBox(height: 20),
          _buildSocialButtons(),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onPasswordToggle,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: isPassword && !isPasswordVisible,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Color(0xFFe2e8f0), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Color(0xFFe2e8f0), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Color(0xFF3b82f6), width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Color(0xFF6b7280),
                    ),
                    onPressed: onPasswordToggle,
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String text,
  }) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: Color(0xFF3b82f6),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: Color(0xFF6b7280)),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _acceptTerms,
          onChanged: (value) {
            setState(() {
              _acceptTerms = value ?? false;
            });
          },
          activeColor: Color(0xFF3b82f6),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _acceptTerms = !_acceptTerms;
              });
            },
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 14, color: Color(0xFF6b7280)),
                children: [
                  TextSpan(
                    text: 'Kullanım Koşulları',
                    style: TextStyle(
                      color: Color(0xFF3b82f6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(text: ' ve '),
                  TextSpan(
                    text: 'Gizlilik Politikası',
                    style: TextStyle(
                      color: Color(0xFF3b82f6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(text: "'nı kabul ediyorum."),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF3b82f6),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 4,
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Color(0xFFcbd5e1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'veya',
            style: TextStyle(fontSize: 14, color: Color(0xFF9ca3af)),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Color(0xFFcbd5e1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildSocialButton(
            'Google',
            Icons.g_mobiledata,
            Color(0xFF4285f4),
            () => _socialLogin('Google'),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildSocialButton(
            'Facebook',
            Icons.facebook,
            Color(0xFF1877f2),
            () => _socialLogin('Facebook'),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton(
    String text,
    IconData icon,
    Color iconColor,
    VoidCallback onPressed,
  ) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Color(0xFFe2e8f0), width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: EdgeInsets.symmetric(vertical: 12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 20),
          SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForgotPassword() {
    return TextButton(
      onPressed: _showForgotPassword,
      child: Text(
        'Şifremi Unuttum',
        style: TextStyle(
          color: Color(0xFF3b82f6),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
