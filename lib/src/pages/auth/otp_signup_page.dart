import 'dart:async';
import 'package:dine_deals/src/pages/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dine_deals/main.dart';

class OtpSignupPage extends StatefulWidget {
  const OtpSignupPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const OtpSignupPage());
  }

  @override
  State<OtpSignupPage> createState() => _OtpSignupPageState();
}

class _OtpSignupPageState extends State<OtpSignupPage> {
  bool _isLoading = false;
  bool _isSent = false;
  // ignore: unused_field
  bool _hasError = false;
  late final TextEditingController _emailController = TextEditingController();
  late final TextEditingController _otpController = TextEditingController();

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
        type: OtpType.email,
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OTP Signup')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        children: [
          const Text('Sign up with your email below'),
          const SizedBox(height: 18),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            enabled: !_isSent,
          ),
          if (_isSent) ...[
            const SizedBox(height: 18),
            TextFormField(
              controller: _otpController,
              decoration: const InputDecoration(labelText: 'OTP'),
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      if (_otpController.text.length == 6) {
                        _verifyOTP();
                      } else {
                        context.showSnackBar('Enter a valid 6-digit OTP',
                            isError: true);
                      }
                    },
              child: Text(_isLoading ? 'Loading...' : 'Verify'),
            ),
            const SizedBox(height: 18),
            TextButton(
              onPressed: _tryAgain,
              child: const Text('Try Again'),
            ),
          ],
          if (!_isSent) ...[
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _isLoading ? null : _sendOTP,
              child: Text(_isLoading ? 'Loading...' : 'Send OTP'),
            ),
          ],
        ],
      ),
    );
  }
}
