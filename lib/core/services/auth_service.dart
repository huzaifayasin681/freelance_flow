import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../shared/models/user_model.dart';

/// Authentication service for handling user login, registration, and profile management
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current user stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get current user
  static User? get currentUser => _auth.currentUser;

  /// Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;

  /// Check if user is authenticated
  static bool get isAuthenticated => _auth.currentUser != null;

  /// Register with email and password
  static Future<UserCredential?> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name if provided
      if (displayName != null && credential.user != null) {
        await credential.user!.updateDisplayName(displayName);
      }

      // Create user document in Firestore
      if (credential.user != null) {
        await _createUserDocument(credential.user!);
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Registration error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected registration error: $e');
      rethrow;
    }
  }

  /// Sign in with email and password
  static Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign in error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected sign in error: $e');
      rethrow;
    }
  }

  /// Sign in with Google
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the sign in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with the credential
      final userCredential = await _auth.signInWithCredential(credential);

      // Create or update user document in Firestore
      if (userCredential.user != null) {
        await _createUserDocument(userCredential.user!);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Google sign in error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected Google sign in error: $e');
      rethrow;
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }

  /// Send password reset email
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      debugPrint('Password reset error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected password reset error: $e');
      rethrow;
    }
  }

  /// Update user profile
  static Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user signed in');

      await user.updateDisplayName(displayName);
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      // Update user document in Firestore
      await _updateUserDocument(user);
    } catch (e) {
      debugPrint('Profile update error: $e');
      rethrow;
    }
  }

  /// Update password
  static Future<void> updatePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user signed in');

      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      debugPrint('Password update error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected password update error: $e');
      rethrow;
    }
  }

  /// Delete user account
  static Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user signed in');

      // Delete user document from Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete Firebase Auth account
      await user.delete();
    } on FirebaseAuthException catch (e) {
      debugPrint('Account deletion error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected account deletion error: $e');
      rethrow;
    }
  }

  /// Get user document from Firestore
  static Future<UserModel?> getUserDocument(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      
      return null;
    } catch (e) {
      debugPrint('Get user document error: $e');
      return null;
    }
  }

  /// Get current user document
  static Future<UserModel?> getCurrentUserDocument() async {
    final userId = currentUserId;
    if (userId == null) return null;
    
    return await getUserDocument(userId);
  }

  /// Update user document in Firestore
  static Future<void> updateUserDocument(UserModel userModel) async {
    try {
      await _firestore
          .collection('users')
          .doc(userModel.id)
          .update(userModel.toMap());
    } catch (e) {
      debugPrint('Update user document error: $e');
      rethrow;
    }
  }

  /// Create user document in Firestore
  static Future<void> _createUserDocument(User user) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        final userModel = UserModel(
          id: user.uid,
          email: user.email!,
          displayName: user.displayName,
          photoUrl: user.photoURL,
          phoneNumber: user.phoneNumber,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await userDoc.set(userModel.toMap());
      }
    } catch (e) {
      debugPrint('Create user document error: $e');
      rethrow;
    }
  }

  /// Update existing user document
  static Future<void> _updateUserDocument(User user) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      
      await userDoc.update({
        'displayName': user.displayName,
        'photoUrl': user.photoURL,
        'phoneNumber': user.phoneNumber,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Update user document error: $e');
      rethrow;
    }
  }

  /// Reauthenticate user (required for sensitive operations)
  static Future<void> reauthenticateWithPassword(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('No user signed in');
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      debugPrint('Reauthentication error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected reauthentication error: $e');
      rethrow;
    }
  }

  /// Send email verification
  static Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user signed in');

      if (!user.emailVerified) {
        await user.sendEmailVerification();
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Email verification error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected email verification error: $e');
      rethrow;
    }
  }

  /// Check if email is verified
  static bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  /// Reload user to get updated email verification status
  static Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }
}