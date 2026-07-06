import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/user.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  final UserService _userService = UserService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true; // true = login, false = register
  bool _isAdmin = false; // only for registration

  Future<void> _submit() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields.')),
      );
      return;
    }
    if (!_isLogin && _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        // Sign in
        await _auth.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        // Register
        User? firebaseUser = await _auth.registerWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        if (firebaseUser != null) {
          // Save user data to Firestore
          final appUser = AppUser(
            id: firebaseUser.uid,
            email: firebaseUser.email!,
            name: _nameController.text.trim(),
            isAdmin: _isAdmin,
          );
          await _userService.saveUser(appUser);
        }
      }
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _emailController.clear();
      _passwordController.clear();
      _nameController.clear();
      _isAdmin = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.task, size: 80, color: Colors.blue),
            const SizedBox(height: 30),
            Text(
              _isLogin ? 'Welcome Back' : 'Create Account',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // Email
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 15),

            // Password
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),

            // Extra fields for registration
            if (!_isLogin) ...[
              const SizedBox(height: 15),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  const Text('Register as Admin?'),
                  const Spacer(),
                  Switch(
                    value: _isAdmin,
                    onChanged: (value) {
                      setState(() {
                        _isAdmin = value;
                      });
                    },
                  ),
                ],
              ),
            ],

            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(_isLogin ? 'Login' : 'Register'),
              ),
            ),
            const SizedBox(height: 15),
            TextButton(
              onPressed: _toggleMode,
              child: Text(
                _isLogin
                    ? "Don't have an account? Register"
                    : 'Already have an account? Login',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
