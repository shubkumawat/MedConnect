import 'package:dio/dio.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:digitalhealth/app/core/Util/CustomLoading/custom_loading.dart';
import 'package:digitalhealth/app/core/Util/Print/print_log.dart';
import 'web_api_constant.dart';




class ApiProvider {
  Dio _dio = new Dio();

  Map<String, String> headers = {
    "Content-type": "application/json",
    // "Authorization": 'Bearer $authToken',
  };
  String authKey = "DREAD*RK&Y&*T9KeykhfdiT";


  // Future<DepositResponse?> loadwalleRazorPay(context,String token,Map<String, dynamic> dict) async {
  //   DepositResponse? result;
  //   if(await ConnectionValidator().check()){
  //     try{
  //       CustomLoading().show(context);
  //       final Response? response = await requestPostForApi(context, WebApiConstant.API_URL_RAZORPAY_DEPOSIT, dict, token);
  //       log("loadwalletresponse: ${response?.data}");
  //       if(response != null && response.statusCode == 200){
  //         result = DepositResponse.fromJson(response.data);
  //       }
  //       CustomLoading().hide(context);
  //       return result;
  //     }catch(e){
  //       CustomLoading().hide(context);
  //       PrintLog.printLog("Exception..........$e.........");
  //       Fluttertoast.showToast(msg: "Something went wrong");
  //       return result;
  //     }
  //   }else{
  //     CustomLoading().hide(context);
  //     // Navigator.pushNamed(context, networkErrorScreenRoute);
  //     // Fluttertoast.showToast( msg: 'Please check network connection and try again !');
  //   }
  //   return null;
  // }


    Future<Map<String, dynamic>?> loginApi(context, String url, Map<String, dynamic> dictParameter, String token) async {
    Map<String, dynamic>? result;
    // if(await ConnectionValidator().check()){
      try{
       CustomLoading().show(context);
        final Response? response = await requestPostForApi(context, url, dictParameter, token);

        if(response != null && response.statusCode == 200){
          result = Map<String, dynamic>.from(response.data);
        }
       CustomLoading().hide(context);
        return result;
      }catch(e){
        CustomLoading().hide(context);
        PrintLog.printLog("Exception..........$e.........");
        Fluttertoast.showToast(msg: "Something went wrong");
        return result;
      }
    //}
    // else{
    //  CustomLoading().hide(context);
    //   // Navigator.pushNamed(context, networkErrorScreenRoute);
    //   Fluttertoast.showToast( msg: 'Please check network connection and try again !');
    // }
    return null;
  }
  Future<Map<String, dynamic>?> getPatientProfileAPI(context, String url, Map<String, dynamic> dictParameter, String token) async {
    Map<String, dynamic>? result;
    try {
      CustomLoading().show(context);
      final Response? response = await requestGetForApi(context, url, dictParameter, token);

      if (response != null && (response.statusCode == 200 || response.statusCode == 201)) {
        result = Map<String, dynamic>.from(response.data);
      }
      CustomLoading().hide(context);
      return result;
    } catch (e) {
      CustomLoading().hide(context);
      PrintLog.printLog("Exception getPatientProfileAPI..........$e.........");
      return result;
    }
  }

  Future<Map<String, dynamic>?> updateFamilyMemberAPI(context, String url, Map<String, dynamic> dictParameter, String token) async {
    Map<String, dynamic>? result;
    try {
      CustomLoading().show(context);
      final Response? response = await requestPostForApi(context, url, dictParameter, token);

      if (response != null && response.statusCode == 200) {
        result = Map<String, dynamic>.from(response.data);
      }
      CustomLoading().hide(context);
      return result;
    } catch (e) {
      CustomLoading().hide(context);
      PrintLog.printLog("Exception updateFamilyMemberAPI: $e");
      Fluttertoast.showToast(msg: "Something went wrong");
      return result;
    }
  }

  Future<Map<String, dynamic>?> addFamilyMemberMultipartAPI(context, String url, dynamic formData, String token) async {
    Map<String, dynamic>? result;
    try {
      CustomLoading().show(context);
      final Response? response = await requestMultipartApi(context, url, formData, token);

      if (response != null && (response.statusCode == 200 || response.statusCode == 201)) {
        result = Map<String, dynamic>.from(response.data);
      }
      CustomLoading().hide(context);
      return result;
    } catch (e) {
      CustomLoading().hide(context);
      PrintLog.printLog("Exception addFamilyMemberMultipartAPI: $e");
      Fluttertoast.showToast(msg: "Something went wrong");
      return result;
    }
  }

