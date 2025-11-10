import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth/auth_service.dart';
import '../services/firebase/firestore_service.dart';
import '../services/storage/local_storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<User?>? _authSubscription;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  bool _isInitializing = true;

  AuthProvider() {
    _initAuthListener();
    _checkStoredAuth();
  }

  // Check if user is already logged in via Firebase Auth or localStorage
  Future<void> _checkStoredAuth() async {
    _setLoading(true);
    
    try {
      // First check Firebase Auth (persists automatically across app restarts)
      final firebaseUser = _authService.currentUser;
      if (firebaseUser != null) {
        debugPrint(' Firebase Auth session found: ${firebaseUser.uid}');
        // Firebase Auth has active session - load user data
        final firestoreService = FirestoreService();
        _currentUser = await firestoreService.getUserById(firebaseUser.uid);
        
        // Ensure localStorage is synced
        if (_currentUser != null) {
          await LocalStorageService.saveAuthState(
            userId: _currentUser!.id,
            email: _currentUser!.email,
            displayName: _currentUser!.displayName,
          );
          debugPrint(' User loaded from Firestore: ${_currentUser!.email}');
        } else {
          debugPrint(' User not found in Firestore');
        }
        
        _setLoading(false);
        _isInitializing = false;
        notifyListeners();
        return;
      }
      
      debugPrint(' No Firebase Auth session, checking localStorage...');
      // If Firebase Auth doesn't have session, check localStorage
      // (This handles cases where Firebase Auth session expired but user data is stored)
      final isLoggedIn = await LocalStorageService.isLoggedIn();
      if (isLoggedIn) {
        final userId = await LocalStorageService.getUserId();
        if (userId != null) {
          debugPrint('Found stored userId in localStorage: $userId');
          final firestoreService = FirestoreService();
          _currentUser = await firestoreService.getUserById(userId);
          if (_currentUser != null) {
            debugPrint(' User loaded from localStorage: ${_currentUser!.email}');
          }
        }
      } else {
        debugPrint('  No stored auth state found');
      }
    } catch (e) {
      debugPrint(' Error checking stored auth: $e');
    } finally {
      _setLoading(false);
      _isInitializing = false;
      notifyListeners();
    }
  }

  // Listen to auth state changes
  void _initAuthListener() {
    _authSubscription = _authService.authStateChanges.listen((User? user) async {
      // Don't interfere with initial auth check
      if (_isInitializing) {
        debugPrint(' Skipping auth listener - still initializing');
        return;
      }
      
      if (user != null) {
        debugPrint(' Auth state changed: User signed in ${user.uid}');
        // Add a small delay to ensure token propagation
        await Future.delayed(const Duration(milliseconds: 500));
        // Force token refresh
        await user.getIdToken(true);
        // User is signed in, fetch user data
        final firestoreService = FirestoreService();
        _currentUser = await firestoreService.getUserById(user.uid);
        
        // Sync to localStorage
        if (_currentUser != null) {
          await LocalStorageService.saveAuthState(
            userId: _currentUser!.id,
            email: _currentUser!.email,
            displayName: _currentUser!.displayName,
          );
        }
      } else {
        debugPrint('Auth state changed: User signed out');
        // User is signed out
        _currentUser = null;
      }
      notifyListeners();
    });
  }

  // Sign up with email
  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _currentUser = await _authService.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      
      // Don't save to localStorage on signup - user must login
      // Clear the current user so they have to login
      final success = _currentUser != null;
      _currentUser = null;
      
      _setLoading(false);
      return success;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Sign in with email
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _currentUser = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      
      // Save to localStorage
      if (_currentUser != null) {
        await LocalStorageService.saveAuthState(
          userId: _currentUser!.id,
          email: _currentUser!.email,
          displayName: _currentUser!.displayName,
        );
      }
      
      _setLoading(false);
      return _currentUser != null;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      _currentUser = await _authService.signInWithGoogle();
      
      // Save to localStorage
      if (_currentUser != null) {
        // Ensure we have a valid Firebase token
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.getIdToken(true); // Force token refresh
        }
        
        await LocalStorageService.saveAuthState(
          userId: _currentUser!.id,
          email: _currentUser!.email,
          displayName: _currentUser!.displayName,
        );
      }
      
      _setLoading(false);
      return _currentUser != null;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _authService.signOut();
    await LocalStorageService.clearAuthState();
    _currentUser = null;
    notifyListeners();
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.resetPassword(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Update user data
  void updateUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  // Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
