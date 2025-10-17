import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import '../providers/auth_provider.dart';

class UpgradeProfileScreen extends StatefulWidget {
  final String tailorId;
  final String token;

  const UpgradeProfileScreen({
    super.key,
    required this.tailorId,
    required this.token,
  });

  @override
  State<UpgradeProfileScreen> createState() => _UpgradeProfileScreenState();
}

class _UpgradeProfileScreenState extends State<UpgradeProfileScreen> {
  final String baseUrl = 'http://100.27.221.127:3000/api/v1';
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8F0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Upgrade Profile',
          style: GoogleFonts.lato(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: Image.asset(
                  'assets/images/star_check.png',
                  fit: BoxFit.contain,
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -35),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.brown.shade700, Colors.brown.shade600],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.brown.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Boost Your Business',
                        style: GoogleFonts.lato(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Get a featured spot',
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _buildBenefitItem(
                              icon: Icons.show_chart,
                              iconColor: Colors.green.shade600,
                              backgroundColor: Colors.green.shade50,
                              title: 'Increased Visibility',
                              description:
                              'Increase your visibility on our homepage and in search results.',
                            ),
                            const SizedBox(height: 24),
                            _buildBenefitItem(
                              icon: Icons.card_giftcard,
                              iconColor: Colors.orange.shade600,
                              backgroundColor: Colors.orange.shade50,
                              title: 'More Orders & Higher Revenue',
                              description:
                              'Drive more customer inquiries and increase your earnings.',
                            ),
                            const SizedBox(height: 24),
                            _buildBenefitItem(
                              icon: Icons.emoji_events,
                              iconColor: Colors.purple.shade600,
                              backgroundColor: Colors.purple.shade50,
                              title: 'Enhanced Credibility',
                              description:
                              'Build a stronger, more professional brand reputation.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.red.shade400, Colors.red.shade500],
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isProcessing ? null : () => _showUpgradeConfirmation(context),
                            borderRadius: BorderRadius.circular(28),
                            child: Center(
                              child: _isProcessing
                                  ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                                  : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Upgrade Plan',
                                    style: GoogleFonts.lato(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '•',
                                    style: GoogleFonts.lato(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '₹499',
                                    style: GoogleFonts.lato(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    ' /month',
                                    style: GoogleFonts.lato(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 28,
              color: iconColor,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showUpgradeConfirmation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Confirm Upgrade',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to upgrade to the premium plan for ₹499/month?',
          style: GoogleFonts.lato(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: Text(
              'Cancel',
              style: GoogleFonts.lato(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _initiateUpgrade();
            },
            child: Text(
              'Upgrade',
              style: GoogleFonts.lato(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initiateUpgrade() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Step 1: Call sponsor API
      final sponsorResponse = await _callSponsorAPI();

      if (sponsorResponse['success'] == true) {
        final paymentLink = sponsorResponse['paymentLink'];

        // Step 2: Open payment link
        await _openPaymentLink(paymentLink);

        // Step 3: Wait for user to complete payment and return
        // Show a waiting dialog
        if (mounted) {
          _showPaymentProcessingDialog();
        }
      } else {
        if (mounted) {
          _showErrorDialog(sponsorResponse['message'] ?? 'Failed to initiate upgrade');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('An error occurred: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>> _callSponsorAPI() async {

    try {
      final url = Uri.parse('http://100.27.221.127:3000/api/v1/tailor/sponsor');
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token}',
        },

        // body: json.encode({
        //   'tailorId': widget.tailorId,
        // }),
      );
      debugPrint("✅ Sponsor API token: ${token}");
      debugPrint("✅ Sponsor API Response: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          'success': true,
          'paymentLink': data['paymentLink'],
          'paymentLinkId': data['paymentLinkId'],
          'amount': data['amount'],
          'message': data['message'],
        };
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to generate payment link',
        };
      }
    } catch (e) {
      debugPrint("❌ Sponsor API Error: ${e.toString()}");
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  Future<void> _openPaymentLink(String paymentLink) async {
    try {
      final Uri url = Uri.parse(paymentLink);
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Could not launch payment link');
      }
    } catch (e) {
      debugPrint("❌ Error opening payment link: ${e.toString()}");
      rethrow;
    }
  }

  void _showPaymentProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Complete Payment',
            style: GoogleFonts.lato(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Please complete the payment in your browser and return to the app.',
                style: GoogleFonts.lato(),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _checkPaymentStatus();
              },
              child: Text(
                'I\'ve Completed Payment',
                style: GoogleFonts.lato(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkPaymentStatus() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Verifying payment...',
                style: GoogleFonts.lato(),
              ),
            ],
          ),
        ),
      ),
    );

    // Wait for 5 seconds
    await Future.delayed(const Duration(seconds: 7));

    // Call getTailorProfile API
    final profileResponse = await _getTailorProfile();

    // Close loading dialog
    if (mounted) {
      Navigator.of(context).pop();
    }

    if (profileResponse['success'] == true) {
      final tailorData = profileResponse['data'];
      final isSponsored = tailorData['is_sponsored'] ?? false;

      if (isSponsored) {
        // Show success screen
        if (mounted) {
          _showSuccessScreen();
        }
      } else {
        // Payment not verified yet
        if (mounted) {
          _showPaymentPendingDialog();
        }
      }
    } else {
      if (mounted) {
        _showErrorDialog(profileResponse['message'] ?? 'Failed to verify payment');
      }
    }
  }

  Future<Map<String, dynamic>> _getTailorProfile() async {
    try {
      final url = Uri.parse('$baseUrl/tailor/profile');
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token}',
        },
      );

      debugPrint("✅ Get Profile Response: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          'success': true,
          'data': data['tailor'] ?? {},
          'message': data['message'] ?? 'Profile fetched successfully',
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Unauthorized access. Please login again.',
        };
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  void _showSuccessScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ProfileUpgradedSuccessScreen(
          onComplete: () {
            // Navigate back to home after success screen
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/home', (route) => false);
          },
        ),
      ),
    );
  }

  void _showPaymentPendingDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Payment Pending',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Your payment is being processed. Please wait a few moments and try again.',
          style: GoogleFonts.lato(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: Text(
              'OK',
              style: GoogleFonts.lato(color: Colors.blue),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _checkPaymentStatus();
            },
            child: Text(
              'Check Again',
              style: GoogleFonts.lato(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Error',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: GoogleFonts.lato(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: Text(
              'OK',
              style: GoogleFonts.lato(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }
}

// Success Screen Widget
class ProfileUpgradedSuccessScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const ProfileUpgradedSuccessScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<ProfileUpgradedSuccessScreen> createState() =>
      _ProfileUpgradedSuccessScreenState();
}

class _ProfileUpgradedSuccessScreenState
    extends State<ProfileUpgradedSuccessScreen> {
  @override
  void initState() {
    super.initState();
    // Auto navigate after 4 seconds
    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 50,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Profile Upgraded',
                style: GoogleFonts.lato(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your profile will be\nfeatured from now',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}