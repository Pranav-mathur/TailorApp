import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayPaymentPage extends StatefulWidget {
  final double amount;
  final String? userName;
  final String? userEmail;
  final String? userPhone;

  const RazorpayPaymentPage({
    Key? key,
    required this.amount,
    this.userName,
    this.userEmail,
    this.userPhone,
  }) : super(key: key);

  @override
  State<RazorpayPaymentPage> createState() => _RazorpayPaymentPageState();
}

class _RazorpayPaymentPageState extends State<RazorpayPaymentPage> {
  late Razorpay _razorpay;
  bool _isProcessing = false;

  // 🔑 REPLACE WITH YOUR TEST KEY
  static const String _keyId = 'rzp_test_RQFfi9dG2GYNnE';

  @override
  void initState() {
    super.initState();
    _initializeRazorpay();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // ✅ SUCCESS - Navigate to success page
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    setState(() => _isProcessing = false);

    // Navigate to success page with payment details
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentSuccessPage(
          paymentId: response.paymentId ?? '',
          orderId: response.orderId ?? '',
          signature: response.signature ?? '',
          amount: widget.amount,
        ),
      ),
    );
  }

  // ❌ ERROR - Show error dialog
  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isProcessing = false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 10),
            Text('Payment Failed'),
          ],
        ),
        content: Text('Error: ${response.message}\nCode: ${response.code}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Retry'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous page
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // 💳 EXTERNAL WALLET - Handle wallet payments
  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() => _isProcessing = false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('External Wallet'),
        content: Text('Wallet: ${response.walletName}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // 🚀 OPEN RAZORPAY CHECKOUT
  void _openCheckout() {
    setState(() => _isProcessing = true);

    var options = {
      'key': _keyId,
      'amount': (widget.amount * 100).toInt(), // Convert to paise
      'name': 'Your Business Name',
      'description': 'Payment for ₹${widget.amount}',
      'timeout': 300, // 5 minutes
      'currency': 'INR',

      // Pre-fill customer details
      'prefill': {
        'contact': widget.userPhone ?? '9999999999',
        'email': widget.userEmail ?? 'test@example.com',
        'name': widget.userName ?? 'Test User',
      },

      // Theme
      'theme': {'color': '#3F51B5'},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      setState(() => _isProcessing = false);
      debugPrint('Error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pay ₹${widget.amount.toStringAsFixed(0)}',
          style: const TextStyle(color: Colors.black, fontSize: 18),
        ),
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Processing payment...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3F51B5), Color(0xFF5C6BC0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Amount',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '₹${widget.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Payment Methods Section
                  const Text(
                    'Pay by any UPI App',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 15),

                  _buildPaymentOption(
                    icon: Icons.payment,
                    title: 'Google Pay UPI',
                    color: Colors.blue,
                  ),
                  _buildPaymentOption(
                    icon: Icons.phonelink,
                    title: 'PhonePe Pay UPI',
                    color: Colors.purple,
                  ),
                  _buildPaymentOption(
                    icon: Icons.credit_card,
                    title: 'CRED UPI',
                    color: Colors.black87,
                  ),
                  _buildPaymentOption(
                    icon: Icons.add,
                    title: 'Add new UPI ID',
                    color: Colors.blue,
                    isAdd: true,
                  ),

                  const SizedBox(height: 30),
                  const Text(
                    'Cards',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 15),

                  _buildPaymentOption(
                    icon: Icons.credit_card,
                    title: 'Credit/Debit Card',
                    subtitle: 'Visa, Mastercard, RuPay',
                    color: Colors.orange,
                  ),

                  const SizedBox(height: 30),
                  const Text(
                    'Wallets',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 15),

                  _buildPaymentOption(
                    icon: Icons.account_balance_wallet,
                    title: 'Amazon Pay',
                    color: Colors.orange,
                  ),
                  _buildPaymentOption(
                    icon: Icons.wallet,
                    title: 'Mobikwik',
                    color: Colors.blue,
                  ),
                  _buildPaymentOption(
                    icon: Icons.account_balance,
                    title: 'Paytm',
                    color: Colors.lightBlue,
                  ),

                  const SizedBox(height: 30),

                  // Test Mode Info
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      border: Border.all(color: Colors.amber.shade200),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber.shade700),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Test Mode',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'Use test credentials:\nUPI: success@razorpay\nCard: 4111 1111 1111 1111',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Pay Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _openCheckout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3F51B5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'Pay ₹${widget.amount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Security Info
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield, size: 16, color: Colors.grey),
                      SizedBox(width: 5),
                      Text(
                        'Secure payment powered by Razorpay',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color color,
    bool isAdd = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isAdd ? Colors.blue : Colors.black87,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              )
            : null,
        trailing: Icon(
          isAdd ? Icons.add_circle_outline : Icons.arrow_forward_ios,
          color: Colors.grey.shade400,
          size: 20,
        ),
      ),
    );
  }
}

// ✅ SUCCESS PAGE - Shown after successful payment
class PaymentSuccessPage extends StatelessWidget {
  final String paymentId;
  final String orderId;
  final String signature;
  final double amount;

  const PaymentSuccessPage({
    Key? key,
    required this.paymentId,
    required this.orderId,
    required this.signature,
    required this.amount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 60, color: Colors.green),
                ),
              ),

              const SizedBox(height: 30),

              // Success Text
              const Text(
                'Payment Successful!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                '₹${amount.toStringAsFixed(2)} paid successfully',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
              ),

              const SizedBox(height: 40),

              // Payment Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildDetailRow('Payment ID', paymentId),
                    _buildDetailRow('Order ID', orderId),
                    _buildDetailRow('Amount', '₹${amount.toStringAsFixed(2)}'),
                    _buildDetailRow(
                      'Date',
                      '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to your home page or order page
                    Navigator.of(context).popUntil((route) => route.isFirst);

                    // Or navigate to specific page:
                    // Navigator.pushReplacement(
                    //   context,
                    //   MaterialPageRoute(builder: (context) => YourHomePage()),
                    // );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3F51B5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue Shopping',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              OutlinedButton(
                onPressed: () {
                  // Download receipt or view order details
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Receipt will be sent to your email'),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'View Receipt',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
