import 'dart:async';
import 'package:dine_deals/src/pages/auth/profile_setup_page.dart';
import 'package:dine_deals/src/pages/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dine_deals/main.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const AuthPage());
  }

  @override
  State<AuthPage> createState() => _AuthPageState();
}

enum AuthMode { signIn, signUp, forgotPassword }

class _AuthPageState extends State<AuthPage> {
  bool _isLoading = false;
  bool _isSent = false;
  // ignore: unused_field
  bool _hasError = false;
  late final TextEditingController _emailController = TextEditingController();
  late final TextEditingController _otpController = TextEditingController();
  late final TextEditingController _passwordController =
      TextEditingController();

  // Auth mode controls which form is shown

  AuthMode _currentMode = AuthMode.signIn;

  Future<void> _sendOTP() async {
    try {
      setState(() {
        _isLoading = true;
        _isSent = true;
        _hasError = false;
      });
      await supabase.auth.signInWithOtp(
        email: _emailController.text.trim(),
      );
      if (mounted) {
        context.showSnackBar('Check your email for an OTP!');
      }
    } on AuthException catch (error) {
      if (mounted) {
        context.showSnackBar(error.message, isError: true);
        setState(() {
          _hasError = true;
        });
      }
    } catch (error) {
      if (mounted) {
        context.showSnackBar('Unexpected error occurred', isError: true);
        setState(() {
          _hasError = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyOTP() async {
    try {
      setState(() {
        _isLoading = true;
      });
      await supabase.auth.verifyOTP(
        email: _emailController.text.trim(),
        token: _otpController.text.trim(),
        type: _currentMode == AuthMode.forgotPassword
            ? OtpType.recovery
            : OtpType.email,
      );
      if (mounted) {
        // Check if user exists in users table or needs profile setup
        final user = supabase.auth.currentUser;
        if (user != null) {
          final userData = await supabase
              .from('users')
              .select('first_name, last_name, phone')
              .eq('id', user.id)
              .single();

          if (userData['first_name'] == null ||
              userData['first_name'].isEmpty) {
            // User needs to set up their profile
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const ProfileSetupPage()),
            );
          } else {
            // User already has a profile, go to home page
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          }
        } else {
          // If for some reason we don't have a user, go to home page
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      }
    } on AuthException catch (error) {
      if (mounted) {
        context.showSnackBar(error.message, isError: true);
        setState(() {
          _hasError = true;
        });
      }
    } catch (error) {
      if (mounted) {
        context.showSnackBar('Unexpected error occurred', isError: true);
        setState(() {
          _hasError = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithPassword() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        // Check if user exists in users table or needs profile setup
        final user = supabase.auth.currentUser;
        if (user != null) {
          final userData = await supabase
              .from('users')
              .select('first_name, last_name, phone')
              .eq('id', user.id)
              .single();

          if (userData['first_name'] == null ||
              userData['first_name'].isEmpty) {
            // User needs to set up their profile
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const ProfileSetupPage()),
            );
          } else {
            // User already has a profile, go to home page
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          }
        } else {
          // If for some reason we don't have a user, go to home page
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      }
    } on AuthException catch (error) {
      if (mounted) {
        context.showSnackBar(error.message, isError: true);
      }
    } catch (error) {
      if (mounted) {
        context.showSnackBar('Unexpected error occurred', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Guest navigation function
  void _continueAsGuest() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  void _switchMode(AuthMode mode) {
    setState(() {
      _currentMode = mode;
      _isSent = false;
      _hasError = false;
      _otpController.clear();
    });
  }

  void _tryAgain() {
    setState(() {
      _isSent = false;
      _hasError = false;
      _otpController.clear();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the current theme to determine if we're in dark mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo or App Name
                  Icon(Icons.restaurant, size: 80, color: colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    'Dine Deals',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Auth mode selector tabs
                  Container(
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? colorScheme.surfaceContainerHighest
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _switchMode(AuthMode.signIn),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _currentMode == AuthMode.signIn
                                    ? colorScheme.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Center(
                                child: Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _currentMode == AuthMode.signIn
                                        ? colorScheme.onPrimary
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _switchMode(AuthMode.signUp),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _currentMode == AuthMode.signUp
                                    ? colorScheme.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Center(
                                child: Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _currentMode == AuthMode.signUp
                                        ? colorScheme.onPrimary
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Main form fields
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: isDarkMode
                              ? Colors.black26
                              : Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _currentMode == AuthMode.signIn
                              ? 'Welcome Back'
                              : _currentMode == AuthMode.signUp
                                  ? 'Create Account'
                                  : 'Reset Password',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),

                        // Email field
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined,
                                color: colorScheme.primary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            enabled: !_isSent,
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),

                        // Password field (only for sign in)
                        if (_currentMode == AuthMode.signIn && !_isSent) ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline,
                                  color: colorScheme.primary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            obscureText: true,
                          ),
                        ],

                        // OTP field (when sent)
                        if (_isSent) ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: _otpController,
                            decoration: InputDecoration(
                              labelText: 'Enter OTP Code',
                              prefixIcon:
                                  Icon(Icons.pin, color: colorScheme.primary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                letterSpacing: 10, fontSize: 20),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Main action button
                        ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  if (_isSent) {
                                    if (_otpController.text.length == 6) {
                                      _verifyOTP();
                                    } else {
                                      context.showSnackBar(
                                          'Enter a valid 6-digit OTP',
                                          isError: true);
                                    }
                                  } else if (_currentMode == AuthMode.signIn) {
                                    _signInWithPassword();
                                  } else {
                                    _sendOTP();
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.onPrimary,
                                  ),
                                )
                              : Text(
                                  _isSent
                                      ? 'Verify OTP'
                                      : _currentMode == AuthMode.signIn
                                          ? 'Sign In'
                                          : _currentMode == AuthMode.signUp
                                              ? 'Send OTP'
                                              : 'Send Reset Link',
                                  style: const TextStyle(fontSize: 16),
                                ),
                        ),

                        if (_isSent) ...[
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: _tryAgain,
                            child: Text(
                              'Try Again',
                              style: TextStyle(color: colorScheme.primary),
                            ),
                          ),
                        ],

                        // Forgot password link
                        if (_currentMode == AuthMode.signIn && !_isSent) ...[
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () =>
                                _switchMode(AuthMode.forgotPassword),
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(color: colorScheme.primary),
                            ),
                          ),
                        ],

                        // Back to sign in for forgot password
                        if (_currentMode == AuthMode.forgotPassword &&
                            !_isSent) ...[
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => _switchMode(AuthMode.signIn),
                            child: Text(
                              'Back to Sign In',
                              style: TextStyle(color: colorScheme.primary),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // OR Divider
                  Row(
                    children: [
                      Expanded(
                          child: Divider(
                              thickness: 1, color: colorScheme.outline)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(color: colorScheme.outline),
                        ),
                      ),
                      Expanded(
                          child: Divider(
                              thickness: 1, color: colorScheme.outline)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Replace social login buttons with Continue as Guest
                  ElevatedButton(
                    onPressed: _continueAsGuest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode
                          ? colorScheme.surfaceContainerHighest
                          : Colors.grey.shade200,
                      foregroundColor: colorScheme.onSurfaceVariant,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                            color: isDarkMode
                                ? colorScheme.outline
                                : Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_outline, size: 24),
                        const SizedBox(width: 8),
                        const Text('Continue as Guest'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
