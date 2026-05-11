import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AuthServiceException implements Exception {
  final String message;
  final String? code;

  const AuthServiceException(this.message, {this.code});

  @override
  String toString() => message;
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _webClientId =
      '950683922466-psqrm6shpqeo71qf1b3kt7j100c9utld.apps.googleusercontent.com';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? _webClientId : null,
    serverClientId: _webClientId,
    scopes: <String>['email', 'profile'],
  );

  User? get currentUser => _auth.currentUser;
  bool get isSignedIn =>
      _auth.currentUser != null && !(_auth.currentUser!.isAnonymous);
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signInWithGoogle() async {
    try {
      debugPrint('AuthService: Starting Google Sign-In...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('AuthService: User cancelled the sign-in dialog.');
        return null;
      }

      debugPrint(
          'AuthService: Google Sign-In account obtained: ${googleUser.email}');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.isAnonymous) {
        try {
          final linkedResult = await currentUser.linkWithCredential(credential);
          debugPrint(
              'AuthService: Anonymous account linked to ${linkedResult.user?.email}');
          return linkedResult.user;
        } on FirebaseAuthException catch (e) {
          if (!_shouldFallbackToSignIn(e.code)) {
            rethrow;
          }
          debugPrint(
              'AuthService: Google credential already exists, signing in instead.');
        }
      }

      final UserCredential result =
          await _auth.signInWithCredential(credential);
      debugPrint(
          'AuthService: Firebase Sign-In successful for ${result.user?.email}');
      return result.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService: FirebaseAuthException during Google Sign-In: '
          '${e.code} ${e.message}');
      throw AuthServiceException(
        _friendlyFirebaseAuthMessage(e),
        code: e.code,
      );
    } on PlatformException catch (e) {
      debugPrint('AuthService: PlatformException during Google Sign-In: '
          '${e.code} ${e.message}');
      throw AuthServiceException(
        _friendlyPlatformMessage(e),
        code: e.code,
      );
    } catch (e) {
      debugPrint('AuthService: ERROR during Google Sign-In: $e');
      throw const AuthServiceException(
        'Login Google gagal. Coba lagi beberapa saat lagi.',
      );
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

  bool _shouldFallbackToSignIn(String code) {
    return code == 'credential-already-in-use' ||
        code == 'email-already-in-use' ||
        code == 'provider-already-linked';
  }

  String _friendlyFirebaseAuthMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'account-exists-with-different-credential':
      case 'credential-already-in-use':
      case 'email-already-in-use':
        return 'Akun Google ini sudah terhubung. Silakan masuk memakai akun Google tersebut.';
      case 'network-request-failed':
        return 'Koneksi internet bermasalah. Periksa jaringan lalu coba lagi.';
      case 'user-disabled':
        return 'Akun ini dinonaktifkan dan tidak bisa digunakan untuk login.';
      case 'operation-not-allowed':
        return 'Login Google belum diaktifkan di Firebase Authentication.';
      default:
        return error.message ?? 'Login Google gagal. Coba lagi.';
    }
  }

  String _friendlyPlatformMessage(PlatformException error) {
    final message = error.message ?? error.details?.toString() ?? '';
    if (message.contains('ApiException: 10') ||
        message.contains('DEVELOPER_ERROR')) {
      return 'Konfigurasi Google Sign-In belum cocok. Pastikan SHA-1/SHA-256 build ini sudah ditambahkan di Firebase, lalu unduh ulang google-services.json.';
    }
    if (error.code == 'network_error') {
      return 'Koneksi internet bermasalah. Periksa jaringan lalu coba lagi.';
    }
    if (error.code == 'sign_in_canceled') {
      return 'Login dibatalkan.';
    }
    return 'Login Google gagal. Coba lagi.';
  }
}
