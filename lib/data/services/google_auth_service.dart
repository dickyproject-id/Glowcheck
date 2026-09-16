import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Import biasa saja

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fungsi Login Google
  Future<User?> signInWithGoogle() async {
    try {
      // 1. Trigger Login Flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null; // User batal login
      }

      // 2. Dapatkan Auth Detail
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Buat Credential
      // Di versi 5.0.0, accessToken dan idToken pasti ada (nullable handled by firebase)
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Login ke Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      return userCredential.user;
    } catch (e) {
      print("Error Google Sign In: $e");
      throw Exception("Gagal Login Google");
    }
  }

  // Fungsi Logout
  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}
