import 'dart:async';
import 'dart:convert';
import 'package:dine_deals/src/pages/auth/profile_setup_page.dart';
import 'package:dine_deals/src/pages/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _isLoading = true; // Start with loading to check auth status
  bool _isSent = false;
  // ignore: unused_field
  bool _hasError = false;
  late final TextEditingController _emailController = TextEditingController();
  late final TextEditingController _otpController = TextEditingController();
  late final TextEditingController _passwordController =
      TextEditingController();

  // Auth mode controls which form is shown
  AuthMode _currentMode = AuthMode.signIn;

  @override
  void initState() {
    super.initState();
    // Check for existing authentication when the page loads
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      // First check if we have cached user data (this is faster than checking Supabase)
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');

      if (userData != null) {
        // We have cached user data
        final user = jsonDecode(userData);

        // Check if cache is not too old (optional, e.g. 30 days)
        final lastSignIn = DateTime.parse(user['last_sign_in']);
        final now = DateTime.now();
        final difference = now.difference(lastSignIn).inDays;

        if (difference <= 30) {
          // Cache is valid for 30 days
          try {
            // Try to get user profile to verify authentication is still valid
            await supabase
                .from('users')
                .select('id, first_name, last_name')
                .eq('id', user['id'])
                .single();

            // If we got here, the user is authenticated via cache
            await _redirectAuthenticatedUser();
            return;
          } catch (e) {
            // Cache is invalid, will continue to check Supabase session
            await prefs.remove('user_data');
            debugPrint('Cache validation failed: $e');
          }
        } else {
          // Cache is too old, remove it
          await prefs.remove('user_data');
        }
      }

      // If cache didn't work, check if there's a current session
      final session = supabase.auth.currentSession;

      if (session != null) {
        // User is authenticated via Supabase session
        await _redirectAuthenticatedUser();
        return;
      }

      // If we get here, user is not authenticated
    } catch (e) {
      debugPrint('Error checking authentication: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _redirectAuthenticatedUser() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      // Cache user data for faster future authentication checks
      _cacheUserData(user);

      try {
        // Check if user has a profile
        final userData = await supabase
            .from('users')
            .select('first_name, last_name, phone')
            .eq('id', user.id)
            .single();

        if (mounted) {
          if (userData['first_name'] == null ||
              userData['first_name'].isEmpty) {
            // User needs to set up profile
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const ProfileSetupPage()),
            );
          } else {
            // User has a profile, go to home
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          }
        }
      } catch (e) {
        // If error checking profile, direct to profile setup
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const ProfileSetupPage()),
          );
        }
      }
    }
  }

  Future<void> _cacheUserData(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = {
        'id': user.id,
        'email': user.email,
        'last_sign_in': DateTime.now().toIso8601String(),
      };
      await prefs.setString('user_data', jsonEncode(userData));
    } catch (e) {
      debugPrint('Error caching user data: $e');
    }
  }

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

      // Cache user data after successful authentication
      final user = supabase.auth.currentUser;
      if (user != null) {
        await _cacheUserData(user);
      }

      if (mounted) {
        await _redirectAuthenticatedUser();
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

      // Cache user data after successful authentication
      final user = supabase.auth.currentUser;
      if (user != null) {
        await _cacheUserData(user);
      }

      if (mounted) {
        await _redirectAuthenticatedUser();
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

    // Show loading indicator while checking authentication
    if (_isLoading && !_isSent) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

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
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_outline, size: 24),
                        SizedBox(width: 8),
                        Text('Continue as Guest'),
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