  Future<Map<String, dynamic>?> getFamilyMemberListAPI(context, String url, Map<String, dynamic> dictParameter, String token) async {
    Map<String, dynamic>? result;
    try {
      CustomLoading().show(context);
      final Response? response = await requestGetForApi(context, url, dictParameter, token);

      if (response != null && (response.statusCode == 200 || response.statusCode == 201)) {
        result = Map<String, dynamic>.from(response.data);
      }
      CustomLoading().hide(context);
      return result;
    } catch (e) {
      CustomLoading().hide(context);
      PrintLog.printLog("Exception GetFamilyList..........$e.........");
      return result;
    }
  }

    Future<Map<String, dynamic>?> updateMedicalApi(context, String url, Map<String, dynamic> dictParameter, String token) async {
    Map<String, dynamic>? result;
    // if(await ConnectionValidator().check()){
      try{
       CustomLoading().show(context);
        final Response? response = await requestPostForApi(context, url, dictParameter, token);

        if(response != null && response.statusCode == 200){
          result = Map<String, dynamic>.from(response.data);
        }
       CustomLoading().hide(context);
        return result;
      }catch(e){
        CustomLoading().hide(context);
        PrintLog.printLog("Exception..........$e.........");
        Fluttertoast.showToast(msg: "Something went wrong");
        return result;
      }
    //}
    // else{
    //  CustomLoading().hide(context);
    //   // Navigator.pushNamed(context, networkErrorScreenRoute);
    //   Fluttertoast.showToast( msg: 'Please check network connection and try again !');
    // }
    return null;
  }

  // Future<Map<String, dynamic>?> getFamilyMemberListAPI(context, String url, Map<String, dynamic> dictParameter, String token) async {
  //   Map<String, dynamic>? result;
  //   try {
  //     CustomLoading().show(context);
  //     final Response? response = await requestGetForApi(context, url, dictParameter, token);
  //
  //     if (response != null && (response.statusCode == 200 || response.statusCode == 201)) {
  //       result = Map<String, dynamic>.from(response.data);
  //     }
  //     CustomLoading().hide(context);
  //     return result;
  //   } catch (e) {
  //     CustomLoading().hide(context);
  //     PrintLog.printLog("Exception GetFamilyList..........$e.........");
  //     return result;
  //   }
  // }

    Future<Map<String, dynamic>?> updateEmergencyAPI(context, String url, Map<String, dynamic> dictParameter, String token) async {
    Map<String, dynamic>? result;
    // if(await ConnectionValidator().check()){
      try{
       CustomLoading().show(context);
        final Response? response = await requestPostForApi(context, url, dictParameter, token);

        if(response != null && response.statusCode == 200){
          result = Map<String, dynamic>.from(response.data);
        }
       CustomLoading().hide(context);
        return result;
      }catch(e){
        CustomLoading().hide(context);
        PrintLog.printLog("Exception..........$e.........");
        Fluttertoast.showToast(msg: "Something went wrong");
        return result;
      }
    //}
    // else{
    //  CustomLoading().hide(context);
    //   // Navigator.pushNamed(context, networkErrorScreenRoute);
    //   Fluttertoast.showToast( msg: 'Please check network connection and try again !');
    // }
    return null;
  }

  // Future<Map<String, dynamic>?> getFamilyMemberListAPI(context, String url, Map<String, dynamic> dictParameter, String token) async {
  //   Map<String, dynamic>? result;
  //   try {
  //     CustomLoading().show(context);
  //     final Response? response = await requestGetForApi(context, url, dictParameter, token);
  //
  //     if (response != null && (response.statusCode == 200 || response.statusCode == 201)) {
  //       result = Map<String, dynamic>.from(response.data);
  //     }
  //     CustomLoading().hide(context);
  //     return result;
  //   } catch (e) {
  //     CustomLoading().hide(context);
  //     PrintLog.printLog("Exception GetFamilyList..........$e.........");
  //     return result;
  //   }
  // }

