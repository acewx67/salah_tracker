import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Service to handle Google Sign-In and Firebase Authentication.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Reactive stream of user authentication state.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get current user from Firebase.
  User? get currentUser => _auth.currentUser;

  /// Sign in with Google and return the Firebase ID token.
  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        return await user.getIdToken();
      }
      return null;
    } catch (e) {
      print('Error during Google Sign-In: $e');
      rethrow;
    }
  }

  /// Sign out from both Firebase and Google.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
