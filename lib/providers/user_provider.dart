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

  UserProvider() {
    _init();
  }

  User? get firebaseUser => _firebaseUser;
  AppUser? get appUser => _appUser;
  bool get isLoading => _isLoading;

  void _init() {
    _authService.user.listen((User? user) async {
      _isLoading = true;
      notifyListeners();
      _firebaseUser = user;
      if (user != null) {
        _appUser = await _userService.getUser(user.uid);
      } else {
        _appUser = null;
      }
      _isLoading = false;
      notifyListeners();
    });
  }
}
