import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/tailor_service.dart';

class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({super.key});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  Map<String, dynamic>? bookingData;
  bool _isUpdatingStatus = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the booking data passed from the previous screen
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      setState(() {
        bookingData = args;
      });
    }
  }

  String _formatOrderId(String bookingId) {
    return bookingId.length >= 5 ? bookingId.substring(0, 5) : bookingId;
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) {
      return 'N/A';
    }
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final dateFormat = DateFormat('d MMM \'\'yy');
      return dateFormat.format(dateTime);
    } catch (e) {
      return dateTimeString;
    }
  }

  Color _getTimelineStatusColor(String status, bool isActive) {
    if (status == "completed" || isActive) {
      return Colors.green;
    }
    return Colors.grey.shade400;
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'order confirmed':
        return 'Order Confirmed';
      case 'measurement done':
        return 'Measurement Done';
      case 'in progress':
        return 'In Progress';
      case 'ready to deliver':
        return 'Ready to Deliver';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'order confirmed':
        return const Color(0xFFFF6B6B);
      case 'measurement done':
        return const Color(0xFFFF9500);
      case 'in progress':
        return const Color(0xFF007AFF);
      case 'ready to deliver':
        return const Color(0xFF9B59B6);
      case 'delivered':
        return const Color(0xFF34C759);
      case 'cancelled':
        return const Color(0xFF8E8E93);
      default:
        return const Color(0xFF8E8E93);
    }
  }

  Future<void> _updateOrderStatus(String nextStatus) async {
    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final tailorService = TailorService();
      final bookingId = bookingData!['bookingId']?.toString() ?? '';

      final response = await tailorService.updateBookingStatus(
        token: token,
        bookingId: bookingId,
        status: nextStatus,
      );

      if (response['success'] == true) {
        // Extract only the timeline from the updated booking
        final updatedBooking = response['data']['booking'] as Map<String, dynamic>?;

        if (updatedBooking != null && updatedBooking['timeline'] != null) {
          // Update only the timeline while keeping all other booking data intact
          setState(() {
            bookingData!['timeline'] = updatedBooking['timeline'];
            bookingData!['status'] = updatedBooking['status'] ?? bookingData!['status'];
            _isUpdatingStatus = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Status updated to $nextStatus'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          // If timeline is not in response, just update loading state
          setState(() {
            _isUpdatingStatus = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Status updated successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to update status');
      }
    } catch (e) {
      setState(() {
        _isUpdatingStatus = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _contactCustomer() {
    final customer = bookingData?['customer'] as Map<String, dynamic>?;
    final phone = customer?['phone'] ?? '';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling $phone...'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _viewItemImages(List<dynamic> images, String itemType) {
    if (images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No images available'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '$itemType Images',
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Image
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
              ),
              child: Image.network(
                images.first.toString(),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Icon(Icons.image, size: 50, color: Colors.grey[500]),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _contactSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening support chat...'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (bookingData == null) {
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
            'Order Details',
            style: GoogleFonts.lato(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Center(
          child: Text(
            'No order data available',
            style: GoogleFonts.lato(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }

    final timeline = bookingData!['timeline'] as List<dynamic>? ?? [];
    final customer = bookingData!['customer'] as Map<String, dynamic>? ?? {};
    final items = bookingData!['items'] as List<dynamic>? ?? [];
    final categories = bookingData!['categories'] as List<dynamic>? ?? [];
    final status = bookingData!['status']?.toString() ?? 'Unknown';
    final orderId = _formatOrderId(bookingData!['bookingId']?.toString() ?? '');
    final createdAt = _formatDateTime(bookingData!['createdAt']?.toString());

    // Calculate total price from categories
    int totalPrice = 0;
    if (categories.isNotEmpty) {
      for (var category in categories) {
        totalPrice += (category['price'] as int?) ?? 0;
      }
    }

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
          'Order Details',
          style: GoogleFonts.lato(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline Section
            if (timeline.isNotEmpty) ...[
              _buildTimelineSection(timeline),
              const SizedBox(height: 24),
            ],

            // Customer Info Section
            _buildCustomerSection(customer, orderId, createdAt, status),

            const SizedBox(height: 24),

            // Items Section
            if (items.isNotEmpty) ...[
              _buildItemsSection(items),
              const SizedBox(height: 24),
            ],

            // Payment Section
            _buildPaymentSection(totalPrice),

            const SizedBox(height: 24),

            // Support Section
            // _buildSupportSection(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineSection(List<dynamic> timeline) {
    // Find current active step and check conditions for buttons
    Map<String, bool> stepStatus = {};
    for (var step in timeline) {
      final stepName = step['step']?.toString().toLowerCase() ?? '';
      final isActive = step['isActive'] ?? false;
      final status = step['status']?.toString().toLowerCase() ?? '';
      stepStatus[stepName] = isActive || status == 'completed';
    }

    return Column(
      children: timeline.asMap().entries.map((entry) {
        int index = entry.key;
        Map<String, dynamic> step = entry.value;
        bool isLast = index == timeline.length - 1;
        final stepName = step['step']?.toString() ?? '';
        final stepNameLower = stepName.toLowerCase();
        final isActive = step['isActive'] ?? false;
        final status = step['status']?.toString().toLowerCase() ?? '';

        // Determine if action button should be shown
        bool showActionButton = false;
        String buttonText = '';
        String nextStatus = '';
        bool isButtonEnabled = false;

        // In Progress button logic only
        if (stepNameLower == 'in progress') {
          final measurementDoneActive = stepStatus['measurement done'] ?? false;
          final inProgressActive = stepStatus['in progress'] ?? false;
          final readyToDeliverActive = stepStatus['ready to deliver'] ?? false;

          // Show "Start Stitching" button when Measurement Done is active and In Progress is not
          if (measurementDoneActive && !inProgressActive && !readyToDeliverActive) {
            showActionButton = true;
            buttonText = 'Start Stitching';
            nextStatus = 'In Progress';
            isButtonEnabled = true;
          }
          // Show "Complete" button when In Progress is active but Ready to Deliver is not
          else if (measurementDoneActive && inProgressActive && !readyToDeliverActive) {
            showActionButton = true;
            buttonText = 'Complete';
            nextStatus = 'Ready to Deliver';
            isButtonEnabled = true;
          }
          // Show disabled "Complete" button when Ready to Deliver is already active
          else if (measurementDoneActive && inProgressActive && readyToDeliverActive) {
            showActionButton = true;
            buttonText = 'Complete';
            nextStatus = 'Ready to Deliver';
            isButtonEnabled = false;
          }
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline Icon and Line
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _getTimelineStatusColor(
                      step['status']?.toString() ?? 'pending',
                      step['isActive'] ?? false,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: step['status'] == 'completed' || (step['isActive'] ?? false)
                      ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  )
                      : null,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: Colors.grey.shade300,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
              ],
            ),

            const SizedBox(width: 16),

            // Timeline Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stepName,
                              style: GoogleFonts.lato(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            if (step['timestamp'] != null && step['date'] != null)
                              Text(
                                '${step['timestamp']}  ${step['date']}',
                                style: GoogleFonts.lato(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            if (step['subtitle'] != null)
                              Text(
                                step['subtitle'].toString(),
                                style: GoogleFonts.lato(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Action Button
                      if (showActionButton)
                        GestureDetector(
                          onTap: isButtonEnabled && !_isUpdatingStatus
                              ? () => _updateOrderStatus(nextStatus)
                              : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isButtonEnabled && !_isUpdatingStatus
                                  ? Colors.brown.shade600
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _isUpdatingStatus
                                ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : Text(
                              buttonText,
                              style: GoogleFonts.lato(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isButtonEnabled
                                    ? Colors.white
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (!isLast) const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildCustomerSection(
      Map<String, dynamic> customer,
      String orderId,
      String placedOn,
      String status,
      ) {
    final statusColor = _getStatusColor(status);
    final formattedStatus = _formatStatus(status);

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        children: [
          // Customer Info
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  image: DecorationImage(
                    image: NetworkImage(
                      customer['image']?.toString() ??
                          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&q=80',
                    ),
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
                      'Customer',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      customer['name']?.toString() ?? 'Unknown Customer',
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Order Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order ID',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      orderId,
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Placed on',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      placedOn,
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  formattedStatus,
                  style: GoogleFonts.lato(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection(List<dynamic> items) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Items',
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 20),

          ...items.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> item = entry.value;
            return _buildItemCard(item, index == items.length - 1);
          }),
        ],
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item, bool isLast) {
    final measurements = item['measurements'] as Map<String, dynamic>? ?? {};
    final hasImages = item['hasImages'] == true;
    final images = item['images'] as List<dynamic>? ?? [];

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 20),
      child: Column(
        children: [
          // Item Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        item['category']?.toString() ?? 'Item',
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    if (item['type'] != null) ...[
                      Text(
                        ' • ',
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      Flexible(
                        child: Text(
                          item['type'].toString(),
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (hasImages && images.isNotEmpty)
                GestureDetector(
                  onTap: () => _viewItemImages(
                    images,
                    item['type']?.toString() ?? 'Item',
                  ),
                  child: Row(
                    children: [
                      Text(
                        'View',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          color: Colors.brown,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.visibility_outlined,
                        size: 16,
                        color: Colors.brown,
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Measurements
          if (measurements.isNotEmpty)
            ...measurements.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.key.toString().toUpperCase(),
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${entry.value} CM',
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            )),

          if (!isLast)
            Container(
              margin: const EdgeInsets.only(top: 16),
              height: 1,
              color: Colors.grey[200],
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(int totalPrice) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment',
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Amount',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              Text(
                '₹$totalPrice',
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Need Support?',
            style: GoogleFonts.lato(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),

          const SizedBox(height: 12),

          GestureDetector(
            onTap: _contactSupport,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.headset_mic_outlined,
                      size: 24,
                      color: Colors.black,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Contact Us',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}