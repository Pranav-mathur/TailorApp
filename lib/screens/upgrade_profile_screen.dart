import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tailor_app/razorPayPayment.dart';

class UpgradeProfileScreen extends StatelessWidget {
  const UpgradeProfileScreen({super.key});

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
              // Star icon with checkmark - using the provided PNG image
              SizedBox(
                width: 120,
                height: 120,
                child: Image.asset(
                  'assets/images/star_check.png', // Update this path to where you save the PNG
                  fit: BoxFit.contain,
                ),
              ),

              // Main content card with overlap
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
                      // Header
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

                      // Benefits container
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            // Benefit 1: Increased Visibility
                            _buildBenefitItem(
                              icon: Icons.show_chart,
                              iconColor: Colors.green.shade600,
                              backgroundColor: Colors.green.shade50,
                              title: 'Increased Visibility',
                              description:
                              'Increase your visibility on our homepage and in search results.',
                            ),
                            const SizedBox(height: 24),

                            // Benefit 2: More Orders & Higher Revenue
                            _buildBenefitItem(
                              icon: Icons.card_giftcard,
                              iconColor: Colors.orange.shade600,
                              backgroundColor: Colors.orange.shade50,
                              title: 'More Orders & Higher Revenue',
                              description:
                              'Drive more customer inquiries and increase your earnings.',
                            ),
                            const SizedBox(height: 24),

                            // Benefit 3: Enhanced Credibility
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

                      // Upgrade button
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
                            onTap: () {
                              // Handle upgrade action
                              _showUpgradeConfirmation(context);
                            },
                            borderRadius: BorderRadius.circular(28),
                            child: Center(
                              child: Row(
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
                                    '₹199',
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
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Confirm Upgrade',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to upgrade to the premium plan for ₹199/month?',
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
              // Add upgrade logic here
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RazorpayPaymentPage(amount: 199.0),
                ),
              );
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
}