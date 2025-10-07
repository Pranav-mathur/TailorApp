import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/tailor_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  // Loading and error states
  bool _isLoading = true;
  String? _errorMessage;

  // API data
  Map<String, dynamic> homeData = {};
  List<Map<String, dynamic>> allBookings = [];
  List<Map<String, dynamic>> filteredBookings = [];
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Method to fetch bookings from API
  Future<void> _fetchBookings() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final tailorService = TailorService();

      // Make API call to get bookings
      final response = await tailorService.getBookings(
        token: authProvider.token ?? "",
      );

      print('API Response: $response'); // Debug print

      if (response['success'] == true) {
        final responseData = response['data'] as Map<String, dynamic>;

        setState(() {
          _processBookingsData(responseData);
          _isLoading = false;
        });
      } else {
        Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
          '/login',
              (route) => false,
        );
        throw Exception(response['message'] ?? 'Failed to fetch bookings');
      }
    } catch (e) {
      print('Error fetching bookings: $e'); // Debug print

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading bookings: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // Process API response and organize data
  void _processBookingsData(Map<String, dynamic> responseData) {
    // Extract tailor details from root level
    final tailorDetails = responseData['tailor_details'] as Map<String, dynamic>? ?? {};

    // Extract bookings data
    final bookingsData = responseData['data'] as List<dynamic>? ?? [];
    final pagination = responseData['pagination'] as Map<String, dynamic>? ?? {};

    // Convert to list of maps for easier processing
    allBookings = bookingsData.map((booking) => booking as Map<String, dynamic>).toList();

    // Filter out completed and cancelled orders for main display
    final activeBookings = allBookings.where((booking) {
      final status = booking['status']?.toString().toLowerCase() ?? '';
      return status != 'completed' && status != 'cancelled';
    }).toList();

    // Separate bookings by status for different sections
    final requestedBookings = activeBookings.where((booking) {
      return booking['status']?.toString().toLowerCase() == 'requested';
    }).toList();

    final ongoingBookings = activeBookings.where((booking) {
      final status = booking['status']?.toString().toLowerCase() ?? '';
      return status == 'confirmed' || status == 'in progress';
    }).toList();

    // Create home data structure
    homeData = {
      "businessInfo": {
        "name": tailorDetails['name'] ?? 'Your Business',
        "logo": tailorDetails['profile_pic'] ?? 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&q=80',
        "mobile": tailorDetails['mobile'] ?? '',
        "address": tailorDetails['address'] ?? {},
        "boostPromo": {
          "title": "Boost Your Business",
          "subtitle": "Get a featured spot",
          "buttonText": "Upgrade Now"
        }
      },
      "ordersToReview": {
        "count": requestedBookings.length,
        "orders": requestedBookings.map((booking) => _formatBookingForUI(booking)).toList(),
      },
      "ongoingOrders": {
        "count": ongoingBookings.length,
        "orders": ongoingBookings.map((booking) => _formatBookingForUI(booking)).toList(),
      },
      "totalBookings": pagination['totalCount'] ?? 0,
    };

    // Initialize filtered bookings
    _filterBookings();

    print('Processed home data: $homeData'); // Debug print
  }

  // Format booking data for UI consumption
  Map<String, dynamic> _formatBookingForUI(Map<String, dynamic> booking) {
    final bookingId = booking['bookingId']?.toString() ?? '';
    final orderId = bookingId.length >= 5 ? bookingId.substring(0, 5) : bookingId;

    final customer = booking['customer'] as Map<String, dynamic>? ?? {};
    final category = booking['category'] as Map<String, dynamic>? ?? {};

    return {
      "id": orderId,
      "customerName": customer['name']?.toString() ?? 'Unknown Customer',
      "customerImage": customer['image']?.toString() ?? 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&q=80',
      "amount": category['price'] ?? 0,
      "items": category['categoryId']?['name']?.toString() ??
          (category['subCategoryName']?.toString() ?? 'Service'),
      "status": _formatStatus(booking['status']?.toString() ?? 'Unknown'),
      "statusColor": _getStatusColor(booking['status']?.toString() ?? 'Unknown'),
      "bookingId": bookingId,
      "createdAt": booking['createdAt']?.toString() ?? '',
    };
  }

  // Format status for display
  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'requested':
        return 'Order Assigned';
      case 'confirmed':
        return 'Order Confirmed';
      case 'in progress':
        return 'Stitching';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  // Get status color
  String _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'requested':
        return '#FF6B6B'; // Red
      case 'confirmed':
        return '#FF9500'; // Orange
      case 'in progress':
        return '#007AFF'; // Blue
      case 'completed':
        return '#34C759'; // Green
      case 'cancelled':
        return '#8E8E93'; // Gray
      default:
        return '#8E8E93'; // Gray
    }
  }

  // Filter bookings based on search query
  void _filterBookings() {
    if (_searchQuery.isEmpty) {
      setState(() {
        filteredBookings = [];
      });
      return;
    }

    final query = _searchQuery.toLowerCase();
    filteredBookings = allBookings.where((booking) {
      final bookingId = booking['bookingId']?.toString().toLowerCase() ?? '';
      final customer = booking['customer'] as Map<String, dynamic>? ?? {};
      final customerName = customer['name']?.toString().toLowerCase() ?? '';
      final category = booking['category'] as Map<String, dynamic>? ?? {};
      final categoryName = category['categoryId']?['name']?.toString().toLowerCase() ?? '';

      return bookingId.contains(query) ||
          customerName.contains(query) ||
          categoryName.contains(query);
    }).toList();
  }

  void _openSidebar() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          'Logout',
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.lato(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: Text(
              'Cancel',
              style: GoogleFonts.lato(
                color: Colors.grey[600],
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();

              await Provider.of<AuthProvider>(context, listen: false).logout();

              if (!mounted) return;

              Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
                '/login',
                    (route) => false,
              );
            },
            child: Text(
              'Logout',
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

  // Refresh method
  Future<void> _refreshBookings() async {
    await _fetchBookings();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_errorMessage != null) {
      return _buildErrorScreen();
    }

    final businessInfo = homeData['businessInfo'] ?? {};
    final ordersToReview = homeData['ordersToReview'] ?? {'count': 0, 'orders': []};
    final ongoingOrders = homeData['ongoingOrders'] ?? {'count': 0, 'orders': []};

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      endDrawer: _buildSidebar(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshBookings,
          color: Colors.red,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Row(
                  children: [
                    // Business Logo
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(businessInfo['logo'] ?? ''),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Business Name
                    Expanded(
                      child: Text(
                        businessInfo['name'] ?? 'Your Business',
                        style: GoogleFonts.lato(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    // Menu Button
                    GestureDetector(
                      onTap: _openSidebar,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.menu,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Boost Business Promo
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.brown.shade600,
                        Colors.brown.shade500,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.star,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              businessInfo['boostPromo']?['title'] ?? 'Boost Your Business',
                              style: GoogleFonts.lato(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              businessInfo['boostPromo']?['subtitle'] ?? 'Get a featured spot',
                              style: GoogleFonts.lato(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/upgrade-profile');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            businessInfo['boostPromo']?['buttonText'] ?? 'Upgrade Now',
                            style: GoogleFonts.lato(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.brown.shade600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Search Bar
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.lato(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Search order ID, customer',
                      hintStyle: GoogleFonts.lato(
                        color: Colors.grey[500],
                        fontSize: 16,
                      ),
                      suffixIcon: Icon(
                        Icons.search,
                        color: Colors.grey[500],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim();
                        _filterBookings();
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Search Results Section
                if (_searchQuery.isNotEmpty) ...[
                  _buildSearchResults(),
                  const SizedBox(height: 24),
                ],

                // Orders to Review Section (Requested status)
                if (_searchQuery.isEmpty && ordersToReview['count'] > 0) ...[
                  _buildOrderSection(
                    title: 'Orders to Review',
                    count: ordersToReview['count'],
                    orders: ordersToReview['orders'],
                  ),
                  const SizedBox(height: 24),
                ],

                // Ongoing Orders Section (Confirmed & In Progress status)
                if (_searchQuery.isEmpty && ongoingOrders['count'] > 0) ...[
                  _buildOrderSection(
                    title: 'Ongoing Orders',
                    count: ongoingOrders['count'],
                    orders: ongoingOrders['orders'],
                  ),
                  const SizedBox(height: 24),
                ],

                // Show empty state if no active orders and no search
                if (_searchQuery.isEmpty && ordersToReview['count'] == 0 && ongoingOrders['count'] == 0) ...[
                  _buildEmptyState(),
                  const SizedBox(height: 24),
                ],

                // Past Orders Section
                if (_searchQuery.isEmpty)
                  Container(
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
                          'Past Orders',
                          style: GoogleFonts.lato(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/past-orders');
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'View All Past Orders',
                                style: GoogleFonts.lato(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.grey[600],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Loading screen
  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading your bookings...',
              style: GoogleFonts.lato(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Error screen
  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
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
                'Failed to load bookings',
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Unknown error occurred',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _refreshBookings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.lato(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Empty state widget
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
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
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No Active Orders',
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You don\'t have any pending or ongoing orders at the moment.',
            style: GoogleFonts.lato(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Search results widget
  Widget _buildSearchResults() {
    if (filteredBookings.isEmpty) {
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
            Icon(
              Icons.search_off_outlined,
              size: 48,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 12),
            Text(
              'No results found',
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try searching with different keywords',
              style: GoogleFonts.lato(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return _buildOrderSection(
      title: 'Search Results',
      count: filteredBookings.length,
      orders: filteredBookings.map((booking) => _formatBookingForUI(booking)).toList(),
    );
  }

  // ===========================
  // Helper Methods
  // ===========================

  Widget _buildOrderSection({
    required String title,
    required int count,
    required List<dynamic> orders,
  }) {
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
            '$title ($count)',
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          ...orders.map((order) => _buildOrderItem(order)),
        ],
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> order) {
    Color statusColor =
    Color(int.parse(order['statusColor'].replaceFirst('#', '0xFF')));

    // Find the full booking data from allBookings
    final fullBooking = allBookings.firstWhere(
          (booking) => booking['bookingId'] == order['bookingId'],
      orElse: () => <String, dynamic>{},
    );

    return GestureDetector(
      onTap: () {
        if (fullBooking.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to load order details'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        // Pass the full booking object
        Navigator.pushNamed(
          context,
          '/order-details',
          arguments: fullBooking,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: NetworkImage(order['customerImage']),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                              order['customerName'],
                              style: GoogleFonts.lato(
                                fontSize: 14,
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
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Order ID',
                              style: GoogleFonts.lato(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              order['id'],
                              style: GoogleFonts.lato(
                                fontSize: 14,
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
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Text(
                              '₹${order['amount']}',
                              style: GoogleFonts.lato(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                ' • ${order['items']}',
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
                            order['status'],
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

  Widget _buildSidebar() {
    return Container(
      width: 280,
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Menu',
                    style: GoogleFonts.lato(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.close,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            // Menu Items
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Account',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMenuItem(
                      icon: Icons.shopping_cart_outlined,
                      title: 'Past Orders',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/past-orders');
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.person_outline,
                      title: 'My Profile',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/my-profile');
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.account_balance_outlined,
                      title: 'Bank Details',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/bank-details');
                      },
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Settings & Support',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMenuItem(
                      icon: Icons.headset_mic_outlined,
                      title: 'Contact Us',
                      onTap: () {
                        Navigator.pop(context);
                        // Add contact us navigation or functionality
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.logout_outlined,
                      title: 'Logout',
                      onTap: _confirmLogout,
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Boost Business Section
            Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.brown.shade600,
                    Colors.brown.shade500,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.star,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Boost Your Business',
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Get a featured spot',
                          style: GoogleFonts.lato(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/upgrade-profile');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Upgrade',
                        style: GoogleFonts.lato(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.brown.shade600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: Colors.black,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}