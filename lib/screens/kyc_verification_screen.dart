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

  // Track which specific document is currently uploading
  String? _currentlyUploadingDocument;

  Future<void> _handleDocumentUpload(String documentType, String documentName) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        // Set this document as currently uploading
        setState(() {
          _currentlyUploadingDocument = documentType;
        });

        final file = File(image.path);

        // Extract and store the image file name
        final fileName = path.basename(image.path);
        setState(() {
          documentFileNames[documentType] = fileName;
        });

        // Get token from AuthProvider
        final token = Provider.of<AuthProvider>(context, listen: false).token;
        if (token == null) {
          setState(() {
            _currentlyUploadingDocument = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User not logged in.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
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
        }

        // Clear uploading state
        setState(() {
          _currentlyUploadingDocument = null;
        });

        // Show success snackbar for 2 seconds only
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$documentName uploaded successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // Clear uploading state if no image selected
        setState(() {
          _currentlyUploadingDocument = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No image selected'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Remove the file name if upload failed
      setState(() {
        documentFileNames.remove(documentType);
        _currentlyUploadingDocument = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
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
          duration: Duration(seconds: 2),
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

  // Show bottom sheet for supported documents
  void _showSupportedDocumentsBottomSheet(BuildContext context, String documentType) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            // Header with icon
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.credit_card,
                          color: Colors.blue.shade400,
                          size: 24,
                        ),
                        Positioned(
                          right: 6,
                          bottom: 6,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Supported Documents',
                    style: GoogleFonts.lato(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // ID Proof Section
            if (documentType == 'id_proof') ...[
              _buildDocumentTypeSection(
                'ID Proof',
                'Aadhaar Card, Passport, PAN Card, Voter ID, Driving Licence, Ration Card, Bank passbook',
              ),
              const SizedBox(height: 16),
            ],
            // Address Proof Section
            if (documentType == 'address_proof') ...[
              _buildDocumentTypeSection(
                'Address Proof',
                'Aadhaar Card, Passport, PAN Card, Voter ID, Driving Licence, Ration Card, Bank passbook',
              ),
              const SizedBox(height: 16),
            ],
            // Show both sections if documentType is 'all'
            if (documentType == 'all') ...[
              _buildDocumentTypeSection(
                'ID Proof',
                'Aadhaar Card, Passport, PAN Card, Voter ID, Driving Licence, Ration Card, Bank passbook',
              ),
              const SizedBox(height: 16),
              _buildDocumentTypeSection(
                'Address Proof',
                'Aadhaar Card, Passport, PAN Card, Voter ID, Driving Licence, Ration Card, Bank passbook',
              ),
              const SizedBox(height: 16),
            ],
            // Okay Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE57373),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Okay',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // Build document type section for bottom sheet
  Widget _buildDocumentTypeSection(String title, String documents) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              documents,
              style: GoogleFonts.lato(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentUploadItem(String documentName, String documentType) {
    final kycProvider = Provider.of<KycProvider>(context);
    final globalProvider = Provider.of<GlobalProvider>(context);

    bool isUploaded = kycProvider.uploadStatus[documentType] ?? false;
    bool isUploadingThisDocument = _currentlyUploadingDocument == documentType;
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
              onTap: isUploadingThisDocument
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
                child: isUploadingThisDocument
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
              onTap: isUploadingThisDocument
                  ? null
                  : () => _handleDocumentUpload(documentType, documentName),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: isUploadingThisDocument
                    ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.red.shade400,
                    strokeWidth: 2,
                  ),
                )
                    : Row(
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

  // Document Section with clickable badge
  Widget _buildDocumentSection({
    required String title,
    required List<Map<String, String>> documents,
    required String documentType, // 'id_proof' or 'address_proof'
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
                GestureDetector(
                  onTap: () => _showSupportedDocumentsBottomSheet(context, documentType),
                  child: Container(
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
                      ],
                    ),
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
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back, color: Colors.black),
        //   onPressed: () => Navigator.of(context).pop(),
        // ),
        title: Text(
          'KYC Verification',
          style: GoogleFonts.lato(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
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
                // Text(
                //   'To verify lorem ipsum',
                //   style: GoogleFonts.lato(
                //     fontSize: 14,
                //     color: Colors.grey[600],
                //   ),
                // ),
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
                      documentType: 'id_proof',
                      documents: [
                        {'name': 'ID Proof Front', 'type': 'id_front'},
                        {'name': 'ID Proof Back', 'type': 'id_back'},
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildDocumentSection(
                      title: 'Upload Address Proof',
                      documentType: 'address_proof',
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