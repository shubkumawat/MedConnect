// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// import '../AdditionalWidget/AdditionalWidget.dart';
// import '../Colors/colors.dart';
// import '../Font/font_family.dart';
// import '../StringDefine/strings.dart';
//
// class CustomDialog{
//
//   showDialog1(BuildContext context,String message){
//     showDialog(
//         context: context,
//         barrierDismissible: false,
//         // user must tap button for close dialog!
//         builder: (BuildContext context) {
//           var contexDialog = context;
//           return WillPopScope(
//             onWillPop: () async => false,
//             child: Dialog(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               elevation: 0,
//               insetPadding: EdgeInsets.all(20),
//               backgroundColor: Colors.transparent,
//               child: Center(
//                 child: Container(
//                   padding: const EdgeInsets.all(20.00),
//                   width: MediaQuery.of(context).size.width-40,
//                   height: MediaQuery.of(context).size.height/2,
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(10),
//                     color: Colors.white,
//                     boxShadow: const [
//                       BoxShadow(color: Colors.grey, spreadRadius: 1),
//                     ],
//                   ),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       Image.asset(oops_image,height: 100,),
//                       const SizedBox(height: 40,),
//                       Text(message,style: const TextStyle(fontSize: 16),),
//                       const SizedBox(height: 40,),
//                       InkWell(
//                         onTap: (){
//                           Get.back();
//                           Get.back();
//                         },
//                         child: Container(
//                           height: 34,
//                           width: 110,
//                           margin: const EdgeInsets.only(bottom: 10),
//                           decoration: BoxDecoration(
//                             borderRadius: const BorderRadius.all(Radius.circular(5)),
//                             gradient: AppColors.blueGradientColor,
//                           ),
//                           child: Center(child: buildText("Continue", 15.0, FontFamily.PoppinsRegular, CustomColors.txtwhiteColor)),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           );
//         });
//   }
//   showDialogSuccess(BuildContext context,String message){
//     showDialog(
//         context: context,
//         barrierDismissible: false,
//         // user must tap button for close dialog!
//         builder: (BuildContext context) {
//           var contexDialog = context;
//           return WillPopScope(
//             onWillPop: () async => false,
//             child: Dialog(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               elevation: 0,
//               insetPadding: EdgeInsets.all(20),
//               backgroundColor: Colors.transparent,
//               child: Center(
//                 child: Container(
//                   padding: const EdgeInsets.all(20.00),
//                   width: MediaQuery.of(context).size.width-40,
//                   height: MediaQuery.of(context).size.height/2,
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(10),
//                     color: Colors.white,
//                     boxShadow: const [
//                       BoxShadow(color: Colors.grey, spreadRadius: 1),
//                     ],
//                   ),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                      Icon(Icons.check_circle,color: Colors.green,size: 55,),
//                       const SizedBox(height: 40,),
//                       Text(message,style: const TextStyle(fontSize: 16),),
//                       const SizedBox(height: 40,),
//                       InkWell(
//                         onTap: (){
//                           Get.back();
//                           Get.back();
//                         },
//                         child: Container(
//                           height: 34,
//                           width: 110,
//                           margin: const EdgeInsets.only(bottom: 10),
//                           decoration: BoxDecoration(
//                             borderRadius: const BorderRadius.all(Radius.circular(5)),
//                             gradient: CustomColors.blueGradientColor,
//                           ),
//                           child: Center(child: buildText("Continue", 15.0, FontFamily.PoppinsRegular, CustomColors.txtwhiteColor)),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           );
//         });
//   }
//   showConfiramtionDialog(BuildContext context,String title,String message,String btnYes,String btnNo,VoidCallback onPressed){
//     showDialog(
//         context: context,
//         barrierDismissible: false,
//         // user must tap button for close dialog!
//         builder: (BuildContext context) {
//           var contexDialog = context;
//           return WillPopScope(
//             onWillPop: () async => false,
//             child: Dialog(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               elevation: 0,
//               insetPadding: EdgeInsets.all(20),
//               backgroundColor: Colors.transparent,
//               child: Center(
//                 child: Container(
//                   padding: const EdgeInsets.all(20.00),
//                   width: MediaQuery.of(context).size.width-60,
//                   height: MediaQuery.of(context).size.height/2,
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(10),
//                     color: Colors.white,
//                     boxShadow: const [
//                       BoxShadow(color: Colors.grey, spreadRadius: 1),
//                     ],
//                   ),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       Text(title,style: const TextStyle(fontSize: 20,color: Colors.black,fontWeight: FontWeight.w700),),
//                       const SizedBox(height: 40,),
//                       Text(message,style: const TextStyle(fontSize: 16),textAlign: TextAlign.center),
//                       const SizedBox(height: 40,),
//                       Row(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         mainAxisAlignment: btnNo.isNotEmpty ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
//                         children: [
//                           if(btnNo.isNotEmpty)
//                           InkWell(
//                             onTap: (){
//                               Get.back();
//                             },
//                             child: Container(
//                               height: 34,
//                               width: 110,
//                               margin: const EdgeInsets.only(bottom: 10),
//                               decoration: BoxDecoration(
//                                 borderRadius: const BorderRadius.all(Radius.circular(5)),
//                                 gradient: CustomColors.greyNegativeBtnGradientColor,
//                               ),
//                               child: Center(child: buildText(btnNo, 15.0, FontFamily.PoppinsRegular, CustomColors.txtwhiteColor)),
//                             ),
//                           ),
//                           InkWell(
//                             onTap: (){
//                               Get.back();
//                               onPressed();
//                             },
//                             child: Container(
//                               height: 34,
//                               width: 110,
//                               margin: const EdgeInsets.only(bottom: 10),
//                               decoration: BoxDecoration(
//                                 borderRadius: const BorderRadius.all(Radius.circular(5)),
//                                 gradient: CustomColors.blueGradientColor,
//                               ),
//                               child: Center(child: buildText(btnYes, 15.0, FontFamily.PoppinsRegular, CustomColors.txtwhiteColor)),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           );
//         });
//   }
// }