    Future<Map<String, dynamic>?> updateProfileApi(context, String url, Map<String, dynamic> dictParameter, String token) async {
    Map<String, dynamic>? result;
    // if(await ConnectionValidator().check()){
      try{
       CustomLoading().show(context);
        final Response? response = await requestPostForApi(context, url, dictParameter, token);

        if(response != null && response.statusCode == 200){
          result = Map<String, dynamic>.from(response.data);
        }
       CustomLoading().hide(context);
        return result;
      }catch(e){
        CustomLoading().hide(context);
        PrintLog.printLog("Exception..........$e.........");
        Fluttertoast.showToast(msg: "Something went wrong");
        return result;
      }
    //}
    // else{
    //  CustomLoading().hide(context);
    //   // Navigator.pushNamed(context, networkErrorScreenRoute);
    //   Fluttertoast.showToast( msg: 'Please check network connection and try again !');
    // }
    return null;
  }

  // Future<Map<String, dynamic>?> getFamilyMemberListAPI(context, String url, Map<String, dynamic> dictParameter, String token) async {
  //   Map<String, dynamic>? result;
  //   try {
  //     CustomLoading().show(context);
  //     final Response? response = await requestGetForApi(context, url, dictParameter, token);
  //
  //     if (response != null && (response.statusCode == 200 || response.statusCode == 201)) {
  //       result = Map<String, dynamic>.from(response.data);
  //     }
  //     CustomLoading().hide(context);
  //     return result;
  //   } catch (e) {
  //     CustomLoading().hide(context);
  //     PrintLog.printLog("Exception GetFamilyList..........$e.........");
  //     return result;
  //   }
  // }

      Future<Map<String, dynamic>?> getAllMasterDataAPI(context, String url, Map<String, dynamic> dictParameter, String token) async {
    Map<String, dynamic>? result;
    try {
      CustomLoading().show(context);
      final Response? response = await requestGetForApi(context, url, dictParameter, token);

      if (response != null && (response.statusCode == 200 || response.statusCode == 201)) {
        result = Map<String, dynamic>.from(response.data);
      }
      CustomLoading().hide(context);
      return result;
    } catch (e) {
      CustomLoading().hide(context);
      PrintLog.printLog("Exception getAllMasterDataAPI..........$e.........");
      return result;
    }
  }

  Future<Map<String, dynamic>?> getMasterRelationAPI(context, String url, Map<String, dynamic> dictParameter, String token) async {
    Map<String, dynamic>? result;
      try{
       CustomLoading().show(context);
        final Response? response = await requestGetForApi(context, url, dictParameter, token);

        if(response != null && (response.statusCode == 200 || response.statusCode == 201)){
          result = Map<String, dynamic>.from(response.data);
        }
       CustomLoading().hide(context);
        return result;
      }catch(e){
        CustomLoading().hide(context);
        PrintLog.printLog("Exception..........$e.........");
        return result;
      }
    return null;
  }

  Future<Map<String, dynamic>?> getMasterCountryAPI(context, String url, Map<String, dynamic> dictParameter, String token) async {
    Map<String, dynamic>? result;
    // if(await ConnectionValidator().check()){
      try{
       CustomLoading().show(context);
        final Response? response = await requestGetForApi(context, url, dictParameter, token);

        if(response != null && response.statusCode == 200){
          result = Map<String, dynamic>.from(response.data);
        }
       CustomLoading().hide(context);
        return result;
      }catch(e){
        CustomLoading().hide(context);
        PrintLog.printLog("Exception..........$e.........");
        Fluttertoast.showToast(msg: "Something went wrong");
        return result;
      }
    //}
    // else{
    //  CustomLoading().hide(context);
    //   // Navigator.pushNamed(context, networkErrorScreenRoute);
    //   Fluttertoast.showToast( msg: 'Please check network connection and try again !');
    // }
    return null;
  }

  Future<Map<String, dynamic>?> getMasterOccupationAPI(context, String url, Map<String, dynamic> dictParameter, String token) async {
    Map<String, dynamic>? result;
    try {
      CustomLoading().show(context);
      final Response? response = await requestGetForApi(context, url, dictParameter, token);

      if (response != null && (response.statusCode == 200 || response.statusCode == 201)) {
        result = Map<String, dynamic>.from(response.data);
      }
      CustomLoading().hide(context);
      return result;
    } catch (e) {
      CustomLoading().hide(context);
      PrintLog.printLog("Exception getMasterOccupationAPI..........$e.........");
      return result;
    }
  }

