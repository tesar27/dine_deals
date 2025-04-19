import 'package:dine_deals/src/pages/auth/auth_page.dart';
import 'package:dine_deals/src/pages/home/home_page.dart';
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
  runApp(const ProviderScope(child: MyApp()));
}

final supabase = Supabase.instance.client;

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Dine Deals',
      theme: ref.watch(themeDataProvider(Brightness.light)),
      darkTheme: ref.watch(themeDataProvider(Brightness.dark)),
      themeMode: themeMode,
      home: supabase.auth.currentSession == null
          ? const AuthPage()
          : const HomePage(),
    );
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
