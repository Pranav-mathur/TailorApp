import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PastOrdersScreen extends StatefulWidget {
  const PastOrdersScreen({super.key});

  @override
  State<PastOrdersScreen> createState() => _PastOrdersScreenState();
}

class _PastOrdersScreenState extends State<PastOrdersScreen> {
  // JSON structure representing API response for past orders
  final Map<String, dynamic> pastOrdersData = {
    "metadata": {
      "totalOrders": 15,
      "totalPages": 2,
      "currentPage": 1,
      "ordersPerPage": 10,
      "lastUpdated": "2024-07-15T10:30:00Z"
    },
    "orders": [
      {
        "id": "454382",
        "customerName": "Bhuvesh Kumar",
        "customerImage": "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100&q=80",
        "amount": 899,
        "items": "Formal shirt",
        "status": "Payment Pending",
        "statusColor": "#FF6B6B",
        "orderDate": "2024-07-12T09:38:00Z",
        "completionDate": null,
        "paymentStatus": "pending",
        "deliveryStatus": "completed"
      },
      {
        "id": "454381",
        "customerName": "Chaitanya Rathi",
        "customerImage": "https://images.unsplash.com/photo-1494790108755-2616b332c3a2?w=100&q=80",
        "amount": 999,
        "items": "Kurta",
        "status": "Completed",
        "statusColor": "#6B7280",
        "orderDate": "2024-07-10T14:25:00Z",
        "completionDate": "2024-07-13T16:00:00Z",
        "paymentStatus": "paid",
        "deliveryStatus": "delivered"
      },
      {
        "id": "454380",
        "customerName": "Aatish Kumar",
        "customerImage": "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&q=80",
        "amount": 499,
        "items": "Trousers",
        "status": "Completed",
        "statusColor": "#6B7280",
        "orderDate": "2024-07-08T11:15:00Z",
        "completionDate": "2024-07-11T10:30:00Z",
        "paymentStatus": "paid",
        "deliveryStatus": "delivered"
      },
      {
        "id": "454379",
        "customerName": "Rajesh Sharma",
        "customerImage": "https://images.unsplash.com/photo-1560250097-0b93528c311a?w=100&q=80",
        "amount": 1299,
        "items": "Blazer, Formal shirt",
        "status": "Completed",
        "statusColor": "#6B7280",
        "orderDate": "2024-07-05T13:45:00Z",
        "completionDate": "2024-07-09T15:20:00Z",
        "paymentStatus": "paid",
        "deliveryStatus": "delivered"
      },
      {
        "id": "454378",
        "customerName": "Amit Patel",
        "customerImage": "https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=100&q=80",
        "amount": 799,
        "items": "Casual shirt",
        "status": "Completed",
        "statusColor": "#6B7280",
        "orderDate": "2024-07-03T16:30:00Z",
        "completionDate": "2024-07-07T12:15:00Z",
        "paymentStatus": "paid",
        "deliveryStatus": "delivered"
      }
    ],
    "statistics": {
      "completedOrders": 4,
      "pendingPayments": 1,
      "totalRevenue": 4395,
      "averageOrderValue": 879
    }
  };

  void _navigateToOrderDetails(Map<String, dynamic> order) {
    // Store navigation context for proper back navigation
    Navigator.pushNamed(
      context,
      '/order-details',
    ).then((_) {
      // This callback executes when returning from order details
      // No additional action needed as we want to stay on past orders
    });
  }

  @override
  Widget build(BuildContext context) {
    final orders = pastOrdersData['orders'] as List<dynamic>;
    final metadata = pastOrdersData['metadata'];

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title
            Text(
              'Past Orders',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 20),

            // Orders List
            ...orders.map((order) => _buildPastOrderItem(order)),

            const SizedBox(height: 20),

            // Load More Section (if needed)
            if (metadata['currentPage'] < metadata['totalPages'])
              Container(
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
          ],
        ),
      ),
    );
  }

  Widget _buildPastOrderItem(Map<String, dynamic> order) {
    Color statusColor = Color(int.parse(order['statusColor'].replaceFirst('#', '0xFF')));

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
                image: DecorationImage(
                  image: NetworkImage(order['customerImage']),
                  fit: BoxFit.cover,
                ),
              ),
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
                              order['customerName'],
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
                              order['id'],
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
}