import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/global_provider.dart';
import '../services/tailor_service.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  String _searchQuery = "";

  // Loading and error states
  bool _isLoading = true;
  String? _errorMessage;

  // This will hold the fetched categories from API
  Map<String, List<Map<String, String>>> serviceCategories = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchCategories(); // Fetch categories when component loads
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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
      // If gender is not recognized, add to Designers as fallback
        return 'Designers';
    }
  }

  // Method to process API response and convert to required format
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
        final subcategories = category['subcategories'] as List<dynamic>? ?? [];

        if (categoryName.isEmpty) {
          print('Warning: Category name is empty for category: $category');
          continue;
        }

        // Convert subcategories to comma-separated string
        final services = subcategories
            .map((sub) => sub['name']?.toString() ?? '')
            .where((name) => name.isNotEmpty)
            .join(',');

        final categoryData = {
          'category': categoryName,
          'services': services.isNotEmpty ? services : categoryName, // Fallback to category name if no subcategories
          'id': categoryId,
        };

        // Map gender to tab categories
        final tabCategory = _mapGenderToTab(gender);
        processedCategories[tabCategory]?.add(categoryData);

        print('Added category "$categoryName" to tab "$tabCategory" with services: "$services"');

      } catch (e) {
        print('Error processing category: $category, Error: $e');
        continue;
      }
    }

    // Log final processed categories
    processedCategories.forEach((tab, categories) {
      print('Tab "$tab" has ${categories.length} categories');
    });

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

  // Method to refresh categories
  Future<void> _refreshCategories() async {
    await _fetchCategories();
  }

  // Check if a service is selected by looking at the globalData categories
  bool _isServiceSelected(String serviceName) {
    final provider = context.read<GlobalProvider>();
    final categories = provider.getValue('categories') as List<Map<String, dynamic>>?;

    if (categories == null) return false;

    return categories.any((category) => category['category_id'] == serviceName);
  }

  // Get service details from globalData
  Map<String, dynamic>? _getServiceDetails(String serviceName) {
    final provider = context.read<GlobalProvider>();
    final categories = provider.getValue('categories') as List<Map<String, dynamic>>?;

    if (categories == null) return null;

    try {
      return categories.firstWhere(
            (category) => category['category_id'] == serviceName,
      );
    } catch (e) {
      return null;
    }
  }

  void _onServiceToggle(String serviceName, bool isSelected) {
    if (isSelected) {
      // Show service details modal to add the service
      _showServiceDetailsModal(serviceName, isNew: true);
    } else {
      // Remove service from globalData
      final provider = context.read<GlobalProvider>();
      provider.removeCategory(serviceName);
      setState(() {}); // Refresh UI
    }
  }

  void _showServiceDetailsModal(String serviceName, {bool isNew = false}) {
    final existingDetails = isNew ? null : _getServiceDetails(serviceName);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ServiceDetailsModal(
        serviceName: serviceName,
        existingDetails: existingDetails,
        onSave: (details) {
          final provider = context.read<GlobalProvider>();

          if (isNew) {
            // Add new category
            provider.addCategory(
              categoryId: serviceName,
              price: details['price'] as double,
              delivery_time: details['delivery_time'] as String? ?? '',
              display_images: (details['display_images'] as List<dynamic>?)
                  ?.map((e) => e.toString()).toList() ?? [],
              category_name: serviceName,
            );
          } else {
            // Update existing category
            provider.updateCategory(
              categoryId: serviceName,
              price: details['price'] as double?,
              deliveryTime: details['delivery_time'] as String?,
              displayImages: (details['display_images'] as List<dynamic>?)
                  ?.map((e) => e.toString()).toList(),
              categoryName: serviceName,
            );
          }

          // Print current data for debugging
          provider.printCurrentData();
          setState(() {}); // Refresh UI
        },
        onCancel: () {
          // If it was a new service being added, make sure it's not marked as selected
          if (isNew) {
            setState(() {});
          }
        },
      ),
    );
  }

  void _editServiceDetails(String serviceName) {
    _showServiceDetailsModal(serviceName, isNew: false);
  }

  bool get _canSave {
    final provider = context.read<GlobalProvider>();
    final categories = provider.getValue('categories') as List<Map<String, dynamic>>?;
    return categories != null && categories.isNotEmpty;
  }

  void _saveChanges() async {
    if (_canSave) {
      final provider = context.read<GlobalProvider>();
      final authProvider = context.read<AuthProvider>();

      provider.printCurrentData(); // Debug print

      try {
        // Show loading dialog while making API call
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

        // Prepare the request body
        final body = {
          "categories": provider.getValue("categories") ?? [],
          "portfolio_images": provider.getValue("images") ?? [],
          "name": provider.getValue("name") ?? "",
          "address": provider.getValue("address") ?? "",
          "email": provider.getValue("email") ?? "",
          "phone": provider.getValue("phone") ?? "",
        };

        print('Request body: $body'); // Debug print

        // Make API call
        final response = await tailorService.createTailorProfile(
          token: authProvider.token ?? "",
          body: body,
        );

        // Close loading dialog
        if (mounted) {
          Navigator.of(context).pop();
        }

        print('API Response: $response'); // Debug print

        // Check if API call was successful
        if (response['success'] == true) {
          // Show success dialog
          _showSuccessDialog(response['message'] ?? 'Profile created successfully');
        } else {
          // Show error via snackbar
          _showErrorSnackbar(response['message'] ?? 'Failed to create profile');
        }

      } catch (e) {
        // Close loading dialog if still open
        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }

        print('Error creating profile: $e'); // Debug print

        // Show error via snackbar
        _showErrorSnackbar('Network error: ${e.toString()}');
      }
    }
  }

  void _showSuccessDialog(String message) {
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
              'Services Saved Successfully!',
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
              // Close dialog first
              Navigator.of(context).pop();

              // Navigate to home page
              Navigator.pushReplacementNamed(context, '/home');
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
              'Services',
              style: GoogleFonts.lato(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: false,
            actions: [
              // Refresh button
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

  // Loading widget
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

  // Error widget
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

  // Main content widget
  Widget _buildMainContent(GlobalProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header and Search
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
              // Search Bar
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

        // Tab Bar
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

        // Tab Content
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

        // Save Button
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
                'Save Changes',
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

    // Show empty state if no categories available
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
          // Checkbox
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

          // Service Name and Details
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

          // Edit Details Button
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

// ServiceDetailsModal remains the same
class ServiceDetailsModal extends StatefulWidget {
  final String serviceName;
  final Map<String, dynamic>? existingDetails;
  final Function(Map<String, dynamic>) onSave;
  final VoidCallback onCancel;

  const ServiceDetailsModal({
    super.key,
    required this.serviceName,
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
  List<String> _uploadedImages = [];

  @override
  void initState() {
    super.initState();

    // Pre-fill with existing details if available
    if (widget.existingDetails != null) {
      _priceController.text = widget.existingDetails!['price']?.toString() ?? '';
      _deliveryTimeController.text = widget.existingDetails!['delivery_time']?.toString() ?? '';
      _uploadedImages = List<String>.from(widget.existingDetails!['display_images'] ?? []);
    }
  }

  Future<void> _uploadImages() async {
    try {
      // Allow multiple image selection from gallery
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        // Show loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Processing images...'),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 1),
          ),
        );

        // Simulate upload delay
        await Future.delayed(const Duration(seconds: 1));

        // Add images to list
        setState(() {
          for (XFile image in images) {
            String fileName = image.name.isEmpty
                ? 'service_${DateTime.now().millisecondsSinceEpoch}.jpeg'
                : image.name;
            _uploadedImages.add(fileName);
          }
        });

        // Show success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${images.length} image(s) uploaded successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // User cancelled
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No images selected'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading images: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
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
      ),
    );
  }

  void _viewImage(String fileName) {
    // Show image preview dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Image Preview', style: GoogleFonts.lato()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image, size: 50, color: Colors.grey[500]),
                    const SizedBox(height: 8),
                    Text(
                      fileName,
                      style: GoogleFonts.lato(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.lato()),
          ),
        ],
      ),
    );
  }

  void _saveService() {
    if (_priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the price'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final details = {
      'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
      'delivery_time': _deliveryTimeController.text.trim(),
      'display_images': _uploadedImages,
      'category_name': widget.serviceName,
    };

    widget.onSave(details);
    Navigator.pop(context);
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
              onTap: _uploadImages,
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
                      'Upload Display Image(s)',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
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
                      child: Icon(
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
                String fileName = entry.value;

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
                        child: Text(
                          fileName,
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _viewImage(fileName),
                        child: Text(
                          'View',
                          style: GoogleFonts.lato(
                            fontSize: 12,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Text(
                          'Remove',
                          style: GoogleFonts.lato(
                            fontSize: 12,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],

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