import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../providers/global_provider.dart';
import '../providers/kyc_provider.dart';
import '../providers/auth_provider.dart';

class BusinessDetailsScreen extends StatefulWidget {
  const BusinessDetailsScreen({super.key});

  @override
  State<BusinessDetailsScreen> createState() => _BusinessDetailsScreenState();
}

class _BusinessDetailsScreenState extends State<BusinessDetailsScreen> {
  final TextEditingController _businessNameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  List<Map<String, String>> uploadedImages = []; // Stores {fileName, url}
  bool _isSubmitting = false;
  bool _isUploadingImage = false;
  Map<String, dynamic>? _selectedAddress;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final globalProvider = Provider.of<GlobalProvider>(context, listen: false);

    // Auto-fill if data exists in GlobalProvider
    if (_businessNameController.text.isEmpty && globalProvider.getValue('name') != null) {
      _businessNameController.text = globalProvider.getValue('name');
    }

    if (uploadedImages.isEmpty && globalProvider.getValue('portfolio_images') != null) {
      final portfolioImages = globalProvider.getValue('portfolio_images');
      if (portfolioImages is List) {
        setState(() {
          // Convert List<String> URLs to List<Map<String, String>>
          uploadedImages = portfolioImages.map<Map<String, String>>((url) {
            final urlString = url.toString();
            final fileName = urlString.split('/').last; // Extract filename from URL
            return {
              'fileName': fileName,
              'url': urlString,
            };
          }).toList();
        });
      }
    }

    // Check if address data exists in global provider
    if (_selectedAddress == null && globalProvider.getAddress() != null) {
      setState(() {
        _selectedAddress = globalProvider.getAddress();
      });
    }
  }

  Future<void> _uploadDisplayImages() async {
    if (_isUploadingImage) return;

    try {
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
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }

        // Upload document via KycProvider (reusing for portfolio images)
        // Using a custom document type for portfolio images
        final documentType = 'portfolio_${DateTime.now().millisecondsSinceEpoch}';
        await Provider.of<KycProvider>(context, listen: false)
            .uploadDocument(file, documentType, token);

        // Get the uploaded URL from KycProvider
        final imageUrl = Provider.of<KycProvider>(context, listen: false).uploadedUrls[documentType];

        if (imageUrl != null) {
          setState(() {
            uploadedImages.add({
              'fileName': fileName,
              'url': imageUrl,
            });
            _isUploadingImage = false;
          });

          // Save images globally (extract URLs only)
          final imageUrls = uploadedImages.map((img) => img['url']!).toList();
          Provider.of<GlobalProvider>(context, listen: false)
              .setPortfolioImages(imageUrls);

          debugPrint("=== 📸 PORTFOLIO IMAGE UPLOADED ===");
          debugPrint("📄 File Name: $fileName");
          debugPrint("🔗 URL: $imageUrl");
          debugPrint("💾 Total Images: ${uploadedImages.length}");
          debugPrint("===================================");

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
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      uploadedImages.removeAt(index);

      // Update images in GlobalProvider (extract URLs only)
      final imageUrls = uploadedImages.map((img) => img['url']!).toList();
      Provider.of<GlobalProvider>(context, listen: false)
          .setPortfolioImages(imageUrls);
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

  void _refreshAddress() {
    final globalProvider = Provider.of<GlobalProvider>(context, listen: false);
    final address = globalProvider.getAddress();

    if (address != null) {
      setState(() {
        _selectedAddress = address;
      });
    }
  }

  Future<void> _addAddress() async {
    try {
      await Navigator.pushNamed(context, '/set-location');
      _refreshAddress();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleSubmit() async {
    if (_businessNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter business name'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (uploadedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload at least one display image'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select business address'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final globalProvider = Provider.of<GlobalProvider>(context, listen: false);

    // Save business name globally
    globalProvider.setBusinessDetails(name: _businessNameController.text.trim());

    // Save uploaded images globally (extract URLs only)
    final imageUrls = uploadedImages.map((img) => img['url']!).toList();
    globalProvider.setPortfolioImages(imageUrls);

    // Print the current state of globalData
    debugPrint("=== 📦 CURRENT GLOBAL DATA ===");
    debugPrint(globalProvider.globalData.toString());
    debugPrint("==============================");

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isSubmitting = false;
    });

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
              'Business Details Saved!',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Your business information has been saved successfully.',
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
              Navigator.of(context).pop();
              Navigator.pushNamed(context, '/services');
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

  String _getAddressDisplay() {
    if (_selectedAddress == null) return '';

    final city = _selectedAddress!['city'] ?? '';
    final street = _selectedAddress!['street'] ?? '';
    final state = _selectedAddress!['state'] ?? '';
    final pincode = _selectedAddress!['pincode'] ?? '';

    return '$street, $city, $state - $pincode';
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
          'Business',
          style: GoogleFonts.lato(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Business Icon and Title
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(Icons.store, size: 40, color: Colors.blue.shade600),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.orange.shade600,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.shopping_cart,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Business Details',
                    style: GoogleFonts.lato(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Business Name
            Text(
              'Business Name',
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _businessNameController,
                style: GoogleFonts.lato(fontSize: 16, color: Colors.black),
                decoration: InputDecoration(
                  hintText: 'Enter Business Name',
                  hintStyle: GoogleFonts.lato(fontSize: 16, color: Colors.grey[400]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Display Image Section
            Text(
              'Display Image',
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Upload button
                    GestureDetector(
                      onTap: _isUploadingImage ? null : _uploadDisplayImages,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              uploadedImages.isEmpty
                                  ? 'Upload Display Image'
                                  : 'Upload Display Image(s)',
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
                                  : Icon(Icons.upload, color: Colors.red.shade400, size: 16),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Uploaded images list
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
                                child: const Icon(Icons.check, color: Colors.white, size: 14),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.only(top: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey[600],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'You can upload multiple images one at a time',
                                style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.only(top: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey[600],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'These images will appear in your profile card',
                                style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Business Address Section
            Text(
              'Business Address',
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            _selectedAddress != null
                ? Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.location_on, color: Colors.black, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedAddress!['building'] ?? 'Business Address',
                          style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getAddressDisplay(),
                          style: GoogleFonts.lato(fontSize: 14, color: Colors.grey[600]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _addAddress,
                    icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
                  ),
                ],
              ),
            )
                : GestureDetector(
              onTap: _addAddress,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Center(
                  child: Text(
                    '+ Add Address',
                    style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 60),

            // Submit Button
            Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.pink.shade300, Colors.pink.shade400]),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : Text(
                  'Submit',
                  style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    super.dispose();
  }
}