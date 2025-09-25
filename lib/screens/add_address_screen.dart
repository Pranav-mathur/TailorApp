import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final TextEditingController _buildingNameController = TextEditingController();
  final TextEditingController _roadAreaController = TextEditingController();
  final TextEditingController _streetCityController = TextEditingController();

  bool _isLoading = false;
  String _locationName = '';
  String _locationAddress = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get the arguments passed from location picker
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (arguments != null) {
      _locationName = arguments['locationName'] ?? 'SNN Raj Vista';
      _locationAddress = arguments['locationAddress'] ?? 'Koramanagala, Bangalore';

      // Pre-fill the form with default values
      _buildingNameController.text = '';
      _roadAreaController.text = '';
      _streetCityController.text = '';
    }
  }

  Future<void> _saveAddress() async {
    // Validate form
    if (_buildingNameController.text.trim().isEmpty ||
        _roadAreaController.text.trim().isEmpty ||
        _streetCityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all address fields'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate saving address
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    // Create the complete address object to pass back
    final completeAddress = {
      'locationName': _locationName,
      'buildingName': _buildingNameController.text.trim(),
      'roadArea': _roadAreaController.text.trim(),
      'streetCity': _streetCityController.text.trim(),
      'fullAddress': '${_buildingNameController.text.trim()}, ${_roadAreaController.text.trim()}, ${_streetCityController.text.trim()}',
    };

    // Navigate back to business details with the address
    Navigator.of(context).popUntil((route) => route.settings.name == '/business');

    // Pass the address back to business details
    // Note: You might want to use a state management solution for this in a real app
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Address saved successfully!'),
        backgroundColor: Colors.green,
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
          children: [
            const SizedBox(height: 20),

            // Location Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Icon(
                Icons.location_on,
                size: 40,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 40),

            // Building Name
            _buildInputField(
              label: 'Building Name',
              controller: _buildingNameController,
              hintText: 'Enter building name',
            ),

            const SizedBox(height: 24),

            // Road/Area
            _buildInputField(
              label: 'Road/Area',
              controller: _roadAreaController,
              hintText: 'Enter road or area',
            ),

            const SizedBox(height: 24),

            // Street and City
            _buildInputField(
              label: 'Street and City',
              controller: _streetCityController,
              hintText: 'Enter street and city',
            ),

            const SizedBox(height: 60),

            // Save Address Button
            Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                color: Colors.red.shade400,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: _isLoading
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

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: controller,
            style: GoogleFonts.lato(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.w600,
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
        ),
      ],
    );
  }

  @override
  void dispose() {
    _buildingNameController.dispose();
    _roadAreaController.dispose();
    _streetCityController.dispose();
    super.dispose();
  }
}