  Future<Map<String, dynamic>?> getMasterDisabilityTypeAPI(context, String url, Map<String, dynamic> dictParameter, String token) async {
    Map<String, dynamic>? result;
    try {
      CustomLoading().show(context);
      final Response? response = await requestGetForApi(context, url, dictParameter, token);

      if (response != null && (response.statusCode == 200 || response.statusCode == 201)) {
        result = Map<String, dynamic>.from(response.data);
      }
      CustomLoading().hide(context);
      return result;
    } catch (e) {
      CustomLoading().hide(context);
      PrintLog.printLog("Exception getMasterDisabilityTypeAPI..........$e.........");
      return result;
    }
  }

  Future<Map<String, dynamic>?> deleteFamilyMemberAPI(context, String url, String token) async {
    Map<String, dynamic>? result;
    try {
      CustomLoading().show(context);
      final Response? response = await requestDeleteForApi(context, url, token);
      if (response != null && (response.statusCode == 200 || response.statusCode == 204)) {
        result = Map<String, dynamic>.from(response.data);
      }
      CustomLoading().hide(context);
      return result;
    } catch (e) {
      CustomLoading().hide(context);
      PrintLog.printLog("Exception deleteFamilyMemberAPI: $e");
      return result;
    }
  }

  Future<Map<String, dynamic>?> updateAccessControlAPI(context, String url, Map<String, dynamic> dictParameter, String token) async {
    Map<String, dynamic>? result;
    try {
      CustomLoading().show(context);
      final Response? response = await requestPostForApi(context, url, dictParameter, token);
      if (response != null && response.statusCode == 200) {
        result = Map<String, dynamic>.from(response.data);
      }
      CustomLoading().hide(context);
      return result;
    } catch (e) {
      CustomLoading().hide(context);
      PrintLog.printLog("Exception updateAccessControlAPI: $e");
      return result;
    }
  }

  // Future<Map<String, dynamic>?> getFamilyMemberListAPI(context, String url, Map<String, dynamic> dictParameter, String token) async {
  //   Map<String, dynamic>? result;
  //   try {
  //     CustomLoading().show(context);
  //     final Response? response = await requestGetForApi(context, url, dictParameter, token);
  //
  //     if (response != null && (response.statusCode == 200 || response.statusCode == 201)) {
  //       result = Map<String, dynamic>.from(response.data);
  //     }
  //     CustomLoading().hide(context);
  //     return result;
  //   } catch (e) {
  //     CustomLoading().hide(context);
  //     PrintLog.printLog("Exception GetFamilyList..........$e.........");
  //     return result;
  //   }
  // }

  //
  // Future<Map<String, dynamic>?> getAddress(context,String token) async {
  //   Map<String, dynamic>? result;
  //   try{
  //     Map<String, dynamic> dictParameter = {
  //     };
  //     CustomLoading().show(context);
  //     final Response? response = await requestGetForApi(context, WebApiConstant.API_URL_GET_ADDRESS, dictParameter, token);
  //     PrintLog.printLog("ResponseNew..........$response.........");
  //     if(response != null && response.statusCode == 200){
  //       result = Map<String, dynamic>.from(response.data);
  //     }
  //     CustomLoading().hide(context);
  //     return result;
  //   }catch(e){
  //     CustomLoading().hide(context);
  //     PrintLog.printLog("Exception..........$e.........");
  //     Fluttertoast.showToast(msg: "Something went wrong");
  //     return result;
  //
  //     return null;
  //   }}
  // Future<Map<String, dynamic>?> buyNowApi(context, String url, Map<String, dynamic> dictParameter, String token) async {
  //   Map<String, dynamic>? result;
  //   // if(await ConnectionValidator().check()){
  //   try{
  //     CustomLoading().show(context);
  //     final Response? response = await requestPostForApi(context, url, dictParameter, token);
  //
  //     if(response != null && response.statusCode == 200){
  //       result = Map<String, dynamic>.from(response.data);
  //     }
  //     CustomLoading().hide(context);
  //
  //     return result;
  //   }catch(e) {
  //     PrintLog.printLog("Exception..........$e.........");
  //     Fluttertoast.showToast(msg: "Something went wrong");
  //     return result;
  //   }
  // }


  // Future<Map<String, dynamic>?> updateTPinApi(context, String url, Map<String, dynamic> dictParameter, String token) async {
  //   Map<String, dynamic>? result;
  //      try{
  //       //CustomLoading().show(context);
  //       final Response? response = await requestPostForApi(context, url, dictParameter, token);
  //
  //       if(response != null && response.statusCode == 200){
  //         result = Map<String, dynamic>.from(response.data);
  //       }
  //       CustomLoading().hide(context);
  //       return result;
  //     }catch(e){
  //       CustomLoading().hide(context);
  //       PrintLog.printLog("Exception..........$e.........");
  //       Fluttertoast.showToast(msg: "Something went wrong");
  //       return result;
  //     }
  // }



