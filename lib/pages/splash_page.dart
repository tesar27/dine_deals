import 'package:flutter/material.dart';
import 'package:dine_deals/main.dart';
import 'package:dine_deals/pages/auth/auth_page.dart';
import 'package:dine_deals/pages/home/home_page.dart';
import 'package:dine_deals/widgets/app_components.dart';

/// Optimized splash page with proper navigation handling
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Small delay to show splash screen
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    // Check authentication state
    final session = supabase.auth.currentSession;
    
    // Navigate to appropriate page
    final targetRoute = session != null 
        ? MaterialPageRoute(builder: (_) => const HomePage())
        : MaterialPageRoute(builder: (_) => const AuthPage());

    Navigator.of(context).pushReplacement(targetRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 80,
              color: Colors.white,
            ),
            SizedBox(height: 24),
            Text(
              'Dine Deals',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Discover amazing deals nearby',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 48),
            AppLoadingIndicator(
              color: Colors.white,
              size: 32,
            ),
          ],
        ),
      ),
    );
  }
}
