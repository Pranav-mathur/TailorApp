import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../providers/auth_provider.dart';
import '../providers/kyc_provider.dart';
import '../services/tailor_service.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedCategoryIndex = 0;
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];

  bool _isLoading = true;
  Map<String, dynamic>? _apiData;
  Map<String, dynamic>? _profileData;
  List<Map<String, dynamic>> _categories = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfileData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final tailorService = TailorService();
      final result = await tailorService.getTailorProfile(token: authProvider.token ?? "",);
      print(result);

      if (result['success']) {
        final apiData = result['data'];
        _processApiData(apiData);
      } else {
        setState(() {
          _errorMessage = result['error'];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading profile: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _processApiData(Map<String, dynamic> apiData) {
    _apiData = apiData;

    final categoriesMap = <String, Map<String, dynamic>>{};

    for (var category in apiData['categories']) {
      final gender = category['category_gender'] as String;
      String categoryKey;

      if (gender == 'men') {
        categoryKey = 'Men';
      } else if (gender == 'women') {
        categoryKey = 'Women';
      } else {
        categoryKey = 'Unisex';
      }

      if (!categoriesMap.containsKey(categoryKey)) {
        categoriesMap[categoryKey] = {
          'name': categoryKey,
          'image': _getCategoryImage(categoryKey),
          'color': _getCategoryColor(categoryKey),
          'gender': gender,
        };
      }
    }

    final deliveryTimes = apiData['categories']
        .map((c) => c['delivery_time'] as String)
        .toList();
    final avgDeliveryTime = deliveryTimes.isNotEmpty
        ? deliveryTimes.first
        : '3-5 days';

    final prices = apiData['categories']
        .map((c) => c['price'] as int)
        .toList();
    final minPrice = prices.isNotEmpty
        ? prices.reduce((a, b) => a < b ? a : b)
        : 0;

    final transformedData = {
      'businessProfile': {
        'name': apiData['name'] ?? 'Tailor',
        'logo': apiData['profile_pic'] ?? '',
        'rating': (apiData['ratingsAndReviews']['avg_rating'] ?? 0.0).toDouble(),
        'totalReviews': apiData['ratingsAndReviews']['review_count'] ?? 0,
        'googleRating': (apiData['ratingsAndReviews']['avg_rating'] ?? 0.0).toDouble(),
        'deliveryTime': avgDeliveryTime,
        'startingPrice': minPrice,
        'isOnline': true,
        'description': 'Professional tailoring services',
        'address': _formatAddress(apiData['address']),
        'phone': apiData['address']['mobile'] ?? '',
        'kyc_done': apiData['kyc_done'] ?? false,
        'is_sponsored': apiData['is_sponsored'] ?? false,
      },
      'services': _transformServices(apiData['categories']),
      'gallery': _transformGallery(apiData['categories']),
      'reviews': [],
    };

    setState(() {
      _profileData = transformedData;
      _categories = categoriesMap.values.toList();
      if (_categories.isNotEmpty) {
        _selectedCategoryIndex = 0;
      }
    });
  }

  String _getCategoryImage(String category) {
    switch (category) {
      case 'Men':
        return 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&q=80';
      case 'Women':
        return 'https://images.unsplash.com/photo-1494790108755-2616b332c3a2?w=200&q=80';
      case 'Unisex':
        return 'https://images.unsplash.com/photo-1503944583220-79d8926ad5e2?w=200&q=80';
      default:
        return 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=200&q=80';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Men':
        return const Color(0xFFE8F5E8);
      case 'Women':
        return const Color(0xFFFFF4E6);
      case 'Unisex':
        return const Color(0xFFE3F2FD);
      default:
        return const Color(0xFFF0E6FF);
    }
  }

  String _formatAddress(Map<String, dynamic> address) {
    final parts = <String>[];
    if (address['street'] != null && address['street'].toString().isNotEmpty) {
      parts.add(address['street']);
    }
    if (address['city'] != null && address['city'].toString().isNotEmpty) {
      parts.add(address['city']);
    }
    if (address['state'] != null && address['state'].toString().isNotEmpty) {
      parts.add(address['state']);
    }
    if (address['pincode'] != null && address['pincode'].toString().isNotEmpty) {
      parts.add(address['pincode']);
    }
    return parts.join(', ');
  }

  Map<String, List<Map<String, dynamic>>> _transformServices(List<dynamic> categories) {
    final services = <String, List<Map<String, dynamic>>>{
      'men': [],
      'women': [],
      'unisex': [],
    };

    final groupedCategories = <String, Map<String, dynamic>>{};

    for (var category in categories) {
      final gender = category['category_gender'] as String;
      final categoryName = category['category_name'] as String;
      final key = '$gender-$categoryName';

      if (!groupedCategories.containsKey(key)) {
        groupedCategories[key] = <String, dynamic>{
          'gender': gender,
          'category_name': categoryName,
          'items': <dynamic>[],
        };
      }
      (groupedCategories[key]!['items'] as List).add(category);
    }

    for (var entry in groupedCategories.values) {
      final gender = entry['gender'] as String;
      final categoryName = entry['category_name'] as String;
      final items = entry['items'] as List<dynamic>;

      final serviceItem = {
        'category': categoryName,
        'items': items.map((item) => {
          'name': item['sub_category_name'],
          'price': item['price'],
          'image': (item['display_images'] as List).isNotEmpty
              ? item['display_images'][0]
              : 'https://via.placeholder.com/300',
          'deliveryTime': item['delivery_time'],
          'category_id': item['category_id'],
          'categoryData': item,
        }).toList(),
      };

      if (gender == 'men') {
        services['men']!.add(serviceItem);
      } else if (gender == 'women') {
        services['women']!.add(serviceItem);
      } else {
        services['unisex']!.add(serviceItem);
      }
    }

    return services;
  }

  Map<String, Map<String, Map<String, dynamic>>> _transformGallery(List<dynamic> categories) {
    final gallery = <String, Map<String, Map<String, dynamic>>>{
      'men': {},
      'women': {},
      'unisex': {},
    };

    for (var category in categories) {
      final gender = category['category_gender'] as String;
      final categoryName = (category['category_name'] as String)
          .toLowerCase()
          .replaceAll(' ', '_')
          .replaceAll("'", '');
      final subcategoryName = (category['sub_category_name'] as String)
          .toLowerCase()
          .replaceAll(' ', '_')
          .replaceAll("'", '');
      final images = List<String>.from(category['display_images']);
      final categoryId = category['category_id'] as String;

      String genderKey = gender;
      if (gender != 'men' && gender != 'women') {
        genderKey = 'unisex';
      }

      if (!gallery[genderKey]!.containsKey(categoryName)) {
        gallery[genderKey]![categoryName] = {};
      }

      gallery[genderKey]![categoryName]![subcategoryName] = {
        'images': images,
        'category_id': categoryId,
        'display_name': category['sub_category_name'],
        'category_display_name': category['category_name'],
      };
    }
    print(gallery);
    return gallery;
  }

  void _toggleOnlineStatus() {
    if (_profileData == null) return;

    setState(() {
      _profileData!['businessProfile']['isOnline'] =
      !_profileData!['businessProfile']['isOnline'];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            _profileData!['businessProfile']['isOnline']
                ? 'You are now online'
                : 'You are now offline'
        ),
        backgroundColor: _profileData!['businessProfile']['isOnline']
            ? Colors.green
            : Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showEditServiceBottomSheet(Map<String, dynamic> categoryData) {
    final priceController = TextEditingController(text: categoryData['price'].toString());
    final deliveryTimeController = TextEditingController(text: categoryData['delivery_time']);

    // Store uploaded images with their URLs (from existing + newly uploaded)
    List<Map<String, String>> uploadedImages = [];

    // Pre-populate with existing images
    final existingImageUrls = List<String>.from(categoryData['display_images'] ?? []);
    uploadedImages = existingImageUrls.map((url) {
      final fileName = url.split('/').last;
      return {
        'fileName': fileName,
        'url': url,
      };
    }).toList();

    bool isUploadingImage = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
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
                      ' • ${categoryData['sub_category_name']}',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Price Field
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
                    controller: priceController,
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

                // Delivery Time Field
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
                    controller: deliveryTimeController,
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

                // Display Images
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
                  onTap: isUploadingImage ? null : () async {
                    try {
                      // Single image selection
                      final XFile? image = await _picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 1920,
                        maxHeight: 1080,
                        imageQuality: 85,
                      );

                      if (image != null) {
                        setModalState(() {
                          isUploadingImage = true;
                        });

                        final file = File(image.path);
                        final fileName = path.basename(image.path);

                        // Get token from AuthProvider
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        final token = authProvider.token;

                        if (token == null) {
                          setModalState(() {
                            isUploadingImage = false;
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('User not logged in.'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }

                        // Upload document via KycProvider
                        final documentType = 'service_${categoryData['sub_category_name']}_${DateTime.now().millisecondsSinceEpoch}';
                        final kycProvider = Provider.of<KycProvider>(context, listen: false);
                        await kycProvider.uploadDocument(file, documentType, token);

                        // Get the uploaded URL from KycProvider
                        final imageUrl = kycProvider.uploadedUrls[documentType];

                        if (imageUrl != null) {
                          setModalState(() {
                            uploadedImages.add({
                              'fileName': fileName,
                              'url': imageUrl,
                            });
                            isUploadingImage = false;
                          });

                          debugPrint("=== 📸 SERVICE IMAGE UPLOADED ===");
                          debugPrint("📄 File Name: $fileName");
                          debugPrint("🔗 URL: $imageUrl");
                          debugPrint("💾 Total Images: ${uploadedImages.length}");
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
                          setModalState(() {
                            isUploadingImage = false;
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
                      }
                    } catch (e) {
                      setModalState(() {
                        isUploadingImage = false;
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
                  },
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
                            color: isUploadingImage ? Colors.grey[400] : Colors.black,
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
                          child: isUploadingImage
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
                if (uploadedImages.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...uploadedImages.asMap().entries.map((entry) {
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
                            onTap: () => _viewImageDialog(fileName, imageUrl),
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
                            onTap: () {
                              setModalState(() {
                                uploadedImages.removeAt(index);
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Image removed'),
                                  backgroundColor: Colors.orange,
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
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

                // Save Changes Button
                Container(
                  width: double.infinity,
                  height: 55,
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: ElevatedButton(
                    onPressed: () => _updateServiceWithUploadedImages(
                      context,
                      categoryData,
                      priceController.text,
                      deliveryTimeController.text,
                      uploadedImages,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _viewImageDialog(String fileName, String imageUrl) {
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

  Future<void> _updateServiceWithUploadedImages(
      BuildContext context,
      Map<String, dynamic> categoryData,
      String price,
      String deliveryTime,
      List<Map<String, String>> uploadedImages,
      ) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final tailorService = TailorService();

      // Extract URLs from uploaded images
      final imageUrls = uploadedImages.map((img) => img['url']!).toList();

      // Prepare updated category data
      final updatedCategory = {
        'category_id': categoryData['category_id'],
        'category_name': categoryData['category_name'],
        'category_gender': categoryData['category_gender'],
        'sub_category_name': categoryData['sub_category_name'],
        'price': int.parse(price),
        'delivery_time': deliveryTime,
        'display_images': imageUrls,
        'is_valid_sub_category': categoryData['is_valid_sub_category'] ?? true,
      };

      // Get all categories from API data and update the specific one
      final allCategories = List<Map<String, dynamic>>.from(_apiData!['categories']);
      final categoryIndex = allCategories.indexWhere(
            (cat) => cat['category_id'] == categoryData['category_id'],
      );

      if (categoryIndex != -1) {
        allCategories[categoryIndex] = updatedCategory;
      }

      // Call update API
      final body = {
        'categories': allCategories,
      };

      final result = await tailorService.updateTailorProfile(
        token: authProvider.token ?? '',
        body: body,
      );

      Navigator.pop(context); // Close loading dialog
      Navigator.pop(context); // Close bottom sheet

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Service updated successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Reload profile data
        _loadProfileData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update failed: ${result['message']}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      Navigator.pop(context); // Close bottom sheet

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating service: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showAddPhotosBottomSheet(
      String categoryId,
      String categoryDisplayName,
      String subcategoryDisplayName,
      ) {
    setState(() {
      _selectedImages.clear();
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          categoryDisplayName.toUpperCase(),
                          style: GoogleFonts.lato(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          ' • ${subcategoryDisplayName.toUpperCase()}',
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Add Photos',
                      style: GoogleFonts.lato(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Text(
                          'Upload Photo(s)',
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.cloud_upload_outlined,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Expanded(
                        child: _selectedImages.isEmpty
                            ? _buildPhotoPlaceholder(setModalState)
                            : _buildPhotoGrid(setModalState),
                      ),

                      Container(
                        width: double.infinity,
                        height: 50,
                        margin: const EdgeInsets.only(bottom: 20, top: 20),
                        child: ElevatedButton(
                          onPressed: _selectedImages.isNotEmpty
                              ? () => _uploadPhotosToAPI(context, categoryId)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedImages.isNotEmpty
                                ? Colors.red
                                : Colors.grey[300],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Add Photo',
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _selectedImages.isNotEmpty
                                  ? Colors.white
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPlaceholder(StateSetter setModalState) {
    return GestureDetector(
      onTap: () => _pickImages(setModalState),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[300]!,
            style: BorderStyle.solid,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Tap to select photos',
              style: GoogleFonts.lato(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You can select multiple photos',
              style: GoogleFonts.lato(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGrid(StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _pickImages(setModalState),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey[300]!,
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  color: Colors.grey[600],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Tap to add more photos',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        Expanded(
          child: ListView.builder(
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              final image = _selectedImages[index];
              final fileName = image.name;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        fileName,
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _viewImage(image),
                      child: Text(
                        'View',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    GestureDetector(
                      onTap: () {
                        setModalState(() {
                          _selectedImages.removeAt(index);
                        });
                      },
                      child: Text(
                        'Remove',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _viewImage(XFile image) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(image.path),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImages(StateSetter setModalState) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 80,
      );

      if (images.isNotEmpty) {
        setModalState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting images: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _uploadPhotosToAPI(BuildContext context, String categoryId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final imagePaths = _selectedImages.map((img) => img.path).toList();
      final tailorService = TailorService();

      final result = await tailorService.uploadCategoryImages(
        authProvider.token ?? '',
        categoryId,
        imagePaths,
      );

      Navigator.pop(context);
      Navigator.pop(context);

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedImages.length} photo(s) uploaded successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        _loadProfileData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${result['error']}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading images: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      _selectedImages.clear();
    }
  }

  void _editProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit profile functionality coming soon'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: GoogleFonts.lato(
                  fontSize: 16,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadProfileData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
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
        ),
      );
    }

    if (_profileData == null || _categories.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Center(
          child: Text(
            'No profile data available',
            style: GoogleFonts.lato(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }

    final businessProfile = _profileData!['businessProfile'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _editProfile,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.red),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Edit',
                            style: GoogleFonts.lato(
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _toggleOnlineStatus,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: businessProfile['isOnline']
                                ? Colors.green
                                : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            businessProfile['isOnline']
                                ? Icons.power_settings_new
                                : Icons.power_settings_new,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: NetworkImage(businessProfile['logo']),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              businessProfile['name'],
                              style: GoogleFonts.lato(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  businessProfile['rating'].toStringAsFixed(1),
                                  style: GoogleFonts.lato(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                ...List.generate(5, (index) => Icon(
                                  Icons.star,
                                  size: 16,
                                  color: index < businessProfile['rating'].floor()
                                      ? Colors.orange
                                      : Colors.grey[300],
                                )),
                                const SizedBox(width: 4),
                                Text(
                                  '(${businessProfile['totalReviews']})',
                                  style: GoogleFonts.lato(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            businessProfile['deliveryTime'],
                            style: GoogleFonts.lato(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Row(
                        children: [
                          Icon(Icons.currency_rupee, size: 16, color: Colors.grey[600]),
                          Text(
                            'starts from ₹${businessProfile['startingPrice']}',
                            style: GoogleFonts.lato(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'G',
                              style: GoogleFonts.lato(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              businessProfile['googleRating'].toStringAsFixed(1),
                              style: GoogleFonts.lato(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.red,
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: Colors.red,
                tabs: const [
                  Tab(text: 'Services'),
                  Tab(text: 'Gallery'),
                  Tab(text: 'Reviews'),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildServicesTab(),
                  _buildGalleryTab(),
                  _buildReviewsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          height: 55,
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(15),
          ),
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/services');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Text(
              'Edit Services',
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServicesTab() {
    return Column(
      children: [
        _buildCategorySelector(),
        Expanded(
          child: _buildServicesList(_categories[_selectedCategoryIndex]['gender']),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _categories.asMap().entries.map((entry) {
          final index = entry.key;
          final category = entry.value;
          final isSelected = _selectedCategoryIndex == index;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategoryIndex = index;
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: category['color'],
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(color: Colors.red, width: 2)
                      : null,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        image: DecorationImage(
                          image: NetworkImage(category['image']),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category['name'],
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.red : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildServicesList(String gender) {
    final services = _profileData!['services'][gender] as List<dynamic>;

    if (services.isEmpty) {
      return Center(
        child: Text(
          'No services available',
          style: GoogleFonts.lato(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: services.map((serviceCategory) {
          final categoryName = serviceCategory['category'];
          final items = serviceCategory['items'] as List<dynamic>;

          return Container(
            margin: const EdgeInsets.only(bottom: 24),
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
                const SizedBox(height: 12),
                ...items.map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(item['image']),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'],
                              style: GoogleFonts.lato(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              '₹${item['price']}',
                              style: GoogleFonts.lato(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showEditServiceBottomSheet(item['categoryData']),
                        child: Text(
                          'Edit Details',
                          style: GoogleFonts.lato(
                            fontSize: 12,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGalleryTab() {
    return Column(
      children: [
        _buildCategorySelector(),
        Expanded(
          child: _buildGalleryGrid(_categories[_selectedCategoryIndex]['gender']),
        ),
      ],
    );
  }

  Widget _buildGalleryGrid(String gender) {
    final gallery = _profileData!['gallery'][gender] as Map<String, dynamic>;

    if (gallery.isEmpty) {
      return Center(
        child: Text(
          'No gallery images available',
          style: GoogleFonts.lato(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: gallery.entries.map((categoryEntry) {
          final subcategories = categoryEntry.value as Map<String, dynamic>;

          return Column(
            children: subcategories.entries.map((subEntry) {
              final itemData = subEntry.value as Map<String, dynamic>;
              final images = itemData['images'] as List<dynamic>;
              final categoryId = itemData['category_id'] as String;
              final displayName = itemData['display_name'] as String;
              final categoryDisplayName = itemData['category_display_name'] as String;

              return Container(
                margin: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${categoryDisplayName.toUpperCase()} • ${displayName.toUpperCase()}',
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _showAddPhotosBottomSheet(
                            categoryId,
                            categoryDisplayName,
                            displayName,
                          ),
                          child: Text(
                            'Add Photos',
                            style: GoogleFonts.lato(
                              fontSize: 12,
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    images.isEmpty
                        ? Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'No images yet',
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    )
                        : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1,
                      ),
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        final imagePath = images[index] as String;

                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: imagePath.startsWith('http')
                                  ? NetworkImage(imagePath) as ImageProvider
                                  : FileImage(File(imagePath)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReviewsTab() {
    final reviews = _profileData!['reviews'] as List<dynamic>;

    if (reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No reviews yet',
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
      padding: const EdgeInsets.all(20),
      child: Column(
        children: reviews.map((review) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: DecorationImage(
                        image: NetworkImage(review['avatar']),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review['customerName'],
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        Row(
                          children: [
                            ...List.generate(5, (index) => Icon(
                              Icons.star,
                              size: 14,
                              color: index < review['rating']
                                  ? Colors.orange
                                  : Colors.grey[300],
                            )),
                            const SizedBox(width: 8),
                            Text(
                              review['date'],
                              style: GoogleFonts.lato(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                review['review'],
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }
}