  // Future<Map<String, dynamic>?> registerApi(context, String url, Map<String, dynamic> dictParameter, String token) async {
  //   Map<String, dynamic>? result;
  //  // if(await ConnectionValidator().check()){
  //     try{
  //       CustomLoading().show(context);
  //       final Response? response = await requestPostForApi(context, url, dictParameter, token);
  //
  //       if(response != null && response.statusCode == 200){
  //         result = Map<String, dynamic>.from(response.data);
  //       }
  //       CustomLoading().hide(context);
  //       return result;
  //     }catch(e){
  //       CustomLoading().hide(context);
  //       PrintLog.printLog("Exception..........$e.........");
  //       Fluttertoast.showToast(msg: "Something went wrong");
  //       return result;
  //     }
  //  // }
  //   // else{
  //   //   CustomLoading().hide(context);
  //   //   // Navigator.pushNamed(context, networkErrorScreenRoute);
  //   //   // Fluttertoast.showToast( msg: 'Please check network connection and try again !');
  //   // }
  //   return null;
  // }





  Future<Map<String, dynamic>?> videoLikeAPI(context, String videoId, String token) async {
    Map<String, dynamic>? result;
    try {
      final Response? response = await requestPostForApi(context, "videos/$videoId/like/", {}, token);
      if (response != null && response.statusCode == 200) {
        result = Map<String, dynamic>.from(response.data);
      }
      return result;
    } catch (e) {
      PrintLog.printLog("Exception videoLikeAPI: $e");
      return result;
    }
  }

  Future<Map<String, dynamic>?> videoUnlikeAPI(context, String videoId, String token) async {
    Map<String, dynamic>? result;
    try {
      final Response? response = await requestPostForApi(context, "videos/$videoId/unlike/", {}, token);
      if (response != null && response.statusCode == 200) {
        result = Map<String, dynamic>.from(response.data);
      }
      return result;
    } catch (e) {
      PrintLog.printLog("Exception videoUnlikeAPI: $e");
      return result;
    }
  }

  Future<Map<String, dynamic>?> videoBookmarkAPI(context, String videoId, String token) async {
    Map<String, dynamic>? result;
    try {
      final Response? response = await requestPostForApi(context, "videos/$videoId/bookmark/", {}, token);
      if (response != null && response.statusCode == 200) {
        result = Map<String, dynamic>.from(response.data);
      }
      return result;
    } catch (e) {
      PrintLog.printLog("Exception videoBookmarkAPI: $e");
      return result;
    }
  }

  Future<Map<String, dynamic>?> videoRemoveBookmarkAPI(context, String videoId, String token) async {
    Map<String, dynamic>? result;
    try {
      final Response? response = await requestDeleteForApi(context, "videos/$videoId/bookmark/", token);
      if (response != null && response.statusCode == 200) {
        result = Map<String, dynamic>.from(response.data);
      }
      return result;
    } catch (e) {
      PrintLog.printLog("Exception videoRemoveBookmarkAPI: $e");
      return result;
    }
  }

  Future<Map<String, dynamic>?> videoShareAPI(context, String videoId, String platform, String token) async {
    Map<String, dynamic>? result;
    try {
      final Response? response = await requestPostForApi(context, "videos/$videoId/share/", {"platform": platform}, token);
      if (response != null && response.statusCode == 200) {
        result = Map<String, dynamic>.from(response.data);
      }
      return result;
    } catch (e) {
      PrintLog.printLog("Exception videoShareAPI: $e");
      return result;
    }
  }

  Future<Map<String, dynamic>?> videoProgressAPI(context, String videoId, Map<String, dynamic> data, String token) async {
    Map<String, dynamic>? result;
    try {
      final Response? response = await requestPostForApi(context, "videos/$videoId/progress/", data, token);
      if (response != null && response.statusCode == 200) {
        result = Map<String, dynamic>.from(response.data);
      }
      return result;
    } catch (e) {
      PrintLog.printLog("Exception videoProgressAPI: $e");
      return result;
    }
  }

