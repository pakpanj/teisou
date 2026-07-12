import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Anonymous-first auth, matching the Cash Teisou pattern: every user gets
/// signed in anonymously on first launch, and can later link a Google
/// account without their UID changing (so progress carries over).
class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _auth = auth ?? FirebaseAuth.instance,
      _googleSignIn =
          googleSignIn ??
          GoogleSignIn(
            serverClientId:
                '329692614759-n4fn14l7ba87g2odmea5hl2svreve0hp.apps.googleusercontent.com',
            scopes: const ['email'],
          );

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? true;

  /// Signs in anonymously if there is no current user yet. Safe to call on
  /// every app start.
  Future<User> ensureSignedIn() async {
    final current = _auth.currentUser;
    if (current != null) return current;
    final credential = await _auth.signInAnonymously();
    return credential.user!;
  }

  /// Links the current anonymous account to Google so the UID (and all
  /// progress keyed by it) is preserved. Falls back to a normal sign-in if
  /// the Google account is already linked to a different Firebase user.
  Future<User?> linkWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final current = _auth.currentUser;
    if (current != null && current.isAnonymous) {
      try {
        final result = await current.linkWithCredential(credential);
        return result.user;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'credential-already-in-use') {
          final result = await _auth.signInWithCredential(credential);
          return result.user;
        }
        rethrow;
      }
    }

    final result = await _auth.signInWithCredential(credential);
    return result.user;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
