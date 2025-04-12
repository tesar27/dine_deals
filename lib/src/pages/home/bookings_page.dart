import 'package:flutter/material.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  _BookingsPageState createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, String>> activeBookings = [
    {'title': '2for1 Pizza', 'details': 'Booked for 2 people on Oct 15, 2025'},
    {'title': '2for1 Burger', 'details': 'Booked for 3 people on Oct 18, 2025'},
  ];

  final List<Map<String, String>> historyBookings = [
    {'title': '2for1 Main Dish', 'details': 'Used on Oct 10, 2025'},
    {'title': '2for1 Pizza', 'details': 'Used on Oct 5, 2025'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bookings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Active'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookingsList(activeBookings),
          _buildBookingsList(historyBookings),
        ],
      ),
    );
  }

  Widget _buildBookingsList(List<Map<String, String>> bookings) {
    if (bookings.isEmpty) {
      return Center(child: Text('No bookings available.'));
    }
    return ListView.builder(
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return ListTile(
          title: Text(booking['title']!),
          subtitle: Text(booking['details']!),
          leading: Icon(Icons.local_offer),
        );
      },
    );
  }
}
