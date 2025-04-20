import 'package:dine_deals/main.dart';
import 'package:dine_deals/src/pages/auth/auth_page.dart';
import 'package:dine_deals/src/pages/home/home_page.dart';
import 'package:flutter/material.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _loading = false;
  String? _firstName;
  String? _lastName;
  String? _avatarUrl;
  var _darkMode = false;

  @override
  void initState() {
    super.initState();
    // Only fetch profile if user is signed in
    if (isUserSignedIn()) {
      _getProfile();
    }
  }

  Future<void> _getProfile() async {
    // Add logic to fetch user profile
  }

  @override
  Widget build(BuildContext context) {
    final bool userSignedIn = isUserSignedIn();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (userSignedIn) ...[
            // User profile content for signed in users
            _loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: _avatarUrl != null
                            ? NetworkImage(_avatarUrl!)
                            : null,
                        child: _avatarUrl == null
                            ? const Icon(Icons.person, size: 50)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _firstName != null && _lastName != null
                            ? '$_firstName $_lastName'
                            : 'No Name Set',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        supabase.auth.currentUser?.email ?? 'No email',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          // Navigate to edit profile page
                        },
                        child: const Text('Edit Profile'),
                      ),
                    ],
                  ),
            const SizedBox(height: 24),
          ] else ...[
            // Sign in button for non-authenticated users
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.account_circle_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Sign in to access your account',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(AuthPage.route());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
          const Divider(),
          SwitchListTile(
            title: const Text('Dark Mode'),
            secondary: const Icon(Icons.brightness_4),
            value: _darkMode,
            onChanged: (bool value) {
              setState(() {
                _darkMode = value;
                // Apply theme change logic here
              });
            },
          ),
          const ListTile(
            leading: Icon(Icons.help_outline),
            title: Text('Help'),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About'),
          ),
          const ListTile(
            leading: Icon(Icons.policy_outlined),
            title: Text('Privacy Policy'),
          ),
          const ListTile(
            leading: Icon(Icons.description_outlined),
            title: Text('Terms of Service'),
          ),
          if (userSignedIn)
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title:
                  const Text('Sign Out', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await supabase.auth.signOut();
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const HomePage()),
                  );
                }
              },
            ),
        ],
      ),
    );
  }
}
