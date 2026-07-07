import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  User? _firebaseUser;
  AppUser? _appUser;
  bool _isLoading = true;
  String? _error;
  StreamSubscription<User?>? _authSubscription;

  UserProvider() {
    _init();
  }

  User? get firebaseUser => _firebaseUser;
  AppUser? get appUser => _appUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _init() {
    _authSubscription = _authService.user.listen((User? user) async {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _firebaseUser = user;
      if (user != null) {
        try {
          _appUser = await _userService.getUser(user.uid);
          if (_appUser == null) {
            _error = 'User profile not found. Please contact support.';
          }
        } catch (e) {
          _error = 'Failed to load profile: ${e.toString()}';
          _appUser = null;
        }
      } else {
        _appUser = null;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
