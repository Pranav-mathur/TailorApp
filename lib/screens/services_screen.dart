import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  // Track selected services and their details
  Map<String, bool> selectedServices = {};
  Map<String, Map<String, dynamic>> serviceDetails = {};
  String _searchQuery = "";


  // Service categories data
  final Map<String, List<Map<String, String>>> serviceCategories = {
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Start with empty state - no pre-selected services
    selectedServices = {};
    serviceDetails = {};
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onServiceToggle(String serviceName, bool isSelected) {
    if (isSelected) {
      // Show service details modal
      _showServiceDetailsModal(serviceName);
    } else {
      // Remove service
      setState(() {
        selectedServices[serviceName] = false;
        serviceDetails.remove(serviceName);
      });
    }
  }

  void _showServiceDetailsModal(String serviceName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ServiceDetailsModal(
        serviceName: serviceName,
        existingDetails: serviceDetails[serviceName],
        onSave: (details) {
          setState(() {
            selectedServices[serviceName] = true;
            serviceDetails[serviceName] = details;
          });
        },
        onCancel: () {
          setState(() {
            selectedServices[serviceName] = false;
          });
        },
      ),
    );
  }

  void _editServiceDetails(String serviceName) {
    _showServiceDetailsModal(serviceName);
  }

  bool get _canSave {
    return selectedServices.values.any((selected) => selected == true) &&
        selectedServices.entries
            .where((entry) => entry.value == true)
            .every((entry) => serviceDetails.containsKey(entry.key));
  }

  void _saveChanges() {
    if (_canSave) {
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
                'Your services have been configured and are ready to use.',
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
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                      (route) => false, // Remove all previous routes
                );
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
  }

  @override
  Widget build(BuildContext context) {
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
      ),
      body: Column(
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
      ),
    );
  }

  Widget _buildServicesList(String category) {
    final categories = serviceCategories[category] ?? [];


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
    final bool isSelected = selectedServices[serviceName] ?? false;
    final bool hasDetails = serviceDetails.containsKey(serviceName);

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

          // Service Name
          Expanded(
            child: Text(
              serviceName,
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),

          // Edit Details Button
          if (isSelected && hasDetails)
            GestureDetector(
              onTap: () => _editServiceDetails(serviceName),
              child: Text(
                'Edit Details',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: Colors.red.shade400,
                  fontWeight: FontWeight.w500,
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
      _priceController.text = widget.existingDetails!['price'] ?? '';
      _deliveryTimeController.text = widget.existingDetails!['deliveryTime'] ?? '';
      _uploadedImages = List<String>.from(widget.existingDetails!['images'] ?? []);
    }
    // No pre-filled data for new services - let user input everything
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

  void _addService() {
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
      'price': _priceController.text.trim(),
      'deliveryTime': _deliveryTimeController.text.trim(),
      'images': _uploadedImages,
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
                  'Shirts',
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
              'Price',
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
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Display Image
            Text(
              'Display Image',
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

            // Add Service Button
            Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                color: Colors.red.shade400,
                borderRadius: BorderRadius.circular(25),
              ),
              child: ElevatedButton(
                onPressed: _addService,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  'Add Service',
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