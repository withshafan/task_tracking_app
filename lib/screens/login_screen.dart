import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/user.dart';
import '../app_theme.dart';

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
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isLogin = true;
  bool _isAdmin = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await _auth.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        User? firebaseUser = await _auth.registerWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        if (firebaseUser != null) {
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
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
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
      _obscurePassword = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkGradient : AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.rocket_launch_rounded,
                      size: 36,
                      color: Colors.white,
                    ),
                  ).animate().scale(
                        begin: const Offset(0.5, 0.5),
                        end: const Offset(1.0, 1.0),
                        duration: 500.ms,
                        curve: Curves.elasticOut,
                      ),

                  const SizedBox(height: 16),

                  Text(
                    'Tracking Task',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ).animate(delay: 200.ms).fadeIn(duration: 400.ms),

                  const SizedBox(height: 32),

                  // Glassmorphic card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.black : Colors.white).withAlpha(isDark ? 60 : 230),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withAlpha(isDark ? 20 : 40),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(25),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Title
                            Text(
                              _isLogin ? 'Welcome Back' : 'Create Account',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _isLogin
                                  ? 'Sign in to continue managing your tasks'
                                  : 'Join Tracking Task and start being productive',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color
                                        ?.withAlpha(150),
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 28),

                            // Name (register only)
                            if (!_isLogin) ...[
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Full Name',
                                  prefixIcon: Icon(Icons.person_outline_rounded),
                                ),
                                validator: (v) =>
                                    v == null || v.trim().isEmpty ? 'Enter your name' : null,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Email
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Enter your email';
                                if (!v.contains('@')) return 'Enter a valid email';
                                return null;
                              },
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 16),

                            // Password
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                  onPressed: () {
                                    setState(() => _obscurePassword = !_obscurePassword);
                                  },
                                ),
                              ),
                              obscureText: _obscurePassword,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Enter a password';
                                if (v.length < 6) return 'At least 6 characters';
                                return null;
                              },
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                            ),

                            // Admin toggle (register only)
                            if (!_isLogin) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Theme.of(context).dividerColor,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.admin_panel_settings_outlined,
                                      color: _isAdmin ? AppColors.primary : AppColors.pending,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Register as Admin'),
                                    const Spacer(),
                                    Switch.adaptive(
                                      value: _isAdmin,
                                      onChanged: (v) => setState(() => _isAdmin = v),
                                      activeTrackColor: AppColors.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 28),

                            // Submit button
                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  disabledBackgroundColor: AppColors.primary.withAlpha(120),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Text(
                                        _isLogin ? 'Sign In' : 'Create Account',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Toggle mode
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _isLogin
                                      ? "Don't have an account? "
                                      : 'Already have an account? ',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                GestureDetector(
                                  onTap: _toggleMode,
                                  child: Text(
                                    _isLogin ? 'Register' : 'Sign In',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate(delay: 300.ms).fadeIn(duration: 500.ms).slideY(begin: 0.15, end: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
