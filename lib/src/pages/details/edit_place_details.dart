import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dine_deals/src/providers/deals_provider.dart';
import 'package:dine_deals/src/providers/restaurants_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class EditPlaceDetails extends ConsumerStatefulWidget {
  final Map<String, dynamic> restaurant;

  const EditPlaceDetails({super.key, required this.restaurant});

  @override
  ConsumerState<EditPlaceDetails> createState() => _EditPlaceDetailsState();
}

class _EditPlaceDetailsState extends ConsumerState<EditPlaceDetails> {
  bool _isLoading = true;
  bool _isEditMode = false;
  List<Map<String, dynamic>> _deals = [];
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _ratingController;
  late TextEditingController _hoursController;
  final _supabase = Supabase.instance.client;
  String? _selectedImagePath;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.restaurant['name'] ?? '');
    _addressController =
        TextEditingController(text: widget.restaurant['address'] ?? '');
    _ratingController = TextEditingController(
        text: (widget.restaurant['rating'] ?? '4.5').toString());
    _hoursController = TextEditingController(
        text: widget.restaurant['hours'] ?? '9 AM - 9 PM');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDealsForRestaurant();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _ratingController.dispose();
    _hoursController.dispose();
    super.dispose();
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
      debugPrint("Error fetching deals: $error");
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

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() {
      _selectedImagePath = image.path;
      _isLoading = true;
    });

    try {
      final restaurantId = widget.restaurant['id']?.toString();
      if (restaurantId == null) {
        throw Exception('Restaurant ID not found');
      }

      // Upload to Supabase Storage
      final fileExt = path.extension(image.path);
      final fileName = 'restaurant_$restaurantId$fileExt';
      final file = File(image.path);

      // Debug output
      print('Current user: ${_supabase.auth.currentUser?.id}');
      print('Uploading to bucket: pictures');
      print('File name: $fileName');

      // Upload to 'pictures' bucket
      await _supabase.storage.from('pictures').upload(fileName, file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true));

      // Get the public URL
      final imageUrl =
          _supabase.storage.from('pictures').getPublicUrl(fileName);
      print('Generated image URL: $imageUrl'); // Add this debug line

      // Construct a raw update query
      final response = await _supabase.rpc(
        'update_restaurant_image',
        params: {
          'restaurant_id': restaurantId,
          'new_image_url': imageUrl,
        },
      );
      print('RPC response: $response');

      // Update the restaurant with the new image URL
      await _supabase
          .from('restaurants')
          .update({'image_url': imageUrl}).eq('id', restaurantId);

      // After update, fetch the row to verify
      final updatedRecord = await _supabase
          .from('restaurants')
          .select('image_url')
          .eq('id', restaurantId)
          .single();
      print('Updated record: $updatedRecord'); // Debug output to verify update

      // Update local state and refresh data
      setState(() {
        widget.restaurant['image_url'] = imageUrl;
      });

      // Refresh restaurants in provider
      ref.invalidate(restaurantsNotifierProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating image: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveRestaurantChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final restaurantId = widget.restaurant['id']?.toString();
      if (restaurantId == null) {
        throw Exception('Restaurant ID not found');
      }

      // Prepare updated data
      final updatedData = {
        'name': _nameController.text,
        'address': _addressController.text,
        'rating': double.tryParse(_ratingController.text) ?? 4.5,
        'hours': _hoursController.text,
      };

      // Update restaurant in Supabase
      await _supabase
          .from('restaurants')
          .update(updatedData)
          .eq('id', restaurantId);

      // Update local state
      setState(() {
        widget.restaurant['name'] = _nameController.text;
        widget.restaurant['address'] = _addressController.text;
        widget.restaurant['rating'] =
            double.tryParse(_ratingController.text) ?? 4.5;
        widget.restaurant['hours'] = _hoursController.text;

        // Exit edit mode
        _isEditMode = false;
      });

      // Force refresh restaurants provider
      ref.invalidate(restaurantsNotifierProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restaurant updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating restaurant: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteRestaurant() async {
    final restaurantId = widget.restaurant['id']?.toString();
    if (restaurantId == null) return;

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Restaurant?'),
            content: const Text(
              'This action cannot be undone. All associated deals will also be deleted.',
              style: TextStyle(color: Colors.red),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // First delete all deals associated with this restaurant
      await _supabase.from('deals').delete().eq('restaurant_id', restaurantId);

      // Then delete the restaurant
      await _supabase.from('restaurants').delete().eq('id', restaurantId);

      // Force refresh the restaurants provider
      final restaurantsNotifier =
          ref.read(restaurantsNotifierProvider.notifier);

      // Force a refresh by explicitly fetching with forceRefresh: true
      await restaurantsNotifier.fetchRestaurants(forceRefresh: true);

      // Make sure the provider is invalidated to trigger rebuild of UI
      ref.invalidate(restaurantsNotifierProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Restaurant deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to admin page with refresh result
        Navigator.of(context)
            .pop(true); // Return true to indicate a refresh is needed
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting restaurant: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Edit toggle button
          IconButton(
            icon: Icon(_isEditMode ? Icons.visibility : Icons.edit),
            color: _isEditMode ? Colors.blue : Colors.white,
            onPressed: () {
              setState(() {
                _isEditMode = !_isEditMode;
              });
            },
          ),
          // Delete button
          IconButton(
            icon: const Icon(Icons.delete_forever),
            color: Colors.red,
            onPressed: _deleteRestaurant,
            tooltip: 'Delete Restaurant',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDealModal,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchDealsForRestaurant,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image section with tap to change functionality
                    GestureDetector(
                      onTap: _pickAndUploadImage,
                      child: Stack(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 300,
                            child: _selectedImagePath != null
                                ? Image.file(
                                    File(_selectedImagePath!),
                                    width: double.infinity,
                                    height: 300,
                                    fit: BoxFit.cover,
                                  )
                                : Image.network(
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
                          // Camera indicator overlay
                          Positioned.fill(
                            child: Container(
                              alignment: Alignment.center,
                              color: Colors.black.withOpacity(0.2),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 50,
                              ),
                            ),
                          ),
                          // Gradient overlay at the bottom
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
                    // Display or edit restaurant details depending on mode
                    _isEditMode ? _buildEditForm() : _buildRestaurantDetails(),

                    // Deals section (always visible)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Manage Deals',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
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

  Widget _buildRestaurantDetails() {
    return Padding(
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
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.grey[700], size: 18),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.restaurant['address'] ?? 'No address available',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Action to edit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text('EDIT DETAILS'),
              onPressed: () {
                setState(() {
                  _isEditMode = true;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit Restaurant Details',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            // Name field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Restaurant Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Address field
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Rating and hours in a row
            Row(
              children: [
                // Rating field
                Expanded(
                  child: TextFormField(
                    controller: _ratingController,
                    decoration: const InputDecoration(
                      labelText: 'Rating (0-5)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.star),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final rating = double.tryParse(value);
                      if (rating == null) {
                        return 'Invalid number';
                      }
                      if (rating < 0 || rating > 5) {
                        return 'Rating must be between 0-5';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Hours field
                Expanded(
                  child: TextFormField(
                    controller: _hoursController,
                    decoration: const InputDecoration(
                      labelText: 'Hours',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.access_time),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action buttons row
            Row(
              children: [
                // Cancel button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Reset form and exit edit mode
                      _nameController.text = widget.restaurant['name'] ?? '';
                      _addressController.text =
                          widget.restaurant['address'] ?? '';
                      _ratingController.text =
                          (widget.restaurant['rating'] ?? '4.5').toString();
                      _hoursController.text =
                          widget.restaurant['hours'] ?? '9 AM - 9 PM';

                      setState(() {
                        _isEditMode = false;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('CANCEL'),
                  ),
                ),
                const SizedBox(width: 16),
                // Save button
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveRestaurantChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('SAVE CHANGES'),
                  ),
                ),
              ],
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
          subtitle: Text('Use the + button to add new deals'),
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    // Edit deal functionality
                    // TODO: Implement edit deal
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Edit deal functionality coming soon')),
                    );
                  },
                ),
                IconButton(
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
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
