import 'package:dine_deals/src/pages/auth/auth_page.dart';
import 'package:dine_deals/src/pages/home/home_page.dart';
import 'package:dine_deals/src/providers/theme/app_theme.dart';
import 'package:dine_deals/src/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://kpceyekfdauxsbljihst.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtwY2V5ZWtmZGF1eHNibGppaHN0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzkxOTQ1MjUsImV4cCI6MjA1NDc3MDUyNX0.U5go8S7atXgblQDKFXlk707J_d8JQlaBeiRr3bVJYGY',
  );
  await dotenv.load(fileName: ".env");

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

final supabase = Supabase.instance.client;

// Add this function to check if user is signed in
bool isUserSignedIn() {
  return supabase.auth.currentUser != null;
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Dine Deals',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const AuthPage(),
    );
  }
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    // Wait for any initializations if needed
    await Future.delayed(const Duration(milliseconds: 100));

    // Redirect to the appropriate page
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}

extension ContextExtension on BuildContext {
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(this).colorScheme.error
            : Theme.of(this).snackBarTheme.backgroundColor,
      ),
    );
  }
}
