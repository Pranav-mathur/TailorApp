import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({super.key});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  // Static order data that would come from API
  late Map<String, dynamic> orderData;

  @override
  void initState() {
    super.initState();
    // This would normally be fetched from API based on selected order
    orderData = _getOrderData();
  }

  Map<String, dynamic> _getOrderData() {
    // This represents the JSON structure that would come from your API
    return {
      "orderId": "34564",
      "timeline": [
        {
          "step": "Order Assigned",
          "status": "completed",
          "timestamp": "1:30 PM",
          "date": "12, July '25",
          "isActive": true
        },
        {
          "step": "Order Pickup",
          "status": "pending",
          "timestamp": null,
          "date": null,
          "isActive": false,
          "subtitle": "Yet to pick"
        },
        {
          "step": "Stitching",
          "status": "pending",
          "timestamp": null,
          "date": null,
          "isActive": false
        },
        {
          "step": "Ready to Deliver",
          "status": "pending",
          "timestamp": null,
          "date": null,
          "isActive": false
        }
      ],
      "customer": {
        "name": "Arjun Das",
        "image": "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&q=80",
        "phone": "+91 98765 43210"
      },
      "orderInfo": {
        "placedOn": "9:38 PM • 12 July '25",
        "currentStatus": "Order Pickup"
      },
      "items": [
        {
          "category": "Shirts",
          "type": "Casual shirt",
          "measurements": {
            "Collar": "49 CM",
            "Chest": "102 CM"
          },
          "hasImages": true,
          "images": [
            "https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=400&q=80"
          ]
        },
        {
          "category": "Shirts",
          "type": "Formal shirt",
          "measurements": {
            "Collar": "49 CM",
            "Chest": "102 CM"
          },
          "hasImages": true,
          "images": [
            "https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=400&q=80"
          ]
        }
      ],
      "payment": {
        "totalAmount": 2198,
        "currency": "₹",
        "breakdown": {
          "itemCost": 2148,
          "taxes": 50
        }
      },
      "support": {
        "available": true,
        "contactTitle": "Contact Us"
      }
    };
  }

  Color _getTimelineStatusColor(String status, bool isActive) {
    if (status == "completed" || isActive) {
      return Colors.green;
    }
    return Colors.grey.shade400;
  }

  void _contactCustomer() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling...'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _viewItemImages(List<String> images, String itemType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$itemType Images', style: GoogleFonts.lato()),
        content: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            image: images.isNotEmpty
                ? DecorationImage(
              image: NetworkImage(images.first),
              fit: BoxFit.cover,
            )
                : null,
          ),
          child: images.isEmpty
              ? Center(
            child: Icon(Icons.image, size: 50, color: Colors.grey[500]),
          )
              : null,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.lato()),
          ),
        ],
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
    final timeline = orderData['timeline'] as List<dynamic>;
    final customer = orderData['customer'];
    final orderInfo = orderData['orderInfo'];
    final items = orderData['items'] as List<dynamic>;
    final payment = orderData['payment'];

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
            _buildTimelineSection(timeline),

            const SizedBox(height: 24),

            // Customer Info Section
            _buildCustomerSection(customer, orderInfo),

            const SizedBox(height: 24),

            // Items Section
            _buildItemsSection(items),

            const SizedBox(height: 24),

            // Payment Section
            _buildPaymentSection(payment),

            const SizedBox(height: 24),

            // Support Section
            _buildSupportSection(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineSection(List<dynamic> timeline) {
    return Column(
      children: timeline.asMap().entries.map((entry) {
        int index = entry.key;
        Map<String, dynamic> step = entry.value;
        bool isLast = index == timeline.length - 1;

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
                    color: _getTimelineStatusColor(step['status'], step['isActive'] ?? false),
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
                  Text(
                    step['step'],
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  if (step['timestamp'] != null)
                    Text(
                      '${step['timestamp']}  ${step['date']}',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  if (step['subtitle'] != null)
                    Text(
                      step['subtitle'],
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
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

  Widget _buildCustomerSection(Map<String, dynamic> customer, Map<String, dynamic> orderInfo) {
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
                    image: NetworkImage(customer['image']),
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
                      customer['name'],
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),

              // Call Button
              GestureDetector(
                onTap: _contactCustomer,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.phone,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Order Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
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
                    orderData['orderId'],
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              Column(
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
                    orderInfo['placedOn'],
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  orderInfo['currentStatus'],
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
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

          ...items.map((item) => _buildItemCard(item, items)),
        ],
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item, List<dynamic> allItems) {
    final measurements = item['measurements'] as Map<String, dynamic>;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          // Item Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    item['category'],
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    ' • ${item['type']}',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              if (item['hasImages'])
                GestureDetector(
                  onTap: () => _viewItemImages(
                      List<String>.from(item['images']),
                      item['type']
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
                      Icon(
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
          ...measurements.entries.map((entry) =>
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      entry.value,
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
          ),

          if (item != allItems.last)
            Container(
              margin: const EdgeInsets.only(top: 16),
              height: 1,
              color: Colors.grey[200],
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(Map<String, dynamic> payment) {
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
                '${payment['currency']}${payment['totalAmount']}',
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
                    Icon(
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