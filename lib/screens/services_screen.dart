import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../providers/auth_provider.dart';
import '../providers/global_provider.dart';
import '../providers/kyc_provider.dart';
import '../services/tailor_service.dart';
import '../services/location_service.dart';

class ServicesScreen extends StatefulWidget {
  final bool isEditMode;
  final List<dynamic>? existingCategories;

  const ServicesScreen({
    super.key,
    this.isEditMode = false,
    this.existingCategories,
  });

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  String _searchQuery = "";
  final LocationService _locationService = LocationService();

  // Loading and error states
  bool _isLoading = true;
  String? _errorMessage;

  // This will hold the fetched categories from API
  Map<String, List<Map<String, String>>> serviceCategories = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Clear categories from GlobalProvider to prevent interference
    final provider = Provider.of<GlobalProvider>(context, listen: false);
    provider.globalData['categories'] = <Map<String, dynamic>>[];

    _fetchCategories(); // Fetch categories when component loads

    // If in edit mode, pre-populate existing services after categories are loaded
    if (widget.isEditMode && widget.existingCategories != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _prePopulateExistingServices();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();

    // Only clear categories if we're in edit mode and user is navigating away without saving
    // This prevents edit mode changes from affecting KYC flow
    if (widget.isEditMode) {
      final provider = Provider.of<GlobalProvider>(context, listen: false);
      provider.globalData['categories'] = <Map<String, dynamic>>[];
    }

    super.dispose();
  }

  // Method to fetch categories from API
  Future<void> _fetchCategories() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final tailorService = TailorService();

      // Make API call to get categories
      final response = await tailorService.getServiceCategories(
        token: authProvider.token ?? "",
      );

      print('API Response: $response'); // Debug print

      // Process the response and update serviceCategories
      if (response['success'] == true) {
        final responseData = response['data'] as Map<String, dynamic>;
        print('response, ${responseData}');
        print('Categories data: ${responseData['categories']}'); // Debug print

        final processedCategories = _processApiCategories(responseData);
        print('Processed categories: $processedCategories'); // Debug print

        setState(() {
          serviceCategories = processedCategories;
          _isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch categories');
      }

    } catch (e) {
      print('Error fetching categories: $e'); // Debug print

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading categories: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      // Fallback to default categories if API fails
      _setDefaultCategories();
    }
  }

  // Helper method to map API gender to tab categories
  String _mapGenderToTab(String gender) {
    switch (gender.toLowerCase().trim()) {
      case 'male':
      case 'men':
      case 'man':
        return 'Men';
      case 'female':
      case 'women':
      case 'woman':
        return 'Women';
      case 'kids':
      case 'children':
      case 'child':
      case 'kid':
        return 'Kids';
      case 'unisex':
      case 'designer':
      case 'designers':
      case 'custom':
        return 'Designers';
      default:
        return 'Designers';
    }
  }

  Map<String, List<Map<String, String>>> _processApiCategories(Map<String, dynamic> apiData) {
    Map<String, List<Map<String, String>>> processedCategories = {
      'Men': [],
      'Women': [],
      'Kids': [],
      'Designers': [],
    };

    final categories = apiData['categories'] as List<dynamic>? ?? [];

    if (categories.isEmpty) {
      print('Warning: No categories found in API response');
      return processedCategories;
    }

    for (var category in categories) {
      try {
        final gender = category['gender']?.toString() ?? '';
        final categoryName = category['name']?.toString() ?? '';
        final categoryId = category['id']?.toString() ?? '';
        final sub_categories = category['sub_categories'] as List<dynamic>? ?? [];

        if (categoryName.isEmpty || categoryId.isEmpty) {
          print('Warning: Category name or ID is empty for category: $category');
          continue;
        }

        // Convert sub_categories to comma-separated string
        final services = sub_categories
            .map((sub) => sub['name']?.toString() ?? '')
            .where((name) => name.isNotEmpty)
            .join(',');

        final categoryData = {
          'category': categoryName,
          'services': services.isNotEmpty ? services : categoryName,
          'id': categoryId,
        };

        final tabCategory = _mapGenderToTab(gender);
        processedCategories[tabCategory]?.add(categoryData);

        print('Added category "$categoryName" (ID: $categoryId) to tab "$tabCategory"');

      } catch (e) {
        print('Error processing category: $category, Error: $e');
        continue;
      }
    }

    return processedCategories;
  }

