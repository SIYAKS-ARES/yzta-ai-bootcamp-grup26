import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseDebugService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Firebase bağlantısını test et
  static Future<Map<String, dynamic>> testFirebaseConnection() async {
    try {
      // Auth durumunu kontrol et
      User? currentUser = _auth.currentUser;

      // Firestore bağlantısını test et
      await _firestore.collection('test').doc('connection').get();

      return {
        'success': true,
        'authConnected': true,
        'firestoreConnected': true,
        'currentUser': currentUser?.email ?? 'Kullanıcı giriş yapmamış',
        'userId': currentUser?.uid ?? 'Yok',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'authConnected': false,
        'firestoreConnected': false,
      };
    }
  }

  // Kullanıcı listesini getir (sadece debug için)
  static Future<List<Map<String, dynamic>>> getUsersList() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('users').get();
      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['name'] ?? 'İsimsiz',
          'email': data['email'] ?? 'E-posta yok',
          'createdAt': data['createdAt']?.toString() ?? 'Tarih yok',
        };
      }).toList();
    } catch (e) {
      // Kullanıcı listesi alınamadı
      return [];
    }
  }

  // Belirli bir kullanıcıyı kontrol et
  static Future<Map<String, dynamic>> checkUserByEmail(String email) async {
    try {
      // Firestore'da kullanıcıyı ara
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        Map<String, dynamic> userData =
            querySnapshot.docs.first.data() as Map<String, dynamic>;
        return {
          'found': true,
          'userData': userData,
          'userId': querySnapshot.docs.first.id,
        };
      } else {
        return {
          'found': false,
          'message': 'Bu e-posta ile kayıtlı kullanıcı bulunamadı',
        };
      }
    } catch (e) {
      return {'found': false, 'error': e.toString()};
    }
  }

  // Firebase Auth durumunu dinle
  static Stream<User?> getAuthStateChanges() {
    return _auth.authStateChanges();
  }

  // Mevcut kullanıcı bilgilerini getir
  static Map<String, dynamic> getCurrentUserInfo() {
    User? user = _auth.currentUser;
    if (user != null) {
      return {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'emailVerified': user.emailVerified,
        'isAnonymous': user.isAnonymous,
        'metadata': {
          'creationTime': user.metadata.creationTime?.toString(),
          'lastSignInTime': user.metadata.lastSignInTime?.toString(),
        },
      };
    } else {
      return {'message': 'Kullanıcı giriş yapmamış'};
    }
  }

  // Keychain hatası için özel kontrol
  static Future<bool> testKeychainAccess() async {
    try {
      // Basit bir keychain testi
      await _auth.signInAnonymously();
      await _auth.signOut();
      return true;
    } catch (e) {
      // Keychain test hatası
      return false;
    }
  }
}
