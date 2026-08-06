import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign Up
  Future<User?> signUp(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  // Sign In
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get Current User
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Check if user is logged in
  bool isLoggedIn() {
    return _auth.currentUser != null;
  }

  // Get User ID
  String? getUserId() {
    return _auth.currentUser?.uid;
  }

  // Get User Email
  String? getUserEmail() {
    return _auth.currentUser?.email;
  }

  // Get User Display Name
  String? getUserName() {
    return _auth.currentUser?.displayName;
  }
}