  // Fallback method to set default categories if API fails
  void _setDefaultCategories() {
    setState(() {
      serviceCategories = {
        'Men': [
          {'category': 'Shirts', 'services': 'Formal shirts,Casual shirts'},
          {'category': 'Suits & Blazers', 'services': '3 piece,2 piece,Double breasted,Tuxedo,Waist Coat,Blazer'},
          {'category': 'Sherwani', 'services': 'Indo Western'},
        ],
        'Women': [
          {'category': 'Dresses', 'services': 'Casual dresses,Formal dresses,Party dresses'},
          {'category': 'Suits', 'services': 'Business suits,Traditional suits'},
          {'category': 'Blouses', 'services': 'Silk blouses,Cotton blouses'},
        ],
        'Kids': [
          {'category': 'Shirts', 'services': 'Casual shirts,Formal shirts'},
          {'category': 'Dresses', 'services': 'Party dresses,School uniforms'},
        ],
        'Designers': [
          {'category': 'Custom Designs', 'services': 'Wedding wear,Party wear,Formal wear'},
        ],
      };
    });
  }

  // Method to pre-populate existing services in edit mode
  void _prePopulateExistingServices() {
    if (!widget.isEditMode || widget.existingCategories == null) return;

    final provider = Provider.of<GlobalProvider>(context, listen: false);

    // Clear existing categories
    provider.globalData['categories'] = <Map<String, dynamic>>[];

    // Process each existing category
    for (var category in widget.existingCategories!) {
      try {
        final categoryId = category['category_id']?.toString() ?? '';
        final subCategoryName = category['sub_category_name']?.toString() ?? '';
        final price = (category['price'] is int)
            ? (category['price'] as int).toDouble()
            : (category['price'] as double?) ?? 0.0;
        final deliveryTime = category['delivery_time']?.toString() ?? '';
        final displayImages = (category['display_images'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ?? [];

        if (categoryId.isNotEmpty && subCategoryName.isNotEmpty) {
          provider.addCategory(
            categoryId: categoryId,
            price: price,
            delivery_time: deliveryTime,
            display_images: displayImages,
            sub_category_name: subCategoryName,
          );
        }
      } catch (e) {
        print('Error pre-populating category: $e');
      }
    }

    setState(() {});

    debugPrint('✅ Pre-populated ${widget.existingCategories!.length} services in edit mode');
  }

  // Method to refresh categories
  Future<void> _refreshCategories() async {
    await _fetchCategories();
  }

  // Check if a service is selected
  bool _isServiceSelected(String serviceName) {
    final provider = context.read<GlobalProvider>();
    final categories = provider.getCategories();

    return categories.any((category) => category['sub_category_name'] == serviceName);
  }

  // Get service details
  Map<String, dynamic>? _getServiceDetails(String serviceName) {
    final provider = context.read<GlobalProvider>();
    final categories = provider.getCategories();

    try {
      return categories.firstWhere(
            (category) => category['sub_category_name'] == serviceName,
      );
    } catch (e) {
      return null;
    }
  }

  void _onServiceToggle(String serviceName, bool isSelected) {
    if (isSelected) {
      _showServiceDetailsModal(serviceName, isNew: true);
    } else {
      // Deselect and remove from global provider
      final provider = Provider.of<GlobalProvider>(context, listen: false);
      final categories = provider.getCategories();

      // Remove the category with matching sub_category_name
      categories.removeWhere((category) => category['sub_category_name'] == serviceName);

      // Trigger update
      provider.notifyListeners();
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$serviceName removed'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showServiceDetailsModal(String serviceName, {bool isNew = false}) {
    final existingDetails = isNew ? null : _getServiceDetails(serviceName);

    // Find the category ID for this service
    String? categoryId;
    for (var tab in serviceCategories.values) {
      for (var categoryData in tab) {
        final services = categoryData['services']!.split(',').map((s) => s.trim()).toList();
        if (services.contains(serviceName)) {
          categoryId = categoryData['id'];
          break;
        }
      }
      if (categoryId != null) break;
    }

    if (categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Category ID not found'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (BuildContext modalContext) => ServiceDetailsModal(
        serviceName: serviceName,
        categoryId: categoryId!,
        existingDetails: existingDetails,
        onSave: (details) {
          final provider = Provider.of<GlobalProvider>(context, listen: false);

          if (isNew) {
            provider.addCategory(
              categoryId: categoryId!,
              price: details['price'] as double,
              delivery_time: details['delivery_time'] as String?,
              display_images: (details['display_images'] as List<dynamic>?)
                  ?.map((e) => e.toString()).toList(),
              sub_category_name: serviceName,
            );

          } else {
            // Update existing service
            final categories = provider.getCategories();
            final index = categories.indexWhere(
                    (cat) => cat['sub_category_name'] == serviceName
            );

            if (index != -1) {
              categories[index] = {
                'category_id': categoryId!,
                'price': details['price'] as double,
                'delivery_time': details['delivery_time'] as String? ?? '',
                'display_images': (details['display_images'] as List<dynamic>?)
                    ?.map((e) => e.toString()).toList() ?? [],
                'sub_category_name': serviceName,
              };
              provider.notifyListeners();
            }

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$serviceName updated. Click "Update Services" to save all changes.'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }

          // Update state and close modal without navigating back
          if (mounted) {
            setState(() {});
          }
          Navigator.of(modalContext).pop(); // Only close the modal, not the screen
        },
        onCancel: () {
          if (isNew) {
            final provider = Provider.of<GlobalProvider>(context, listen: false);
            final categories = provider.getCategories();

            categories.removeWhere((category) =>
            category['sub_category_name'] == serviceName
            );

            provider.notifyListeners();
            if (mounted) {
              setState(() {});
            }
          }
          Navigator.of(modalContext).pop(); // Only close the modal
        },
      ),
    );
  }

  void _editServiceDetails(String serviceName) {
    _showServiceDetailsModal(serviceName, isNew: false);
  }

  bool get _canSave {
    final provider = context.read<GlobalProvider>();
    final categories = provider.getCategories();
    return categories.isNotEmpty;
  }

  void _saveChanges() async {
    if (_canSave) {
      final provider = context.read<GlobalProvider>();
      final authProvider = context.read<AuthProvider>();

      // If in edit mode, call update API
      if (widget.isEditMode) {
        try {
          // Show loading dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: Colors.red,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Updating your services...',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );

          final tailorService = TailorService();

          final body = {
            "categories": provider.globalData['categories'] ?? [],
          };

          print('Update Request body: $body');

          final response = await tailorService.updateTailorProfile(
            token: authProvider.token ?? "",
            body: body,
          );

          if (mounted) {
            Navigator.of(context).pop(); // Close loading dialog
          }

          print('Update API Response: $response');

          if (response['success'] == true) {
            // Clear categories after successful save to prevent affecting KYC flow
            provider.globalData['categories'] = <Map<String, dynamic>>[];

            _showSuccessDialog(
              response['message'] ?? 'Services updated successfully',
              isEditMode: true,
            );
          } else {
            _showErrorSnackbar(response['message'] ?? 'Failed to update services');
          }

        } catch (e) {
          if (mounted && Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }

          print('Error updating services: $e');
          _showErrorSnackbar('Network error: ${e.toString()}');
        }
      } else {
        // Original create profile flow
        // Fetch location silently
        Map<String, double>? location;
        try {
          debugPrint('📍 Fetching location...');
          location = await _locationService.getCurrentLocation();
          if (location != null) {
            debugPrint('✅ Location fetched: ${location['latitude']}, ${location['longitude']}');
            provider.setValue('location', location);
          } else {
            debugPrint('⚠️ Location not available, continuing without it');
          }
        } catch (e) {
          debugPrint('⚠️ Location fetch failed, continuing without it: $e');
          location = null;
        }

        provider.printCurrentData();

        try {
          // Show loading dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: Colors.red,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Saving your profile...',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Please wait while we create your tailor profile.',
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );

          final tailorService = TailorService();

          final body = {
            "categories": provider.globalData['categories'] ?? [],
            "portfolio_images": provider.globalData['images'] ?? [],
            "name": provider.globalData['name'] ?? "",
            "address": provider.globalData['address'] ?? "",
            "email": provider.globalData['email'] ?? "",
            "phone": provider.globalData['phone'] ?? "",
          };

          print('Request body: $body');

          final response = await tailorService.createTailorProfile(
            token: authProvider.token ?? "",
            body: provider.getAllData(),
          );

          if (mounted) {
            Navigator.of(context).pop();
          }

          print('API Response: $response');

          if (response['success'] == true) {
            _showSuccessDialog(
              response['message'] ?? 'Profile created successfully',
              isEditMode: false,
            );
          } else {
            _showErrorSnackbar(response['message'] ?? 'Failed to create profile');
          }

        } catch (e) {
          if (mounted && Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }

          print('Error creating profile: $e');
          _showErrorSnackbar('Network error: ${e.toString()}');
        }
      }
    }
  }

  void _showSuccessDialog(String message, {required bool isEditMode}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isEditMode ? 'All Services Updated Successfully!' : 'Services Saved Successfully!',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: GoogleFonts.lato(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              if (isEditMode) {
                // Return true to indicate success and go back to profile
                Navigator.of(context).pop(true);
              } else {
                // Original flow - go to home
                Navigator.pushReplacementNamed(context, '/home');
              }
            },
            child: Text(
              'Continue',
              style: GoogleFonts.lato(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(String errorMessage) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  errorMessage,
                  style: GoogleFonts.lato(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GlobalProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              widget.isEditMode ? 'Edit Services' : 'Services',
              style: GoogleFonts.lato(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.black),
                onPressed: _isLoading ? null : _refreshCategories,
              ),
            ],
          ),
          body: _isLoading
              ? _buildLoadingWidget()
              : _errorMessage != null
              ? _buildErrorWidget()
              : _buildMainContent(provider),
        );
      },
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading categories...',
            style: GoogleFonts.lato(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load categories',
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage ?? 'Unknown error occurred',
              style: GoogleFonts.lato(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _refreshCategories,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Retry',
              style: GoogleFonts.lato(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(GlobalProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select your Services',
                style: GoogleFonts.lato(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.lato(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Search services',
                    hintStyle: GoogleFonts.lato(
                      color: Colors.grey[500],
                      fontSize: 16,
                    ),
                    suffixIcon: Icon(
                      Icons.search,
                      color: Colors.grey[500],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim().toLowerCase();
                    });
                  },
                ),
              ),
            ],
          ),
        ),

        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          child: TabBar(
            controller: _tabController,
            isScrollable: false,
            labelColor: Colors.red.shade400,
            unselectedLabelColor: Colors.black,
            labelStyle: GoogleFonts.lato(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.lato(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            indicatorColor: Colors.red.shade400,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Men'),
              Tab(text: 'Women'),
              Tab(text: 'Kids'),
              Tab(text: 'Designers'),
            ],
          ),
        ),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildServicesList('Men'),
              _buildServicesList('Women'),
              _buildServicesList('Kids'),
              _buildServicesList('Designers'),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            height: 55,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _canSave
                    ? [Colors.red.shade300, Colors.red.shade400]
                    : [Colors.grey.shade300, Colors.grey.shade400],
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: _canSave
                  ? [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ]
                  : [],
            ),
            child: ElevatedButton(
              onPressed: _canSave ? _saveChanges : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(
                widget.isEditMode ? 'Update Services' : 'Save Changes',
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServicesList(String category) {
    final categories = serviceCategories[category] ?? [];

    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No services available in $category',
              style: GoogleFonts.lato(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: categories.map((categoryData) {
          final categoryName = categoryData['category']!;
          final services = categoryData['services']!
              .split(',')
              .map((s) => s.trim())
              .where((s) => _searchQuery.isEmpty || s.toLowerCase().contains(_searchQuery))
              .toList();

          return services.isEmpty
              ? const SizedBox.shrink()
              : Container(
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryName,
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...services.map((service) => _buildServiceItem(service)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildServiceItem(String serviceName) {
    final bool isSelected = _isServiceSelected(serviceName);
    final serviceDetails = _getServiceDetails(serviceName);
    final bool hasDetails = serviceDetails != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _onServiceToggle(serviceName, !isSelected),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? Colors.red.shade400 : Colors.transparent,
                border: Border.all(
                  color: isSelected ? Colors.red.shade400 : Colors.grey.shade400,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: isSelected
                  ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              )
                  : null,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  serviceName,
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                if (isSelected && hasDetails) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Price: ₹${serviceDetails!['price']} ${serviceDetails['delivery_time']?.isNotEmpty == true ? '• ${serviceDetails['delivery_time']}' : ''}',
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (isSelected && hasDetails)
            GestureDetector(
              onTap: () => _editServiceDetails(serviceName),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  'Edit Details',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ServiceDetailsModal extends StatefulWidget {
  final String serviceName;
  final String categoryId;
  final Map<String, dynamic>? existingDetails;
  final Function(Map<String, dynamic>) onSave;
  final VoidCallback onCancel;

  const ServiceDetailsModal({
    super.key,
    required this.serviceName,
    required this.categoryId,
    this.existingDetails,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<ServiceDetailsModal> createState() => _ServiceDetailsModalState();
}

class _ServiceDetailsModalState extends State<ServiceDetailsModal> {
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _deliveryTimeController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<Map<String, String>> _uploadedImages = []; // {fileName, url}
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();

    // Pre-fill with existing details if available
    if (widget.existingDetails != null) {
      _priceController.text = widget.existingDetails!['price']?.toString() ?? '';
      _deliveryTimeController.text = widget.existingDetails!['delivery_time']?.toString() ?? '';

      final existingImageUrls = List<String>.from(widget.existingDetails!['display_images'] ?? []);
      _uploadedImages = existingImageUrls.map((url) {
        final fileName = url.split('/').last;
        return {
          'fileName': fileName,
          'url': url,
        };
      }).toList();
    }
  }

  Future<void> _uploadImage() async {
    if (_isUploadingImage) return;

    try {
      // Single image selection
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _isUploadingImage = true;
        });

        final file = File(image.path);
        final fileName = path.basename(image.path);

        // Get token from AuthProvider
        final token = Provider.of<AuthProvider>(context, listen: false).token;
        if (token == null) {
          setState(() {
            _isUploadingImage = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User not logged in.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }

        // Upload document via KycProvider
        final documentType = 'service_${widget.serviceName}_${DateTime.now().millisecondsSinceEpoch}';
        await Provider.of<KycProvider>(context, listen: false)
            .uploadDocument(file, documentType, token);

        // Get the uploaded URL from KycProvider
        final imageUrl = Provider.of<KycProvider>(context, listen: false).uploadedUrls[documentType];

        if (imageUrl != null) {
          setState(() {
            _uploadedImages.add({
              'fileName': fileName,
              'url': imageUrl,
            });
            _isUploadingImage = false;
          });

          debugPrint("=== 📸 SERVICE IMAGE UPLOADED ===");
          debugPrint("📄 File Name: $fileName");
          debugPrint("🔗 URL: $imageUrl");
          debugPrint("💾 Total Images: ${_uploadedImages.length}");
          debugPrint("=================================");

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image uploaded successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          setState(() {
            _isUploadingImage = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Upload failed - no URL returned'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() {
          _isUploadingImage = false;
        });
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading image: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _uploadedImages.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image removed'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _viewImage(String fileName, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Image Preview',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Image preview
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 400),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, size: 50, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              'Unable to load image',
                              style: GoogleFonts.lato(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        padding: const EdgeInsets.all(60),
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // File name
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  fileName,
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveService() {
    if (_priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the price'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Extract URLs from uploaded images
    final imageUrls = _uploadedImages.map((img) => img['url']!).toList();

    final details = {
      'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
      'delivery_time': _deliveryTimeController.text.trim(),
      'display_images': imageUrls,
      'sub_category_name': widget.serviceName,
    };

    widget.onSave(details);
    // Don't call Navigator.pop here - let onSave callback handle it
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  'Service Details',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  ' • ${widget.serviceName}',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Price
            Text(
              'Price *',
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                  controller: _priceController,
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter the price',
                    hintStyle: GoogleFonts.lato(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                    prefixText: '₹ ',
                    prefixStyle: GoogleFonts.lato(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ]
              ),
            ),

            const SizedBox(height: 24),

            // Delivery Time
            Text(
              'Delivery Time',
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _deliveryTimeController,
                style: GoogleFonts.lato(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g., 3-5 days',
                  hintStyle: GoogleFonts.lato(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Display Image
            Text(
              'Display Images',
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),

            // Upload Images Section
            GestureDetector(
              onTap: _isUploadingImage ? null : _uploadImage,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Upload Display Image',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: _isUploadingImage ? Colors.grey[400] : Colors.black,
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.red.shade300,
                          width: 2,
                        ),
                      ),
                      child: _isUploadingImage
                          ? Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: CircularProgressIndicator(
                          color: Colors.red,
                          strokeWidth: 2,
                        ),
                      )
                          : Icon(
                        Icons.upload,
                        color: Colors.red.shade400,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Uploaded Images List
            if (_uploadedImages.isNotEmpty) ...[
              const SizedBox(height: 16),
              ..._uploadedImages.asMap().entries.map((entry) {
                int index = entry.key;
                String fileName = entry.value['fileName'] ?? '';
                String imageUrl = entry.value['url'] ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fileName,
                              style: GoogleFonts.lato(
                                fontSize: 14,
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.cloud_done,
                                  size: 12,
                                  color: Colors.blue[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Uploaded',
                                  style: GoogleFonts.lato(
                                    fontSize: 11,
                                    color: Colors.blue[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _viewImage(fileName, imageUrl),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: Text(
                            'View',
                            style: GoogleFonts.lato(
                              fontSize: 12,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: Text(
                            'Remove',
                            style: GoogleFonts.lato(
                              fontSize: 12,
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],

            const SizedBox(height: 16),

            // Helper text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.blue[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can upload multiple images one at a time',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Save Button
            Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                color: Colors.red.shade400,
                borderRadius: BorderRadius.circular(25),
              ),
              child: ElevatedButton(
                onPressed: _saveService,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  widget.existingDetails != null ? 'Update Service' : 'Add Service',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    _deliveryTimeController.dispose();
    super.dispose();
  }
}