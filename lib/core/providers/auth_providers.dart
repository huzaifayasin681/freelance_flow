import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import '../../shared/models/user_model.dart';

/// Provider for Firebase Auth user stream
final authStateProvider = StreamProvider<User?>((ref) {
  return AuthService.authStateChanges;
});

/// Provider for current user document
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null) return null;
  
  return await AuthService.getCurrentUserDocument();
});

/// Provider for authentication state
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value != null;
});

/// Provider for auth loading state
final authLoadingProvider = StateProvider<bool>((ref) => false);

/// Provider for login form state
final loginFormProvider = StateNotifierProvider<LoginFormNotifier, LoginFormState>((ref) {
  return LoginFormNotifier();
});

/// Login form state
class LoginFormState {
  final String email;
  final String password;
  final bool isLoading;
  final String? errorMessage;

  const LoginFormState({
    this.email = '',
    this.password = '',
    this.isLoading = false,
    this.errorMessage,
  });

  LoginFormState copyWith({
    String? email,
    String? password,
    bool? isLoading,
    String? errorMessage,
  }) {
    return LoginFormState(
      email: email ?? this.email,
      password: password ?? this.password,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Login form state notifier
class LoginFormNotifier extends StateNotifier<LoginFormState> {
  LoginFormNotifier() : super(const LoginFormState());

  void updateEmail(String email) {
    state = state.copyWith(email: email, errorMessage: null);
  }

  void updatePassword(String password) {
    state = state.copyWith(password: password, errorMessage: null);
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setError(String? error) {
    state = state.copyWith(errorMessage: error, isLoading: false);
  }

  Future<bool> signInWithEmail() async {
    if (state.email.isEmpty || state.password.isEmpty) {
      setError('Please fill in all fields');
      return false;
    }

    setLoading(true);
    
    try {
      await AuthService.signInWithEmailAndPassword(
        email: state.email.trim(),
        password: state.password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      setError(_getErrorMessage(e.code));
      return false;
    } catch (e) {
      setError('An unexpected error occurred');
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    setLoading(true);
    
    try {
      final result = await AuthService.signInWithGoogle();
      return result != null;
    } on FirebaseAuthException catch (e) {
      setError(_getErrorMessage(e.code));
      return false;
    } catch (e) {
      setError('Google sign-in failed');
      return false;
    }
  }

  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      default:
        return 'Login failed. Please try again.';
    }
  }
}