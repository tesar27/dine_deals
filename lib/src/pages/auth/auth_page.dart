import 'dart:async';
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
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
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
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
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

  Future<void> _signInWithGoogle() async {
    try {
      setState(() {
        _isLoading = true;
      });
      // This needs to be implemented based on your Google auth configuration
      await supabase.auth.signInWithOAuth(OAuthProvider.google,
          redirectTo:
              'https://kpceyekfdauxsbljihst.supabase.co/auth/v1/callback');
      // Navigation will happen automatically on successful authentication via deep link
    } catch (error) {
      if (mounted) {
        context.showSnackBar('Failed to sign in with Google', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithApple() async {
    try {
      setState(() {
        _isLoading = true;
      });
      // This needs to be implemented based on your Apple auth configuration
      await supabase.auth.signInWithOAuth(OAuthProvider.apple,
          redirectTo:
              'https://kpceyekfdauxsbljihst.supabase.co/auth/v1/callback');
      // Navigation will happen automatically on successful authentication via deep link
    } catch (error) {
      if (mounted) {
        context.showSnackBar('Failed to sign in with Apple', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
                  const Icon(Icons.restaurant, size: 80, color: Colors.orange),
                  const SizedBox(height: 12),
                  const Text(
                    'Dine Deals',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Auth mode selector tabs
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
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
                                    ? Colors.orange
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Center(
                                child: Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _currentMode == AuthMode.signIn
                                        ? Colors.white
                                        : Colors.black54,
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
                                    ? Colors.orange
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Center(
                                child: Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _currentMode == AuthMode.signUp
                                        ? Colors.white
                                        : Colors.black54,
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
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
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),

                        // Email field
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email_outlined),
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
                              prefixIcon: const Icon(Icons.lock_outline),
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
                              prefixIcon: const Icon(Icons.pin),
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
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
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
                            child: const Text('Try Again'),
                          ),
                        ],

                        // Forgot password link
                        if (_currentMode == AuthMode.signIn && !_isSent) ...[
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () =>
                                _switchMode(AuthMode.forgotPassword),
                            child: const Text('Forgot Password?'),
                          ),
                        ],

                        // Back to sign in for forgot password
                        if (_currentMode == AuthMode.forgotPassword &&
                            !_isSent) ...[
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => _switchMode(AuthMode.signIn),
                            child: const Text('Back to Sign In'),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // OR Divider
                  Row(
                    children: [
                      const Expanded(child: Divider(thickness: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                      const Expanded(child: Divider(thickness: 1)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Social login buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Google button
                      ElevatedButton(
                        onPressed: _signInWithGoogle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.g_mobiledata,
                                size: 24, color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            const Text('Google'),
                          ],
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Apple button
                      ElevatedButton(
                        onPressed: _signInWithApple,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.apple, size: 24),
                            SizedBox(width: 8),
                            Text('Apple'),
                          ],
                        ),
                      ),
                    ],
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
