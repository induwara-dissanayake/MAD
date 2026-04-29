import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(FirebaseAuth.instance);
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

class AuthService {
  final FirebaseAuth _auth;

  AuthService(this._auth);

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Sign in with NIC-derived email and password.
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Create a new Firebase Auth account using a secondary isolated instance
  /// so that the currently logged-in admin/resident is NOT signed out.
  ///
  /// Returns the UID of the newly created user.
  Future<String> createUserAccount({
    required String email,
    required String password,
  }) async {
    final secondaryAppName =
        'vc-account-creator-${DateTime.now().microsecondsSinceEpoch}';
    final secondaryApp = await Firebase.initializeApp(
      name: secondaryAppName,
      options: Firebase.app().options,
    );

    try {
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final newUid = credential.user!.uid;
      await secondaryAuth.signOut();
      return newUid;
    } finally {
      await secondaryApp.delete();
    }
  }

  /// Generate a secure random password for new residents.
  /// Format: 3 uppercase + 3 digits + 3 lowercase + special char = strong & readable
  static String generatePassword() {
    const upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    const lower = 'abcdefghjkmnpqrstuvwxyz';
    const digits = '23456789';
    const special = '@#\$!';

    final rand = Random.secure();
    final chars = [
      upper[rand.nextInt(upper.length)],
      upper[rand.nextInt(upper.length)],
      upper[rand.nextInt(upper.length)],
      digits[rand.nextInt(digits.length)],
      digits[rand.nextInt(digits.length)],
      digits[rand.nextInt(digits.length)],
      lower[rand.nextInt(lower.length)],
      lower[rand.nextInt(lower.length)],
      lower[rand.nextInt(lower.length)],
      special[rand.nextInt(special.length)],
    ]..shuffle(rand);
    return chars.join();
  }

  /// Set the display name on the Firebase Auth user profile.
  Future<void> updateDisplayName(String displayName) async {
    await _auth.currentUser?.updateDisplayName(displayName);
  }

  /// Change password for the currently signed-in user.
  ///
  /// Firebase requires a recent sign-in, so we first reauthenticate using
  /// current email + current password.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No authenticated user found.',
      );
    }

    final email = user.email;
    if (email == null || email.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-email',
        message: 'Current account has no email for reauthentication.',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  /// Update the password for the currently signed-in user after a recent login.
  ///
  /// Used by first-login activation, where Firebase has already authenticated
  /// the temporary password immediately before the setup screen is shown.
  Future<void> updateCurrentUserPassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No authenticated user found.',
      );
    }
    await user.updatePassword(newPassword);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
