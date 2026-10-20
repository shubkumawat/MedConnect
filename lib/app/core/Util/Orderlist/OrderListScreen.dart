// import 'package:flutter/material.dart';
// import '../../Model/MyOrdersModel/MyOrderResponseApi.dart';
// import '../Colors/colors.dart';
//
// class OrderListItem extends StatelessWidget {
//   final OrderModel order;
//   final Function(String) onCancelOrder;
//
//   const OrderListItem({
//     Key? key,
//     required this.order,
//     required this.onCancelOrder,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: Card(
//         elevation: 4,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(15),
//         ),
//         child: Column(
//           children: [
//             // Order Header
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.grey[50],
//                 borderRadius: const BorderRadius.only(
//                   topLeft: Radius.circular(15),
//                   topRight: Radius.circular(15),
//                 ),
//               ),
//               child: Row(
//                 children: [
//                   const Icon(Icons.shopping_bag, color:Colors.teal),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           order.userName,
//                           style: const TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           order.phoneNo,
//                           style: TextStyle(
//                             color: Colors.grey[600],
//                             fontSize: 14,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   _buildStatusChip(getStatusText(order.orderStatus)),
//                 ],
//               ),
//             ),
//
//             // Order Details
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 children: [
//                   _buildDetailRow(
//                     icon: Icons.location_on,
//                     title: "Delivery Address",
//                     value: "${order.address}\nPIN: ${order.pinCode}",
//                     isMultiLine: true,
//                   ),
//                   const Divider(height: 24),
//                   _buildDetailRow(
//                     icon: Icons.shopping_cart,
//                     title: "Order Quantity",
//                     value: order.orderQty.toString(),
//                   ),
//                   const SizedBox(height: 12),
//                   _buildDetailRow(
//                     icon: Icons.payment,
//                     title: "Total Amount",
//                     value: "₹${order.totalAmount}",
//                     valueColor: CustomColors.tealdark,
//                   ),
//                   const SizedBox(height: 12),
//                   _buildDetailRow(
//                     icon: Icons.payment_outlined,
//                     title: "Payment Status",
//                     value: getStatusText(order.paymentStatus),
//                     valueColor: _getStatusColor(order.paymentStatus),
//                   ),
//                 ],
//               ),
//             ),
//
//             // Cancel Button
//             if (order.paymentStatus != 1)
//               InkWell(
//                 onTap: () => onCancelOrder(order.id),
//                 child: Container(
//                   height: 50,
//                   decoration: BoxDecoration(
//                     color: CustomColors.tealdark,
//                     borderRadius: const BorderRadius.only(
//                       bottomLeft: Radius.circular(15),
//                       bottomRight: Radius.circular(15),
//                     ),
//                   ),
//                   child: const Center(
//                     child: Text(
//                       "Cancel Order",
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 16,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDetailRow({
//     required IconData icon,
//     required String title,
//     required String value,
//     Color? valueColor,
//     bool isMultiLine = false,
//   }) {
//     return Row(
//       crossAxisAlignment: isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
//       children: [
//         Icon(icon, size: 20, color: Colors.grey[600]),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 title,
//                 style: TextStyle(
//                   color: Colors.grey[600],
//                   fontSize: 14,
//                 ),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 value,
//                 style: TextStyle(
//                   color: valueColor ?? Colors.black87,
//                   fontSize: 15,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildStatusChip(String status) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         color: _getStatusColor(status).withOpacity(0.1),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Text(
//         status,
//         style: TextStyle(
//           color: _getStatusColor(status),
//           fontSize: 12,
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//     );
//   }
//
//   Color _getStatusColor(dynamic status) {
//     if (status == 1 || status == "Completed") return Colors.green;
//     if (status == 0 || status == "Pending") return Colors.orange;
//     return Colors.red;
//   }
//   String getStatusText(int status) {
//     if (status == 0) {
//       return "Pending";
//     } else if (status == 1) {
//       return "Completed";
//     } else {
//       return "Unknown";
//     }
//   }
// }