  Future<Map<String, dynamic>?> videoCompleteAPI(context, String videoId, String device, String token) async {
    Map<String, dynamic>? result;
    try {
      final Response? response = await requestPostForApi(context, "videos/$videoId/complete/", {"device": device}, token);
      if (response != null && response.statusCode == 200) {
        result = Map<String, dynamic>.from(response.data);
      }
      return result;
    } catch (e) {
      PrintLog.printLog("Exception videoCompleteAPI: $e");
      return result;
    }
  }

  Future<Map<String, dynamic>?> videoReportAPI(context, String videoId, String reason, String comment, String token) async {
    Map<String, dynamic>? result;
    try {
      final Response? response = await requestPostForApi(context, "videos/$videoId/report/", {"reason": reason, "comment": comment}, token);
      if (response != null && response.statusCode == 200) {
        result = Map<String, dynamic>.from(response.data);
      }
      return result;
    } catch (e) {
      PrintLog.printLog("Exception videoReportAPI: $e");
      return result;
    }
  }

  Future<Map<String, dynamic>?> getContinueWatchingAPI(context, String token) async {
    Map<String, dynamic>? result;
    try {
      final Response? response = await requestGetForApi(context, WebApiConstant.API_URL_VIDEO_CONTINUE_WATCHING, {}, token);
      if (response != null && response.statusCode == 200) {
        result = Map<String, dynamic>.from(response.data);
      }
      return result;
    } catch (e) {
      PrintLog.printLog("Exception getContinueWatchingAPI: $e");
      return result;
    }
  }

  Future<Map<String, dynamic>?> getSavedVideosAPI(context, String token) async {
    Map<String, dynamic>? result;
    try {
      final Response? response = await requestGetForApi(context, WebApiConstant.API_URL_VIDEO_SAVED, {}, token);
      if (response != null && response.statusCode == 200) {
        result = Map<String, dynamic>.from(response.data);
      }
      return result;
    } catch (e) {
      PrintLog.printLog("Exception getSavedVideosAPI: $e");
      return result;
    }
  }

  Future<Map<String, dynamic>?> getVideoHistoryAPI(context, String token) async {
    Map<String, dynamic>? result;
    try {
      final Response? response = await requestGetForApi(context, WebApiConstant.API_URL_VIDEO_HISTORY, {}, token);
      if (response != null && response.statusCode == 200) {
        result = Map<String, dynamic>.from(response.data);
      }
      return result;
    } catch (e) {
      PrintLog.printLog("Exception getVideoHistoryAPI: $e");
      return result;
    }
  }

  Future<Map<String, dynamic>?> getSpecializationsAPI(context, String token) async {
    Map<String, dynamic>? result;
    try {
      final Response? response = await requestGetForApi(context, WebApiConstant.API_URL_DOCTOR_SPECIALIZATIONS, {}, token);
      if (response != null && response.statusCode == 200) {
        result = Map<String, dynamic>.from(response.data);
      }
      return result;
    } catch (e) {
      PrintLog.printLog("Exception getSpecializationsAPI: $e");
      return result;
    }
  }

  Future<Map<String, dynamic>?> getNearbyDoctorsAPI(context, double lat, double lng, String token) async {
    Map<String, dynamic>? result;
    try {
      final Response? response = await requestGetForApi(
        context,
        WebApiConstant.API_URL_DOCTOR_NEARBY,
        {"lat": lat, "lng": lng},
        token,
      );
      if (response != null && response.statusCode == 200) {
        result = Map<String, dynamic>.from(response.data);
      }
      return result;
    } catch (e) {
      PrintLog.printLog("Exception getNearbyDoctorsAPI: $e");
      return result;
    }
  }

  Future<Map<String, dynamic>?> getHospitalsAPI(context, String token) async {
    Map<String, dynamic>? result;
    try {
      final Response? response = await requestGetForApi(context, WebApiConstant.API_URL_HOSPITALS, {}, token);
      if (response != null && response.statusCode == 200) {
        result = Map<String, dynamic>.from(response.data);
      }
      return result;
    } catch (e) {
      PrintLog.printLog("Exception getHospitalsAPI: $e");
      return result;
    }
  }

  Future<Map<String, dynamic>?> getHospitalDetailAPI(context, String hospitalId, String token) async {
    Map<String, dynamic>? result;
    try {
      final Response? response = await requestGetForApi(context, "${WebApiConstant.API_URL_HOSPITAL_DETAIL}$hospitalId/", {}, token);
      if (response != null && response.statusCode == 200) {
        result = Map<String, dynamic>.from(response.data);
      }
      return result;
    } catch (e) {
      PrintLog.printLog("Exception getHospitalDetailAPI: $e");
      return result;
    }
  }

