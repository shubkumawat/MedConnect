import 'package:flutter/material.dart';

class OrderSuccessDialog extends StatelessWidget {
  final String orderId;
  final String customerName;
  final String address;
  final VoidCallback onClose;
  final int Payment;


   OrderSuccessDialog({
    Key? key,
    required this.orderId,
    required this.customerName,
    required this.address,
    required this.onClose,
    required this.Payment,

  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 70,
              ),
              const SizedBox(height: 20),

              // Success Title
              const Text(
                'Order Successful!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 10),

              // const Text(
              //   'Thank you for your order. Your package is on its way!',
              //   textAlign: TextAlign.center,
              //   style: TextStyle(
              //     color: Colors.grey,
              //   ),
              // ),
              // const SizedBox(height: 20),

              // Order Details Section
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow('Order ID:', orderId),
                    _buildDetailRow('Customer Name:', customerName),
                    // _buildDetailRow('Product:', productName),
                    // _buildDetailRow('Quantity:', Payment.toString()),
                    // _buildDetailRow('Price:', '₹${price.toStringAsFixed(2)}'),
                    _buildDetailRow('Date:', DateTime.now().toString().split(' ')[0]),
                    _buildDetailRow('Pay type:',Payment.toString()=="0"?"Cash On":"Online"),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Address Section
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Delivery Address',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      address,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Continue Shopping Button
              ElevatedButton(
                onPressed: onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Continue Shopping',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label, // Limits to 24 words
              style: const TextStyle(color: Colors.grey, fontSize: 11),
              overflow: TextOverflow.ellipsis, // Adds "..." if text overflows
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 10), // Add spacing between elements
          Expanded(
            child: Text(
              value.split(' ').take(25).join(' '),
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
              overflow: TextOverflow.ellipsis, // Adds "..." if text overflows
              maxLines: 1,
              textAlign: TextAlign.right, // Aligns text to the right
            ),
          ),
        ],
      ),
    );
  }
}