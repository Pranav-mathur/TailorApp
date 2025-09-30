import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;
import '../providers/kyc_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/global_provider.dart';

class KycVerificationScreen extends StatefulWidget {
  const KycVerificationScreen({super.key});

  @override
  State<KycVerificationScreen> createState() => _KycVerificationScreenState();
}

class _KycVerificationScreenState extends State<KycVerificationScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  // Store image file names for each document type
  Map<String, String> documentFileNames = {};

  Future<void> _handleDocumentUpload(String documentType, String documentName) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);

        // Extract and store the image file name
        final fileName = path.basename(image.path);
        setState(() {
          documentFileNames[documentType] = fileName;
        });

        // Get token from AuthProvider
        final token = Provider.of<AuthProvider>(context, listen: false).token;
        if (token == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User not logged in.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Upload document via KycProvider
        await Provider.of<KycProvider>(context, listen: false)
            .uploadDocument(file, documentType, token);

        // Get the uploaded URL from KycProvider
        final imageUrl = Provider.of<KycProvider>(context, listen: false).uploadedUrls[documentType];

        if (imageUrl != null) {
          // Save uploaded URL in GlobalProvider using specific methods
          final globalProvider = Provider.of<GlobalProvider>(context, listen: false);

          switch (documentType) {
            case 'id_front':
              globalProvider.setIdProofFront(imageUrl);
              break;
            case 'id_back':
              globalProvider.setIdProofBack(imageUrl);
              break;
            case 'address_front':
              globalProvider.setKycAddressProofFront(imageUrl);
              break;
            case 'address_back':
              globalProvider.setKycAddressProofBack(imageUrl);
              break;
            default:
            // Fallback to generic setValue for any other document types
              globalProvider.setValue(documentType, imageUrl);
          }

          // Debug print to confirm data is saved
          debugPrint("=== 📁 DOCUMENT UPLOADED TO GLOBAL PROVIDER ===");
          debugPrint("📄 Document Type: $documentType");
          debugPrint("🔗 URL: $imageUrl");
          debugPrint("💾 Saved to GlobalProvider successfully");
          debugPrint("===============================================");
          debugPrint("$jsonEncode(globalData)");
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$documentName uploaded successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No image selected'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Remove the file name if upload failed
      setState(() {
        documentFileNames.remove(documentType);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  bool get _canSubmit => context.read<KycProvider>().canSubmit;

  Future<void> _handleSubmit() async {
    if (!context.read<KycProvider>().canSubmit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload all required documents'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Simulate API submission for KYC using uploaded URLs
    await Future.delayed(const Duration(seconds: 2));

    // Get data from GlobalProvider using the specific getters
    final globalProvider = context.read<GlobalProvider>();

    debugPrint("=== 📤 SUBMITTING KYC WITH GLOBAL PROVIDER DATA ===");
    debugPrint("🆔 ID Proof Front: ${globalProvider.getValue('id_proof_front')}");
    debugPrint("🆔 ID Proof Back: ${globalProvider.getValue('id_proof_back')}");
    debugPrint("🏠 Address Proof Front: ${globalProvider.getValue('kyc_address_proof_front')}");
    debugPrint("🏠 Address Proof Back: ${globalProvider.getValue('kyc_address_proof_back')}");

    // Show data summary
    final dataSummary = globalProvider.getDataSummary();
    debugPrint("📊 KYC Documents Count: ${dataSummary['kyc_docs_count']}/4");
    debugPrint("✅ Is KYC Complete: ${_areKycDocumentsComplete(globalProvider)}");

    // Get the complete API payload (if you need to submit all data)
    final apiPayload = globalProvider.getApiPayload();
    debugPrint("📋 Complete API Payload: $apiPayload");
    debugPrint("================================================");

    setState(() {
      _isSubmitting = false;
    });

    // Show success dialog
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
              'KYC Submitted Successfully!',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Your documents are under review. We\'ll notify you once verified.',
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
              Navigator.pushNamed(context, '/business');
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

  // Helper method to check if all KYC documents are uploaded
  bool _areKycDocumentsComplete(GlobalProvider provider) {
    return provider.getValue('id_proof_front') != null &&
        provider.getValue('id_proof_back') != null &&
        provider.getValue('kyc_address_proof_front') != null &&
        provider.getValue('kyc_address_proof_back') != null;
  }

  Widget _buildDocumentUploadItem(String documentName, String documentType) {
    final kycProvider = Provider.of<KycProvider>(context);
    final globalProvider = Provider.of<GlobalProvider>(context);

    bool isUploaded = kycProvider.uploadStatus[documentType] ?? false;
    bool isUploading = kycProvider.isUploading;
    String fileName = documentFileNames[documentType] ?? '';

    // Check if document exists in GlobalProvider as well
    String? globalProviderKey = _getGlobalProviderKey(documentType);
    bool isInGlobalProvider = globalProviderKey != null &&
        globalProvider.getValue(globalProviderKey) != null;

    if (!isUploaded) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    documentName,
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isInGlobalProvider) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Saved to profile',
                      style: GoogleFonts.lato(
                        fontSize: 11,
                        color: Colors.green[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            GestureDetector(
              onTap: isUploading
                  ? null
                  : () => _handleDocumentUpload(documentType, documentName),
              child: Container(
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
                child: isUploading
                    ? const CircularProgressIndicator(
                  color: Colors.red,
                  strokeWidth: 2,
                )
                    : Icon(
                  Icons.upload,
                  color: Colors.red.shade400,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    documentName,
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (fileName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      fileName,
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (isInGlobalProvider) ...[
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
                          'Saved to profile',
                          style: GoogleFonts.lato(
                            fontSize: 11,
                            color: Colors.blue[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            GestureDetector(
              onTap: isUploading
                  ? null
                  : () => _handleDocumentUpload(documentType, documentName),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Re-upload',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: Colors.red.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.upload,
                      size: 14,
                      color: Colors.red.shade400,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  // Helper method to get the corresponding GlobalProvider key
  String? _getGlobalProviderKey(String documentType) {
    switch (documentType) {
      case 'id_front':
        return 'id_proof_front';
      case 'id_back':
        return 'id_proof_back';
      case 'address_front':
        return 'kyc_address_proof_front';
      case 'address_back':
        return 'kyc_address_proof_back';
      default:
        return null;
    }
  }

  // Document Section (unchanged)
  Widget _buildDocumentSection({
    required String title,
    required List<Map<String, String>> documents,
  }) {
    return Container(
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.brown.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Documents',
                        style: GoogleFonts.lato(
                          fontSize: 11,
                          color: Colors.brown.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        Icons.help_outline,
                        size: 12,
                        color: Colors.brown.shade700,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Document Upload Items
            Column(
              children: documents.map(
                    (document) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: _buildDocumentUploadItem(
                    document['name']!,
                    document['type']!,
                  ),
                ),
              ).toList(),
            ),
          ],
        ),
      ),
    );
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
          'KYC Verification',
          style: GoogleFonts.lato(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade300, Colors.blue.shade500],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.person_outline, size: 28, color: Colors.white),
                      Positioned(
                        right: 6,
                        bottom: 6,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, size: 12, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'KYC Verification',
                  style: GoogleFonts.lato(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'To verify lorem ipsum',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildDocumentSection(
                      title: 'Upload ID Proof',
                      documents: [
                        {'name': 'ID Proof Front', 'type': 'id_front'},
                        {'name': 'ID Proof Back', 'type': 'id_back'},
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildDocumentSection(
                      title: 'Upload Address Proof',
                      documents: [
                        {'name': 'Address Proof Front', 'type': 'address_front'},
                        {'name': 'Address Proof Back', 'type': 'address_back'},
                      ],
                    ),
                    Consumer<GlobalProvider>(
                      builder: (context, globalProvider, child) {
                        bool globalKycComplete = _areKycDocumentsComplete(globalProvider);
                        return Container(
                          width: double.infinity,
                          height: 50,
                          margin: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _canSubmit
                                  ? [Colors.pink.shade300, Colors.pink.shade400]
                                  : [Colors.grey.shade300, Colors.grey.shade400],
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: _canSubmit
                                ? [
                              BoxShadow(
                                color: Colors.pink.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ]
                                : [],
                          ),
                          child: ElevatedButton(
                            onPressed: (_isSubmitting || !_canSubmit || !globalKycComplete)
                                ? null
                                : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : Text(
                              'Submit',
                              style: GoogleFonts.lato(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}