  Future<Map<String, dynamic>?> postReviewAPI(context, String url, Map<String, dynamic> dictParameter, String token) async {
    Map<String, dynamic>? result;
    try {
      final Response? response = await requestPostForApi(context, url, dictParameter, token);
      if (response != null && (response.statusCode == 200 || response.statusCode == 201)) {
        result = Map<String, dynamic>.from(response.data);
      }
      return result;
    } catch (e) {
      PrintLog.printLog("Exception postReviewAPI: $e");
      return result;
    }
  }

  Future<Map<String, dynamic>?> getVideoTopicsAPI(context, String url, Map<String, dynamic> dictParameter, String token) async {
    Map<String, dynamic>? result;
    try {
      final Response? response = await requestGetForApi(context, url, dictParameter, token);
      if (response != null && response.statusCode == 200) {
        result = Map<String, dynamic>.from(response.data);
      }
      return result;
    } catch (e) {
      PrintLog.printLog("Exception getVideoTopicsAPI: $e");
      return result;
    }
  }

  Future<Map<String, dynamic>?> getVideosAPI(context, String url, Map<String, dynamic> dictParameter, String token) async {
    Map<String, dynamic>? result;
    try {
      final Response? response = await requestGetForApi(context, url, dictParameter, token);
      if (response != null && response.statusCode == 200) {
        result = Map<String, dynamic>.from(response.data);
      }
      return result;
    } catch (e) {
      PrintLog.printLog("Exception getVideosAPI: $e");
      return result;
    }
  }

  Future<Map<String, dynamic>?> giveAccessAPI(context, String url, Map<String, dynamic> dictParameter, String token) async {
    Map<String, dynamic>? result;
    try {
      CustomLoading().show(context);
      final Response? response = await requestPostForApi(context, url, dictParameter, token);

      if (response != null && (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 400)) {
        result = Map<String, dynamic>.from(response.data);
      }
      CustomLoading().hide(context);
      return result;
    } catch (e) {
      CustomLoading().hide(context);
      PrintLog.printLog("Exception giveAccessAPI: $e");
      return result;
    }
  }

  Future<Response?> requestGetForApi(context, String url, Map<String, dynamic> dictParameter,String token) async {
    try {
      Map<String, String> headers = {
        "Content-type": "application/json",
        "Authkey": authKey
      };
      if (token.isNotEmpty) {
        headers["Authorization"] = "Bearer $token";
      }

      PrintLog.printLog("Headers: $headers");
      PrintLog.printLog("Url:  $url");
      PrintLog.printLog("Token:  $token");
      PrintLog.printLog("DictParameter: $dictParameter");

      BaseOptions options = BaseOptions(
          baseUrl: WebApiConstant.BASE_URL,
          receiveTimeout: Duration(seconds: 30),
          connectTimeout: Duration(seconds: 30),
          headers: headers);

      _dio.options = options;
      dictParameter['demo'] = true;
      
      Response response = await _dio.get(
        url, 
        queryParameters: dictParameter,
        options: Options(
          validateStatus: (status) => (status ?? 0) < 500, // 401 ko allow karega
        ),
      );
      
      PrintLog.printLog("Response Status Code: ${response.statusCode}");
      Map<String, dynamic>? result = Map<String, dynamic>.from(response.data);
      
      if(response.statusCode == 401 || result["errorCode"] == 7){
        PrintLog.printLog("Session Expired or Unauthorized");
        return response;
      } else {
        return response;
      }
    } catch (error) {
      PrintLog.printLog("Exception_Main: $error");
      return null;
    }
  }
  Future<Response?> requestGetsForApi(context, String url, Map<String, dynamic> dictParameter,String token) async {
    try {
      Map<String, String> headers = {
        "Content-type": "application/json",
        "Authkey": authKey
      };
      if (token.isNotEmpty) {
        headers["Authorization"] = "Bearer $token";
      }

      PrintLog.printLog("Headers: $headers");
      PrintLog.printLog("Url:  $url");
      PrintLog.printLog("Token:  $token");
      PrintLog.printLog("DictParameter: $dictParameter");

      // Create a new Dio instance without baseUrl for this request
      Dio dio = Dio(BaseOptions(
          receiveTimeout: Duration(seconds: 30),
          connectTimeout: Duration(seconds: 30),
          headers: headers));

      dictParameter['demo'] = true;

      // Use full URL directly
      Response response = await dio.get(url, queryParameters: dictParameter);

      PrintLog.printLog("Response111: $response");
      PrintLog.printLog("Response_headers1: ${response.headers}");

      Map<String, dynamic>? result = Map<String, dynamic>.from(response.data);
      if(result["errorCode"] == 7){
        PrintLog.printLog("authentication failed");
        return response;
      } else {
        return response;
      }
    } catch (error) {
      PrintLog.printLog("Exception_Main: $error");
      return null;
    }
  }

