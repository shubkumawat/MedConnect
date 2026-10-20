// import 'package:flutter/services.dart';
// import 'package:flutter/material.dart';
// import '../Colors/colors.dart';
//
//
// contentBox(context){
//   return Stack(
//     children: <Widget>[
//       Container(
//         padding: const EdgeInsets.only(top: 20, left: 20, bottom: 10, right: 10),
//         decoration: BoxDecoration(
//             shape: BoxShape.rectangle,
//             color: Colors.grey[100],
//             borderRadius: BorderRadius.circular(20.0),
//             boxShadow: const [
//               BoxShadow(color: Colors.black,offset: Offset(0,10),
//                   blurRadius: 10
//               ),
//             ]
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//
//           children: <Widget>[
//             Image.asset("assets/images/Comingsoon.png",height: 100,),
//             const SizedBox(
//               height: 15,
//             ),
//             Align(
//               alignment: Alignment.bottomRight,
//               child: TextButton(
//                   onPressed: (){
//                     Navigator.pop(context);
//                   },
//                   child: Text("Okay",style: TextStyle(fontSize: 18, color: AppColors().blackColor),)),
//             ),
//           ],
//         ),
//       ),
//     ],
//   );
// }
//
// uploadBox(context){
//   return Stack(
//     children: <Widget>[
//       Container(
//         padding: const EdgeInsets.only(top: 20, left: 20, bottom: 10, right: 10),
//         decoration: BoxDecoration(
//             shape: BoxShape.rectangle,
//             color: Colors.grey[100],
//             borderRadius: BorderRadius.circular(20.0),
//             boxShadow: const [
//               BoxShadow(color: Colors.black,offset: Offset(0,10),
//                   blurRadius: 10
//               ),
//             ]
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: <Widget>[
//             const Text("Update App",style: TextStyle(fontWeight: FontWeight.w700,fontSize: 20),),
//             const SizedBox(
//               height: 15,
//             ),
//             const Text("Please update app for better performance and new features",style: TextStyle(fontWeight: FontWeight.w500,fontSize: 14,),),
//             const SizedBox(
//               height: 15,
//             ),
//             const SizedBox(
//               height: 15,
//             ),
//             Align(
//               alignment: Alignment.bottomRight,
//               child: TextButton(
//                   onPressed: () async {
//                     Navigator.pop(context);
//                     // if (!await launchUrl(Uri.parse("https://play.google.com/store/apps/details?id=com.payonads.app"))) {
//                     // throw 'Could not launch https://play.google.com/store/apps/details?id=com.payonads.app';
//                     // }
//                     String url = 'https://play.google.com/store/apps/details?id=com.payonads.app';
//                     await MethodChannel('com.quick_finz/device_id').invokeMethod('openUrl',{"url": url});
//
//
//                   },
//                   child: Text("Update Now",style: TextStyle(fontSize: 18, color: CustomColors.blackColor),)),
//             ),
//           ],
//         ),
//       ),
//     ],
//   );
// }