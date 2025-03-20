import 'package:flutter/material.dart';
import 'package:dine_deals/src/utils/constants.dart';
import 'package:dine_deals/main.dart';
import 'package:dine_deals/src/pages/auth/otp_signup_page.dart';
import 'package:dine_deals/src/pages/home/account_page.dart';

/// Page to redirect users to the appropriate page depending on the initial auth state
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  SplashPageState createState() => SplashPageState();
}

class SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    // await for for the widget to mount
    await Future.delayed(Duration.zero);

    final session = supabase.auth.currentSession;
    if (session == null) {
      Navigator.of(context)
          .pushAndRemoveUntil(OtpSignupPage.route(), (route) => false);
    } else {
      Navigator.of(context)
          .pushAndRemoveUntil(AccountPage.route(), (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: preloader);
  }
}
