import 'package:dine_deals/main.dart';
import 'package:dine_deals/src/pages/home/admin_page.dart';
import 'package:dine_deals/src/pages/home/restaurants_page.dart';
import 'package:flutter/material.dart';
import 'package:dine_deals/src/pages/home/account_page.dart';
import 'package:dine_deals/src/pages/home/deals_page.dart'; // Replace with your new page

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final user = supabase.auth.currentUser;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = <Widget>[
      const DealsPage(),
      const RestaurantsPage(),
      // user?.id == '96cf7dcc-da80-452d-9b30-bf9587b5b6de'
      //     ? const AdminPage()
      //     : const Center(child: Text('Access Denied')),
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
    return Scaffold(
      body: Center(
        child: _pages.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Ensures all items are visible
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Deals', // Replace with your new page label
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.restaurant),
            label: 'Restaurants', // Replace with your new page label
          ),
          if (user?.id == '96cf7dcc-da80-452d-9b30-bf9587b5b6de')
            const BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings),
              label: 'Admin', // Replace with your new page label
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
  }
}
