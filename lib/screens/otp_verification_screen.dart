import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String? phoneNumber;

  const OtpVerificationScreen({
    super.key,
    this.phoneNumber,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
        (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
        (index) => FocusNode(),
  );

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _otpCode {
    return _otpControllers.map((controller) => controller.text).join();
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpCode;

    if (otp.length != 6) {
      _showErrorSnackBar('Please enter the complete 6-digit OTP');
      return;
    }

    final String phoneNumber = ModalRoute.of(context)!.settings.arguments as String;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.verifyOtp(phoneNumber, otp);

    if (!mounted) return;

    if (success != null && success["token"] != null && success["token"].length > 0) {
      if (success["is_new_user"] == true) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/kyc',
              (route) => false,
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
              (route) => false,
        );
      }
    } else {
      _showErrorSnackBar(authProvider.error ?? "OTP verification failed");
      _clearOtpFields();
    }
  }

  Future<void> _handleResendOtp() async {
    final String phoneNumber = ModalRoute.of(context)?.settings.arguments as String? ?? '';

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.sendOtp(phoneNumber);

    if (!mounted) return;

    if (success) {
      _showSuccessSnackBar('OTP sent successfully');
      _clearOtpFields();
    } else {
      _showErrorSnackBar(authProvider.error ?? "Failed to resend OTP");
    }
  }

  void _clearOtpFields() {
    for (var controller in _otpControllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Auto verify when all 6 digits are entered
    if (_otpCode.length == 6) {
      _handleVerifyOtp();
    }
  }

  @override
  Widget build(BuildContext context) {
    final String phoneNumber = widget.phoneNumber ??
        ModalRoute.of(context)?.settings.arguments as String? ??
        '';

    final isLoading = context.watch<AuthProvider>().isLoading;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive sizing based on screen dimensions
    final bool isSmallScreen = screenHeight < 700;
    final double titleSize = isSmallScreen ? 22 : 28;
    final double taglineSize = isSmallScreen ? 11 : 13;
    final double headingSize = isSmallScreen ? 22 : 26;
    final double bodyTextSize = isSmallScreen ? 13 : 14;
    final double phoneTextSize = isSmallScreen ? 14 : 16;
    final double otpBoxSize = screenWidth < 360 ? 45 : 50;
    final double otpBoxHeight = isSmallScreen ? 55 : 60;

    return Scaffold(
      body: Stack(
        children: [
          /// Background tailor image
          Positioned.fill(
            child: Image.asset(
              "assets/images/tailor.png",
              fit: BoxFit.cover,
            ),
          ),

          /// Dark gradient overlay
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0xFF1A0F08),
                  ],
                ),
              ),
            ),
          ),

          /// Main content with proper constraints
          SafeArea(
            child: Column(
              children: [
                /// Back button
                Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                /// App name + tagline
                Column(
                  children: [
                    Text(
                      "CASA DARZI",
                      style: GoogleFonts.playfairDisplay(
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 2 : 4),
                    Text(
                      "WHERE STYLE COMES HOME",
                      style: GoogleFonts.lato(
                        fontSize: taglineSize,
                        color: Colors.white.withOpacity(0.8),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: isSmallScreen ? 20 : 30),

                /// OTP verification form section
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.06,
                            vertical: isSmallScreen ? 16 : 20,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Verify OTP',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: headingSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 8 : 12),

                              Text(
                                'We have sent a verification code to',
                                style: GoogleFonts.lato(
                                  fontSize: bodyTextSize,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 2 : 4),

                              Text(
                                ModalRoute.of(context)!.settings.arguments as String,
                                style: GoogleFonts.lato(
                                  fontSize: phoneTextSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 25 : 40),

                              /// OTP Input Fields - 6 digits
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(6, (index) {
                                  return Container(
                                    width: otpBoxSize,
                                    height: otpBoxHeight,
                                    margin: EdgeInsets.symmetric(
                                      horizontal: index == 2
                                          ? (screenWidth < 360 ? 6 : 8)
                                          : (screenWidth < 360 ? 3 : 4),
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: TextField(
                                      controller: _otpControllers[index],
                                      focusNode: _focusNodes[index],
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.lato(
                                        color: Colors.white,
                                        fontSize: isSmallScreen ? 18 : 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        LengthLimitingTextInputFormatter(1),
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        counterText: '',
                                      ),
                                      onChanged: (value) => _onOtpChanged(value, index),
                                    ),
                                  );
                                }),
                              ),
                              SizedBox(height: isSmallScreen ? 20 : 30),

                              /// Verify button
                              Container(
                                width: double.infinity,
                                height: isSmallScreen ? 48 : 50,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFF5252),
                                      Color(0xFFFF1744),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF1744).withOpacity(0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : _handleVerifyOtp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                      : Text(
                                    'Verify',
                                    style: GoogleFonts.lato(
                                      fontSize: isSmallScreen ? 15 : 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 16 : 20),

                              /// Resend OTP
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Didn't receive code? ",
                                    style: GoogleFonts.lato(
                                      fontSize: bodyTextSize,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: isLoading ? null : _handleResendOtp,
                                    child: Text(
                                      "Resend",
                                      style: GoogleFonts.lato(
                                        fontSize: bodyTextSize,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFFF5252),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: isSmallScreen ? 12 : 16),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}