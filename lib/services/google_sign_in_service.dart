import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GoogleSignInService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<UserCredential?> signInWithGoogle() async {
    try {
      // Google Sign-In akışını başlat
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // Kullanıcı giriş yapmaktan vazgeçti
        return null;
      }

      // Google kimlik doğrulama detaylarını al
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Firebase için kimlik bilgisi oluştur
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase ile giriş yap
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      // Yeni kullanıcı ise Firestore'a ekle
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _createUserProfile(userCredential.user!);
      }

      return userCredential;
    } catch (e) {
      print('Google Sign-In Error: $e');
      throw Exception('Google ile giriş yapılırken hata oluştu: $e');
    }
  }

  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
      throw Exception('Çıkış yapılırken hata oluştu: $e');
    }
  }

  static Future<void> _createUserProfile(User user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'email': user.email ?? '',
        'name': user.displayName ?? 'Kullanıcı',
        'age': 25, // Varsayılan değer
        'weight': 70.0, // Varsayılan değer
        'height': 170.0, // Varsayılan değer
        'gender': 'Belirtilmemiş',
        'dietType': 'Dengeli',
        'activityLevel': 'Orta',
        'allergies': '',
        'photoUrl': user.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'loginMethod': 'google',
      });
    } catch (e) {
      print('Error creating user profile: $e');
      throw Exception('Kullanıcı profili oluşturulurken hata oluştu: $e');
    }
  }

  static bool isSignedIn() {
    return _auth.currentUser != null;
  }

  static User? getCurrentUser() {
    return _auth.currentUser;
  }
}
