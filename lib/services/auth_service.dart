import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Di Web, kita butuh clientId. Di Android, kita butuh serverClientId.
    clientId: kIsWeb ? '950683922466-m5l920riqqpav4mkfhsgcqilnllv4ofh.apps.googleusercontent.com' : null,
    serverClientId: '950683922466-m5l920riqqpav4mkfhsgcqilnllv4ofh.apps.googleusercontent.com',
  );

  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => _auth.currentUser != null && !(_auth.currentUser!.isAnonymous);
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signInWithGoogle() async {
    try {
      debugPrint('AuthService: Starting Google Sign-In...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('AuthService: User cancelled the sign-in dialog.');
        return null;
      }

      debugPrint('AuthService: Google Sign-In account obtained: ${googleUser.email}');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential result = await _auth.signInWithCredential(credential);
      debugPrint('AuthService: Firebase Sign-In successful for ${result.user?.email}');
      return result.user;
    } catch (e) {
      debugPrint('AuthService: ERROR during Google Sign-In: $e');
      if (e.toString().contains('10')) {
        debugPrint('AuthService: Error 10 detected. This usually means SHA-1 mismatch or missing Support Email in Firebase Console.');
      }
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      debugPrint('AuthService: Signed out');
    } catch (e) {
      debugPrint('AuthService: Sign out failed: $e');
    }
  }
}
