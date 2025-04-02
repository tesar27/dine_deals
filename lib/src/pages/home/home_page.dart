import 'package:dine_deals/src/models/user_provider.dart';
import 'package:dine_deals/src/pages/home/admin_page.dart';
import 'package:dine_deals/src/pages/home/restaurants_page.dart';
import 'package:flutter/material.dart';
import 'package:dine_deals/src/pages/home/account_page.dart';
import 'package:dine_deals/src/pages/home/deals_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;

  // ignore: unused_field
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = <Widget>[
      const DealsPage(),
      const RestaurantsPage(),
      const AccountPage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userNotifierProvider);

    return userAsync.when(
      data: (user) {
        final isSuperAdmin = user?['is_super_admin'] == true;
        print('User: $user');
        // Dynamically add AdminPage if the user is a super admin
        final pages = [
          const DealsPage(),
          const RestaurantsPage(),
          if (isSuperAdmin) const AdminPage(),
          const AccountPage(),
        ];

        return Scaffold(
          body: Center(
            child: pages.elementAt(_selectedIndex),
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            items: <BottomNavigationBarItem>[
              const BottomNavigationBarItem(
                icon: Icon(Icons.explore),
                label: 'Deals',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.restaurant),
                label: 'Restaurants',
              ),
              if (isSuperAdmin)
                const BottomNavigationBarItem(
                  icon: Icon(Icons.admin_panel_settings),
                  label: 'Admin',
                ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.account_circle),
                label: 'Account',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.green,
            onTap: _onItemTapped,
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
}
