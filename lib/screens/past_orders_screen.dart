import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/tailor_service.dart';

class PastOrdersScreen extends StatefulWidget {
  const PastOrdersScreen({super.key});

  @override
  State<PastOrdersScreen> createState() => _PastOrdersScreenState();
}

class _PastOrdersScreenState extends State<PastOrdersScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _orders = [];
  Map<String, dynamic>? _metaData;
  int _currentPage = 1;
  final int _limit = 20;

  @override
  void initState() {
    super.initState();
    // Delay to ensure provider is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPastOrders();
    });
  }

  Future<void> _fetchPastOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get token from AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        setState(() {
          _errorMessage = 'Please login to view past orders';
          _isLoading = false;
        });
        return;
      }
      final tailorService = TailorService();

      // Call the API - filtering for delivered and cancelled orders
      final response = await tailorService.getBookings(
        token: token,
        status: null, // We'll filter locally to show both Delivered and Cancelled
        page: _currentPage,
        limit: _limit,
      );

      if (response['success'] == true) {
        final data = response['data'];
        final bookings = data['data'] as List<dynamic>;

        // Filter for only Delivered or Cancelled orders
        final pastOrders = bookings.where((booking) {
          final status = booking['status']?.toString().toLowerCase() ?? '';
          return status == 'delivered' || status == 'cancelled';
        }).toList();

        setState(() {
          _orders = pastOrders;
          _metaData = data['pagination'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to fetch orders';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading orders: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _navigateToOrderDetails(Map<String, dynamic> order) {
    Navigator.pushNamed(
      context,
      '/order-details',
      arguments: order, // Pass the order data
    ).then((_) {
      // Optionally refresh orders when returning
      _fetchPastOrders();
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'order confirmed':
        return const Color(0xFFFF6B6B); // Red
      case 'measurement done':
        return const Color(0xFFFF9500); // Orange
      case 'in progress':
        return const Color(0xFF007AFF); // Blue
      case 'ready to deliver':
        return const Color(0xFF9B59B6); // Purple
      case 'delivered':
        return const Color(0xFF34C759); // Green
      case 'cancelled':
        return const Color(0xFF8E8E93); // Gray
      default:
        return const Color(0xFF6B7280); // Gray
    }
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
          'Past Orders',
          style: GoogleFonts.lato(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorWidget()
          : _orders.isEmpty
          ? _buildEmptyState()
          : _buildOrdersList(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An error occurred',
              style: GoogleFonts.lato(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchPastOrders,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Past Orders',
              style: GoogleFonts.lato(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your delivered and cancelled orders will appear here',
              style: GoogleFonts.lato(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList() {
    return RefreshIndicator(
      onRefresh: _fetchPastOrders,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title with count
            Text(
              'Past Orders (${_orders.length})',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 20),

            // Orders List
            ..._orders.map((order) => _buildPastOrderItem(order)),

            const SizedBox(height: 20),

            // Load More Section (if there might be more orders)
            if (_metaData != null &&
                _orders.length >= _limit)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _currentPage++;
                  });
                  _fetchPastOrders();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Center(
                    child: Text(
                      'Load More Orders',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPastOrderItem(Map<String, dynamic> order) {
    final status = order['status'] ?? 'Unknown';
    final statusColor = _getStatusColor(status);
    final formattedStatus = _formatStatus(status);

    // Extract customer data from new structure
    final customer = order['customer'] as Map<String, dynamic>? ?? {};
    final customerName = customer['name'] ?? 'Unknown Customer';
    final customerImage = customer['image'] ?? '';

    // Extract order ID
    final bookingId = order['bookingId'] ?? 'N/A';
    final orderId = bookingId.length >= 5 ? bookingId.substring(0, 5) : bookingId;

    // Extract price and category from categories array
    final categories = order['categories'] as List<dynamic>? ?? [];
    int totalPrice = 0;
    String categoryName = 'Service';

    if (categories.isNotEmpty) {
      final firstCategory = categories.first as Map<String, dynamic>;
      totalPrice = firstCategory['price'] ?? 0;
      categoryName = firstCategory['subCategoryName']?.toString() ??
          (firstCategory['categoryId']?['name']?.toString() ?? 'Service');
    }

    return GestureDetector(
      onTap: () => _navigateToOrderDetails(order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            // Customer Image
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                color: Colors.grey[200],
                image: customerImage.isNotEmpty
                    ? DecorationImage(
                  image: NetworkImage(customerImage),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: customerImage.isEmpty
                  ? Icon(
                Icons.person,
                size: 30,
                color: Colors.grey[400],
              )
                  : null,
            ),

            const SizedBox(width: 16),

            // Order Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer and Order ID Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Customer',
                              style: GoogleFonts.lato(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              customerName,
                              style: GoogleFonts.lato(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'ID',
                              style: GoogleFonts.lato(
                                fontSize: 12,
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
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Amount, Items and Status Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Text(
                              '₹$totalPrice',
                              style: GoogleFonts.lato(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                ' • $categoryName',
                                style: GoogleFonts.lato(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
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
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}