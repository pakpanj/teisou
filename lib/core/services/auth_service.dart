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
        return _withGoogleName(result.user, googleUser.displayName);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'credential-already-in-use') {
          final result = await _auth.signInWithCredential(credential);
          return _withGoogleName(result.user, googleUser.displayName);
        }
        rethrow;
      }
    }

    final result = await _auth.signInWithCredential(credential);
    return _withGoogleName(result.user, googleUser.displayName);
  }

  /// Copies the Google account's name onto the Firebase user when Firebase
  /// didn't set it itself.
  ///
  /// Linking a credential onto an *anonymous* user leaves `displayName`
  /// null: the name arrives in the new provider entry, but Firebase doesn't
  /// promote it to the top-level user profile the way a fresh Google
  /// sign-in does. `UserProfile.resolveDisplayName` reads that top-level
  /// field, so every linked account fell through to the "Pelajar Kana"
  /// fallback and looked as though signing in had lost the user's name.
  ///
  /// Best-effort by design: failing here costs a display name, not the
  /// sign-in that already succeeded, so it must never propagate. A name the
  /// user sets later is unaffected — `resolveDisplayName` still prefers
  /// `customDisplayName` over this.
  Future<User?> _withGoogleName(User? user, String? googleName) async {
    if (user == null) return null;
    final existing = user.displayName;
    if (existing != null && existing.isNotEmpty) return user;
    final name = googleName?.trim();
    if (name == null || name.isEmpty) return user;
    try {
      await user.updateDisplayName(name);
      await user.reload();
      return _auth.currentUser ?? user;
    } catch (_) {
      return user;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
