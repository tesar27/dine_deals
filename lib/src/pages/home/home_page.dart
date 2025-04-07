import 'package:dine_deals/src/providers/user_provider.dart';
import 'package:dine_deals/src/pages/home/bookings_page.dart';
import 'package:dine_deals/src/pages/home/news_page.dart';
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

  // Get current page based on selected index
  Widget get _currentPage {
    switch (_selectedIndex) {
      case 0:
        return const DealsPage();
      case 1:
        return const NewsPage();
      case 2:
        return const BookingsPage();
      case 3:
        return const AccountPage();
      default:
        return const DealsPage();
    }
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
        // final isSuperAdmin = user?['is_super_admin'] == true;
        // print('User: $user');
        // Dynamically add AdminPage if the user is a super admin

        return Scaffold(
          body: _currentPage,
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.explore),
                label: 'Deals',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.newspaper),
                label: 'News',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt),
                label: 'Bookings',
              ),
              // if (isSuperAdmin)
              //    BottomNavigationBarItem(
              //     icon: Icon(Icons.admin_panel_settings),
              //     label: 'Admin',
              //   ),
              BottomNavigationBarItem(
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
