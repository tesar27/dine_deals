import 'package:flutter/material.dart';

class DealsPage extends StatefulWidget {
  const DealsPage({super.key});

  @override
  _DealsPageState createState() => _DealsPageState();
}

class _DealsPageState extends State<DealsPage> {
  String _chosenCity = 'Choose your city';
  bool _iconTapped = false;

  final List<String> _cities = [
    'New York',
    'Los Angeles',
    'Chicago',
    'Houston',
    'Phoenix',
    'Philadelphia',
    'San Antonio',
    'San Diego',
    'Dallas',
    'San Jose',
    'Austin',
    'Jacksonville',
    'Fort Worth',
    'Columbus',
    'Charlotte',
    'San Francisco',
    'Indianapolis',
    'Seattle',
    'Denver',
    'Washington'
  ];

  void _showCitiesList() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ListView.builder(
          itemCount: _cities.length,
          itemBuilder: (BuildContext context, int index) {
            return ListTile(
              title: Text(_cities[index]),
              onTap: () {
                setState(() {
                  _chosenCity = _cities[index];
                  _iconTapped = false;
                });
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Align(
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              GestureDetector(
                onTapDown: (_) {
                  setState(() {
                    _iconTapped = true;
                  });
                },
                onTapUp: (_) {
                  setState(() {
                    _iconTapped = false;
                  });
                  _showCitiesList();
                },
                onTapCancel: () {
                  setState(() {
                    _iconTapped = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: _iconTapped
                        ? const Color.fromARGB(255, 106, 108, 107)
                        : const Color.fromARGB(255, 78, 75, 75),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.business,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(_chosenCity),
            ],
          ),
        ),
      ),
      body: const Center(
        child: Text('This is the new page'),
      ),
    );
  }
}
