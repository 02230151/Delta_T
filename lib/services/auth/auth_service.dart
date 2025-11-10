import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../models/user_model.dart';
import '../firebase/firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _firestoreService = FirestoreService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display nameha
      await userCredential.user?.updateDisplayName(displayName);

      // Create user document in Firestore
      if (userCredential.user != null) {
        final userModel = UserModel(
          id: userCredential.user!.uid,
          email: email,
          displayName: displayName,
          createdAt: DateTime.now(),
          lastActiveDate: DateTime.now(),
        );
        await _firestoreService.createUser(userModel);
        return userModel;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Get user data from Firestore
        return await _firestoreService.getUserById(userCredential.user!.uid);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      print('Starting Google Sign In flow...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('Google Sign In cancelled by user');
        return null;
      }
      print('Google Sign In successful for email: ${googleUser.email}');

      // Obtain the auth details from the request
      print('Getting Google auth details...');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      print('Got access token: ${googleAuth.accessToken != null}');
      print('Got ID token: ${googleAuth.idToken != null}');

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      print('Created Firebase credential');

      // Sign in to Firebase with the Google credential
      print('Signing in to Firebase...');
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        // Check if user exists in Firestore
        UserModel? existingUser =
            await _firestoreService.getUserById(userCredential.user!.uid);

        if (existingUser == null) {
          // Create new user document
          final userModel = UserModel(
            id: userCredential.user!.uid,
            email: userCredential.user!.email ?? '',
            displayName: userCredential.user!.displayName ?? 'User',
            photoUrl: userCredential.user!.photoURL,
            createdAt: DateTime.now(),
            lastActiveDate: DateTime.now(),
          );
          await _firestoreService.createUser(userModel);
          return userModel;
        }
        return existingUser;
      }
      return null;
    } catch (e) {
      throw 'Google Sign-In failed: ${e.toString()}';
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      default:
        return 'Authentication error: ${e.message}';
    }
  }
}
