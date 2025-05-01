import 'package:dine_deals/src/pages/details/edit_place_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dine_deals/src/providers/deals_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dine_deals/src/providers/user_provider.dart';

class PlaceDetails extends ConsumerStatefulWidget {
  final Map<String, dynamic> restaurant;

  const PlaceDetails({super.key, required this.restaurant});

  @override
  ConsumerState<PlaceDetails> createState() => _PlaceDetailsState();
}

class _PlaceDetailsState extends ConsumerState<PlaceDetails> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _deals = [];
  bool _isFavorite = false;
  bool _isSuperAdmin = false;

  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDealsForRestaurant();
      _checkFavoriteStatus();
    });
  }

  Future<void> _checkFavoriteStatus() async {
    final restaurantId = widget.restaurant['id']?.toString();
    if (restaurantId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList('favorites') ?? [];

    setState(() {
      _isFavorite = favorites.contains(restaurantId);
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final response = await _supabase
            .from('users')
            .select('favorites')
            .eq('id', user.id)
            .single();

        final serverFavorites = List<String>.from(response['favorites'] ?? []);

        if (mounted) {
          setState(() {
            _isFavorite = serverFavorites.contains(restaurantId);
          });

          if (_isFavorite != favorites.contains(restaurantId)) {
            await prefs.setStringList('favorites', serverFavorites);
          }
        }
      }
    } catch (e) {
      print('Error checking favorites: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    final restaurantId = widget.restaurant['id']?.toString();
    if (restaurantId == null) return;

    setState(() {
      _isFavorite = !_isFavorite;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = prefs.getStringList('favorites') ?? [];

      if (_isFavorite) {
        if (!favorites.contains(restaurantId)) {
          favorites.add(restaurantId);
        }
      } else {
        favorites.remove(restaurantId);
      }

      await prefs.setStringList('favorites', favorites);

      final user = _supabase.auth.currentUser;
      if (user != null) {
        final response = await _supabase
            .from('users')
            .select('favorites')
            .eq('id', user.id)
            .single();

        List<String> serverFavorites = [];
        if (response['favorites'] != null) {
          serverFavorites = List<String>.from(response['favorites']);
        }

        if (_isFavorite) {
          if (!serverFavorites.contains(restaurantId)) {
            serverFavorites.add(restaurantId);
          }
        } else {
          serverFavorites.remove(restaurantId);
        }

        await _supabase
            .from('users')
            .update({'favorites': serverFavorites}).eq('id', user.id);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              _isFavorite ? 'Added to favorites' : 'Removed from favorites'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() {
        _isFavorite = !_isFavorite;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating favorites: $e'),
          backgroundColor: Colors.red,
        ),
      );
      print('Error toggling favorite: $e');
    }
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

  void _showMenuBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: Column(
            children: [
              const SizedBox(height: 10),
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
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Menu',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMenuCategory('Salads', [
                          {'name': 'Greek Salad', 'price': '12.50'},
                          {'name': 'Caesar Salad', 'price': '14.00'},
                          {'name': 'Garden Salad', 'price': '9.50'},
                        ]),
                        _buildMenuCategory('Main Courses', [
                          {'name': 'Grilled Salmon', 'price': '24.00'},
                          {'name': 'Beef Steak', 'price': '28.50'},
                          {'name': 'Vegetable Pasta', 'price': '18.00'},
                        ]),
                        _buildMenuCategory('Desserts', [
                          {'name': 'Chocolate Cake', 'price': '8.50'},
                          {'name': 'Ice Cream', 'price': '6.00'},
                          {'name': 'Fruit Salad', 'price': '7.50'},
                        ]),
                        _buildMenuCategory('Drinks', [
                          {'name': 'Fresh Orange Juice', 'price': '5.00'},
                          {'name': 'Sparkling Water', 'price': '3.50'},
                          {'name': 'Coffee', 'price': '4.00'},
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuCategory(String title, List<Map<String, String>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Divider(),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item['name'] ?? ''),
                  Text(
                    '${item['price']} CHF',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Access user data from userNotifierProvider
    final userState = ref.watch(userNotifierProvider);

    // Check super admin status whenever user data changes
    userState.whenData((userData) {
      if (userData != null) {
        final isSuperAdmin = userData['is_super_admin']?.toString() ?? 'false';
        setState(() {
          _isSuperAdmin = isSuperAdmin.toLowerCase() == 'true';
        });
      }
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_isSuperAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.7),
                ),
                child: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.black),
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) =>
                          EditPlaceDetails(restaurant: widget.restaurant),
                    ),
                  ),
                  tooltip: 'Edit Place Details',
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPlaceDetails,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 300,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.network(
                            widget.restaurant['image_url'] ??
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
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 60,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withOpacity(0.0),
                                  Colors.white.withOpacity(0.7),
                                  Colors.white,
                                ],
                                stops: const [0.0, 0.7, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ],
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
                    Row(
                      children: [
                        Expanded(
                          flex: 75,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.menu_book,
                                color: Colors.black),
                            label: const Text(
                              'Menu',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () => _showMenuBottomSheet(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: IconButton(
                            icon: Icon(
                              _isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: _isFavorite ? Colors.red : Colors.black,
                            ),
                            onPressed: _toggleFavorite,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.share, color: Colors.black),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Share functionality triggered')),
                              );
                            },
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
          ),
        );
      }).toList(),
    );
  }

  Future<void> _refreshPlaceDetails() async {
    await Future.wait([
      _fetchDealsForRestaurant(),
      _checkFavoriteStatus(),
    ]);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Place details refreshed'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void editPlaceDetails() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit functionality will be implemented here'),
        duration: Duration(seconds: 2),
      ),
    );
    // TODO: Navigate to edit page or show edit dialog
  }
}
