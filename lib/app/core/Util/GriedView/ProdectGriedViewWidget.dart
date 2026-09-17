// import 'dart:math';
import 'package:healaura/app/core/Util/app_toast.dart';
//
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:groticapp/Model/CategoriesModel/CategoriesResponseApi.dart';
// import 'package:groticapp/Model/ProductModel/ProductResponseApi.dart';
// import 'package:groticapp/View/AddToCartScreen/AddToCartScreen.dart';
// import 'package:groticapp/View/LoginScreen/login_screen.dart';
// import 'package:groticapp/View/SubCategory/SubcategoryScreen.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../DataProvider/CartStorage.dart';
// import '../../DataProvider/api_provider.dart';
// import '../../DataProvider/app_shared_preferences.dart';
// import '../../DataProvider/web_api_constant.dart';
// import '../../Model/HomeDetails/HomeDetailsResponseApi.dart';
// import '../../Model/OfferBuy1Get1ResonseApi/Buy1Get1ResponseModel.dart';
// import '../../Model/SearchModel/SearchRasponseApi.dart';
// import '../../View/Dashboard/Cart/CartScreenController.dart';
// import '../../View/ProductScreen/ProductScreen.dart';
// import '../HelperClasses/CustomeButton/CustomButton.dart';
// import '../Print/print_log.dart';
// List<Child> categoryMainList = [];
//
// class CustomCetegories {
//   static bool cart = false;
//   CartScreenController cartCtrl = Get.put(CartScreenController());
//
//   bool isLogin = false;
//
//
//
// // Assuming you are passing the list of Category objects
//   homeCategoriesWidget(List<Category> categoryList) {
//     return Container(
//       width: double.infinity,
//       child: GridView.builder(
//         shrinkWrap: true, // Ensures the GridView uses only the space it needs
//         physics:
//             NeverScrollableScrollPhysics(), // Prevents GridView from scrolling independently
//         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 2, // 3 items per row
//         ),
//         itemCount: categoryList.length, // Total items to display
//         itemBuilder: (context, index) {
//           final cart = categoryList[index]; // Get the current Category
//
//           return Card(
//             elevation: 3,
//             color: Colors.white10,
//             margin: EdgeInsets.all(8),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(11), // Card ka border radius
//             ),
//             child: InkWell(
//               onTap: () {
//                 print("Navigating to SubCategoryScreen...");
//                 if (categoryList[index].children == "True") {
//
//                   // Get.to(SubCategoryScreen(categoryId: categoryList[index].category_id));
//
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => SubCategoryScreen(
//                           categoryId: categoryList[index].category_id),
//                     ),
//                   );
//                 } else {
//                   print("object1212");
//                   // categoryMainList = categoryList;
//                   Get.to(ProductScreen(id: categoryList[index].id,isTopProuct: 0,));
//                 }
//               },
//               child: Container(
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(11),
//                   color: Colors.white,
//                 ),
//                 child: Column(
//                   children: [
//                     Expanded(
//                       child: ClipRRect(
//                         borderRadius: BorderRadius.only(
//                             topLeft: Radius.circular(11),
//                             topRight: Radius.circular(
//                                 8)), // Image ko bhi rounded corner dena hai
//                         child: Container(
//                           color: Colors.white,
//                           child: cart.image != null
//                               ? Image.network(
//                                   cart.image ?? "",
//                                   fit: BoxFit.contain, // **Crop nahi karega, image poori dikhegi**
//                                   width: double.infinity,
//                                   height: double.infinity,
//                                   errorBuilder: (context, error, stackTrace) {
//                                     return Image.asset(
//                                       'assets/logo/groticapp.png',
//                                       fit: BoxFit.contain, // Backup image bhi proper show ho
//                                     );
//                                   },
//                                 )
//                               : Image.asset(
//                                   "assets/logo/groticapp.png",
//                                   fit: BoxFit.contain,
//                                 ),
//                         ),
//                       ),
//                     ),
//                     Padding(
//                       padding: const EdgeInsets.all(8.0),
//                       child: Center(
//                         child: Text(
//                           cart.title ?? "No Title",
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis,
//                           style: TextStyle(fontWeight: FontWeight.w700,),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   categorieWidget(List<Category> categoryList) {
//     return Container(
//       width: double.infinity,
//       child: GridView.builder(
//         shrinkWrap: true, // Ensures the GridView uses only the space it needs
//         physics:
//             NeverScrollableScrollPhysics(), // Prevents GridView from scrolling independently
//         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 2, // 3 items per row
//
//         ),
//         itemCount: categoryList.length, // Total items to display
//           itemBuilder: (context, index) {
//             final cart = categoryList[index]; // Get the current Category
//
//           return Card(
//             elevation: 3,
//             color: Colors.white10,
//             margin: EdgeInsets.all(8),
//             child: InkWell(
//               onTap: () {
//                 // Handle tap if needed
//                 Get.to(SubCategoryScreen(
//                     categoryId: categoryList[index]
//                         .category_id)); // Passing imagePath to AddToCartScreen
//               },
//               child: Container(
//                 height: 140,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(11),
//                   color: Colors.white,
//                 ),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.spaceAround,
//                   children: [
//                     ClipRRect(
//                       borderRadius: BorderRadius.circular(12),
//                       child: FadeInImage.assetNetwork(
//                         placeholder: "assets/logo/groticapp.png",
//                         placeholderFit: BoxFit.contain,
//                         image: cart.image ?? "",
//                         fit: BoxFit.fill,
//                         width: double.infinity,
//                         height: 100,
//                         imageErrorBuilder: (context, error, stackTrace) {
//                           return Image.asset(
//                             "assets/logo/groticapp.png",
//                             fit: BoxFit.contain,
//                             width: double.infinity,
//                             height: 100,
//                           );
//                         },
//                       ),
//                     ),
//                     Padding(
//                       padding: const EdgeInsets.all(8.0),
//                       child: Container(
//                         color: Colors.white,
//                         child: Center(
//                           child: Text(
//                             cart.title ?? "No Title",
//                             maxLines: 2,
//                             overflow: TextOverflow.ellipsis,
//                             textAlign: TextAlign.center,
//                             style: TextStyle(fontSize: 16,fontWeight: FontWeight.w700),
//                           ),
//                           // child: Text(  HomeScreenController homeCtrl=HomeScreenController(); ?? "No Title"), // Displaying category title
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   subCategoriesWidget(List<Child> itemCount, CalbackFunctionCat onPress) {
//     return Container(
//       width: double.infinity,
//       child: GridView.builder(
//         shrinkWrap: true, // Ensures the GridView uses only the space it needs
//         physics:
//             NeverScrollableScrollPhysics(), // Prevents GridView from scrolling independently
//         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 2, // 3 items per row
//         ),
//         itemCount: itemCount.length, // Total items to display
//         itemBuilder: (context, index) {
//           final cart = itemCount[index]; // Get the current Category
//
//           return Card(
//             elevation: 3,
//             color: Colors.white10,
//             margin: EdgeInsets.all(8),
//             child: InkWell(
//               onTap: () {
//                 onPress(index);
//               },
//               child: Container(
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(11),
//                   color: Colors.white,
//                 ),
//                 child: Column(
//                   children: [
//                     Expanded(
//                       child: Container(
//                         color: Colors.white,
//                         child: cart.image != null
//                             ? Image.network(
//                                 cart.image ?? "", // Using network image path
//                                 fit: BoxFit.fill,
//                                 errorBuilder: (context, error, stackTrace) {
//                                   return Image.asset(
//                                     'assets/logo/groticapp.png',
//                                     fit: BoxFit
//                                         .contain, // Backup image bhi proper show ho
//                                   );
//                                 },
//                               )
//                             : Image.asset("assets/logo/groticapp.png"),
//                       ),
//                     ),
//                     Padding(
//                       padding: const EdgeInsets.all(8.0),
//                       child: Container(
//                         color: Colors.white,
//                         child: Center(
//                           child: Text(
//                             cart.title ?? "No Title",
//                             maxLines: 2,
//                             overflow: TextOverflow.ellipsis,
//                             style: TextStyle(fontWeight: FontWeight.w700,),
//                           ),
//                           // child: Text(  HomeScreenController homeCtrl=HomeScreenController(); ?? "No Title"), // Displaying category title
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
//   catTitleshow(String title){
//     return Container(
//       width: Get.size.width,
//       margin: EdgeInsets.only(left: 10,right: 10),
//       padding: EdgeInsets.symmetric(horizontal: 20, vertical: 2),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             Color(0xFF004a86), // Your main theme color
//             Color(0xFF0072b1), // A lighter blue for gradient effect
//           ],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.2),
//             offset: Offset(0, 4),
//             blurRadius: 4,
//           ),
//         ],
//       ),
//       child: Text(
//         title,
//         textAlign: TextAlign.center,
//         style: TextStyle(
//           color: Colors.white,
//           fontSize: 18,
//           fontWeight: FontWeight.w600,
//           letterSpacing: 0.5,
//
//         ),
//       ),
//     );
//
//   }
//   topCategoriesWidgets1(List<TopSelling> top_s_p_list) {
//     return Container(
//       // height: 521,
//       width: double.infinity,
//       child: GridView.builder(
//         shrinkWrap: true, // Ensures the GridView uses only the space it needs
//         physics:
//             NeverScrollableScrollPhysics(), // Prevents GridView from scrolling independently
//         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 2, // 3 items per row
//         ),
//         itemCount: top_s_p_list.length, // Total items to display
//         itemBuilder: (context, index) {
//           num price = top_s_p_list[index].price ?? 0;
//           num discPrice = top_s_p_list[index].discPrice ?? 0;
//
//           // Calculate discount percentage
//           double discountPercentage = 0;
//           int discountPercentageInt = 0;
//           if (price > 0 && discPrice > 0) {
//             discountPercentage = ((price - discPrice) / price) * 100;
//             discountPercentageInt = discountPercentage.toInt(); // Result: 25
//           }
//           return Card(
//             elevation: 2,
//             color: Colors.white10,
//             margin: EdgeInsets.all(8),
//             child: Container(
//               //height: 111,
//               // color: Colors.white,
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(11),
//                 color: Colors.white,
//               ),
//               child: Stack(
//                 children: [
//                   InkWell(
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) {
//                             // Replace `NextScreen()` with the screen you want to navigate to
//                             return AddToCartScreen(
//                               image: top_s_p_list[index].image,
//                               slug: top_s_p_list[index].slug,
//                               qty:top_s_p_list[index]!.cartItem =
//                                   (top_s_p_list[index]!.cartItem ?? 0),
//                             );
//                           },
//                         ),
//                       );
//                     },
//                     child: Padding(
//                       padding: const EdgeInsets.all(0),
//                       child: Column(
//                         children: [
//                           Expanded(
//                             child: Container(
//                               //height: 111,
//                               color: Colors.white,
//                               child: Image.network(
//                                 top_s_p_list[index].image ??
//                                     "", // Correct usage of image path
//                                 fit: BoxFit.fill,
//                                 errorBuilder: (context, error, stackTrace) {
//                                   return Image.asset(
//                                     'assets/logo/groticapp.png',
//                                     fit: BoxFit
//                                         .contain, // Backup image bhi proper show ho
//                                   );
//                                 },
//                               ),
//                             ),
//                           ),
//                           Container(
//                             color: Colors.white,
//                             child: Center(
//                               child: Text(
//                                 top_s_p_list[index].title ?? "No Title",
//                                 maxLines: 2,
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                             ),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   "₹ ${top_s_p_list[index].discPrice ?? "No Title"}",
//                                   style: TextStyle(
//                                     fontSize: 11,
//                                     color: Colors.teal,
//                                   ),
//                                 ),
//                                 SizedBox(
//                                   width: 31,
//                                 ),
//                                 Text(
//                                   "₹ ${top_s_p_list[index].price ?? "No Title"}",
//                                   style: TextStyle(
//                                     fontSize: 11,
//                                     color: Colors.red,
//                                     decoration: TextDecoration
//                                         .lineThrough, // This adds the line through effect
//                                     decorationColor: Colors
//                                         .black, // You can customize the color of the line
//                                     decorationThickness: 2,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   Positioned(
//                     bottom: 0,
//                     right: 0,
//                     child: InkWell(
//                         onTap: () {},
//                         child: Container(
//                           height: 31,
//                           width: 35,
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.only(
//                                 topLeft: Radius.circular(11),
//                                 bottomRight: Radius.circular(11)),
//                             color: Colors.yellow[700],
//                           ),
//                           child: Center(
//                               child: Icon(
//                             Icons.add,
//                             color: Colors.white,
//                           )),
//                         )),
//                   ),
//                   Positioned(
//                     child: Container(
//                       height: 25,
//                       width: 91,
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.only(
//                           topLeft: Radius.circular(15),
//                           bottomRight: Radius.circular(15),
//                         ),
//                         color: Colors.teal,
//                       ),
//                       child: Center(
//                           child: Text(
//                         "${discountPercentageInt}% Off",
//                         style: TextStyle(color: Colors.white, fontSize: 11),
//                       )),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
//   //
//   // setState(() {
//   // isInCart = true;
//   // });
//
//   List<TopSelling> sortByDiscount(List<TopSelling> top_s_p_list) {
//     top_s_p_list.sort((a, b) {
//       num priceA = a.price ?? 0;
//       num discPriceA = a.discPrice ?? 0;
//       num priceB = b.price ?? 0;
//       num discPriceB = b.discPrice ?? 0;
//
//       double discountA = (priceA > 0 && discPriceA > 0)
//           ? ((priceA - discPriceA) / priceA) * 100
//           : 0;
//       double discountB = (priceB > 0 && discPriceB > 0)
//           ? ((priceB - discPriceB) / priceB) * 100
//           : 0;
//
//       return discountB.compareTo(discountA); // Sort in descending order
//     });
//     return top_s_p_list;
//   }
//   List<Buy1Get1> buy1Get1Discount(List<Buy1Get1> top_s_p_list) {
//     top_s_p_list.sort((a, b) {
//       num priceA = a.price ?? 0;
//       num discPriceA = a.discPrice ?? 0;
//       num priceB = b.price ?? 0;
//       num discPriceB = b.discPrice ?? 0;
//
//       double discountA = (priceA > 0 && discPriceA > 0)
//           ? ((priceA - discPriceA) / priceA) * 100
//           : 0;
//       double discountB = (priceB > 0 && discPriceB > 0)
//           ? ((priceB - discPriceB) / priceB) * 100
//           : 0;
//
//       return discountB.compareTo(discountA); // Sort in descending order
//     });
//     return top_s_p_list;
//   }
//
//   topSelllingCategoriesWidgets(List<TopSelling> top_s_p_list,
//       List<CartItemData> cartItems, bool isloading, Function(bool) onItemClicked,) {
//     if (!isloading) {
//       return Image.asset("assets/images/product_not_found.png");
//     }
//
//     // Sort the product list by highest discount first
//     top_s_p_list = sortByDiscount(top_s_p_list);
//     return Container(
//       width: Get.width,
//       height: 235,
//       child: GridView.builder(
//         shrinkWrap: true,
//         scrollDirection: Axis.horizontal,
//         physics: BouncingScrollPhysics(),
//         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 1, // Height of each item (adjust as needed)
//           mainAxisExtent:
//               140, // Width of each item (adjust to show 2 items per screen width)
//           mainAxisSpacing: 12,
//           crossAxisSpacing: 12,
//         ),
//         itemCount: top_s_p_list.length,
//         itemBuilder: (context, index) {
//           num price = top_s_p_list[index].price ?? 0;
//           num discPrice = top_s_p_list[index].discPrice ?? 0;
//           bool isInCart = false;
//
//           // Add a stateful quantity variable
//           return StatefulBuilder(builder: (context, setState) {
//             // Calculate discount percentage
//             int discountPercentageInt = 0;
//             if (price > 0 && discPrice > 0) {
//               double discountPercentage = ((price - discPrice) / price) * 100;
//               discountPercentageInt = discountPercentage.toInt();
//             }
//
//             return Container(
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(8),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.grey.withOpacity(0.15),
//                     spreadRadius: 1,
//                     blurRadius: 3,
//                     offset: Offset(0, 1),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Product Image with Discount Badge
//                   Stack(
//                     children: [
//                       // Product Image Container
//                       InkWell(
//                         onTap: () async {
//                           Future.delayed(Duration.zero, () {
//                              Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => AddToCartScreen(
//                                   image: top_s_p_list[index].image,
//                                   slug: top_s_p_list[index].slug,
//                                   qty: top_s_p_list[index]!.cartItem =
//                                   (top_s_p_list[index]!.cartItem ?? 0),
//                                 ),
//                               ),
//                             ).then((onValue) {
//                               onItemClicked(true);
//                             });
//                           });
//
//
//
//                         },
//                         child: ClipRRect(
//                           borderRadius: BorderRadius.only(
//                             topLeft: Radius.circular(8),
//                             topRight: Radius.circular(8),
//                           ),
//                           child: Container(
//                             height: 116,
//                             child: Center(
//                               child: Image.network(
//                                 top_s_p_list[index].images?.isNotEmpty == true
//                                     ? top_s_p_list[index].images![0]
//                                     : '',
//                                 fit: BoxFit.cover,
//                                 errorBuilder: (context, error, stackTrace) {
//                                   return Container(
//                                     color: Colors.grey[100],
//                                     child: Center(
//                                       child: Padding(
//                                         padding: const EdgeInsets.all(28.0),
//                                         child:
//                                             Image.asset("assets/logo/groticapp.png"),
//                                       ),
//                                     ),
//                                   );
//                                 },
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//
//                       // Discount Badge
//                       if (discountPercentageInt > 0)
//                         Positioned(
//                           top: 8,
//                           left: 8,
//                           child: Container(
//                             padding: EdgeInsets.symmetric(
//                                 horizontal: 6, vertical: 2),
//                             decoration: BoxDecoration(
//                               color: Colors.red[700],
//                               borderRadius: BorderRadius.circular(4),
//                             ),
//                             child: Text(
//                               "$discountPercentageInt% OFF",
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 9,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ),
//
//                       Positioned(
//                           top: -1,
//                           right: -8,
//                           child: Container(
//                             width: 50,
//                             height: 50,
//                             padding: EdgeInsets.symmetric(
//                                 horizontal: 6, vertical: 2),
//                             // decoration: BoxDecoration(
//                             //   color: Colors.red[700],
//                             //   borderRadius: BorderRadius.circular(4),
//                             // ),
//                             child: Image.asset("assets/images/grateDile-removebg-preview.png"),
//                           ),
//                         ),
//                     ],
//                   ),
//
//                   // Product Details
//                   Padding(
//                     padding:
//                         const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Product Title
//                         Text(
//                           top_s_p_list[index].title ?? "No Title",
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis,
//                           style: TextStyle(
//                             fontSize: 12,
//                             height: 1.2,
//                             fontWeight: FontWeight.w500,
//                             color: Colors.grey[800],
//                           ),
//                         ),
//
//                         SizedBox(height: 4),
//
//                         // Pricing Section with Professional Layout
//                         Row(
//                           children: [
//                             // Discount Price (Main Price)
//                             Text(
//                               "₹${discPrice.toStringAsFixed(0)}",
//                               style: TextStyle(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.black87,
//                               ),
//                             ),
//                             SizedBox(width: 5),
//                             // Original Price
//                             if (price > 0 && price != discPrice)
//                               Text(
//                                 "₹${price.toStringAsFixed(0)}",
//                                 style: TextStyle(
//                                   fontSize: 11,
//                                   color: Colors.grey[600],
//                                   decoration: TextDecoration.lineThrough,
//                                   decorationThickness: 1.5,
//                                 ),
//                               ),
//                             Spacer(),
//                             if (price > 0 && price != discPrice)
//                               Text(
//                                 "Save ₹${(price - discPrice).toStringAsFixed(0)}",
//                                 style: TextStyle(
//                                   fontSize: 10,
//                                   color: Colors.green[700],
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                           ],
//                         ),
//                         SizedBox(height: 5),
//
//                         // Savings text
//                       ],
//                     ),
//                   ),
//
//                   Spacer(),
//
//                   // Add to Cart Button with Quantity Controls
//                   if(top_s_p_list[index].stock!=null && top_s_p_list[index].stock! >0)
//                   Padding(
//                     padding:
//                         const EdgeInsets.only(left: 8, right: 8, bottom: 8),
//                     child: top_s_p_list[index].cartItem! > 0
//                         ? Container(
//                             height: 28,
//                             width: double.infinity,
//                             decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(6),
//                               color: Colors.teal,
//                             ),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               crossAxisAlignment: CrossAxisAlignment.center,
//                               children: [
//                                 const SizedBox(width: 5),
//                                 InkWell(
//                                   onTap: () async {
//                                     top_s_p_list[index]!.cartItem = (top_s_p_list[index]!.cartItem ?? 0) - 1;
//
//                                     if (top_s_p_list[index]!.cartItem! <= 0) {
//                                       top_s_p_list[index]!.cartItem = 0;
//
//                                       await CartStorage.removeFromCart(top_s_p_list[index]!.product_id!);
//
//                                       await cartCtrl.getCartList(context);
//
//                                       // setState(() {
//                                       //   top_s_p_list.removeAt(index);
//                                       // });
//                                       setState(() {});
//
//                                       return;
//                                     }
//
//                                     await cartCtrl.addToCartLocal(
//                                       context,
//                                       top_s_p_list[index].product_id!,
//                                       top_s_p_list[index].image,
//                                       top_s_p_list[index].title,
//                                       top_s_p_list[index].price,
//                                       top_s_p_list[index].discPrice,
//                                       top_s_p_list[index].cartItem!,
//                                       top_s_p_list[index].stock!,
//                                     );
//
//                                     onItemClicked(true);
//                                     setState(() {});
//                                   },
//
//                                   child: const Text(
//                                     "−",
//                                     style: TextStyle(
//                                         fontSize: 21,
//                                         color: Colors.white,
//                                         fontWeight: FontWeight.bold),
//                                   ),
//                                 ),
//                                 const SizedBox(width: 5),
//                                 Obx(() {
//                                   final productId =
//                                       top_s_p_list[index].product_id.toString();
//                                   final cartItem =
//                                       cartCtrl.cartList.firstWhereOrNull(
//                                     (item) => item.productId == productId,
//                                   );
//
//                                   final qty = cartItem?.qty ?? 1;
//
//                                   return Text(
//                                     "${top_s_p_list[index].cartItem}",
//                                     style: const TextStyle(
//                                         fontSize: 18,
//                                         color: Colors.white,
//                                         fontWeight: FontWeight.w500),
//                                   );
//                                 }),
//                                 const SizedBox(width: 5),
//                                 InkWell(
//                                   onTap: () async {
//                                     // final productId = top_s_p_list[index].product_id.toString();
//                                     // final cartItem = cartCtrl.cartList.firstWhereOrNull(
//                                     //       (item) => item.productId == productId,
//                                     // );
//                                     //
//                                     // int.parse(cartCtrl.cartList[index]!.totalProduct!.toString());
//                                     // cartCtrl.prodectQty.value = cartItem!.totalProduct! + 1;_
//                                     if ((top_s_p_list[index]!.cartItem ?? 0) < 5 && (top_s_p_list[index]!.cartItem ?? 0) < top_s_p_list[index].stock!) {
//                                       top_s_p_list[index]!.cartItem =
//                                           (top_s_p_list[index]!.cartItem ?? 0) +
//                                               1;
//                                       await cartCtrl.addToCartLocal(context, top_s_p_list[index].product_id!, top_s_p_list[index].image,
//                                           top_s_p_list[index].title, top_s_p_list[index].price, top_s_p_list[index].discPrice,
//                                           (top_s_p_list[index].cartItem!), (top_s_p_list[index].stock!));
//                                       onItemClicked(true);
//                                       //
//                                     } else {
//                                       AppToast.showToast(msg: "You added maximum.");
//                                     }
//
//                                     // await cartCtrl.addToCartLocal(context, top_s_p_list[index].product_id!, top_s_p_list[index].image, top_s_p_list[index].title, top_s_p_list[index].price, top_s_p_list[index].discPrice, (top_s_p_list[index].cartItem!));
//                                     // onItemClicked(true);
//                                     //
//                                     // cartCtrl.addToCart(
//                                     //   context,
//                                     //   top_s_p_list[index].product_id!,
//                                     //   qty: top_s_p_list[index]!
//                                     //       .cartItem!
//                                     //       .toString(),
//                                     // );
//                                   },
//                                   child: const Text(
//                                     "+",
//                                     style: TextStyle(
//                                         fontSize: 24,
//                                         color: Colors.white,
//                                         fontWeight: FontWeight.bold),
//                                   ),
//                                 ),
//                                 const SizedBox(width: 5),
//                               ],
//                             ),
//                           )
//                         : InkWell(
//                             onTap: () async {
//                               // SharedPreferences.getInstance().then((value) {
//                               //   isLogin = value.getBool(
//                               //           AppSharedPreferences.isLogin) ??
//                               //       false;
//                               //
//                               //   if (isLogin) {
//                               //
//                               //   } else {
//                               //     Get.to(LoginScreen());
//                               //   }
//                               // });
//
//                               top_s_p_list[index].cartItem =
//                                   top_s_p_list[index].cartItem! + 1;
//                               // cartCtrl.addToCart(
//                               //   context,
//                               //   top_s_p_list[index].product_id.toString(),
//                               //   qty: "1",
//                               // );
//                               await cartCtrl.addToCartLocal(context, top_s_p_list[index].product_id!,
//                                   top_s_p_list[index].image, top_s_p_list[index].title,
//                                   top_s_p_list[index].price, top_s_p_list[index].discPrice,
//                                   (top_s_p_list[index].cartItem!), (top_s_p_list[index].stock!));
//                               onItemClicked(true);
//
//                               // setState(() {
//                                 isInCart = true;
//                               // });
//
//                             },
//                             child: Container(
//                               height: 28,
//                               width: double.infinity,
//                               decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.circular(6),
//                                 color: Colors.red,
//                               ),
//                               child: Center(
//                                 child: Row(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: const [
//                                     Icon(
//                                       Icons.shopping_cart_outlined,
//                                       color: Colors.white,
//                                       size: 14,
//                                     ),
//                                     SizedBox(width: 4),
//                                     Text(
//                                       "Add to cart",
//                                       style: TextStyle(
//                                         fontSize: 12,
//                                         fontWeight: FontWeight.w600,
//                                         color: Colors.white,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ),
//                   ),
//                   if(top_s_p_list[index].stock! <= 0 || top_s_p_list[index].stock==null)
//                   Padding(
//                     padding: const EdgeInsets.only(bottom: 1, top: 1, left: 16, right: 16),
//                     child:  InkWell(
//                       onTap: () async {
//                         // Add first item to cart
//                         // setState(() {
//                         //   productCtrl.quntity.value = 1;
//                         // });
//                         // await cartCtrl.addToCartLocal(
//                         //   context,
//                         //   productCtrl.product_id.value.toString(),
//                         //   productCtrl.banner.value[0],
//                         //   productCtrl.title.value.toString(),
//                         //   productCtrl.price.value.toString(),
//                         //   productCtrl.disc_price.value.toString(),
//                         //   productCtrl.quntity.value,
//                         // );
//                       },
//                      child: Container(
//                         height: 28,
//                         width: double.infinity,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(6),
//                           color: Colors.red[100],
//                         ),
//                         child: Center(
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: const [
//                               // Icon(
//                               //   Icons.shopping_cart_outlined,
//                               //   color: Colors.white,
//                               //   size: 14,
//                               // ),
//                               // SizedBox(width: 4),
//                               Text(
//                                 "Out of Stock",
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w600,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       // child: Container(
//                       //   height: 50,
//                       //   width: double.infinity,
//                       //   decoration: BoxDecoration(
//                       //     borderRadius: BorderRadius.circular(8),
//                       //     color: Colors.red[100],
//                       //   ),
//                       //   child: const Center(
//                       //     child: Row(
//                       //       mainAxisAlignment: MainAxisAlignment.center,
//                       //       children: [
//                       //         // Icon(
//                       //         //   Icons.shopping_cart_outlined,
//                       //         //   color: Colors.white,
//                       //         //   size: 20,
//                       //         // ),
//                       //         SizedBox(width: 8),
//                       //         Text(
//                       //           "Out of Stock",
//                       //           style: TextStyle(
//                       //             fontSize: 16,
//                       //             fontWeight: FontWeight.w600,
//                       //             color: Colors.white,
//                       //           ),
//                       //         ),
//                       //       ],
//                       //     ),
//                       //   ),
//                       // ),
//                     ),
//                   ),
//
//                 ],
//               ),
//             );
//           });
//         },
//       ),
//     );
//   }
//
//   buy1GetOneCategoriesWidgets(List<TopSelling> top_s_p_list,
//       List<CartItemData> cartItems, bool isloading, Function(bool) onItemClicked,)
//   {
//     if (!isloading) {
//       return Image.asset("assets/images/product_not_found.png");
//     }
//
//     // Sort the product list by highest discount first
//     top_s_p_list = sortByDiscount(top_s_p_list);
//
//     // Sort to move out of stock items to the end
//     top_s_p_list.sort((a, b) {
//       bool aOutOfStock = (a.stock == null || a.stock == 0);
//       bool bOutOfStock = (b.stock == null || b.stock == 0);
//
//       // If both are out of stock or both are in stock, maintain current order
//       if (aOutOfStock == bOutOfStock) return 0;
//
//       // Move out of stock items to the end
//       if (aOutOfStock) return 1;
//       if (bOutOfStock) return -1;
//
//       return 0;
//     });
//
//     return Container(
//       width: Get.width,
//       height: 235,
//       child: GridView.builder(
//         shrinkWrap: true,
//         scrollDirection: Axis.horizontal,
//         physics: BouncingScrollPhysics(),
//         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 1,
//           mainAxisExtent: 140,
//           mainAxisSpacing: 12,
//           crossAxisSpacing: 12,
//         ),
//         itemCount: min(7, top_s_p_list.length),
//         itemBuilder: (context, index) {
//           num price = top_s_p_list[index].price ?? 0;
//           num discPrice = top_s_p_list[index].discPrice ?? 0;
//           bool isInCart = false;
//
//           return StatefulBuilder(builder: (context, setState) {
//             // Calculate discount percentage
//             int discountPercentageInt = 0;
//             if (price > 0 && discPrice > 0) {
//               double discountPercentage = ((price - discPrice) / price) * 100;
//               discountPercentageInt = discountPercentage.toInt();
//             }
//
//             return Container(
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(8),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.grey.withOpacity(0.15),
//                     spreadRadius: 1,
//                     blurRadius: 3,
//                     offset: Offset(0, 1),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Product Image with Discount Badge
//                   Stack(
//                     children: [
//                       // Product Image Container
//                       InkWell(
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => AddToCartScreen(
//                                 image: top_s_p_list[index].image,
//                                 slug: top_s_p_list[index].slug,
//                                 qty: top_s_p_list[index]!.cartItem =
//                                 (top_s_p_list[index]!.cartItem ?? 0),
//                               ),
//                             ),
//                           ).then((onValue){
//                             onItemClicked(true);
//                           });
//                         },
//                         child: ClipRRect(
//                           borderRadius: BorderRadius.only(
//                             topLeft: Radius.circular(8),
//                             topRight: Radius.circular(8),
//                           ),
//                           child: Container(
//                             height: 116,
//                             child: Center(
//                               child: Image.network(
//                                 top_s_p_list[index].images?.isNotEmpty == true
//                                     ? top_s_p_list[index].images![0]
//                                     : '',
//                                 fit: BoxFit.cover,
//                                 errorBuilder: (context, error, stackTrace) {
//                                   return Container(
//                                     color: Colors.grey[100],
//                                     child: Center(
//                                       child: Padding(
//                                         padding: const EdgeInsets.all(28.0),
//                                         child:
//                                         Image.asset("assets/logo/groticapp.png"),
//                                       ),
//                                     ),
//                                   );
//                                 },
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//
//                       // Discount Badge
//                       if (discountPercentageInt > 0)
//                         Positioned(
//                           top: 8,
//                           left: 8,
//                           child: Container(
//                             padding: EdgeInsets.symmetric(
//                                 horizontal: 6, vertical: 2),
//                             decoration: BoxDecoration(
//                               color: Colors.red[700],
//                               borderRadius: BorderRadius.circular(4),
//                             ),
//                             child: Text(
//                               "$discountPercentageInt% OFF",
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 9,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ),
//
//                       Positioned(
//                         top: -5,
//                         right: -8,
//                         child: Container(
//                           width: 50,
//                           height: 50,
//                           padding: EdgeInsets.symmetric(
//                               horizontal: 6, vertical: 2),
//                           child: Image.asset("assets/images/buyoffer.png"),
//                         ),
//                       ),
//                     ],
//                   ),
//
//                   // Product Details
//                   Padding(
//                     padding:
//                     const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Product Title
//                         Text(
//                           top_s_p_list[index].title ?? "No Title",
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis,
//                           style: TextStyle(
//                             fontSize: 12,
//                             height: 1.2,
//                             fontWeight: FontWeight.w500,
//                             color: Colors.grey[800],
//                           ),
//                         ),
//
//                         SizedBox(height: 4),
//
//                         // Pricing Section with Professional Layout
//                         Row(
//                           children: [
//                             // Discount Price (Main Price)
//                             Text(
//                               "₹${discPrice.toStringAsFixed(0)}",
//                               style: TextStyle(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.black87,
//                               ),
//                             ),
//                             SizedBox(width: 5),
//                             // Original Price
//                             if (price > 0 && price != discPrice)
//                               Text(
//                                 "₹${price.toStringAsFixed(0)}",
//                                 style: TextStyle(
//                                   fontSize: 11,
//                                   color: Colors.grey[600],
//                                   decoration: TextDecoration.lineThrough,
//                                   decorationThickness: 1.5,
//                                 ),
//                               ),
//                             Spacer(),
//                             if (price > 0 && price != discPrice)
//                               Text(
//                                 "Save ₹${(price - discPrice).toStringAsFixed(0)}",
//                                 style: TextStyle(
//                                   fontSize: 10,
//                                   color: Colors.green[700],
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                           ],
//                         ),
//                         SizedBox(height: 5),
//                       ],
//                     ),
//                   ),
//
//                   Spacer(),
//
//                   // Add to Cart Button with Quantity Controls
//
//                     if(top_s_p_list[index].stock!=null && top_s_p_list[index].stock! >0)
//                     Padding(
//                       padding:
//                       const EdgeInsets.only(left: 8, right: 8, bottom: 8),
//                       child: top_s_p_list[index].cartItem! > 0
//                           ? Container(
//                         height: 28,
//                         width: double.infinity,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(6),
//                           color: Colors.teal,
//                         ),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           crossAxisAlignment: CrossAxisAlignment.center,
//                           children: [
//                             const SizedBox(width: 5),
//                             InkWell(
//                               onTap: () async {
//                                 top_s_p_list[index]!.cartItem = (top_s_p_list[index]!.cartItem ?? 0) - 1;
//
//                                 // ✅ FIX: Check if quantity is 0 or less, then REMOVE from cart
//                                 if (top_s_p_list[index]!.cartItem! <= 0) {
//                                   top_s_p_list[index]!.cartItem = 0;
//
//                                   // ✅ Remove from cart storage
//                                   await CartStorage.removeFromCart(top_s_p_list[index]!.product_id!);
//                                   await cartCtrl.getCartList(context);
//                                   onItemClicked(true);
//                                   setState(() {});
//                                   return;
//                                 }
//
//                                 // Only add to cart if quantity > 0
//                                 await cartCtrl.addToCartLocal(
//                                   context,
//                                   top_s_p_list[index].product_id!,
//                                   top_s_p_list[index].image,
//                                   top_s_p_list[index].title,
//                                   top_s_p_list[index].price,
//                                   top_s_p_list[index].discPrice,
//                                   top_s_p_list[index].cartItem!,
//                                   top_s_p_list[index].stock,
//                                 );
//                                 onItemClicked(true);
//                                 setState(() {});
//                               },
//                               child: const Text(
//                                 "−",
//                                 style: TextStyle(
//                                   fontSize: 21,
//                                   color: Colors.white,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                             // InkWell(
//                             //   onTap: () async {
//                             //     top_s_p_list[index]!.cartItem = (top_s_p_list[index]!.cartItem ?? 0) - 1;
//                             //     if (top_s_p_list[index]!.cartItem! >= 0) {
//                             //       await cartCtrl.addToCartLocal(context, top_s_p_list[index].product_id!,
//                             //           top_s_p_list[index].image, top_s_p_list[index].title,
//                             //           top_s_p_list[index].price, top_s_p_list[index].discPrice,
//                             //           (top_s_p_list[index].cartItem!),(top_s_p_list[index].stock),);
//                             //       onItemClicked(true);
//                             //     } else {
//                             //       top_s_p_list[index]!.cartItem = 0;
//                             //     }
//                             //   },
//                             //   child: const Text(
//                             //     "−",
//                             //     style: TextStyle(
//                             //         fontSize: 21,
//                             //         color: Colors.white,
//                             //         fontWeight: FontWeight.bold),
//                             //   ),
//                             // ),
//                             const SizedBox(width: 5),
//                             Obx(() {
//                               final productId =
//                               top_s_p_list[index].product_id.toString();
//                               final cartItem =
//                               cartCtrl.cartList.firstWhereOrNull(
//                                     (item) => item.productId == productId,
//                               );
//
//                               final qty = cartItem?.qty ?? 1;
//
//                               return Text(
//                                 "${top_s_p_list[index].cartItem}",
//                                 style: const TextStyle(
//                                     fontSize: 18,
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.w500),
//                               );
//                             }),
//                             const SizedBox(width: 5),
//                             InkWell(
//                               onTap: () async {
//             if ((top_s_p_list[index]!.cartItem ?? 0) < 2 && (top_s_p_list[index]!.cartItem ?? 0) < top_s_p_list[index]!.stock!) {
//             // if ((top_s_p_list[index]!.cartItem ?? 0) < 5) {
//                                   top_s_p_list[index]!.cartItem =
//                                       (top_s_p_list[index]!.cartItem ?? 0) +
//                                           1;
//                                   await cartCtrl.addToCartLocal(context,
//                                     top_s_p_list[index].product_id!,
//                                     top_s_p_list[index].image,
//                                       top_s_p_list[index].title,
//                                     top_s_p_list[index].price,
//                                     top_s_p_list[index].discPrice,
//                                       top_s_p_list[index].cartItem!,
//                                     top_s_p_list[index].stock,);
//                                   onItemClicked(true);
//
//                                 } else {
//                                   AppToast.showToast(msg: "You added maximum.");
//                                 }
//                               },
//                               child: const Text(
//                                 "+",
//                                 style: TextStyle(
//                                     fontSize: 24,
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.bold),
//                               ),
//                             ),
//                             const SizedBox(width: 5),
//                           ],
//                         ),
//                       )
//                           : InkWell(
//                         onTap: () async {
//                           top_s_p_list[index].cartItem =
//                               top_s_p_list[index].cartItem! + 1;
//                           await cartCtrl.addToCartLocal(context, top_s_p_list[index].product_id!,
//                               top_s_p_list[index].image, top_s_p_list[index].title,
//                               top_s_p_list[index].price, top_s_p_list[index].discPrice,
//                               (top_s_p_list[index].cartItem!), (top_s_p_list[index].stock!));
//                           onItemClicked(true);
//
//                           // setState(() {
//                             isInCart = true;
//                           // });
//                         },
//                         child: Container(
//                           height: 28,
//                           width: double.infinity,
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(6),
//                             color: Colors.red,
//                           ),
//                           child: Center(
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: const [
//                                 Icon(
//                                   Icons.shopping_cart_outlined,
//                                   color: Colors.white,
//                                   size: 14,
//                                 ),
//                                 SizedBox(width: 4),
//                                 Text(
//                                   "Add to cart",
//                                   style: TextStyle(
//                                     fontSize: 12,
//                                     fontWeight: FontWeight.w600,
//                                     color: Colors.white,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   if(top_s_p_list[index].stock! <= 0  || top_s_p_list[index].stock==null)
//                     Padding(
//                       padding: const EdgeInsets.only(bottom: 1, top: 1, left: 16, right: 16),
//                       child:  InkWell(
//                         onTap: () async {
//                           // Out of stock - no action
//                         },
//                         child: Container(
//                           height: 28,
//                           width: double.infinity,
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(6),
//                             color: Colors.red[100],
//                           ),
//                           child: Center(
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: const [
//                                 Text(
//                                   "Out of Stock",
//                                   style: TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.w600,
//                                     color: Colors.white,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             );
//           });
//         },
//       ),
//     );
//   }
//   // buy1GetOneCategoriesWidgets(List<TopSelling> top_s_p_list,
//   //     List<CartItemData> cartItems, bool isloading, Function(bool) onItemClicked,)
//   // {
//   //   if (!isloading) {
//   //     return Image.asset("assets/images/product_not_found.png");
//   //   }
//   //
//   //   // Sort the product list by highest discount first
//   //   top_s_p_list = sortByDiscount(top_s_p_list);
//   //   return Container(
//   //     width: Get.width,
//   //     height: 235,
//   //     child: GridView.builder(
//   //       shrinkWrap: true,
//   //       scrollDirection: Axis.horizontal,
//   //       physics: BouncingScrollPhysics(),
//   //       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//   //         crossAxisCount: 1, // Height of each item (adjust as needed)
//   //         mainAxisExtent:
//   //             140, // Width of each item (adjust to show 2 items per screen width)
//   //         mainAxisSpacing: 12,
//   //         crossAxisSpacing: 12,
//   //       ),
//   //       itemCount: min(7, top_s_p_list.length), // Limit to max 15 items
//   //       itemBuilder: (context, index) {
//   //         num price = top_s_p_list[index].price ?? 0;
//   //         num discPrice = top_s_p_list[index].discPrice ?? 0;
//   //         bool isInCart = false;
//   //
//   //         // Add a stateful quantity variable
//   //         return StatefulBuilder(builder: (context, setState) {
//   //           // Calculate discount percentage
//   //           int discountPercentageInt = 0;
//   //           if (price > 0 && discPrice > 0) {
//   //             double discountPercentage = ((price - discPrice) / price) * 100;
//   //             discountPercentageInt = discountPercentage.toInt();
//   //           }
//   //
//   //           return Container(
//   //             decoration: BoxDecoration(
//   //               color: Colors.white,
//   //               borderRadius: BorderRadius.circular(8),
//   //               boxShadow: [
//   //                 BoxShadow(
//   //                   color: Colors.grey.withOpacity(0.15),
//   //                   spreadRadius: 1,
//   //                   blurRadius: 3,
//   //                   offset: Offset(0, 1),
//   //                 ),
//   //               ],
//   //             ),
//   //             child: Column(
//   //               crossAxisAlignment: CrossAxisAlignment.start,
//   //               children: [
//   //                 // Product Image with Discount Badge
//   //                 Stack(
//   //                   children: [
//   //                     // Product Image Container
//   //                     InkWell(
//   //                       onTap: () {
//   //                         Navigator.push(
//   //                           context,
//   //                           MaterialPageRoute(
//   //                             builder: (context) => AddToCartScreen(
//   //                               image: top_s_p_list[index].image,
//   //                               slug: top_s_p_list[index].slug,
//   //                               qty: top_s_p_list[index]!.cartItem =
//   //                                   (top_s_p_list[index]!.cartItem ?? 0),
//   //                             ),
//   //                           ),
//   //                         ).then((onValue){
//   //                           onItemClicked(true);
//   //                         });
//   //                       },
//   //                       child: ClipRRect(
//   //                         borderRadius: BorderRadius.only(
//   //                           topLeft: Radius.circular(8),
//   //                           topRight: Radius.circular(8),
//   //                         ),
//   //                         child: Container(
//   //                           height: 116,
//   //                           child: Center(
//   //                             child: Image.network(
//   //                               top_s_p_list[index].images?.isNotEmpty == true
//   //                                   ? top_s_p_list[index].images![0]
//   //                                   : '',
//   //                               fit: BoxFit.cover,
//   //                               errorBuilder: (context, error, stackTrace) {
//   //                                 return Container(
//   //                                   color: Colors.grey[100],
//   //                                   child: Center(
//   //                                     child: Padding(
//   //                                       padding: const EdgeInsets.all(28.0),
//   //                                       child:
//   //                                           Image.asset("assets/logo/logo.png"),
//   //                                     ),
//   //                                   ),
//   //                                 );
//   //                               },
//   //                             ),
//   //                           ),
//   //                         ),
//   //                       ),
//   //                     ),
//   //                     // Positioned(
//   //                     //   top: 8,
//   //                     //   right: 8,
//   //                     //   child: Container(
//   //                     //     width: 50,
//   //                     //     height: 50,
//   //                     //     padding: EdgeInsets.symmetric(
//   //                     //         horizontal: 6, vertical: 2),
//   //                     //     // decoration: BoxDecoration(
//   //                     //     //   color: Colors.red[700],
//   //                     //     //   borderRadius: BorderRadius.circular(4),
//   //                     //     // ),
//   //                     //     child: Image.asset("assets/images/buyoffer.png"),
//   //                     //   ),
//   //                     // ),
//   //                     // Discount Badge
//   //                     if (discountPercentageInt > 0)
//   //                       Positioned(
//   //                         top: 8,
//   //                         left: 8,
//   //                         child: Container(
//   //                           padding: EdgeInsets.symmetric(
//   //                               horizontal: 6, vertical: 2),
//   //                           decoration: BoxDecoration(
//   //                             color: Colors.red[700],
//   //                             borderRadius: BorderRadius.circular(4),
//   //                           ),
//   //                           child: Text(
//   //                             "$discountPercentageInt% OFF",
//   //                             style: TextStyle(
//   //                               color: Colors.white,
//   //                               fontSize: 9,
//   //                               fontWeight: FontWeight.bold,
//   //                             ),
//   //                           ),
//   //                         ),
//   //                       ),
//   //
//   //                     Positioned(
//   //                         top: -5,
//   //                         right: -8,
//   //                         child: Container(
//   //                           width: 50,
//   //                           height: 50,
//   //                           padding: EdgeInsets.symmetric(
//   //                               horizontal: 6, vertical: 2),
//   //                           // decoration: BoxDecoration(
//   //                           //   color: Colors.red[700],
//   //                           //   borderRadius: BorderRadius.circular(4),
//   //                           // ),
//   //                           child: Image.asset("assets/images/buyoffer.png"),
//   //                         ),
//   //                       ),
//   //                   ],
//   //                 ),
//   //
//   //                 // Product Details
//   //                 Padding(
//   //                   padding:
//   //                       const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//   //                   child: Column(
//   //                     crossAxisAlignment: CrossAxisAlignment.start,
//   //                     children: [
//   //                       // Product Title
//   //                       Text(
//   //                         top_s_p_list[index].title ?? "No Title",
//   //                         maxLines: 2,
//   //                         overflow: TextOverflow.ellipsis,
//   //                         style: TextStyle(
//   //                           fontSize: 12,
//   //                           height: 1.2,
//   //                           fontWeight: FontWeight.w500,
//   //                           color: Colors.grey[800],
//   //                         ),
//   //                       ),
//   //
//   //                       SizedBox(height: 4),
//   //
//   //                       // Pricing Section with Professional Layout
//   //                       Row(
//   //                         children: [
//   //                           // Discount Price (Main Price)
//   //                           Text(
//   //                             "₹${discPrice.toStringAsFixed(0)}",
//   //                             style: TextStyle(
//   //                               fontSize: 14,
//   //                               fontWeight: FontWeight.bold,
//   //                               color: Colors.black87,
//   //                             ),
//   //                           ),
//   //                           SizedBox(width: 5),
//   //                           // Original Price
//   //                           if (price > 0 && price != discPrice)
//   //                             Text(
//   //                               "₹${price.toStringAsFixed(0)}",
//   //                               style: TextStyle(
//   //                                 fontSize: 11,
//   //                                 color: Colors.grey[600],
//   //                                 decoration: TextDecoration.lineThrough,
//   //                                 decorationThickness: 1.5,
//   //                               ),
//   //                             ),
//   //                           Spacer(),
//   //                           if (price > 0 && price != discPrice)
//   //                             Text(
//   //                               "Save ₹${(price - discPrice).toStringAsFixed(0)}",
//   //                               style: TextStyle(
//   //                                 fontSize: 10,
//   //                                 color: Colors.green[700],
//   //                                 fontWeight: FontWeight.w500,
//   //                               ),
//   //                             ),
//   //                         ],
//   //                       ),
//   //                       SizedBox(height: 5),
//   //
//   //                       // Savings text
//   //                     ],
//   //                   ),
//   //                 ),
//   //
//   //                 Spacer(),
//   //
//   //                 // Add to Cart Button with Quantity Controls
//   //                 if(top_s_p_list[index].stock!=null && top_s_p_list[index].stock! >0)
//   //                 Padding(
//   //                   padding:
//   //                       const EdgeInsets.only(left: 8, right: 8, bottom: 8),
//   //                   child: top_s_p_list[index].cartItem! > 0
//   //                       ? Container(
//   //                           height: 36,
//   //                           width: double.infinity,
//   //                           decoration: BoxDecoration(
//   //                             borderRadius: BorderRadius.circular(6),
//   //                             color: Colors.teal,
//   //                           ),
//   //                           child: Row(
//   //                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//   //                             crossAxisAlignment: CrossAxisAlignment.center,
//   //                             children: [
//   //                               const SizedBox(width: 5),
//   //                               InkWell(
//   //                                 onTap: () async {
//   //                                   top_s_p_list[index]!.cartItem =
//   //                                       (top_s_p_list[index]!.cartItem ?? 0) -
//   //                                           1;
//   //                                   if (top_s_p_list[index]!.cartItem! >= 0) {
//   //                                    await cartCtrl.addToCartLocal(context, top_s_p_list[index].product_id!,
//   //                                        top_s_p_list[index].image, top_s_p_list[index].title,
//   //                                        top_s_p_list[index].price, top_s_p_list[index].discPrice,
//   //                                        (top_s_p_list[index].cartItem!));
//   //                                    onItemClicked(true);
//   //                                     // cartCtrl.addToCart(
//   //                                     //   context,
//   //                                     //   top_s_p_list[index].product_id!,
//   //                                     //   qty: top_s_p_list[index]!
//   //                                     //       .cartItem!
//   //                                     //       .toString(),
//   //                                     // );
//   //                                   } else {
//   //                                     top_s_p_list[index]!.cartItem = 0;
//   //                                   }
//   //                                 },
//   //                                 child: const Text(
//   //                                   "−",
//   //                                   style: TextStyle(
//   //                                       fontSize: 21,
//   //                                       color: Colors.white,
//   //                                       fontWeight: FontWeight.bold),
//   //                                 ),
//   //                               ),
//   //                               const SizedBox(width: 5),
//   //                               Obx(() {
//   //                                 final productId =
//   //                                     top_s_p_list[index].product_id.toString();
//   //                                 final cartItem =
//   //                                     cartCtrl.cartList.firstWhereOrNull(
//   //                                   (item) => item.productId == productId,
//   //                                 );
//   //
//   //                                 final qty = cartItem?.qty ?? 1;
//   //
//   //                                 return Text(
//   //                                   "${top_s_p_list[index].cartItem}",
//   //                                   style: const TextStyle(
//   //                                       fontSize: 18,
//   //                                       color: Colors.white,
//   //                                       fontWeight: FontWeight.w500),
//   //                                 );
//   //                               }),
//   //                               const SizedBox(width: 5),
//   //                               InkWell(
//   //                                 onTap: () async {
//   //                                   // final productId = top_s_p_list[index].product_id.toString();
//   //                                   // final cartItem = cartCtrl.cartList.firstWhereOrNull(
//   //                                   //       (item) => item.productId == productId,
//   //                                   // );
//   //                                   //
//   //                                   // int.parse(cartCtrl.cartList[index]!.totalProduct!.toString());
//   //                                   // cartCtrl.prodectQty.value = cartItem!.totalProduct! + 1;_
//   //                                   if ((top_s_p_list[index]!.cartItem ?? 0) < 5) {
//   //                                     top_s_p_list[index]!.cartItem =
//   //                                         (top_s_p_list[index]!.cartItem ?? 0) +
//   //                                             1;
//   //                                     await cartCtrl.addToCartLocal(context, top_s_p_list[index].product_id!, top_s_p_list[index].image, top_s_p_list[index].title, top_s_p_list[index].price, top_s_p_list[index].discPrice, (top_s_p_list[index].cartItem!));
//   //                                     onItemClicked(true);
//   //                                     //
//   //                                   } else {
//   //                                     AppToast.showToast(msg: "You can add maximum 5 items");
//   //                                   }
//   //
//   //                                   // await cartCtrl.addToCartLocal(context, top_s_p_list[index].product_id!, top_s_p_list[index].image, top_s_p_list[index].title, top_s_p_list[index].price, top_s_p_list[index].discPrice, (top_s_p_list[index].cartItem!));
//   //                                   // onItemClicked(true);
//   //                                   //
//   //                                   // cartCtrl.addToCart(
//   //                                   //   context,
//   //                                   //   top_s_p_list[index].product_id!,
//   //                                   //   qty: top_s_p_list[index]!
//   //                                   //       .cartItem!
//   //                                   //       .toString(),
//   //                                   // );
//   //                                 },
//   //                                 child: const Text(
//   //                                   "+",
//   //                                   style: TextStyle(
//   //                                       fontSize: 24,
//   //                                       color: Colors.white,
//   //                                       fontWeight: FontWeight.bold),
//   //                                 ),
//   //                               ),
//   //                               const SizedBox(width: 5),
//   //                             ],
//   //                           ),
//   //                         )
//   //                       : InkWell(
//   //                           onTap: () async {
//   //                             // SharedPreferences.getInstance().then((value) {
//   //                             //   isLogin = value.getBool(
//   //                             //           AppSharedPreferences.isLogin) ??
//   //                             //       false;
//   //                             //
//   //                             //   if (isLogin) {
//   //                             //
//   //                             //   } else {
//   //                             //     Get.to(LoginScreen());
//   //                             //   }
//   //                             // });
//   //
//   //                             top_s_p_list[index].cartItem =
//   //                                 top_s_p_list[index].cartItem! + 1;
//   //                             // cartCtrl.addToCart(
//   //                             //   context,
//   //                             //   top_s_p_list[index].product_id.toString(),
//   //                             //   qty: "1",
//   //                             // );
//   //                             await cartCtrl.addToCartLocal(context, top_s_p_list[index].product_id!,
//   //                                 top_s_p_list[index].image, top_s_p_list[index].title,
//   //                                 top_s_p_list[index].price, top_s_p_list[index].discPrice, (top_s_p_list[index].cartItem!));
//   //                             onItemClicked(true);
//   //
//   //                             setState(() {
//   //                               isInCart = true;
//   //                             });
//   //
//   //                           },
//   //                           child: Container(
//   //                             height: 28,
//   //                             width: double.infinity,
//   //                             decoration: BoxDecoration(
//   //                               borderRadius: BorderRadius.circular(6),
//   //                               color: Colors.red,
//   //                             ),
//   //                             child: Center(
//   //                               child: Row(
//   //                                 mainAxisAlignment: MainAxisAlignment.center,
//   //                                 children: const [
//   //                                   Icon(
//   //                                     Icons.shopping_cart_outlined,
//   //                                     color: Colors.white,
//   //                                     size: 14,
//   //                                   ),
//   //                                   SizedBox(width: 4),
//   //                                   Text(
//   //                                     "Add to cart",
//   //                                     style: TextStyle(
//   //                                       fontSize: 12,
//   //                                       fontWeight: FontWeight.w600,
//   //                                       color: Colors.white,
//   //                                     ),
//   //                                   ),
//   //                                 ],
//   //                               ),
//   //                             ),
//   //                           ),
//   //                         ),
//   //                 ),
//   //                 if(top_s_p_list[index].stock==0 || top_s_p_list[index].stock==null)
//   //                 Padding(
//   //                   padding: const EdgeInsets.only(bottom: 10, top: 11, left: 16, right: 16),
//   //                   child:  InkWell(
//   //                     onTap: () async {
//   //                       // Add first item to cart
//   //                       // setState(() {
//   //                       //   productCtrl.quntity.value = 1;
//   //                       // });
//   //                       // await cartCtrl.addToCartLocal(
//   //                       //   context,
//   //                       //   productCtrl.product_id.value.toString(),
//   //                       //   productCtrl.banner.value[0],
//   //                       //   productCtrl.title.value.toString(),
//   //                       //   productCtrl.price.value.toString(),
//   //                       //   productCtrl.disc_price.value.toString(),
//   //                       //   productCtrl.quntity.value,
//   //                       // );
//   //                     },
//   //                    child: Container(
//   //                       height: 28,
//   //                       width: double.infinity,
//   //                       decoration: BoxDecoration(
//   //                         borderRadius: BorderRadius.circular(6),
//   //                         color: Colors.red[100],
//   //                       ),
//   //                       child: Center(
//   //                         child: Row(
//   //                           mainAxisAlignment: MainAxisAlignment.center,
//   //                           children: const [
//   //                             // Icon(
//   //                             //   Icons.shopping_cart_outlined,
//   //                             //   color: Colors.white,
//   //                             //   size: 14,
//   //                             // ),
//   //                             // SizedBox(width: 4),
//   //                             Text(
//   //                               "Out of Stock",
//   //                               style: TextStyle(
//   //                                 fontSize: 16,
//   //                                 fontWeight: FontWeight.w600,
//   //                                 color: Colors.white,
//   //                               ),
//   //                             ),
//   //                           ],
//   //                         ),
//   //                       ),
//   //                     ),
//   //                     // child: Container(
//   //                     //   height: 50,
//   //                     //   width: double.infinity,
//   //                     //   decoration: BoxDecoration(
//   //                     //     borderRadius: BorderRadius.circular(8),
//   //                     //     color: Colors.red[100],
//   //                     //   ),
//   //                     //   child: const Center(
//   //                     //     child: Row(
//   //                     //       mainAxisAlignment: MainAxisAlignment.center,
//   //                     //       children: [
//   //                     //         // Icon(
//   //                     //         //   Icons.shopping_cart_outlined,
//   //                     //         //   color: Colors.white,
//   //                     //         //   size: 20,
//   //                     //         // ),
//   //                     //         SizedBox(width: 8),
//   //                     //         Text(
//   //                     //           "Out of Stock",
//   //                     //           style: TextStyle(
//   //                     //             fontSize: 16,
//   //                     //             fontWeight: FontWeight.w600,
//   //                     //             color: Colors.white,
//   //                     //           ),
//   //                     //         ),
//   //                     //       ],
//   //                     //     ),
//   //                     //   ),
//   //                     // ),
//   //                   ),
//   //                 ),
//   //
//   //               ],
//   //             ),
//   //           );
//   //         });
//   //       },
//   //     ),
//   //   );
//   // }
//
//
//   buy1Get1CategoriesWidgets(List<Buy1Get1> top_s_p_list,
//       List<CartItemData> cartItems, bool isloading, Function(bool) onItemClicked,)
//   {
//     if (!isloading) {
//       return Image.asset("assets/images/product_not_found.png");
//     }
//
//     // Sort the product list by highest discount first
//     top_s_p_list = buy1Get1Discount(top_s_p_list);
//     return Container(
//       width: Get.width,
//       height: 235,
//       child: GridView.builder(
//         shrinkWrap: true,
//         scrollDirection: Axis.horizontal,
//         physics: BouncingScrollPhysics(),
//         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 1, // Height of each item (adjust as needed)
//           mainAxisExtent:
//               140, // Width of each item (adjust to show 2 items per screen width)
//           mainAxisSpacing: 12,
//           crossAxisSpacing: 12,
//         ),
//         itemCount: top_s_p_list.length,
//         itemBuilder: (context, index) {
//           num price = top_s_p_list[index].price ?? 0;
//           num discPrice = top_s_p_list[index].discPrice ?? 0;
//           bool isInCart = false;
//
//           // Add a stateful quantity variable
//           return StatefulBuilder(builder: (context, setState) {
//             // Calculate discount percentage
//             int discountPercentageInt = 0;
//             if (price > 0 && discPrice > 0) {
//               double discountPercentage = ((price - discPrice) / price) * 100;
//               discountPercentageInt = discountPercentage.toInt();
//             }
//
//             return Container(
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(8),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.grey.withOpacity(0.15),
//                     spreadRadius: 1,
//                     blurRadius: 3,
//                     offset: Offset(0, 1),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Product Image with Discount Badge
//                   Stack(
//                     children: [
//                       // Product Image Container
//                       InkWell(
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => AddToCartScreen(
//                                 image: top_s_p_list[index].image,
//                                 slug: top_s_p_list[index].slug,
//                                 qty:0,
//                               ),
//                             ),
//                           ).then((onValue){
//                             onItemClicked(true);
//                           });
//                         },
//                         child: ClipRRect(
//                           borderRadius: BorderRadius.only(
//                             topLeft: Radius.circular(8),
//                             topRight: Radius.circular(8),
//                           ),
//                           child: Container(
//                             height: 116,
//                             child: Center(
//                               child: Image.network(
//                                 top_s_p_list[index].images?.isNotEmpty == true
//                                     ? top_s_p_list[index].images![0]
//                                     : '',
//                                 fit: BoxFit.cover,
//                                 errorBuilder: (context, error, stackTrace) {
//                                   return Container(
//                                     color: Colors.grey[100],
//                                     child: Center(
//                                       child: Padding(
//                                         padding: const EdgeInsets.all(28.0),
//                                         child:
//                                             Image.asset("assets/logo/groticapp.png"),
//                                       ),
//                                     ),
//                                   );
//                                 },
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//
//                       // Discount Badge
//                       if (discountPercentageInt > 0)
//                         Positioned(
//                           top: 8,
//                           left: 8,
//                           child: Container(
//                             padding: EdgeInsets.symmetric(
//                                 horizontal: 6, vertical: 2),
//                             decoration: BoxDecoration(
//                               color: Colors.red[700],
//                               borderRadius: BorderRadius.circular(4),
//                             ),
//                             child: Text(
//                               "$discountPercentageInt% OFF",
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 9,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ),
//
//                       Positioned(
//                           top: 8,
//                           right: 8,
//                           child: Container(
//                             width: 50,
//                             height: 50,
//                             padding: EdgeInsets.symmetric(
//                                 horizontal: 6, vertical: 2),
//                             // decoration: BoxDecoration(
//                             //   color: Colors.red[700],
//                             //   borderRadius: BorderRadius.circular(4),
//                             // ),
//                             child: Image.asset("assets/images/buyoffer.png"),
//                           ),
//                         ),
//                     ],
//                   ),
//
//                   // Product Details
//                   Padding(
//                     padding:
//                         const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Product Title
//                         Text(
//                           top_s_p_list[index].title ?? "No Title",
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis,
//                           style: TextStyle(
//                             fontSize: 12,
//                             height: 1.2,
//                             fontWeight: FontWeight.w500,
//                             color: Colors.grey[800],
//                           ),
//                         ),
//
//                         SizedBox(height: 4),
//
//                         // Pricing Section with Professional Layout
//                         Row(
//                           children: [
//                             // Discount Price (Main Price)
//                             Text(
//                               "₹${discPrice.toStringAsFixed(0)}",
//                               style: TextStyle(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.black87,
//                               ),
//                             ),
//                             SizedBox(width: 5),
//                             // Original Price
//                             if (price > 0 && price != discPrice)
//                               Text(
//                                 "₹${price.toStringAsFixed(0)}",
//                                 style: TextStyle(
//                                   fontSize: 11,
//                                   color: Colors.grey[600],
//                                   decoration: TextDecoration.lineThrough,
//                                   decorationThickness: 1.5,
//                                 ),
//                               ),
//                             Spacer(),
//                             if (price > 0 && price != discPrice)
//                               Text(
//                                 "Save ₹${(price - discPrice).toStringAsFixed(0)}",
//                                 style: TextStyle(
//                                   fontSize: 10,
//                                   color: Colors.green[700],
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                           ],
//                         ),
//                         SizedBox(height: 5),
//
//                         // Savings text
//                       ],
//                     ),
//                   ),
//
//                   Spacer(),
//
//                   // Add to Cart Button with Quantity Controls
//                   // if(top_s_p_list[index].stock!=null && top_s_p_list[index].stock! >0)
//                   Padding(
//                     padding:
//                         const EdgeInsets.only(left: 8, right: 8, bottom: 8),
//                     child:
//                     // top_s_p_list[index].cartItem! > 0
//                     //     ?
//                     Container(
//                             height: 28,
//                             width: double.infinity,
//                             decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(6),
//                               color: Colors.teal,
//                             ),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               crossAxisAlignment: CrossAxisAlignment.center,
//                               children: [
//                                 const SizedBox(width: 5),
//                                 InkWell(
//                                   onTap: () async {
//                                     // top_s_p_list[index]!.cartItem =
//                                     //     (top_s_p_list[index]!.cartItem ?? 0) -
//                                     //         1;
//                                     // if (top_s_p_list[index]!.cartItem! >= 0) {
//                                     //  await cartCtrl.addToCartLocal(context, top_s_p_list[index].productId!,
//                                     //      top_s_p_list[index].image, top_s_p_list[index].title,
//                                     //      top_s_p_list[index].price, top_s_p_list[index].discPrice,
//                                     //  0);
//                                     //  onItemClicked(true);
//                                     //   // cartCtrl.addToCart(
//                                     //   //   context,
//                                     //   //   top_s_p_list[index].product_id!,
//                                     //   //   qty: top_s_p_list[index]!
//                                     //   //       .cartItem!
//                                     //   //       .toString(),
//                                     //   // );
//                                     // } else {
//                                     //   top_s_p_list[index]!.cartItem = 0;
//                                     // }
//                                   },
//                                   child: const Text(
//                                     "−",
//                                     style: TextStyle(
//                                         fontSize: 21,
//                                         color: Colors.white,
//                                         fontWeight: FontWeight.bold),
//                                   ),
//                                 ),
//                                 const SizedBox(width: 5),
//                                 Obx(() {
//                                   final productId =
//                                       top_s_p_list[index].productId.toString();
//                                   final cartItem =
//                                       cartCtrl.cartList.firstWhereOrNull(
//                                     (item) => item.productId == productId,
//                                   );
//
//                                   final qty = cartItem?.qty ?? 1;
//
//                                   return Text(
//                                     "${top_s_p_list[index]}",
//                                     style: const TextStyle(
//                                         fontSize: 18,
//                                         color: Colors.white,
//                                         fontWeight: FontWeight.w500),
//                                   );
//                                 }),
//                                 const SizedBox(width: 5),
//                                 InkWell(
//                                   onTap: () async {
//                                     // // final productId = top_s_p_list[index].product_id.toString();
//                                     // // final cartItem = cartCtrl.cartList.firstWhereOrNull(
//                                     // //       (item) => item.productId == productId,
//                                     // // );
//                                     // //
//                                     // // int.parse(cartCtrl.cartList[index]!.totalProduct!.toString());
//                                     // // cartCtrl.prodectQty.value = cartItem!.totalProduct! + 1;_
//                                     // if ((top_s_p_list[index]!.cartItem ?? 0) < 5) {
//                                     //   top_s_p_list[index]!.cartItem =
//                                     //       (top_s_p_list[index]!.cartItem ?? 0) +
//                                     //           1;
//                                     //   await cartCtrl.addToCartLocal(context, top_s_p_list[index].productId!, top_s_p_list[index].image, top_s_p_list[index].title, top_s_p_list[index].price, top_s_p_list[index].discPrice, (top_s_p_list[index].cartItem!));
//                                     //   onItemClicked(true);
//                                     //   //
//                                     // } else {
//                                     //   AppToast.showToast(msg: "You can add maximum 5 items");
//                                     // }
//                                     //
//                                     // // await cartCtrl.addToCartLocal(context, top_s_p_list[index].product_id!, top_s_p_list[index].image, top_s_p_list[index].title, top_s_p_list[index].price, top_s_p_list[index].discPrice, (top_s_p_list[index].cartItem!));
//                                     // // onItemClicked(true);
//                                     // //
//                                     // // cartCtrl.addToCart(
//                                     // //   context,
//                                     // //   top_s_p_list[index].product_id!,
//                                     // //   qty: top_s_p_list[index]!
//                                     // //       .cartItem!
//                                     // //       .toString(),
//                                     // // );
//                                   },
//                                   child: const Text(
//                                     "+",
//                                     style: TextStyle(
//                                         fontSize: 24,
//                                         color: Colors.white,
//                                         fontWeight: FontWeight.bold),
//                                   ),
//                                 ),
//                                 const SizedBox(width: 5),
//                               ],
//                             ),
//                           )
//                         // : InkWell(
//                         //     onTap: () async {
//                         //       // // SharedPreferences.getInstance().then((value) {
//                         //       // //   isLogin = value.getBool(
//                         //       // //           AppSharedPreferences.isLogin) ??
//                         //       // //       false;
//                         //       // //
//                         //       // //   if (isLogin) {
//                         //       // //
//                         //       // //   } else {
//                         //       // //     Get.to(LoginScreen());
//                         //       // //   }
//                         //       // // });
//                         //       //
//                         //       // top_s_p_list[index].cartItem =
//                         //       //     top_s_p_list[index].cartItem! + 1;
//                         //       // // cartCtrl.addToCart(
//                         //       // //   context,
//                         //       // //   top_s_p_list[index].product_id.toString(),
//                         //       // //   qty: "1",
//                         //       // // );
//                         //       // await cartCtrl.addToCartLocal(context, top_s_p_list[index].product_id!,
//                         //       //     top_s_p_list[index].image, top_s_p_list[index].title,
//                         //       //     top_s_p_list[index].price, top_s_p_list[index].discPrice, (top_s_p_list[index].cartItem!));
//                         //       // onItemClicked(true);
//                         //       //
//                         //       // setState(() {
//                         //       //   isInCart = true;
//                         //       // });
//                         //
//                         //     },
//                         //     child: Container(
//                         //       height: 28,
//                         //       width: double.infinity,
//                         //       decoration: BoxDecoration(
//                         //         borderRadius: BorderRadius.circular(6),
//                         //         color: Colors.red,
//                         //       ),
//                         //       child: Center(
//                         //         child: Row(
//                         //           mainAxisAlignment: MainAxisAlignment.center,
//                         //           children: const [
//                         //             Icon(
//                         //               Icons.shopping_cart_outlined,
//                         //               color: Colors.white,
//                         //               size: 14,
//                         //             ),
//                         //             SizedBox(width: 4),
//                         //             Text(
//                         //               "Add to cart",
//                         //               style: TextStyle(
//                         //                 fontSize: 12,
//                         //                 fontWeight: FontWeight.w600,
//                         //                 color: Colors.white,
//                         //               ),
//                         //             ),
//                         //           ],
//                         //         ),
//                         //       ),
//                         //     ),
//                         //   ),
//                   ),
//                   // if(top_s_p_list[index].stock==0 || top_s_p_list[index].stock==null)
//                   // Padding(
//                   //   padding: const EdgeInsets.only(bottom: 10, top: 11, left: 16, right: 16),
//                   //   child:  InkWell(
//                   //     onTap: () async {
//                   //       // Add first item to cart
//                   //       // setState(() {
//                   //       //   productCtrl.quntity.value = 1;
//                   //       // });
//                   //       // await cartCtrl.addToCartLocal(
//                   //       //   context,
//                   //       //   productCtrl.product_id.value.toString(),
//                   //       //   productCtrl.banner.value[0],
//                   //       //   productCtrl.title.value.toString(),
//                   //       //   productCtrl.price.value.toString(),
//                   //       //   productCtrl.disc_price.value.toString(),
//                   //       //   productCtrl.quntity.value,
//                   //       // );
//                   //     },
//                   //    child: Container(
//                   //       height: 28,
//                   //       width: double.infinity,
//                   //       decoration: BoxDecoration(
//                   //         borderRadius: BorderRadius.circular(6),
//                   //         color: Colors.red[100],
//                   //       ),
//                   //       child: Center(
//                   //         child: Row(
//                   //           mainAxisAlignment: MainAxisAlignment.center,
//                   //           children: const [
//                   //             // Icon(
//                   //             //   Icons.shopping_cart_outlined,
//                   //             //   color: Colors.white,
//                   //             //   size: 14,
//                   //             // ),
//                   //             // SizedBox(width: 4),
//                   //             Text(
//                   //               "Out of Stock",
//                   //               style: TextStyle(
//                   //                 fontSize: 16,
//                   //                 fontWeight: FontWeight.w600,
//                   //                 color: Colors.white,
//                   //               ),
//                   //             ),
//                   //           ],
//                   //         ),
//                   //       ),
//                   //     ),
//                   //     // child: Container(
//                   //     //   height: 50,
//                   //     //   width: double.infinity,
//                   //     //   decoration: BoxDecoration(
//                   //     //     borderRadius: BorderRadius.circular(8),
//                   //     //     color: Colors.red[100],
//                   //     //   ),
//                   //     //   child: const Center(
//                   //     //     child: Row(
//                   //     //       mainAxisAlignment: MainAxisAlignment.center,
//                   //     //       children: [
//                   //     //         // Icon(
//                   //     //         //   Icons.shopping_cart_outlined,
//                   //     //         //   color: Colors.white,
//                   //     //         //   size: 20,
//                   //     //         // ),
//                   //     //         SizedBox(width: 8),
//                   //     //         Text(
//                   //     //           "Out of Stock",
//                   //     //           style: TextStyle(
//                   //     //             fontSize: 16,
//                   //     //             fontWeight: FontWeight.w600,
//                   //     //             color: Colors.white,
//                   //     //           ),
//                   //     //         ),
//                   //     //       ],
//                   //     //     ),
//                   //     //   ),
//                   //     // ),
//                   //   ),
//                   // ),
//
//                 ],
//               ),
//             );
//           });
//         },
//       ),
//     );
//   }
//
//   topCategoriesWidget(List<TopSelling> top_s_p_list, List<CartItemData> cartItems, bool isloading, Function(String) onItemClicked,) {
//     if (!isloading) {
//       return Center(
//         child: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Image.asset("assets/images/product_not_found.png"),
//         ),
//       );
//     }
//
//     top_s_p_list = sortByDiscount(top_s_p_list);
//
//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.all(8),
//       child: GridView.builder(
//         shrinkWrap: true,
//         physics: NeverScrollableScrollPhysics(),
//         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 2,
//           childAspectRatio: 0.58, // Adjusted for more height
//           crossAxisSpacing: 8,
//           mainAxisSpacing: 8,
//         ),
//         itemCount: top_s_p_list.length,
//         itemBuilder: (context, index) {
//           final product = top_s_p_list[index];
//           num price = product.price ?? 0;
//           num discPrice = product.discPrice ?? 0;
//
//           int discountPercentageInt = 0;
//           if (price > 0 && discPrice > 0) {
//             double discountPercentage = ((price - discPrice) / price) * 100;
//             discountPercentageInt = discountPercentage.toInt();
//           }
//
//           return StatefulBuilder(
//             builder: (context, setState) {
//               return Container(
//                 key: ValueKey(product.product_id),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(8),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.grey.withOpacity(0.15),
//                       spreadRadius: 1,
//                       blurRadius: 3,
//                       offset: Offset(0, 1),
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Product Image - Fixed height instead of Expanded
//                     Stack(
//                       children: [
//                         InkWell(
//                           onTap: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => AddToCartScreen(
//                                   image: product.image,
//                                   slug: product.slug,
//                                   qty: product.cartItem ?? 0,
//                                 ),
//                               ),
//                             );
//                           },
//                           child: ClipRRect(
//                             borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
//                             child: Container(
//                               height: 100, // Fixed height
//                               width: double.infinity,
//                               child: Image.network(
//                                 product.images?.isNotEmpty == true ? product.images![0] : '',
//                                 fit: BoxFit.cover,
//                                 errorBuilder: (context, error, stackTrace) {
//                                   return Container(
//                                     color: Colors.grey[100],
//                                     child: Center(
//                                       child: Padding(
//                                         padding: const EdgeInsets.all(16.0),
//                                         child: Image.asset("assets/logo/groticapp.png"),
//                                       ),
//                                     ),
//                                   );
//                                 },
//                               ),
//                             ),
//                           ),
//                         ),
//                         if (discountPercentageInt > 0)
//                           Positioned(
//                             top: 4,
//                             left: 4,
//                             child: Container(
//                               padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
//                               decoration: BoxDecoration(
//                                 color: Colors.red[700],
//                                 borderRadius: BorderRadius.circular(4),
//                               ),
//                               child: Text(
//                                 "$discountPercentageInt% OFF",
//                                 style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
//                               ),
//                             ),
//                           ),
//                       ],
//                     ),
//
//                     // Product Details
//                     Expanded(
//                       child: Padding(
//                         padding: const EdgeInsets.all(6),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               product.title ?? "No Title",
//                               maxLines: 2,
//                               overflow: TextOverflow.ellipsis,
//                               style: TextStyle(fontSize: 11, height: 1.2, fontWeight: FontWeight.w500, color: Colors.grey[800]),
//                             ),
//                             SizedBox(height: 4),
//                             Wrap(
//                               spacing: 4,
//                               runSpacing: 2,
//                               crossAxisAlignment: WrapCrossAlignment.center,
//                               children: [
//                                 Container(
//                                   padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
//                                   decoration: BoxDecoration(color: Colors.green[700], borderRadius: BorderRadius.circular(3)),
//                                   child: Text("₹${discPrice.toStringAsFixed(0)}", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
//                                 ),
//                                 if (price > 0 && price != discPrice)
//                                   Text("₹${price.toStringAsFixed(0)}", style: TextStyle(fontSize: 9, color: Colors.red[600], fontWeight: FontWeight.w600, decoration: TextDecoration.lineThrough)),
//                               ],
//                             ),
//                             Spacer(),
//                             // Add to Cart Button - Remove Obx here, use setState instead
//                             if (product.stock != null && product.stock! > 0)...[
//                               buildCartButton(context, product, index, top_s_p_list, setState, onItemClicked)]
//                             else...[
//                               Container(
//                                 height: 28,
//                                 decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: Colors.grey[300]),
//                                 child: Center(child: Text("Out of Stock", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.red[700]))),
//                               ),
//                             ]
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
//
// // Separate method for cart button to avoid Obx issues
//   Widget buildCartButton(BuildContext context, TopSelling product, int index, List<TopSelling> list, StateSetter setState, Function(String) onItemClicked) {
//     int currentQty = product.cartItem ?? 0;
//
//     if (currentQty > 0) {
//       return Container(
//         height: 28,
//         decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: Colors.teal),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//           children: [
//             InkWell(
//               onTap: () async {
//                 product.cartItem = (product.cartItem ?? 0) - 1;
//                 if (product.cartItem! <= 0) {
//                   product.cartItem = 0;
//                   await CartStorage.removeFromCart(product.product_id!);
//                   await cartCtrl.getCartList(context);
//                 } else {
//                   String imageUrl = (product.images != null && product.images!.isNotEmpty)
//                       ? product.images![0]
//                       : (product.image ?? '');
//                   await cartCtrl.addToCartLocal(context, product.product_id!, imageUrl, product.title, product.price, product.discPrice, product.cartItem!, product.stock!);
//                 }
//                 onItemClicked(product.product_id!);
//                 setState(() {});
//               },
//               child: Padding(padding: EdgeInsets.all(4), child: Text("−", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold))),
//             ),
//             Text("${product.cartItem}", style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500)),
//             InkWell(
//               onTap: () async {
//                 if ((product.cartItem ?? 0) < 5 && (product.cartItem ?? 0) < product.stock!) {
//                   product.cartItem = (product.cartItem ?? 0) + 1;
//                   String imageUrl = (product.images != null && product.images!.isNotEmpty)
//                       ? product.images![0]
//                       : (product.image ?? '');
//                   PrintLog.printLog("1========>>>>>>>>>>>>>>>>>>>>> Item Stock:${product.stock}, Image: ${imageUrl}");
//                   await cartCtrl.addToCartLocal(context, product.product_id!, imageUrl, product.title, product.price, product.discPrice, product.cartItem!, product.stock!);
//                   onItemClicked(product.product_id!);
//                   setState(() {});
//                 } else {
//                   AppToast.showToast(msg: "You added maximum.");
//                 }
//                 if(product.stock == 0 || product.stock == null){
//                   AppToast.showToast(msg: "Out of Stock",);
//                 }
//               },
//               child: Padding(padding: EdgeInsets.all(4), child: Text("+", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold))),
//             ),
//           ],
//         ),
//       );
//     } else {
//       return InkWell(
//         onTap: () async {
//           if(product.stock == 0 || product.stock == null){
//             AppToast.showToast(msg: "Out of Stock",);
//           }
//           product.cartItem = (product.cartItem ?? 0) + 1;
//           String imageUrl = (product.images != null && product.images!.isNotEmpty)
//               ? product.images![0]
//               : (product.image ?? '');
//           PrintLog.printLog("2========>>>>>>>>>>>>>>>>>>>>> Item Stock:${product.stock}, Image: ${imageUrl}");
//           await cartCtrl.addToCartLocal(context, product.product_id!, /*product.images![0]*/imageUrl, product.title, product.price, product.discPrice, product.cartItem!, product.stock!);
//           onItemClicked(product.product_id!);
//           setState(() {});
//         },
//         child: Container(
//           height: 28,
//           decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: Colors.red),
//           child: Center(child: Text("Add to cart", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white))),
//         ),
//       );
//     }
//   }
//
//   // topCategoriesWidget(List<TopSelling> top_s_p_list, List<CartItemData> cartItems, bool isloading, Function(String) onItemClicked,){
//   //   if (!isloading) {
//   //     return Center(
//   //       child: Padding(
//   //         padding: const EdgeInsets.all(20.0),
//   //         child: Image.asset("assets/images/product_not_found.png"),
//   //       ),
//   //     );
//   //   }
//   //
//   //   // Sort the product list by highest discount first
//   //   top_s_p_list = sortByDiscount(top_s_p_list);
//   //
//   //   // Sort to move out of stock items to the end
//   //   top_s_p_list.sort((a, b) {
//   //     bool aOutOfStock = (a.stock == null || a.stock == 0);
//   //     bool bOutOfStock = (b.stock == null || b.stock == 0);
//   //     if (aOutOfStock == bOutOfStock) return 0;
//   //     if (aOutOfStock) return 1;
//   //     if (bOutOfStock) return -1;
//   //     return 0;
//   //   });
//   //
//   //   return Container(
//   //     width: double.infinity,
//   //     padding: EdgeInsets.all(8),
//   //     child: GridView.builder(
//   //       shrinkWrap: true,
//   //       physics: NeverScrollableScrollPhysics(),
//   //       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//   //         crossAxisCount: 2,
//   //         childAspectRatio: 0.65,
//   //         crossAxisSpacing: 8,
//   //         mainAxisSpacing: 8,
//   //       ),
//   //       itemCount: top_s_p_list.length,
//   //       itemBuilder: (context, index) {
//   //         final product = top_s_p_list[index];
//   //         num price = product.price ?? 0;
//   //         num discPrice = product.discPrice ?? 0;
//   //
//   //         // ✅ StatefulBuilder ko hataya, ab simple build hoga
//   //         int discountPercentageInt = 0;
//   //         if (price > 0 && discPrice > 0) {
//   //           double discountPercentage = ((price - discPrice) / price) * 100;
//   //           discountPercentageInt = discountPercentage.toInt();
//   //         }
//   //
//   //         return Container(
//   //           // ✅ IMPORTANT: Unique key har item ko identify karta hai
//   //           key: ValueKey(product.product_id),
//   //           decoration: BoxDecoration(
//   //             color: Colors.white,
//   //             borderRadius: BorderRadius.circular(8),
//   //             boxShadow: [
//   //               BoxShadow(
//   //                 color: Colors.grey.withOpacity(0.15),
//   //                 spreadRadius: 1,
//   //                 blurRadius: 3,
//   //                 offset: Offset(0, 1),
//   //               ),
//   //             ],
//   //           ),
//   //           child: Column(
//   //             crossAxisAlignment: CrossAxisAlignment.start,
//   //             mainAxisSize: MainAxisSize.min,
//   //             children: [
//   //               // Product Image with Discount Badge
//   //               Expanded(
//   //                 flex: 5,
//   //                 child: Stack(
//   //                   children: [
//   //                     InkWell(
//   //                       onTap: () {
//   //                         Navigator.push(
//   //                           context,
//   //                           MaterialPageRoute(
//   //                             builder: (context) => AddToCartScreen(
//   //                               image: product.image,
//   //                               slug: product.slug,
//   //                               qty: product.cartItem ?? 0,
//   //                             ),
//   //                           ),
//   //                         );
//   //                       },
//   //                       child: ClipRRect(
//   //                         borderRadius: BorderRadius.vertical(
//   //                           top: Radius.circular(8),
//   //                         ),
//   //                         child: Container(
//   //                           width: double.infinity,
//   //                           child: Image.network(
//   //                             product.images?.isNotEmpty == true
//   //                                 ? product.images![0]
//   //                                 : '',
//   //                             fit: BoxFit.cover,
//   //                             errorBuilder: (context, error, stackTrace) {
//   //                               return Container(
//   //                                 color: Colors.grey[100],
//   //                                 child: Center(
//   //                                   child: Padding(
//   //                                     padding: const EdgeInsets.all(16.0),
//   //                                     child: Image.asset("assets/logo/logo.png"),
//   //                                   ),
//   //                                 ),
//   //                               );
//   //                             },
//   //                           ),
//   //                         ),
//   //                       ),
//   //                     ),
//   //                     if (discountPercentageInt > 0)
//   //                       Positioned(
//   //                         top: 4,
//   //                         left: 4,
//   //                         child: Container(
//   //                           padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
//   //                           decoration: BoxDecoration(
//   //                             color: Colors.red[700],
//   //                             borderRadius: BorderRadius.circular(4),
//   //                           ),
//   //                           child: Text(
//   //                             "$discountPercentageInt% OFF",
//   //                             style: TextStyle(
//   //                               color: Colors.white,
//   //                               fontSize: 8,
//   //                               fontWeight: FontWeight.bold,
//   //                             ),
//   //                           ),
//   //                         ),
//   //                       ),
//   //                   ],
//   //                 ),
//   //               ),
//   //
//   //               // Product Details
//   //               Expanded(
//   //                 flex: 5,
//   //                 child: Padding(
//   //                   padding: const EdgeInsets.all(6),
//   //                   child: Column(
//   //                     crossAxisAlignment: CrossAxisAlignment.start,
//   //                     mainAxisSize: MainAxisSize.min,
//   //                     children: [
//   //                       // Product Title
//   //                       Text(
//   //                         product.title ?? "No Title",
//   //                         maxLines: 2,
//   //                         overflow: TextOverflow.ellipsis,
//   //                         style: TextStyle(
//   //                           fontSize: 11,
//   //                           height: 1.2,
//   //                           fontWeight: FontWeight.w500,
//   //                           color: Colors.grey[800],
//   //                         ),
//   //                       ),
//   //                       SizedBox(height: 4),
//   //
//   //                       // Pricing Section
//   //                       Wrap(
//   //                         spacing: 4,
//   //                         runSpacing: 2,
//   //                         crossAxisAlignment: WrapCrossAlignment.center,
//   //                         children: [
//   //                           Container(
//   //                             padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
//   //                             decoration: BoxDecoration(
//   //                               color: Colors.green[700],
//   //                               borderRadius: BorderRadius.circular(3),
//   //                             ),
//   //                             child: Text(
//   //                               "₹${discPrice.toStringAsFixed(0)}",
//   //                               style: TextStyle(
//   //                                 color: Colors.white,
//   //                                 fontSize: 10,
//   //                                 fontWeight: FontWeight.bold,
//   //                               ),
//   //                             ),
//   //                           ),
//   //                           if (price > 0 && price != discPrice)
//   //                             Text(
//   //                               "₹${price.toStringAsFixed(0)}",
//   //                               style: TextStyle(
//   //                                 fontSize: 9,
//   //                                 color: Colors.red[600],
//   //                                 fontWeight: FontWeight.w600,
//   //                                 decoration: TextDecoration.lineThrough,
//   //                               ),
//   //                             ),
//   //                         ],
//   //                       ),
//   //
//   //                       Spacer(),
//   //
//   //                       // Add to Cart Button
//   //                       if (product.stock != null && product.stock! > 0)
//   //                         Obx(() {
//   //                           int currentQty = product.cartItem ?? 0;
//   //                           return currentQty > 0
//   //                             ? Container(
//   //                           height: 28,
//   //                           decoration: BoxDecoration(
//   //                             borderRadius: BorderRadius.circular(4),
//   //                             color: Colors.teal,
//   //                           ),
//   //                           child: Row(
//   //                             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//   //                             children: [
//   //                               InkWell(
//   //                                 onTap: () async {
//   //                                   // ✅ Decrement logic - removeAt() hataya
//   //                                   product.cartItem = (product.cartItem ?? 0) - 1;
//   //
//   //                                   if (product.cartItem! <= 0) {
//   //                                     product.cartItem = 0;
//   //                                     await CartStorage.removeFromCart(product.product_id!);
//   //                                     await cartCtrl.getCartList(context);
//   //                                     // ✅ Item ko remove nahi karna, sirf callback call karna
//   //                                     onItemClicked(product.product_id!);
//   //                                     return;
//   //                                   }
//   //
//   //                                   await cartCtrl.addToCartLocal(
//   //                                     context,
//   //                                     product.product_id!,
//   //                                     product.images![0],
//   //                                     product.title,
//   //                                     product.price,
//   //                                     product.discPrice,
//   //                                     product.cartItem!,
//   //                                     product.stock!,
//   //                                   );
//   //                                   onItemClicked(product.product_id!);
//   //                                 },
//   //                                 child: Padding(
//   //                                   padding: EdgeInsets.all(4),
//   //                                   child: Text(
//   //                                     "−",
//   //                                     style: TextStyle(
//   //                                       fontSize: 16,
//   //                                       color: Colors.white,
//   //                                       fontWeight: FontWeight.bold,
//   //                                     ),
//   //                                   ),
//   //                                 ),
//   //                               ),
//   //                               Text(
//   //                                 "${product.cartItem}",
//   //                                 style: TextStyle(
//   //                                   fontSize: 14,
//   //                                   color: Colors.white,
//   //                                   fontWeight: FontWeight.w500,
//   //                                 ),
//   //                               ),
//   //                               InkWell(
//   //                                 onTap: () async {
//   //                                   if ((top_s_p_list[index]!.cartItem ?? 0) < 5 && (top_s_p_list[index]!.cartItem ?? 0) < top_s_p_list[index].stock!) {
//   //                                     product.cartItem = (product.cartItem ?? 0) + 1;
//   //                                     await cartCtrl.addToCartLocal(
//   //                                       context,
//   //                                       product.product_id!,
//   //                                       product.images![0],
//   //                                       product.title,
//   //                                       product.price,
//   //                                       product.discPrice,
//   //                                       product.cartItem!,
//   //                                       product.stock!,
//   //                                     );
//   //                                     onItemClicked(product.product_id!);
//   //                                   } else {
//   //                                     AppToast.showToast(msg: "You added maximum.");
//   //                                   }
//   //                                 },
//   //                                 child: Padding(
//   //                                   padding: EdgeInsets.all(4),
//   //                                   child: Text(
//   //                                     "+",
//   //                                     style: TextStyle(
//   //                                       fontSize: 16,
//   //                                       color: Colors.white,
//   //                                       fontWeight: FontWeight.bold,
//   //                                     ),
//   //                                   ),
//   //                                 ),
//   //                               ),
//   //                             ],
//   //                           ),
//   //                         )
//   //                             : InkWell(
//   //                           onTap: () async {
//   //                             product.cartItem = (product.cartItem ?? 0) + 1;
//   //                             await cartCtrl.addToCartLocal(
//   //                               context,
//   //                               product.product_id!,
//   //                               product.images![0],
//   //                               product.title,
//   //                               product.price,
//   //                               product.discPrice,
//   //                               product.cartItem!,
//   //                               product.stock!,
//   //                             );
//   //                             onItemClicked(product.product_id!);
//   //                           },
//   //                           child: Container(
//   //                             height: 28,
//   //                             decoration: BoxDecoration(
//   //                               borderRadius: BorderRadius.circular(4),
//   //                               color: Colors.red,
//   //                             ),
//   //                             child: Center(
//   //                               child: Text(
//   //                                 "Add to cart",
//   //                                 style: TextStyle(
//   //                                   fontSize: 10,
//   //                                   fontWeight: FontWeight.w600,
//   //                                   color: Colors.white,
//   //                                 ),
//   //                               ),
//   //                             ),
//   //                           ),
//   //                         );
//   //                         }),
//   //                       if (product.stock == 0 || product.stock == null)
//   //                         Container(
//   //                           height: 28,
//   //                           decoration: BoxDecoration(
//   //                             borderRadius: BorderRadius.circular(4),
//   //                             color: Colors.grey[300],
//   //                           ),
//   //                           child: Center(
//   //                             child: Text(
//   //                               "Out of Stock",
//   //                               style: TextStyle(
//   //                                 fontSize: 10,
//   //                                 fontWeight: FontWeight.w600,
//   //                                 color: Colors.red[700],
//   //                               ),
//   //                             ),
//   //                           ),
//   //                         ),
//   //                     ],
//   //                   ),
//   //                 ),
//   //               ),
//   //             ],
//   //           ),
//   //         );
//   //       },
//   //     ),
//   //   );
//   // }
//   topCategoriesWidgets(List<TopSelling> top_s_p_list,
//       List<CartItemData> cartItems, bool isloading, Function(bool) onItemClicked,)
//   {
//     if (!isloading) {
//       return Image.asset("assets/images/product_not_found.png");
//     }
//
//     // Sort the product list by highest discount first
//     top_s_p_list = sortByDiscount(top_s_p_list);
//
//     // Sort to move out of stock items to the end
//     top_s_p_list.sort((a, b) {
//       bool aOutOfStock = (a.stock == null || a.stock == 0);
//       bool bOutOfStock = (b.stock == null || b.stock == 0);
//
//       // If both are out of stock or both are in stock, maintain current order
//       if (aOutOfStock == bOutOfStock) return 0;
//
//       // Move out of stock items to the end
//       if (aOutOfStock) return 1;
//       if (bOutOfStock) return -1;
//
//       return 0;
//     });
//
//     return Container(
//       width: double.infinity,
//       child: GridView.builder(
//         shrinkWrap: true,
//         physics: NeverScrollableScrollPhysics(),
//         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 2,
//           childAspectRatio: 0.6,
//           crossAxisSpacing: 12,
//           mainAxisSpacing: 12,
//         ),
//         itemCount: top_s_p_list.length,
//         itemBuilder: (context, index) {
//           // Rest of your itemBuilder code remains the same
//           num price = top_s_p_list[index].price ?? 0;
//           num discPrice = top_s_p_list[index].discPrice ?? 0;
//
//           return StatefulBuilder(builder: (context, setState) {
//             // Your existing itemBuilder code...
//             int discountPercentageInt = 0;
//             if (price > 0 && discPrice > 0) {
//               double discountPercentage = ((price - discPrice) / price) * 100;
//               discountPercentageInt = discountPercentage.toInt();
//             }
//
//             return Container(
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(8),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.grey.withOpacity(0.15),
//                     spreadRadius: 1,
//                     blurRadius: 3,
//                     offset: Offset(0, 1),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Product Image with Discount Badge
//                   Expanded(
//                     flex: 7,
//                     child: Stack(
//                       children: [
//                         // Product Image Container
//                         InkWell(
//                           onTap: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => AddToCartScreen(
//                                   image: top_s_p_list[index].image,
//                                   slug: top_s_p_list[index].slug,
//                                   qty:top_s_p_list[index]!.cartItem =
//                                   (top_s_p_list[index]!.cartItem ?? 0),
//                                 ),
//                               ),
//                             );
//                           },
//                           child: ClipRRect(
//                             borderRadius: BorderRadius.only(
//                               topLeft: Radius.circular(8),
//                               topRight: Radius.circular(8),
//                             ),
//                             child: Container(
//                               height: 150,
//                               width: double.infinity,
//                               child: Image.network(
//                                 top_s_p_list[index].images?.isNotEmpty == true
//                                     ? top_s_p_list[index].images![0]
//                                     : '',
//                                 fit: BoxFit.contain,
//                                 errorBuilder: (context, error, stackTrace) {
//                                   return Container(
//                                     color: Colors.grey[100],
//                                     child: Center(
//                                       child: Padding(
//                                         padding: const EdgeInsets.all(28.0),
//                                         child:
//                                         Image.asset("assets/logo/groticapp.png"),
//                                       ),
//                                     ),
//                                   );
//                                 },
//                               ),
//                             ),
//                           ),
//                         ),
//
//                         // Discount Badge
//                         if (discountPercentageInt > 0)
//                           Positioned(
//                             top: 8,
//                             left: 8,
//                             child: Container(
//                               padding: EdgeInsets.symmetric(
//                                   horizontal: 6, vertical: 2),
//                               decoration: BoxDecoration(
//                                 color: Colors.red[700],
//                                 borderRadius: BorderRadius.circular(4),
//                               ),
//                               child: Text(
//                                 "$discountPercentageInt% OFF",
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 9,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//
//                   // Product Details
//                   Padding(
//                     padding:
//                     const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Product Title
//                         Text(
//                           top_s_p_list[index].title ?? "No Title",
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis,
//                           style: TextStyle(
//                             fontSize: 12,
//                             height: 1.2,
//                             fontWeight: FontWeight.w500,
//                             color: Colors.grey[800],
//                           ),
//                         ),
//
//                         SizedBox(height: 4),
//
//                         // Pricing Section with Professional Layout
//                         Row(
//                           children: [
//                             // Discount Price (Main Price)
//                             Container(
//                               padding: EdgeInsets.symmetric(
//                                   horizontal: 6, vertical: 2),
//                               decoration: BoxDecoration(
//                                 color: Colors.green[700],
//                                 borderRadius: BorderRadius.circular(4),
//                               ),
//                               child: Text(
//                                 "₹${discPrice.toStringAsFixed(0)}",
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 12,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                             SizedBox(width: 5),
//                             // Original Price
//                             if (price > 0 && price != discPrice)
//                               Text(
//                                 "₹${price.toStringAsFixed(0)}",
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   color: Colors.red[600],
//                                   fontWeight: FontWeight.w700,
//                                   decoration: TextDecoration.lineThrough,
//                                   decorationThickness: 1.5,
//                                 ),
//                               ),
//                           ],
//                         ),
//                         SizedBox(height: 5),
//
//                         // Savings text
//                         if (price > 0 && price != discPrice)
//                           Text(
//                             "Save ₹${(price - discPrice).toStringAsFixed(0)}",
//                             style: TextStyle(
//                               fontSize: 12,
//                               color: Colors.green[700],
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//
//                   Spacer(),
//
//                   // Add to Cart Button with Quantity Controls
//                   if(top_s_p_list[index].stock !=null && top_s_p_list[index].stock!>0)
//                     Padding(
//                       padding:
//                       const EdgeInsets.only(left: 8, right: 8, bottom: 8),
//                       child: top_s_p_list[index].cartItem! > 0
//                           ? Container(
//                         height: 36,
//                         width: double.infinity,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(6),
//                           color: Colors.teal,
//                         ),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           crossAxisAlignment: CrossAxisAlignment.center,
//                           children: [
//                             const SizedBox(width: 5),
//                             InkWell(
//                               onTap: () async {
//                                 final productId = top_s_p_list[index]
//                                     .product_id
//                                     .toString();
//                                 top_s_p_list[index]!.cartItem =
//                                     (top_s_p_list[index]!.cartItem ?? 0) -
//                                         1;
//                                 if (top_s_p_list[index]!.cartItem! <= 0) {
//                                   top_s_p_list[index]!.cartItem = 0;
//
//                                   await CartStorage.removeFromCart(top_s_p_list[index]!.product_id!);
//
//                                   await cartCtrl.getCartList(context);
//
//                                   // setState(() {
//                                   //   top_s_p_list.removeAt(index);
//                                   // });
//                                   setState(() {});
//
//                                   return;
//                                 }
//                                 await cartCtrl.addToCartLocal(context,
//                                     top_s_p_list[index].product_id!,
//                                     top_s_p_list[index].images![0],
//                                     top_s_p_list[index].title,
//                                     top_s_p_list[index].price,
//                                     top_s_p_list[index].discPrice,
//                                     (top_s_p_list[index].cartItem!),
//                                     (top_s_p_list[index].stock!),
//                                 );
//                                 onItemClicked(true);
//                                 setState(() {});
//                               },
//                               child: const Text(
//                                 "−",
//                                 style: TextStyle(
//                                     fontSize: 21,
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.bold),
//                               ),
//                             ),
//                             const SizedBox(width: 5),
//                             Obx(() {
//                               final productId =
//                               top_s_p_list[index].product_id.toString();
//                               final cartItem =
//                               cartCtrl.cartList.firstWhereOrNull(
//                                     (item) => item.productId == productId,
//                               );
//
//                               final qty = cartItem?.qty ?? 1;
//
//                               return Text(
//                                 "${top_s_p_list[index].cartItem}",
//                                 style: const TextStyle(
//                                     fontSize: 18,
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.w500),
//                               );
//                             }),
//                             const SizedBox(width: 5),
//                             InkWell(
//                               onTap: () async {
//                                 PrintLog.printLog("========>>>>>>>>>>>>> Quantity: ${(top_s_p_list[index]!.cartItem ?? 0)}, Stock: ${top_s_p_list[index].stock!}");
//                                 if ((top_s_p_list[index]!.cartItem ?? 0) < 5 && (top_s_p_list[index]!.cartItem ?? 0) < top_s_p_list[index].stock!) {
//                                   top_s_p_list[index]!.cartItem =
//                                       (top_s_p_list[index]!.cartItem ?? 0) +
//                                           1;
//                                   await cartCtrl.addToCartLocal(context, top_s_p_list[index].product_id!, top_s_p_list[index].images![0],
//                                       top_s_p_list[index].title, top_s_p_list[index].price, top_s_p_list[index].discPrice,
//                                       (top_s_p_list[index].cartItem!),(top_s_p_list[index].stock!));
//                                   onItemClicked(true);
//                                 } else {
//                                   AppToast.showToast(msg: "You added maximum.");
//                                 }
//                                 setState(() {});
//                               },
//                               child: const Text(
//                                 "+",
//                                 style: TextStyle(
//                                     fontSize: 24,
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.bold),
//                               ),
//                             ),
//                             const SizedBox(width: 5),
//                           ],
//                         ),
//                       )
//                           : InkWell(
//                         onTap: () async {
//                           top_s_p_list[index].cartItem =
//                               top_s_p_list[index].cartItem! + 1;
//                           await cartCtrl.addToCartLocal(context, top_s_p_list[index].product_id!, top_s_p_list[index].images![0], top_s_p_list[index].title,
//                               top_s_p_list[index].price, top_s_p_list[index].discPrice, (top_s_p_list[index].cartItem!), (top_s_p_list[index].stock!));
//                           onItemClicked(true);
//                           setState(() {});
//                         },
//                         child: Container(
//                           height: 36,
//                           width: double.infinity,
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(6),
//                             color: Colors.red,
//                           ),
//                           child: Center(
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: const [
//                                 Icon(
//                                   Icons.shopping_cart_outlined,
//                                   color: Colors.white,
//                                   size: 14,
//                                 ),
//                                 SizedBox(width: 4),
//                                 Text(
//                                   "Add to cart",
//                                   style: TextStyle(
//                                     fontSize: 12,
//                                     fontWeight: FontWeight.w600,
//                                     color: Colors.white,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   if(top_s_p_list[index].stock == 0  || top_s_p_list[index].stock==null)
//                     Padding(
//                       padding: const EdgeInsets.only(bottom: 1, top: 11, left: 16, right: 16),
//                       child:  InkWell(
//                         onTap: () async {
//                           // Out of stock - no action
//                         },
//                         child:  Container(
//                           height: 36,
//                           width: double.infinity,
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(6),
//                             color: Colors.red[100],
//                           ),
//                           child: Center(
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: const [
//                                 Text(
//                                   "Out of Stock",
//                                   style: TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.w600,
//                                     color: Colors.white,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             );
//           });
//         },
//       ),
//     );
//   }
//   topBuyOneGetOneWidgets(List<TopSelling> top_s_p_list, List<CartItemData> cartItems, bool isloading, Function(bool) onItemClicked,)
//   {
//     if (!isloading) {
//       return Image.asset("assets/images/product_not_found.png");
//     }
//
//     // Sort the product list by highest discount first
//     top_s_p_list = sortByDiscount(top_s_p_list);
//
//     // Sort to move out of stock items to the end
//     top_s_p_list.sort((a, b) {
//       bool aOutOfStock = (a.stock == null || a.stock == 0);
//       bool bOutOfStock = (b.stock == null || b.stock == 0);
//
//       // If both are out of stock or both are in stock, maintain current order
//       if (aOutOfStock == bOutOfStock) return 0;
//
//       // Move out of stock items to the end
//       if (aOutOfStock) return 1;
//       if (bOutOfStock) return -1;
//
//       return 0;
//     });
//
//     return Container(
//       width: double.infinity,
//       child: GridView.builder(
//         shrinkWrap: true,
//         physics: NeverScrollableScrollPhysics(),
//         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 2,
//           childAspectRatio: 0.6,
//           crossAxisSpacing: 12,
//           mainAxisSpacing: 12,
//         ),
//         itemCount: top_s_p_list.length,
//         itemBuilder: (context, index) {
//           // Rest of your itemBuilder code remains the same
//           num price = top_s_p_list[index].price ?? 0;
//           num discPrice = top_s_p_list[index].discPrice ?? 0;
//
//           return StatefulBuilder(builder: (context, setState) {
//             // Your existing itemBuilder code...
//             int discountPercentageInt = 0;
//             if (price > 0 && discPrice > 0) {
//               double discountPercentage = ((price - discPrice) / price) * 100;
//               discountPercentageInt = discountPercentage.toInt();
//             }
//
//             return Container(
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(8),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.grey.withOpacity(0.15),
//                     spreadRadius: 1,
//                     blurRadius: 3,
//                     offset: Offset(0, 1),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Product Image with Discount Badge
//                   Expanded(
//                     flex: 7,
//                     child: Stack(
//                       children: [
//                         // Product Image Container
//                         InkWell(
//                           onTap: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => AddToCartScreen(
//                                   image: top_s_p_list[index].image,
//                                   slug: top_s_p_list[index].slug,
//                                   qty:top_s_p_list[index]!.cartItem =
//                                   (top_s_p_list[index]!.cartItem ?? 0),
//                                 ),
//                               ),
//                             );
//                           },
//                           child: ClipRRect(
//                             borderRadius: BorderRadius.only(
//                               topLeft: Radius.circular(8),
//                               topRight: Radius.circular(8),
//                             ),
//                             child: Container(
//                               height: 150,
//                               width: double.infinity,
//                               child: Image.network(
//                                 top_s_p_list[index].images?.isNotEmpty == true
//                                     ? top_s_p_list[index].images![0]
//                                     : '',
//                                 fit: BoxFit.contain,
//                                 errorBuilder: (context, error, stackTrace) {
//                                   return Container(
//                                     color: Colors.grey[100],
//                                     child: Center(
//                                       child: Padding(
//                                         padding: const EdgeInsets.all(28.0),
//                                         child:
//                                         Image.asset("assets/logo/groticapp.png"),
//                                       ),
//                                     ),
//                                   );
//                                 },
//                               ),
//                             ),
//                           ),
//                         ),
//
//                         // Discount Badge
//                         if (discountPercentageInt > 0)
//                           Positioned(
//                             top: 8,
//                             left: 8,
//                             child: Container(
//                               padding: EdgeInsets.symmetric(
//                                   horizontal: 6, vertical: 2),
//                               decoration: BoxDecoration(
//                                 color: Colors.red[700],
//                                 borderRadius: BorderRadius.circular(4),
//                               ),
//                               child: Text(
//                                 "$discountPercentageInt% OFF",
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 9,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//
//                   // Product Details
//                   Padding(
//                     padding:
//                     const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Product Title
//                         Text(
//                           top_s_p_list[index].title ?? "No Title",
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis,
//                           style: TextStyle(
//                             fontSize: 12,
//                             height: 1.2,
//                             fontWeight: FontWeight.w500,
//                             color: Colors.grey[800],
//                           ),
//                         ),
//
//                         SizedBox(height: 4),
//
//                         // Pricing Section with Professional Layout
//                         Row(
//                           children: [
//                             // Discount Price (Main Price)
//                             Container(
//                               padding: EdgeInsets.symmetric(
//                                   horizontal: 6, vertical: 2),
//                               decoration: BoxDecoration(
//                                 color: Colors.green[700],
//                                 borderRadius: BorderRadius.circular(4),
//                               ),
//                               child: Text(
//                                 "₹${discPrice.toStringAsFixed(0)}",
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 12,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                             SizedBox(width: 5),
//                             // Original Price
//                             if (price > 0 && price != discPrice)
//                               Text(
//                                 "₹${price.toStringAsFixed(0)}",
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   color: Colors.red[600],
//                                   fontWeight: FontWeight.w700,
//                                   decoration: TextDecoration.lineThrough,
//                                   decorationThickness: 1.5,
//                                 ),
//                               ),
//                           ],
//                         ),
//                         SizedBox(height: 5),
//
//                         // Savings text
//                         if (price > 0 && price != discPrice)
//                           Text(
//                             "Save ₹${(price - discPrice).toStringAsFixed(0)}",
//                             style: TextStyle(
//                               fontSize: 12,
//                               color: Colors.green[700],
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//
//                   Spacer(),
//
//                   // Add to Cart Button with Quantity Controls
//                   if(top_s_p_list[index].stock !=null && top_s_p_list[index].stock!>0)
//                     Padding(
//                       padding:
//                       const EdgeInsets.only(left: 8, right: 8, bottom: 8),
//                       child: top_s_p_list[index].cartItem! > 0
//                           ? Container(
//                         height: 36,
//                         width: double.infinity,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(6),
//                           color: Colors.teal,
//                         ),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           crossAxisAlignment: CrossAxisAlignment.center,
//                           children: [
//                             const SizedBox(width: 5),
//                             InkWell(
//                               onTap: () async {
//                                 final productId = top_s_p_list[index]
//                                     .product_id
//                                     .toString();
//                                 top_s_p_list[index]!.cartItem =
//                                     (top_s_p_list[index]!.cartItem ?? 0) -
//                                         1;
//                                 if (top_s_p_list[index]!.cartItem! <= 0) {
//                                   top_s_p_list[index]!.cartItem = 0;
//
//                                   await CartStorage.removeFromCart(top_s_p_list[index]!.product_id!);
//
//                                   await cartCtrl.getCartList(context);
//
//                                   // setState(() {
//                                   //   top_s_p_list.removeAt(index);
//                                   // });
//                                   setState(() {});
//
//                                   return;
//                                 }
//                                 await cartCtrl.addToCartLocal(context,
//                                     top_s_p_list[index].product_id!,
//                                     top_s_p_list[index].images![0],
//                                     top_s_p_list[index].title,
//                                     top_s_p_list[index].price,
//                                     top_s_p_list[index].discPrice,
//                                     (top_s_p_list[index].cartItem!),
//                                     (top_s_p_list[index].stock!),
//                                 );
//                                 onItemClicked(true);
//                                 setState(() {});
//                               },
//                               child: const Text(
//                                 "−",
//                                 style: TextStyle(
//                                     fontSize: 21,
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.bold),
//                               ),
//                             ),
//                             const SizedBox(width: 5),
//                             Obx(() {
//                               final productId =
//                               top_s_p_list[index].product_id.toString();
//                               final cartItem =
//                               cartCtrl.cartList.firstWhereOrNull(
//                                     (item) => item.productId == productId,
//                               );
//
//                               final qty = cartItem?.qty ?? 1;
//
//                               return Text(
//                                 "${top_s_p_list[index].cartItem}",
//                                 style: const TextStyle(
//                                     fontSize: 18,
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.w500),
//                               );
//                             }),
//                             const SizedBox(width: 5),
//                             InkWell(
//                               onTap: () async {
//                                 PrintLog.printLog("========>>>>>>>>>>>>> Quantity: ${(top_s_p_list[index]!.cartItem ?? 0)}, Stock: ${top_s_p_list[index].stock!}");
//                                 if ((top_s_p_list[index]!.cartItem ?? 0) < 2 && (top_s_p_list[index]!.cartItem ?? 0) < top_s_p_list[index].stock!) {
//                                   top_s_p_list[index]!.cartItem =
//                                       (top_s_p_list[index]!.cartItem ?? 0) +
//                                           1;
//                                   await cartCtrl.addToCartLocal(context, top_s_p_list[index].product_id!, top_s_p_list[index].images![0],
//                                       top_s_p_list[index].title, top_s_p_list[index].price, top_s_p_list[index].discPrice,
//                                       (top_s_p_list[index].cartItem!),(top_s_p_list[index].stock!));
//                                   onItemClicked(true);
//                                 } else {
//                                   AppToast.showToast(msg: "You added maximum.");
//                                 }
//                                 setState(() {});
//                               },
//                               child: const Text(
//                                 "+",
//                                 style: TextStyle(
//                                     fontSize: 24,
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.bold),
//                               ),
//                             ),
//                             const SizedBox(width: 5),
//                           ],
//                         ),
//                       )
//                           : InkWell(
//                         onTap: () async {
//                           top_s_p_list[index].cartItem =
//                               top_s_p_list[index].cartItem! + 1;
//                           await cartCtrl.addToCartLocal(context, top_s_p_list[index].product_id!, top_s_p_list[index].images![0], top_s_p_list[index].title,
//                               top_s_p_list[index].price, top_s_p_list[index].discPrice, (top_s_p_list[index].cartItem!), (top_s_p_list[index].stock!));
//                           onItemClicked(true);
//                           setState(() {});
//                         },
//                         child: Container(
//                           height: 36,
//                           width: double.infinity,
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(6),
//                             color: Colors.red,
//                           ),
//                           child: Center(
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: const [
//                                 Icon(
//                                   Icons.shopping_cart_outlined,
//                                   color: Colors.white,
//                                   size: 14,
//                                 ),
//                                 SizedBox(width: 4),
//                                 Text(
//                                   "Add to cart",
//                                   style: TextStyle(
//                                     fontSize: 12,
//                                     fontWeight: FontWeight.w600,
//                                     color: Colors.white,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   if(top_s_p_list[index].stock == 0  || top_s_p_list[index].stock==null)
//                     Padding(
//                       padding: const EdgeInsets.only(bottom: 1, top: 11, left: 16, right: 16),
//                       child:  InkWell(
//                         onTap: () async {
//                           // Out of stock - no action
//                         },
//                         child:  Container(
//                           height: 36,
//                           width: double.infinity,
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(6),
//                             color: Colors.red[100],
//                           ),
//                           child: Center(
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: const [
//                                 Text(
//                                   "Out of Stock",
//                                   style: TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.w600,
//                                     color: Colors.white,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             );
//           });
//         },
//       ),
//     );
//   }
//
//   // topCategoriesWidgets(List<TopSelling> top_s_p_list,
//   //     List<CartItemData> cartItems, bool isloading, Function(bool) onItemClicked,)
//   // {
//   //   if (!isloading) {
//   //     return Image.asset("assets/images/product_not_found.png");
//   //   }
//   //
//   //   // Sort the product list by highest discount first
//   //   top_s_p_list = sortByDiscount(top_s_p_list);
//   //   return Container(
//   //     width: double.infinity,
//   //     child: GridView.builder(
//   //       shrinkWrap: true,
//   //       physics: NeverScrollableScrollPhysics(),
//   //       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//   //         crossAxisCount: 2,
//   //         childAspectRatio: 0.62, // Adjusted to give more space vertically
//   //         crossAxisSpacing: 12,
//   //         mainAxisSpacing: 12,
//   //       ),
//   //       itemCount: top_s_p_list.length,
//   //       itemBuilder: (context, index) {
//   //         num price = top_s_p_list[index].price ?? 0;
//   //         num discPrice = top_s_p_list[index].discPrice ?? 0;
//   //
//   //         // Add a stateful quantity variable
//   //         return StatefulBuilder(builder: (context, setState) {
//   //           // Calculate discount percentage
//   //           int discountPercentageInt = 0;
//   //           if (price > 0 && discPrice > 0) {
//   //             double discountPercentage = ((price - discPrice) / price) * 100;
//   //             discountPercentageInt = discountPercentage.toInt();
//   //           }
//   //
//   //           return Container(
//   //             decoration: BoxDecoration(
//   //               color: Colors.white,
//   //               borderRadius: BorderRadius.circular(8),
//   //               boxShadow: [
//   //                 BoxShadow(
//   //                   color: Colors.grey.withOpacity(0.15),
//   //                   spreadRadius: 1,
//   //                   blurRadius: 3,
//   //                   offset: Offset(0, 1),
//   //                 ),
//   //               ],
//   //             ),
//   //             child: Column(
//   //               crossAxisAlignment: CrossAxisAlignment.start,
//   //               children: [
//   //                 // Product Image with Discount Badge
//   //                 Stack(
//   //                   children: [
//   //                     // Product Image Container
//   //                     InkWell(
//   //                       onTap: () {
//   //                         Navigator.push(
//   //                           context,
//   //                           MaterialPageRoute(
//   //                             builder: (context) => AddToCartScreen(
//   //                               image: top_s_p_list[index].image,
//   //                               slug: top_s_p_list[index].slug,
//   //                               qty:top_s_p_list[index]!.cartItem =
//   //                                   (top_s_p_list[index]!.cartItem ?? 0),
//   //                             ),
//   //                           ),
//   //                         );
//   //                       },
//   //                       child: ClipRRect(
//   //                         borderRadius: BorderRadius.only(
//   //                           topLeft: Radius.circular(8),
//   //                           topRight: Radius.circular(8),
//   //                         ),
//   //                         child: Container(
//   //                           height: 150,
//   //                           width: double.infinity,
//   //                           child: Image.network(
//   //                             top_s_p_list[index].images?.isNotEmpty == true
//   //                                 ? top_s_p_list[index].images![0]
//   //                                 : '',
//   //                             fit: BoxFit.contain,
//   //                             errorBuilder: (context, error, stackTrace) {
//   //                               return Container(
//   //                                 color: Colors.grey[100],
//   //                                 child: Center(
//   //                                   child: Padding(
//   //                                     padding: const EdgeInsets.all(28.0),
//   //                                     child:
//   //                                         Image.asset("assets/logo/logo.png"),
//   //                                   ),
//   //                                 ),
//   //                               );
//   //                             },
//   //                           ),
//   //                         ),
//   //                       ),
//   //                     ),
//   //
//   //                     // Discount Badge
//   //                     if (discountPercentageInt > 0)
//   //                       Positioned(
//   //                         top: 8,
//   //                         left: 8,
//   //                         child: Container(
//   //                           padding: EdgeInsets.symmetric(
//   //                               horizontal: 6, vertical: 2),
//   //                           decoration: BoxDecoration(
//   //                             color: Colors.red[700],
//   //                             borderRadius: BorderRadius.circular(4),
//   //                           ),
//   //                           child: Text(
//   //                             "$discountPercentageInt% OFF",
//   //                             style: TextStyle(
//   //                               color: Colors.white,
//   //                               fontSize: 9,
//   //                               fontWeight: FontWeight.bold,
//   //                             ),
//   //                           ),
//   //                         ),
//   //                       ),
//   //                   ],
//   //                 ),
//   //
//   //                 // Product Details
//   //                 Padding(
//   //                   padding:
//   //                       const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//   //                   child: Column(
//   //                     crossAxisAlignment: CrossAxisAlignment.start,
//   //                     children: [
//   //                       // Product Title
//   //                       Text(
//   //                         top_s_p_list[index].title ?? "No Title",
//   //                         maxLines: 2,
//   //                         overflow: TextOverflow.ellipsis,
//   //                         style: TextStyle(
//   //                           fontSize: 12,
//   //                           height: 1.2,
//   //                           fontWeight: FontWeight.w500,
//   //                           color: Colors.grey[800],
//   //                         ),
//   //                       ),
//   //
//   //                       SizedBox(height: 4),
//   //
//   //                       // Pricing Section with Professional Layout
//   //                       Row(
//   //                         children: [
//   //                           // Discount Price (Main Price)
//   //
//   //                           Container(
//   //                             padding: EdgeInsets.symmetric(
//   //                                 horizontal: 6, vertical: 2),
//   //                             decoration: BoxDecoration(
//   //                               color: Colors.green[700],
//   //                               borderRadius: BorderRadius.circular(4),
//   //                             ),
//   //                             child: Text(
//   //                               "₹${discPrice.toStringAsFixed(0)}",
//   //                               style: TextStyle(
//   //                                 color: Colors.white,
//   //                                 fontSize: 12,
//   //                                 fontWeight: FontWeight.bold,
//   //                               ),
//   //                             ),
//   //                           ),
//   //
//   //                           // Text(
//   //                           //   "₹${discPrice.toStringAsFixed(0)}",
//   //                           //   style: TextStyle(
//   //                           //     fontSize: 14,
//   //                           //     fontWeight: FontWeight.bold,
//   //                           //     color: Colors.black87,
//   //                           //   ),
//   //                           // ),
//   //                           SizedBox(width: 5),
//   //                           // Original Price
//   //                           if (price > 0 && price != discPrice)
//   //                             Text(
//   //                               "₹${price.toStringAsFixed(0)}",
//   //                               style: TextStyle(
//   //                                 fontSize: 12,
//   //                                 color: Colors.red[600],
//   //                                 fontWeight: FontWeight.w700,
//   //                                 decoration: TextDecoration.lineThrough,
//   //                                 decorationThickness: 1.5,
//   //                               ),
//   //                             ),
//   //                         ],
//   //                       ),
//   //                       SizedBox(height: 5),
//   //
//   //                       // Savings text
//   //                       if (price > 0 && price != discPrice)
//   //                         Text(
//   //                           "Save ₹${(price - discPrice).toStringAsFixed(0)}",
//   //                           style: TextStyle(
//   //                             fontSize: 12,
//   //                             color: Colors.green[700],
//   //                             fontWeight: FontWeight.w500,
//   //                           ),
//   //                         ),
//   //                     ],
//   //                   ),
//   //                 ),
//   //
//   //                  Spacer(),
//   //                 // SizedBox(height: 21,),
//   //
//   //                 // Add to Cart Button with Quantity Controls
//   //                 if(top_s_p_list[index].stock !=null && top_s_p_list[index].stock!>0)
//   //                   Padding(
//   //                   padding:
//   //                       const EdgeInsets.only(left: 8, right: 8, bottom: 8),
//   //                   child: top_s_p_list[index].cartItem! > 0
//   //                       ? Container(
//   //                           height: 36,
//   //                           width: double.infinity,
//   //                           decoration: BoxDecoration(
//   //                             borderRadius: BorderRadius.circular(6),
//   //                             color: Colors.teal,
//   //                           ),
//   //                           child: Row(
//   //                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//   //                             crossAxisAlignment: CrossAxisAlignment.center,
//   //                             children: [
//   //                               const SizedBox(width: 5),
//   //                               InkWell(
//   //                                 onTap: () async {
//   //                                   final productId = top_s_p_list[index]
//   //                                       .product_id
//   //                                       .toString();
//   //                                   // PrintLog.printLog("Demoprint2");
//   //                                   // cartCtrl.prodectQty.value =
//   //                                   //     cartItem!.totalProduct! - 1;
//   //                                   // cartCtrl.addToCart(
//   //                                   //   context,
//   //                                   //   productId,
//   //                                   //   qty: cartCtrl.prodectQty.value
//   //                                   //       .toString(),
//   //                                   // );
//   //                                   top_s_p_list[index]!.cartItem =
//   //                                       (top_s_p_list[index]!.cartItem ?? 0) -
//   //                                           1;
//   //                                   await cartCtrl.addToCartLocal(context,
//   //                                       top_s_p_list[index].product_id!,
//   //                                       top_s_p_list[index].images![0],
//   //                                       top_s_p_list[index].title,
//   //                                       top_s_p_list[index].price,
//   //                                       top_s_p_list[index].discPrice, (top_s_p_list[index].cartItem!));
//   //                                   onItemClicked(true);
//   //                                   setState(() {});
//   //
//   //                                 },
//   //                                 child: const Text(
//   //                                   "−",
//   //                                   style: TextStyle(
//   //                                       fontSize: 21,
//   //                                       color: Colors.white,
//   //                                       fontWeight: FontWeight.bold),
//   //                                 ),
//   //                               ),
//   //                               const SizedBox(width: 5),
//   //                               Obx(() {
//   //                                 final productId =
//   //                                     top_s_p_list[index].product_id.toString();
//   //                                 final cartItem =
//   //                                     cartCtrl.cartList.firstWhereOrNull(
//   //                                   (item) => item.productId == productId,
//   //                                 );
//   //
//   //                                 final qty = cartItem?.qty ?? 1;
//   //
//   //                                 return Text(
//   //                                   "${top_s_p_list[index].cartItem}",
//   //                                   style: const TextStyle(
//   //                                       fontSize: 18,
//   //                                       color: Colors.white,
//   //                                       fontWeight: FontWeight.w500),
//   //                                 );
//   //                               }),
//   //                               const SizedBox(width: 5),
//   //                               InkWell(
//   //                                 onTap: () async {
//   //                                   // final productId = top_s_p_list[index].product_id.toString();
//   //                                   // final cartItem = cartCtrl.cartList.firstWhereOrNull(
//   //                                   //       (item) => item.productId == productId,
//   //                                   // );
//   //                                   //
//   //                                   // int.parse(cartCtrl.cartList[index]!.totalProduct!.toString());
//   //                                   // cartCtrl.prodectQty.value = cartItem!.totalProduct! + 1;_
//   //                                   if ((top_s_p_list[index]!.cartItem ?? 0) < 5) {
//   //                                     top_s_p_list[index]!.cartItem =
//   //                                         (top_s_p_list[index]!.cartItem ?? 0) +
//   //                                             1;
//   //                                     await cartCtrl.addToCartLocal(context, top_s_p_list[index].product_id!, top_s_p_list[index].images![0], top_s_p_list[index].title, top_s_p_list[index].price, top_s_p_list[index].discPrice, (top_s_p_list[index].cartItem!));
//   //                                     onItemClicked(true);
//   //                                   } else {
//   //                                     AppToast.showToast(msg: "You can add maximum 5 items");
//   //                                   }
//   //                                   // cartCtrl.addToCart(
//   //                                   //   context,
//   //                                   //   top_s_p_list[index].product_id!,
//   //                                   //   qty: top_s_p_list[index]!
//   //                                   //       .cartItem!
//   //                                   //       .toString(),
//   //                                   // );
//   //                                       setState(() {});
//   //
//   //
//   //
//   //                                 },
//   //                                 child: const Text(
//   //                                   "+",
//   //                                   style: TextStyle(
//   //                                       fontSize: 24,
//   //                                       color: Colors.white,
//   //                                       fontWeight: FontWeight.bold),
//   //                                 ),
//   //                               ),
//   //                               const SizedBox(width: 5),
//   //                             ],
//   //                           ),
//   //                         )
//   //                       : InkWell(
//   //                           onTap: () async {
//   //                             // SharedPreferences.getInstance().then((value) {
//   //                             //   isLogin = value.getBool(
//   //                             //           AppSharedPreferences.isLogin) ??
//   //                             //       false;
//   //                             //
//   //                             //   if (isLogin) {
//   //                             //     top_s_p_list[index].cartItem =
//   //                             //         top_s_p_list[index].cartItem! + 1;
//   //                             //     cartCtrl.addToCartLocal(context, top_s_p_list[index].product_id!, top_s_p_list[index].image, top_s_p_list[index].title, top_s_p_list[index].price, top_s_p_list[index].discPrice, (top_s_p_list[index].cartItem!));
//   //                             //
//   //                             //     // cartCtrl.addToCart(
//   //                             //     //   context,
//   //                             //     //   top_s_p_list[index].product_id.toString(),
//   //                             //     //   qty: "1",
//   //                             //     // );
//   //                             //
//   //                             //     setState(() {});
//   //                             //   } else {
//   //                             //     Get.to(LoginScreen());
//   //                             //   }
//   //                             // });
//   //
//   //                             top_s_p_list[index].cartItem =
//   //                                 top_s_p_list[index].cartItem! + 1;
//   //                             await cartCtrl.addToCartLocal(context, top_s_p_list[index].product_id!, top_s_p_list[index].images![0], top_s_p_list[index].title, top_s_p_list[index].price, top_s_p_list[index].discPrice, (top_s_p_list[index].cartItem!));
//   //                             onItemClicked(true);
//   //                             setState(() {});
//   //
//   //                           },
//   //                           child: Container(
//   //                             height: 36,
//   //                             width: double.infinity,
//   //                             decoration: BoxDecoration(
//   //                               borderRadius: BorderRadius.circular(6),
//   //                               color: Colors.red,
//   //                             ),
//   //                             child: Center(
//   //                               child: Row(
//   //                                 mainAxisAlignment: MainAxisAlignment.center,
//   //                                 children: const [
//   //                                   Icon(
//   //                                     Icons.shopping_cart_outlined,
//   //                                     color: Colors.white,
//   //                                     size: 14,
//   //                                   ),
//   //                                   SizedBox(width: 4),
//   //                                   Text(
//   //                                     "Add to cart",
//   //                                     style: TextStyle(
//   //                                       fontSize: 12,
//   //                                       fontWeight: FontWeight.w600,
//   //                                       color: Colors.white,
//   //                                     ),
//   //                                   ),
//   //                                 ],
//   //                               ),
//   //                             ),
//   //                           ),
//   //                         ),
//   //                 ),
//   //                 if(top_s_p_list[index].stock==0 || top_s_p_list[index].stock==null)
//   //                   Padding(
//   //                   padding: const EdgeInsets.only(bottom: 10, top: 11, left: 16, right: 16),
//   //                   child:  InkWell(
//   //                     onTap: () async {
//   //                       // Add first item to cart
//   //                       // setState(() {
//   //                       //   productCtrl.quntity.value = 1;
//   //                       // });
//   //                       // await cartCtrl.addToCartLocal(
//   //                       //   context,
//   //                       //   productCtrl.product_id.value.toString(),
//   //                       //   productCtrl.banner.value[0],
//   //                       //   productCtrl.title.value.toString(),
//   //                       //   productCtrl.price.value.toString(),
//   //                       //   productCtrl.disc_price.value.toString(),
//   //                       //   productCtrl.quntity.value,
//   //                       // );
//   //                     },
//   //                     child:  Container(
//   //                       height: 28,
//   //                       width: double.infinity,
//   //                       decoration: BoxDecoration(
//   //                         borderRadius: BorderRadius.circular(6),
//   //                         color: Colors.red[100],
//   //                       ),
//   //                       child: Center(
//   //                         child: Row(
//   //                           mainAxisAlignment: MainAxisAlignment.center,
//   //                           children: const [
//   //                             // Icon(
//   //                             //   Icons.shopping_cart_outlined,
//   //                             //   color: Colors.white,
//   //                             //   size: 14,
//   //                             // ),
//   //                             // SizedBox(width: 4),
//   //                             Text(
//   //                               "Out of Stock",
//   //                               style: TextStyle(
//   //                                 fontSize: 16,
//   //                                 fontWeight: FontWeight.w600,
//   //                                 color: Colors.white,
//   //                               ),
//   //                             ),
//   //                           ],
//   //                         ),
//   //                       ),
//   //                     ),
//   //                   ),
//   //                 ),
//   //
//   //               ],
//   //             ),
//   //           );
//   //         });
//   //       },
//   //     ),
//   //   );
//   // }
//
//   Widget searchWidgets(List<ProductData> top_s_p_list,Function(bool) onItemClicked ) {
//     return top_s_p_list.isNotEmpty
//         ? Container(
//       width: Get.width,
//
//       child: GridView.builder(
//         shrinkWrap: true,
//         scrollDirection: Axis.vertical,
//         physics: ScrollPhysics(),
//         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 2, // Height of each item (adjust as needed)
//           mainAxisExtent:
//           250, // Width of each item (adjust to show 2 items per screen width)
//           mainAxisSpacing: 12,
//           crossAxisSpacing: 12,
//         ),
//         itemCount: top_s_p_list.length,
//         itemBuilder: (context, index) {
//           num price = top_s_p_list[index].price ?? 0;
//           num discPrice = top_s_p_list[index].discPrice ?? 0;
//           bool isInCart = false;
//
//           // Add a stateful quantity variable
//           return StatefulBuilder(builder: (context, setState) {
//             // Calculate discount percentage
//             int discountPercentageInt = 0;
//             if (price > 0 && discPrice > 0) {
//               double discountPercentage = ((price - discPrice) / price) * 100;
//               discountPercentageInt = discountPercentage.toInt();
//             }
//
//             return Container(
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(8),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.grey.withOpacity(0.15),
//                     spreadRadius: 1,
//                     blurRadius: 3,
//                     offset: Offset(0, 1),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Product Image with Discount Badge
//                   Stack(
//                     children: [
//                       // Product Image Container
//                       InkWell(
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => AddToCartScreen(
//                                 image: top_s_p_list[index].image,
//                                 slug: top_s_p_list[index].slug,
//                                 qty: top_s_p_list[index].cartItemCount,
//                                 // qty:top_s_p_list[index]!.cartItem =
//                                 //     (top_s_p_list[index]!.cartItem ?? 0) +
//                                 //         1;,
//                               ),
//                             ),
//                           ).then((onValue){
//                             onItemClicked(true);
//                           });
//                         },
//                         child: ClipRRect(
//                           borderRadius: BorderRadius.only(
//                             topLeft: Radius.circular(8),
//                             topRight: Radius.circular(8),
//                           ),
//                           child: Container(
//                             height: 120,
//                             child: Center(
//                               child: Image.network(
//                                 top_s_p_list[index].image?.isNotEmpty == true
//                                     ? top_s_p_list[index].image!
//                                     : '',
//                                 fit: BoxFit.cover,
//                                 errorBuilder: (context, error, stackTrace) {
//                                   return Container(
//                                     color: Colors.grey[100],
//                                     child: Center(
//                                       child: Padding(
//                                         padding: const EdgeInsets.all(28.0),
//                                         child:
//                                         Image.asset("assets/logo/groticapp.png"),
//                                       ),
//                                     ),
//                                   );
//                                 },
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//
//                       // Discount Badge
//                       if (discountPercentageInt > 0)
//                         Positioned(
//                           top: 8,
//                           left: 8,
//                           child: Container(
//                             padding: EdgeInsets.symmetric(
//                                 horizontal: 6, vertical: 2),
//                             decoration: BoxDecoration(
//                               color: Colors.red[700],
//                               borderRadius: BorderRadius.circular(4),
//                             ),
//                             child: Text(
//                               "$discountPercentageInt% OFF",
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 9,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//
//                   // Product Details
//                   Padding(
//                     padding:
//                     const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Product Title
//                         Text(
//                           top_s_p_list[index].title ?? "No Title",
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis,
//                           style: TextStyle(
//                             fontSize: 12,
//                             height: 1.2,
//                             fontWeight: FontWeight.w500,
//                             color: Colors.grey[800],
//                           ),
//                         ),
//
//                         SizedBox(height: 4),
//
//                         // Pricing Section with Professional Layout
//                         Row(
//                           children: [
//                             // Discount Price (Main Price)
//                             Text(
//                               "₹${discPrice.toStringAsFixed(0)}",
//                               style: TextStyle(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.black87,
//                               ),
//                             ),
//
//
//                             SizedBox(width: 5),
//                             // Original Price
//                             if (price > 0 && price != discPrice)
//                               Text(
//                                 "₹${price.toStringAsFixed(0)}",
//                                 style: TextStyle(
//                                   fontSize: 11,
//                                   color: Colors.grey[600],
//                                   decoration: TextDecoration.lineThrough,
//                                   decorationThickness: 1.5,
//                                 ),
//                               ),
//                             Spacer(),
//                             if (price > 0 && price != discPrice)
//                               Text(
//                                 "Save ₹${(price - discPrice).toStringAsFixed(0)}",
//                                 style: TextStyle(
//                                   fontSize: 10,
//                                   color: Colors.green[700],
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                           ],
//                         ),
//                         SizedBox(height: 5),
//
//                         // Savings text
//                       ],
//                     ),
//                   ),
//
//                   Spacer(),
//
//                   // Add to Cart Button with Quantity Controls
//                   if(top_s_p_list[index].stock!=null && top_s_p_list[index].stock! >0)
//                     Padding(
//                     padding:
//                     const EdgeInsets.only(left: 8, right: 8, bottom: 8),
//                     child: top_s_p_list[index].cartItemCount! > 0
//                         ? Container(
//                       height: 28,
//                       width: double.infinity,
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(6),
//                         color: Colors.teal,
//                       ),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         children: [
//                           const SizedBox(width: 5),
//                           InkWell(
//                             onTap: () async {
//                               top_s_p_list[index]!.cartItemCount =
//                                   (top_s_p_list[index]!.cartItemCount ?? 0) -
//                                       1;
//                               if (top_s_p_list[index]!.cartItemCount! >= 0) {
//                                 // cartCtrl.addToCart(
//                                 //   context,
//                                 //   top_s_p_list[index].product_id!.toString(),
//                                 //   qty: top_s_p_list[index]!
//                                 //       .cartItemCount!
//                                 //       .toString(),
//                                 // );
//                                 if (top_s_p_list[index]!.cartItemCount! <= 0) {
//                                   top_s_p_list[index]!.cartItemCount = 0;
//
//                                   await CartStorage.removeFromCart(top_s_p_list[index]!.product_id as String);
//
//                                   await cartCtrl.getCartList(context);
//
//                                   // setState(() {
//                                   //   top_s_p_list.removeAt(index);
//                                   // });
//                                   setState(() {});
//
//                                   return;
//                                 }
//
//                                 await cartCtrl.addToCartLocal(context, top_s_p_list[index].product_id!, top_s_p_list[index].image, top_s_p_list[index].title,
//                                     top_s_p_list[index].price, top_s_p_list[index].discPrice, (top_s_p_list[index].cartItemCount!), (top_s_p_list[index].stock!));
//                                 onItemClicked(true);
//
//                               } else {
//                                 top_s_p_list[index]!.cartItemCount = 0;
//                               }
//                             },
//                             child: const Text(
//                               "−",
//                               style: TextStyle(
//                                   fontSize: 21,
//                                   color: Colors.white,
//                                   fontWeight: FontWeight.bold),
//                             ),
//                           ),
//                           const SizedBox(width: 5),
//                           Obx(() {
//                             final productId =
//                             top_s_p_list[index].product_id.toString();
//                             final cartItem =
//                             cartCtrl.cartList.firstWhereOrNull(
//                                   (item) => item.productId == productId,
//                             );
//
//                             final qty = cartItem?.qty ?? 1;
//
//                             return Text(
//                               "${top_s_p_list[index].cartItemCount}",
//                               style: const TextStyle(
//                                   fontSize: 18,
//                                   color: Colors.white,
//                                   fontWeight: FontWeight.w500),
//                             );
//                           }),
//                           const SizedBox(width: 5),
//                           InkWell(
//                             onTap: () async {
//                               // final productId = top_s_p_list[index].product_id.toString();
//                               // final cartItem = cartCtrl.cartList.firstWhereOrNull(
//                               //       (item) => item.productId == productId,
//                               // );
//                               //
//                               // int.parse(cartCtrl.cartList[index]!.totalProduct!.toString());
//                               // cartCtrl.prodectQty.value = cartItem!.totalProduct! + 1;_
//                               if ((top_s_p_list[index]!.cartItemCount ?? 0) < 5 && (top_s_p_list[index]!.cartItemCount ?? 0) < top_s_p_list[index].stock!) {
//                               // if ((top_s_p_list[index]!.cartItemCount ?? 0) < 5) {
//                                 top_s_p_list[index]!.cartItemCount =
//                                     (top_s_p_list[index]!.cartItemCount ?? 0) +
//                                         1;
//                               } else {
//                                 AppToast.showToast(msg: "You added maximum.");
//                               }
//                               // cartCtrl.addToCart(
//                               //   context,
//                               //   top_s_p_list[index].product_id!.toString(),
//                               //   qty: top_s_p_list[index]!
//                               //       .cartItemCount!
//                               //       .toString(),
//                               // );
//
//                               await cartCtrl.addToCartLocal(context, top_s_p_list[index].product_id!, top_s_p_list[index].image, top_s_p_list[index].title, top_s_p_list[index].price,
//                                   top_s_p_list[index].discPrice, (top_s_p_list[index].cartItemCount!), (top_s_p_list[index].stock!));
//                               onItemClicked(true);
//                             },
//                             child: const Text(
//                               "+",
//                               style: TextStyle(
//                                   fontSize: 24,
//                                   color: Colors.white,
//                                   fontWeight: FontWeight.bold),
//                             ),
//                           ),
//                           const SizedBox(width: 5),
//                         ],
//                       ),
//                     )
//                         : InkWell(
//                       onTap: () async {
//                         // SharedPreferences.getInstance().then((value) {
//                         //   isLogin = value.getBool(
//                         //       AppSharedPreferences.isLogin) ??
//                         //       false;
//                         //
//                         //   if (isLogin) {
//                         //     top_s_p_list[index].cartItemCount =
//                         //         top_s_p_list[index].cartItemCount! + 1;
//                         //     // cartCtrl.addToCart(
//                         //     //   context,
//                         //     //   top_s_p_list[index].product_id.toString(),
//                         //     //   qty: "1",
//                         //     // );
//                         //
//                         //     cartCtrl.addToCartLocal(context, top_s_p_list[index].product_id!, top_s_p_list[index].image, top_s_p_list[index].title, top_s_p_list[index].price, top_s_p_list[index].discPrice, (top_s_p_list[index].cartItemCount!));
//                         //
//                         //
//                         //     setState(() {
//                         //       isInCart = true;
//                         //     });
//                         //   } else {
//                         //     Get.to(LoginScreen());
//                         //   }
//                         // });
//
//                         top_s_p_list[index].cartItemCount =
//                             top_s_p_list[index].cartItemCount! + 1;
//                         // cartCtrl.addToCart(
//                         //   context,
//                         //   top_s_p_list[index].product_id.toString(),
//                         //   qty: "1",
//                         // );
//
//                         await cartCtrl.addToCartLocal(context, top_s_p_list[index].product_id!, top_s_p_list[index].image, top_s_p_list[index].title, top_s_p_list[index].price,
//                             top_s_p_list[index].discPrice, (top_s_p_list[index].cartItemCount!), (top_s_p_list[index].stock!));
//                         onItemClicked(true);
//                       },
//                       child: Container(
//                         height: 28,
//                         width: double.infinity,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(6),
//                           color: Colors.red,
//                         ),
//                         child: Center(
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: const [
//                               Icon(
//                                 Icons.shopping_cart_outlined,
//                                 color: Colors.white,
//                                 size: 14,
//                               ),
//                               SizedBox(width: 4),
//                               Text(
//                                 "Add to cart",
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   fontWeight: FontWeight.w600,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   if(top_s_p_list[index].stock == 0  || top_s_p_list[index].stock==null)
//                   Padding(
//                     padding: const EdgeInsets.only(bottom: 1, top: 1, left: 16, right: 16),
//                     child:  InkWell(
//                       onTap: () async {
//                         // Add first item to cart
//                         // setState(() {
//                         //   productCtrl.quntity.value = 1;
//                         // });
//                         // await cartCtrl.addToCartLocal(
//                         //   context,
//                         //   productCtrl.product_id.value.toString(),
//                         //   productCtrl.banner.value[0],
//                         //   productCtrl.title.value.toString(),
//                         //   productCtrl.price.value.toString(),
//                         //   productCtrl.disc_price.value.toString(),
//                         //   productCtrl.quntity.value,
//                         // );
//                       },
//                       child:  Container(
//                         height: 28,
//                         width: double.infinity,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(6),
//                           color: Colors.red[100],
//                         ),
//                         child: Center(
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: const [
//                               // Icon(
//                               //   Icons.shopping_cart_outlined,
//                               //   color: Colors.white,
//                               //   size: 14,
//                               // ),
//                               // SizedBox(width: 4),
//                               Text(
//                                 "Out of Stock",
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w600,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//
//                 ],
//               ),
//             );
//           });
//         },
//       ),
//     )
//         : Center(
//             child: Image.asset("assets/images/product_not_found.png"),
//           );
//   }
//
//   Widget categoryName(String categoryName) {
//     return catTitleshow(categoryName);
//     // Padding(
//     //   padding: EdgeInsets.all(11),
//     //   child: Row(
//     //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//     //     children: [
//     //       Text(
//     //         categoryName,
//     //         style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//     //       ),
//     //       // InkWell(
//     //       //   onTap: (){
//     //       //    // Get.to(ProductListScreen(bannerList: itemCount,categoryName: categoryName,));
//     //       //   },
//     //       //   child: Row(
//     //       //     children: [
//     //       //       Text("view all ",style: TextStyle(fontSize: 15,color: Colors.black87),),
//     //       //       Text(">",style: TextStyle(fontSize: 18,color: Colors.black87),),
//     //       //     ],
//     //       //   ),
//     //       // ),
//     //     ],
//     //   ),
//     // );
//   }
//
//   Widget categoryNames(String categoryName, List<String> itemCount) {
//     return Padding(
//       padding: EdgeInsets.all(11),
//       child: Flexible(
//         fit: FlexFit.tight,
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               categoryName,
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             InkWell(
//               onTap: () {
//                 //Get.to(ProductListScreen(bannerList: itemCount,categoryName: categoryName,));
//               },
//               child: Row(
//                 children: [
//                   Text(
//                     "view all ",
//                     style: TextStyle(fontSize: 15, color: Colors.black87),
//                   ),
//                   Text(
//                     ">",
//                     style: TextStyle(fontSize: 18, color: Colors.black87),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
