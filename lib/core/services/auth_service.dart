import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Thrown by [AuthService.linkWithGoogle] when the chosen Google account
/// is already linked to a **different** Firebase user than the one
/// currently signed in.
///
/// **Carries [credential] rather than making the caller start Google
/// Sign-In over again** — the picker already ran once; asking for it a
/// second time just to retry the same credential would be a worse UX for
/// no safety benefit, since the credential itself is a plain value object,
/// not a single-use token.
///
/// Deliberately does **not** perform the switch itself (see
/// [AuthService.linkWithGoogle]'s own doc comment for why doing so used
/// to happen automatically, silently, and was the real bug): the caller
/// must show the person what this means — the current account's progress/
/// Premium/data will be left behind, not merged — and only call
/// [AuthService.confirmSwitchToExistingGoogleAccount] once they have
/// actually agreed.
class GoogleAccountConflictException implements Exception {
  final AuthCredential credential;
  const GoogleAccountConflictException(this.credential);
}

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
  /// progress keyed by it) is preserved.
  ///
  /// **Throws [GoogleAccountConflictException], rather than switching
  /// accounts on its own, when the Google account is already linked to a
  /// different Firebase user.** This used to fall back to
  /// `signInWithCredential` automatically and silently right here — found
  /// to be a real bug, not a convenience: it abandons whatever the
  /// current (Guest) account holds — including a Premium purchase just
  /// made moments earlier — with no warning that anything happened, let
  /// alone a chance to say no. See [GoogleAccountConflictException]'s own
  /// doc comment for how a caller is meant to recover from this instead.
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
          throw GoogleAccountConflictException(credential);
        }
        rethrow;
      }
    }

    final result = await _auth.signInWithCredential(credential);
    return _withGoogleName(result.user, googleUser.displayName);
  }

  /// Completes the switch [linkWithGoogle] refused to make silently —
  /// called only after the caller has shown the person what it means and
  /// they explicitly agreed. See [GoogleAccountConflictException].
  ///
  /// Does **not** call [_withGoogleName]: unlike [linkWithGoogle]'s other
  /// paths, there is no fresh `GoogleSignInAccount.displayName` in scope
  /// here (only the already-built [credential] survived the round trip
  /// through the exception) — an acceptable gap, not a silent one, since
  /// the account being switched to is by definition one that has signed
  /// in with Google before and so almost always already has a display
  /// name of its own.
  Future<User?> confirmSwitchToExistingGoogleAccount(
    AuthCredential credential,
  ) async {
    final result = await _auth.signInWithCredential(credential);
    return result.user;
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
