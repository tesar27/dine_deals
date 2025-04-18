import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dine_deals/src/providers/deals_provider.dart';

final userNotifierProvider =
    StateNotifierProvider<UserNotifier, AsyncValue<Map<String, dynamic>?>>(
        (ref) {
  return UserNotifier();
});

class UserNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  UserNotifier() : super(const AsyncValue.loading()) {
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      final userData = {
        'email': 'user@example.com',
        'avatar_url': 'https://example.com/avatar.jpg',
        'is_super_admin': 'true',
        'name': 'John Doe',
      };
      state = AsyncValue.data(userData);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

class PlaceDetails extends ConsumerStatefulWidget {
  final Map<String, dynamic> restaurant;

  const PlaceDetails({super.key, required this.restaurant});

  @override
  ConsumerState<PlaceDetails> createState() => _PlaceDetailsState();
}

class _PlaceDetailsState extends ConsumerState<PlaceDetails> {
  bool _isAdmin = false;
  String _isSuperAdmin = 'false';
  bool _isLoading = true;
  List<Map<String, dynamic>> _deals = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProfile();
      _fetchDealsForRestaurant();
    });
  }

  void _initializeProfile() {
    final userAsync = ref.read(userNotifierProvider);
    userAsync.whenData((user) {
      if (user != null) {
        setState(() {
          _isSuperAdmin = user['is_super_admin']?.toString() ?? 'false';
          _isAdmin = _isSuperAdmin == 'true';
        });
      }
    });
  }

  Future<void> _fetchDealsForRestaurant() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dealsNotifier = ref.read(dealsNotifierProvider.notifier);
      final restaurantId = widget.restaurant['id']?.toString();

      if (restaurantId != null) {
        final deals = await dealsNotifier.getDealsForRestaurant(restaurantId);
        setState(() {
          _deals = deals;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error) {
      print("Error fetching deals: $error");
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading deals: $error')),
        );
      }
    }
  }

  void _showAddDealModal() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final savingsController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Add New Deal',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Offer Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.local_offer),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an offer name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Offer Description',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an offer description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: savingsController,
                    decoration: const InputDecoration(
                      labelText: 'Swiss Franks Saved',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.savings),
                      suffixText: 'CHF',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter savings amount';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        if (formKey.currentState?.validate() ?? false) {
                          try {
                            final dealsNotifier =
                                ref.read(dealsNotifierProvider.notifier);

                            await dealsNotifier.addDeal(
                              restaurantId: widget.restaurant['id'].toString(),
                              name: nameController.text,
                              description: descriptionController.text,
                              savings: double.parse(savingsController.text),
                            );

                            Navigator.of(context).pop();

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Deal added successfully!')),
                            );

                            _fetchDealsForRestaurant();
                          } catch (error) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Error adding deal: $error')),
                            );
                          }
                        }
                      },
                      child: const Text(
                        'Add Deal',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              onPressed: _showAddDealModal,
              backgroundColor: Colors.green,
              child: const Icon(Icons.add),
            )
          : null,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipPath(
                  clipper: BottomOvalClipper(),
                  child: Image.network(
                    widget.restaurant['imageUrl'] ??
                        'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=2940&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 300,
                        color: Colors.grey[300],
                        child: const Icon(Icons.restaurant,
                            color: Colors.grey, size: 64),
                      );
                    },
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: Text(
                      widget.restaurant['name'] ?? 'Restaurant Name',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      Text(
                        ' ${widget.restaurant['rating'] ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        ' • ',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${widget.restaurant['hours'] ?? '9 AM - 9 PM'}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        ' • ',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Min ${widget.restaurant['minOrder'] ?? '15 EUR'}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          color: Colors.grey[700], size: 18),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.restaurant['address'] ??
                              'No address available',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Offers',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDealsList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDealsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_deals.isEmpty) {
      return const Card(
        margin: EdgeInsets.all(8.0),
        child: ListTile(
          title: Text('No special offers available'),
        ),
      );
    }

    return Column(
      children: _deals.map((deal) {
        return Card(
          margin: const EdgeInsets.all(8.0),
          child: ListTile(
            leading: const Icon(Icons.local_offer, color: Colors.green),
            title: Text(deal['name'] ?? 'Special Offer'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(deal['description'] ?? 'No description available'),
                const SizedBox(height: 4),
                Text(
                  'Save ${deal['savings']?.toString() ?? '0'} CHF',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            isThreeLine: true,
            trailing: _isAdmin
                ? IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Deal?'),
                              content: const Text(
                                  'Are you sure you want to delete this deal?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Delete',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          ) ??
                          false;

                      if (confirmed && deal['id'] != null) {
                        try {
                          final dealsNotifier =
                              ref.read(dealsNotifierProvider.notifier);
                          await dealsNotifier.deleteDeal(deal['id'].toString());

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Deal deleted successfully!')),
                          );

                          _fetchDealsForRestaurant();
                        } catch (error) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Error deleting deal: $error')),
                          );
                        }
                      }
                    },
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }
}

class BottomOvalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 20);
    path.quadraticBezierTo(
        size.width / 2, size.height - 40, size.width, size.height - 20);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
