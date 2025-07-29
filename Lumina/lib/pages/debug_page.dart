import 'package:flutter/material.dart';
import 'package:lumina/services/firebase_debug_service.dart';

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  Map<String, dynamic> _connectionStatus = {};
  List<Map<String, dynamic>> _usersList = [];
  Map<String, dynamic> _currentUserInfo = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  Future<void> _loadDebugInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Firebase bağlantısını test et
      final connectionResult =
          await FirebaseDebugService.testFirebaseConnection();

      // Kullanıcı listesini getir
      final usersList = await FirebaseDebugService.getUsersList();

      // Mevcut kullanıcı bilgilerini getir
      final currentUserInfo = FirebaseDebugService.getCurrentUserInfo();

      setState(() {
        _connectionStatus = connectionResult;
        _usersList = usersList;
        _currentUserInfo = currentUserInfo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _connectionStatus = {'success': false, 'error': e.toString()};
        _isLoading = false;
      });
    }
  }

  Future<void> _testKeychainAccess() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await FirebaseDebugService.testKeychainAccess();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result ? 'Keychain erişimi başarılı' : 'Keychain erişim hatası',
            ),
            backgroundColor: result ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Keychain test hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Firebase Debug'),
        backgroundColor: Color(0xFF3b82f6),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadDebugInfo),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildConnectionStatus(),
                  SizedBox(height: 20),
                  _buildCurrentUserInfo(),
                  SizedBox(height: 20),
                  _buildKeychainTest(),
                  SizedBox(height: 20),
                  _buildUsersList(),
                ],
              ),
            ),
    );
  }

  Widget _buildConnectionStatus() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Firebase Bağlantı Durumu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            _buildStatusItem(
              'Bağlantı Durumu',
              _connectionStatus['success'] == true ? 'Başarılı' : 'Başarısız',
              _connectionStatus['success'] == true ? Colors.green : Colors.red,
            ),
            _buildStatusItem(
              'Auth Bağlantısı',
              _connectionStatus['authConnected'] == true
                  ? 'Bağlı'
                  : 'Bağlı Değil',
              _connectionStatus['authConnected'] == true
                  ? Colors.green
                  : Colors.red,
            ),
            _buildStatusItem(
              'Firestore Bağlantısı',
              _connectionStatus['firestoreConnected'] == true
                  ? 'Bağlı'
                  : 'Bağlı Değil',
              _connectionStatus['firestoreConnected'] == true
                  ? Colors.green
                  : Colors.red,
            ),
            if (_connectionStatus['error'] != null) ...[
              SizedBox(height: 8),
              Text(
                'Hata: ${_connectionStatus['error']}',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentUserInfo() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mevcut Kullanıcı Bilgileri',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            if (_currentUserInfo['message'] != null)
              Text(_currentUserInfo['message'])
            else ...[
              _buildStatusItem(
                'UID',
                _currentUserInfo['uid'] ?? 'Yok',
                Colors.blue,
              ),
              _buildStatusItem(
                'E-posta',
                _currentUserInfo['email'] ?? 'Yok',
                Colors.blue,
              ),
              _buildStatusItem(
                'Ad Soyad',
                _currentUserInfo['displayName'] ?? 'Yok',
                Colors.blue,
              ),
              _buildStatusItem(
                'E-posta Doğrulandı',
                _currentUserInfo['emailVerified'] == true ? 'Evet' : 'Hayır',
                _currentUserInfo['emailVerified'] == true
                    ? Colors.green
                    : Colors.orange,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildKeychainTest() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Keychain Test',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Keychain erişimini test etmek için aşağıdaki butona tıklayın:',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: _testKeychainAccess,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF3b82f6),
                foregroundColor: Colors.white,
              ),
              child: Text('Keychain Erişimini Test Et'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersList() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kayıtlı Kullanıcılar (${_usersList.length})',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            if (_usersList.isEmpty)
              Text('Henüz kayıtlı kullanıcı yok')
            else
              ...(_usersList.map((user) => _buildUserItem(user)).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildUserItem(Map<String, dynamic> user) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ad: ${user['name']}',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          Text('E-posta: ${user['email']}'),
          Text('ID: ${user['id']}'),
          Text('Kayıt Tarihi: ${user['createdAt']}'),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}
