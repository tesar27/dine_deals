import 'package:dine_deals/src/providers/theme_provider.dart';
import 'package:dine_deals/src/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dine_deals/main.dart';
import 'package:dine_deals/src/pages/auth/otp_signup_page.dart';
import 'dart:math' as math;

class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const AccountPage());
  }

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  String? _avatarUrl;
  String _firstName = '';
  String _lastName = '';
  String _email = '';

  // Stats for the pie chart
  final Map<String, int> _stats = {
    'Deals': 7,
    'Savings': 12,
    'Restaurants': 15,
    'Cities': 3,
    'Ratings': 9,
    'Reviews': 4,
  };

  @override
  void initState() {
    super.initState();
    _initializeProfile();
  }

  void _initializeProfile() {
    final userAsync = ref.read(userNotifierProvider);
    print('userAsync: $userAsync');
    userAsync.whenData((user) {
      if (user != null) {
        setState(() {
          _email = user['email'] ?? '';
          _avatarUrl = user['avatar_url'];

          // Split email to create a name if not available
          final nameParts =
              user['name']?.split(' ') ?? _email.split('@')[0].split('.');
          _firstName = nameParts.isNotEmpty ? nameParts[0] : 'User';
          _lastName = nameParts.length > 1 ? nameParts[1] : '';
        });
      }
    });
  }

  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();
    } catch (error) {
      if (mounted) {
        context.showSnackBar('Unexpected error occurred', isError: true);
      }
    } finally {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OtpSignupPage()),
        );
      }
    }
  }

  void _navigateToPreEditPage() {
    // Navigate to PreEditPage where user can edit their profile
    // This would be implemented in another file
    context.showSnackBar('Navigate to edit profile page');
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userNotifierProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('No user data available.'));
          }

          return SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row with name and avatar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _firstName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _lastName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: _navigateToPreEditPage,
                          child: CircleAvatar(
                            radius: 35,
                            backgroundImage: _avatarUrl != null
                                ? NetworkImage(_avatarUrl!)
                                : null,
                            child: _avatarUrl == null
                                ? Text(
                                    _firstName.isNotEmpty ? _firstName[0] : '?',
                                    style: const TextStyle(fontSize: 30),
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Main option tiles: Favorites, Wallet, Orders
                    Row(
                      children: [
                        _buildOptionTile(
                          icon: Icons.favorite,
                          label: 'Favorites',
                          color: Colors.pinkAccent,
                          onTap: () {},
                        ),
                        const SizedBox(width: 12),
                        _buildOptionTile(
                          icon: Icons.account_balance_wallet,
                          label: 'Wallet',
                          color: Colors.purpleAccent,
                          onTap: () {},
                        ),
                        const SizedBox(width: 12),
                        _buildOptionTile(
                          icon: Icons.receipt_long,
                          label: 'Orders',
                          color: Colors.orangeAccent,
                          onTap: () {},
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Stats pie chart
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Activity',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          height: 200,
                          child: Row(
                            children: [
                              Expanded(
                                child: CustomPaint(
                                  painter: PieChartPainter(_stats),
                                  child: Container(),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: _stats.entries.map((entry) {
                                    final index =
                                        _stats.keys.toList().indexOf(entry.key);
                                    final colors = [
                                      Colors.red,
                                      Colors.green,
                                      Colors.blue,
                                      Colors.amber,
                                      Colors.purple,
                                      Colors.teal,
                                    ];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4.0),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 12,
                                            height: 12,
                                            color:
                                                colors[index % colors.length],
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${entry.key}: ${entry.value}',
                                            style:
                                                const TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Settings items
                    _buildSettingsItem(
                      icon: Icons.help_outline,
                      title: 'Help',
                      onTap: () {},
                    ),
                    _buildSettingsItem(
                      icon: Icons.info_outline,
                      title: 'About',
                      onTap: () {},
                    ),
                    _buildSettingsItem(
                      icon: Icons.logout,
                      title: 'Sign Out',
                      onTap: _signOut,
                      isDestructive: true,
                    ),

                    // Theme toggle with icon
                    ListTile(
                      leading: Icon(themeMode == ThemeMode.dark
                          ? Icons.light_mode
                          : Icons.dark_mode),
                      title: const Text('Appearance'),
                      subtitle: Text(themeMode == ThemeMode.dark
                          ? 'Dark Mode'
                          : 'Light Mode'),
                      trailing: Switch(
                        value: themeMode == ThemeMode.dark,
                        onChanged: (_) {
                          ref.read(themeModeProvider.notifier).toggleTheme();
                        },
                      ),
                    ),

                    // Full theme selector
                    // ListTile(
                    //   leading: const Icon(Icons.settings_brightness),
                    //   title: const Text('Theme Mode'),
                    //   trailing: DropdownButton<ThemeMode>(
                    //     value: themeMode,
                    //     underline: const SizedBox(),
                    //     onChanged: (ThemeMode? newMode) {
                    //       if (newMode != null) {
                    //         ref
                    //             .read(themeModeProvider.notifier)
                    //             .setThemeMode(newMode);
                    //       }
                    //     },
                    //     items: const [
                    //       DropdownMenuItem(
                    //         value: ThemeMode.system,
                    //         child: Text('System'),
                    //       ),
                    //       DropdownMenuItem(
                    //         value: ThemeMode.light,
                    //         child: Text('Light'),
                    //       ),
                    //       DropdownMenuItem(
                    //         value: ThemeMode.dark,
                    //         child: Text('Dark'),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : null,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

// Custom painter for the pie chart
class PieChartPainter extends CustomPainter {
  final Map<String, int> stats;

  PieChartPainter(this.stats);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final total = stats.values.fold(0, (sum, value) => sum + value);

    if (total == 0) {
      // Draw empty circle if no data
      final paint = Paint()
        ..color = Colors.grey.shade300
        ..style = PaintingStyle.stroke
        ..strokeWidth = 15;
      canvas.drawCircle(center, radius - 10, paint);
      return;
    }

    double startAngle = 0;
    int index = 0;

    final colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.amber,
      Colors.purple,
      Colors.teal,
    ];

    stats.forEach((key, value) {
      if (value > 0) {
        final sweepAngle = (value / total) * 2 * math.pi;
        final paint = Paint()
          ..color = colors[index % colors.length]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 30;

        canvas.drawArc(
          rect,
          startAngle,
          sweepAngle,
          false,
          paint,
        );

        startAngle += sweepAngle;
      }
      index++;
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
