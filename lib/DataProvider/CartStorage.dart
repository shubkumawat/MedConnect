// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../Model/CartListModel/CartItem.dart';
// import '../View/Dashboard/Cart/CartScreenController.dart';
//
// class CartStorage {
//   static const _cartKey = "my_cart";
//
//   // Save cart
//   static Future<void> saveCart(List<CartLocalItem> cart) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     List<String> cartJson =
//     cart.map((item) => jsonEncode(item.toJson())).toList();
//     await prefs.setStringList(_cartKey, cartJson);
//   }
//
//   // Load cart
//   static Future<List<CartLocalItem>> loadCart() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     List<String>? cartJson = prefs.getStringList(_cartKey);
//
//     if (cartJson != null) {
//
//       var cartItems =  cartJson
//           .map((item) => CartLocalItem.fromJson(jsonDecode(item)))
//           .toList();
//       // ✅ FIX: Filter out items with qty <= 0
//       cartItems.removeWhere((item) => item.qty <= 0);
//       cartItemTotal.value = cartItems.length;
//       return cartItems;
//     }else{
//       cartItemTotal.value = 0;
//     }
//     return [];
//   }
//
//   static Future<bool> removeFromCart(String productId) async {
//     List<CartLocalItem> _cartItems = await loadCart();
//
//     // Remove item where productId matches
//     _cartItems.removeWhere((item) => item.productId == productId);
//
//     await saveCart(_cartItems);
//
//     // ✅ FIX: Update cart total after removal
//     cartItemTotal.value = _cartItems.length;
//     return true;
//   }
//   static Future<bool> addToCart(CartLocalItem newItem) async {
//     List<CartLocalItem> _cartItems = await loadCart();
//     // ✅ FIX: If qty is 0 or less, remove from cart instead of adding
//     if (newItem.qty <= 0) {
//       _cartItems.removeWhere((item) => item.productId == newItem.productId);
//       await saveCart(_cartItems);
//       cartItemTotal.value = _cartItems.length;
//       return true;
//     }
//     // cartItemTotal.value = _cartItems.length;
//     final index = _cartItems.indexWhere((item) => item.productId == newItem.productId);
//
//     if (index != -1) {
//       _cartItems[index].qty = newItem.qty;
//     } else {
//       _cartItems.add(newItem);
//     }
//
//     await CartStorage.saveCart(_cartItems);
//     cartItemTotal.value = _cartItems.length;
//     return true;
//   }
//   // Clear cart
//   static Future<void> clearCart() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.remove(_cartKey);
//     cartItemTotal.value = 0;
//   }
// }