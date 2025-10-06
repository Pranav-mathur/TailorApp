import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/global_provider.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  // Controllers renamed logically
  final TextEditingController _buildingController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadExistingAddress();
  }

  void _loadExistingAddress() {
    final globalProvider = Provider.of<GlobalProvider>(context, listen: false);
    final address = globalProvider.getAddress();

    if (address != null) {
      _buildingController.text = address['building'] ?? '';
      _streetController.text = address['street'] ?? '';
      _cityController.text = address['city'] ?? '';
      _stateController.text = address['state'] ?? '';
      _pincodeController.text = address['pincode'] ?? '';
      _mobileController.text = address['mobile'] ?? '';
    }
  }

  Future<void> _handleSaveAddress() async {
    // Validation
    if (_buildingController.text.trim().isEmpty) {
      _showSnackBar('Please enter building name', Colors.orange);
      return;
    }

    if (_streetController.text.trim().isEmpty) {
      _showSnackBar('Please enter street/area', Colors.orange);
      return;
    }

    if (_cityController.text.trim().isEmpty) {
      _showSnackBar('Please enter street and city', Colors.orange);
      return;
    }

    if (_stateController.text.trim().isEmpty) {
      _showSnackBar('Please enter state', Colors.orange);
      return;
    }

    if (_pincodeController.text.trim().isEmpty) {
      _showSnackBar('Please enter pincode', Colors.orange);
      return;
    }

    if (_mobileController.text.trim().isEmpty) {
      _showSnackBar('Please enter mobile number', Colors.orange);
      return;
    }

    // Validate mobile number (10 digits)
    if (_mobileController.text.trim().length != 10) {
      _showSnackBar('Please enter a valid 10-digit mobile number', Colors.orange);
      return;
    }

    // Validate pincode (6 digits)
    if (_pincodeController.text.trim().length != 6) {
      _showSnackBar('Please enter a valid 6-digit pincode', Colors.orange);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    final globalProvider = Provider.of<GlobalProvider>(context, listen: false);

    // Save address to GlobalProvider
    globalProvider.setAddress(
      building: _buildingController.text.trim(),
      street: _streetController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      pincode: _pincodeController.text.trim(),
      mobile: _mobileController.text.trim(),
    );

    setState(() {
      _isSubmitting = false;
    });

    _showSnackBar('Address saved successfully!', Colors.green);

    // Navigate back with result
    await Future.delayed(const Duration(milliseconds: 500));
    Navigator.of(context).pop(true);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
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
          'Add Address',
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
            // Location Icon
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_on,
                  size: 40,
                  color: Colors.black,
                ),
              ),
            ),

            const SizedBox(height: 40),

            _buildLabel("Building Name"),
            _buildTextField(controller: _buildingController, hintText: "Enter Building Name"),
            const SizedBox(height: 24),

            _buildLabel("Street/Area"),
            _buildTextField(controller: _streetController, hintText: "Enter Street/Area"),
            const SizedBox(height: 24),

            _buildLabel("City"),
            _buildTextField(controller: _cityController, hintText: "Enter City"),
            const SizedBox(height: 24),

            _buildLabel("State"),
            _buildTextField(controller: _stateController, hintText: "Enter State"),
            const SizedBox(height: 24),

            _buildLabel("Pincode"),
            _buildTextField(
              controller: _pincodeController,
              hintText: "Enter Pincode",
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),

            _buildLabel("Mobile Number"),
            _buildTextField(
              controller: _mobileController,
              hintText: "Enter Mobile Number",
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 60),

            // Save Address Button
            Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                color: const Color(0xFFE57373),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE57373).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSaveAddress,
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
                  'Save Address',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.lato(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.lato(
          fontSize: 16,
          color: Colors.black,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.lato(
            fontSize: 16,
            color: Colors.grey[400],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _buildingController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _mobileController.dispose();
    super.dispose();
  }
}