  Future<Response?> requestPostForApi(context, String url, Map<String, dynamic> dictParameter,String token) async {
    try{
      Map<String, String> headers = {
        "Content-type": "application/json",
        "Authkey": authKey
      };
      if (token.isNotEmpty) {
        headers["Authorization"] = "Bearer $token";
      }
      dictParameter["versionNew"] = 1;
      PrintLog.printLog("Headers: $headers");
      PrintLog.printLog("Url:  $url");
      PrintLog.printLog("Token:  $token");
      PrintLog.printLog("DictParameter: $dictParameter");

      BaseOptions options = BaseOptions(
          baseUrl: WebApiConstant.BASE_URL,
          receiveTimeout: Duration(seconds: 30),
          connectTimeout: Duration(seconds: 30),
          headers: headers);
      _dio.options = options;
      Response response = await _dio.post(url+"?demo=true", data: dictParameter, options: Options(
          followRedirects: false,
          validateStatus: (status) =>true,
          headers: headers
      ));
      PrintLog.printLog("Response21: ${response.data}");
      PrintLog.printLog("Response1: ${response.data["errorCode"]}");
      PrintLog.printLog("Response_headers: ${response.headers}");
      PrintLog.printLog("Response_realuri: ${response.realUri}");
      // if(response.data != null && response.data["status"] == "error"){
      //   response.data["data"] = null;
      //   return response;
      // }else {

      Map<String, dynamic>? result  = Map<String, dynamic>.from(response.data);
      if(result["errorCode"] == 7){
        PrintLog.printLog("authintacktion fiald");
        // onLogout();
        return response;
      }else {
        return response;
      }
      // }
    }catch(error){
      PrintLog.printLog("Exception_Main: $error");
      return null;
    }
  }

  Future<Response?> requestMultipartApi(context, String url,formData,String token) async{
    try{
      Map<String, String> headers = {
        "Authkey": "$authKey"
      };
      if (token.isNotEmpty) {
        headers["Authorization"] = "Bearer $token";
      }

      PrintLog.printLog("Headers: $headers");
      PrintLog.printLog("Url:  $url");
      PrintLog.printLog("Token:  $token");
      PrintLog.printLog("formData: $formData");

      BaseOptions options = BaseOptions(
          baseUrl: WebApiConstant.BASE_URL,
          receiveTimeout: Duration(seconds: 30),
          connectTimeout: Duration(seconds: 30),
          headers: headers);

      _dio.options = options;
      Response response = await _dio.post(url,
          data: formData,
          options: Options(
            followRedirects: false,
            validateStatus: (status) => true,
            headers: headers,
          ));

      PrintLog.printLog("Response: $response");

      return response;

    }catch(error){
      PrintLog.printLog("Exception_Main: $error");
      return null;
    }
  }

  Future<Response?> requestDeleteForApi(context, String url, String token) async {
    try {
      Map<String, String> headers = {
        "Content-type": "application/json",
        "Authkey": authKey
      };
      if (token.isNotEmpty) {
        headers["Authorization"] = "Bearer $token";
      }
      
      PrintLog.printLog("Headers: $headers");
      PrintLog.printLog("Url:  $url");
      PrintLog.printLog("Token:  $token");

      BaseOptions options = BaseOptions(
          baseUrl: WebApiConstant.BASE_URL,
          receiveTimeout: Duration(seconds: 30),
          connectTimeout: Duration(seconds: 30),
          headers: headers);
      _dio.options = options;

      Response response = await _dio.delete(
        url,
        options: Options(
          followRedirects: false,
          validateStatus: (status) => (status ?? 0) < 500,
          headers: headers,
        ),
      );
      PrintLog.printLog("DELETE [$url]: ${response.statusCode}");
      return response;
    } catch (e) {
      PrintLog.printLog("Exception_Delete: $e");
      return null;
    }
  }

}
