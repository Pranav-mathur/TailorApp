import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedCategoryIndex = 0; // Track selected category index
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  String _currentUploadCategory = '';
  String _currentUploadSubcategory = '';
  String _currentUploadItem = '';

  // Category data for the card-style selection
  final List<Map<String, dynamic>> categories = [
    {
      "name": "Men",
      "image": "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&q=80",
      "color": Color(0xFFE8F5E8),
    },
    {
      "name": "Women",
      "image": "https://images.unsplash.com/photo-1494790108755-2616b332c3a2?w=200&q=80",
      "color": Color(0xFFFFF4E6),
    },
    {
      "name": "Designers",
      "image": "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=200&q=80",
      "color": Color(0xFFF0E6FF),
    },
  ];

  // Profile data that would come from API
  final Map<String, dynamic> profileData = {
    "businessProfile": {
      "name": "Vishaal Tailors",
      "logo": "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&q=80",
      "rating": 4.9,
      "totalReviews": 200,
      "googleRating": 4.7,
      "deliveryTime": "4 day delivery",
      "startingPrice": 899,
      "isOnline": true,
      "description": "Premium tailoring services with 15+ years of experience",
      "address": "Shop 232, MG Road, Bangalore",
      "phone": "+91 98765 43210"
    },
    "services": {
      "men": [
        {
          "category": "Shirts",
          "items": [
            {
              "name": "Casual shirts",
              "price": 1999,
              "image": "https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=300&q=80",
              "deliveryTime": "3-4 days"
            },
            {
              "name": "Formal shirts",
              "price": 899,
              "image": "https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=300&q=80",
              "deliveryTime": "2-3 days"
            }
          ]
        },
        {
          "category": "Suits & Blazers",
          "items": [
            {
              "name": "3 piece",
              "price": 1999,
              "image": "https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=300&q=80",
              "deliveryTime": "7-10 days"
            },
            {
              "name": "2 piece",
              "price": 899,
              "image": "https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=300&q=80",
              "deliveryTime": "5-7 days"
            }
          ]
        }
      ],
      "women": [
        {
          "category": "Dresses",
          "items": [
            {
              "name": "Party dresses",
              "price": 2499,
              "image": "https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=300&q=80",
              "deliveryTime": "5-7 days"
            }
          ]
        }
      ],
      "designers": [
        {
          "category": "Wedding Collection",
          "items": [
            {
              "name": "Lehenga",
              "price": 5999,
              "image": "https://images.unsplash.com/photo-1583391265928-4365b2d5f814?w=300&q=80",
              "deliveryTime": "15-20 days"
            }
          ]
        }
      ]
    },
    "gallery": {
      "men": {
        "shirts": {
          "casual": [
            "https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=300&q=80",
            "https://images.unsplash.com/photo-1603252109303-2751441dd157?w=300&q=80",
            "https://images.unsplash.com/photo-1602810318660-d1e50ab47767?w=300&q=80",
            "https://images.unsplash.com/photo-1598300042247-d088f8ab3a91?w=300&q=80",
            "https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=300&q=80",
            "https://images.unsplash.com/photo-1602810316498-ab67cf68c8e1?w=300&q=80"
          ],
          "formal": [
            "https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=300&q=80",
            "https://images.unsplash.com/photo-1603252109303-2751441dd157?w=300&q=80",
            "https://images.unsplash.com/photo-1602810318660-d1e50ab47767?w=300&q=80"
          ]
        }
      },
      "women": {
        "dresses": {
          "party": [
            "https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=300&q=80",
            "https://images.unsplash.com/photo-1566479179817-3aa77ca5e8b2?w=300&q=80"
          ]
        }
      },
      "designers": {
        "wedding": {
          "lehenga": [
            "https://images.unsplash.com/photo-1583391265928-4365b2d5f814?w=300&q=80",
            "https://images.unsplash.com/photo-1631062188012-d6b313e82e4b?w=300&q=80"
          ]
        }
      }
    },
    "reviews": [
      {
        "customerName": "Arjun Das",
        "rating": 5,
        "review": "Excellent tailoring work. Very professional and timely delivery.",
        "date": "2024-07-10",
        "avatar": "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&q=80"
      },
      {
        "customerName": "Priya Sharma",
        "rating": 4,
        "review": "Great quality and fitting. Highly recommended!",
        "date": "2024-07-08",
        "avatar": "https://images.unsplash.com/photo-1494790108755-2616b332c3a2?w=100&q=80"
      }
    ]
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleOnlineStatus() {
    setState(() {
      profileData['businessProfile']['isOnline'] =
      !profileData['businessProfile']['isOnline'];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            profileData['businessProfile']['isOnline']
                ? 'You are now online'
                : 'You are now offline'
        ),
        backgroundColor: profileData['businessProfile']['isOnline']
            ? Colors.green
            : Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAddPhotosBottomSheet(String category, String subcategory, String item) {
    setState(() {
      _selectedImages.clear();
      _currentUploadCategory = category;
      _currentUploadSubcategory = subcategory;
      _currentUploadItem = item;
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
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${category.toUpperCase()}',
                          style: GoogleFonts.lato(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          ' • ${subcategory.toUpperCase()}',
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
                          child: Icon(
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

              // Photo selection area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Photo grid or placeholder
                      Expanded(
                        child: _selectedImages.isEmpty
                            ? _buildPhotoPlaceholder(setModalState)
                            : _buildPhotoGrid(setModalState),
                      ),

                      // Add Photo Button
                      Container(
                        width: double.infinity,
                        height: 50,
                        margin: const EdgeInsets.only(bottom: 20, top: 20),
                        child: ElevatedButton(
                          onPressed: _selectedImages.isNotEmpty
                              ? () => _addPhotosToGallery(context)
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
        // Add more photos section (clickable area)
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

        // Selected photos list
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
                    Icon(
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting images: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _addPhotosToGallery(BuildContext context) {
    // Here you would typically upload the images to your server
    // For now, we'll just simulate adding them to the local gallery data

    // Convert XFile paths to network URLs (in real app, these would be server URLs)
    final newImageUrls = _selectedImages.map((image) => image.path).toList();

    // Add to gallery data structure
    final gallery = profileData['gallery'][_currentUploadCategory] as Map<String, dynamic>;
    final subcategory = gallery[_currentUploadSubcategory] as Map<String, dynamic>;
    final currentImages = subcategory[_currentUploadItem] as List<dynamic>;

    setState(() {
      currentImages.addAll(newImageUrls);
    });

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_selectedImages.length} photo(s) added successfully!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Clear selected images
    _selectedImages.clear();
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
    final businessProfile = profileData['businessProfile'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                children: [
                  // Top Row with back button and action buttons
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      // Edit Button
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
                      // Online/Offline Toggle
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

                  // Business Info Row
                  Row(
                    children: [
                      // Business Logo
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

                      // Business Details
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
                                  businessProfile['rating'].toString(),
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

                  // Service Info Row
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
                      // Google Rating
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
                              businessProfile['googleRating'].toString(),
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

            // Tab Bar
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

            // Tab Content
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
        // Category Selection Cards
        _buildCategorySelector(),

        Expanded(
          child: _buildServicesList(categories[_selectedCategoryIndex]['name'].toLowerCase()),
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
        children: categories.asMap().entries.map((entry) {
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

  Widget _buildServicesList(String category) {
    final services = profileData['services'][category] as List<dynamic>;

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
                      Text(
                        'Edit Details',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
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
        // Category Selection Cards (same as services)
        _buildCategorySelector(),

        Expanded(
          child: _buildGalleryGrid(categories[_selectedCategoryIndex]['name'].toLowerCase()),
        ),
      ],
    );
  }

  Widget _buildGalleryGrid(String category) {
    final gallery = profileData['gallery'][category] as Map<String, dynamic>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: gallery.entries.map((entry) {
          final subcategory = entry.key;
          final items = entry.value as Map<String, dynamic>;

          return Column(
            children: items.entries.map((subEntry) {
              final itemName = subEntry.key;
              final images = subEntry.value as List<dynamic>;

              return Container(
                margin: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${subcategory.toUpperCase()} • ${itemName.toUpperCase()}',
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showAddPhotosBottomSheet(
                            categories[_selectedCategoryIndex]['name'].toLowerCase(),
                            subcategory,
                            itemName,
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
                    GridView.builder(
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
                        final imagePath = images[index];

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
    final reviews = profileData['reviews'] as List<dynamic>;

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