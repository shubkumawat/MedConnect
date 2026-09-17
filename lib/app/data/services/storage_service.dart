import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {

  static const isLogin = "isLogin";
  static const isIntro = "isIntro";
  /// User finished the post-splash location gate (granted or skipped).
  static const locationPromptSkipped = "locationPromptSkipped";
  /// New-user finished Personal → Medical → Emergency (or skipped remaining).
  static const profileSetupDone = "profileSetupDone";
  static const usertype = "usertype";
  static const token = "token";
  static const userID = "userID";
  static const mobileNo = "mobileNo";
  static const email = "email";
  static const userName = "userName";
  static const accessType = "accessType";
  /// Currently selected Health Passport patient (self or family member).
  static const selectedPatientId = "selectedPatientId";
  static const otpToken = "otpToken";
  static const userData = "userData";
  static const userProfile = "userProfile";
  static const kycStatus = "kycStatus";
  static const walletBalance = "walletBalance";
  static const fcmToken = "fcmToken";
  /// Stable local device id for care-reminders API.
  static const deviceId = "deviceId";

  // Reminder settings
  static const medReminders = "medReminders";
  static const vacReminders = "vacReminders";
  static const qrAlerts = "qrAlerts";
  static const recordingConsentAsked = "recordingConsentAsked";
  static const recordingConsentAllowed = "recordingConsentAllowed";
  static const upcomingApptPopupDate = "upcomingApptPopupDate";

  /// Hospital / clinic IDs the current user has already reviewed.
  static const reviewedPlaceIds = "reviewedPlaceIds";

  // Address related keys
  static const savedAddresses = "savedAddresses";
  static const selectedAddress = "selectedAddress";
  static const lastAddress = "lastAddress";
  static const lastPincode = "lastPincode";
  static const lastLatitude = "lastLatitude";
  static const lastLongitude = "lastLongitude";

  // Static variables to store selected address globally
  static String currentSelectedAddress = "";
  static String currentSelectedAddressName = "";
  static String currentSelectedMobile = "";
  static String currentSelectedPincode = "";
  static double? currentSelectedLatitude;
  static double? currentSelectedLongitude;

  Future<String> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key) ?? "";
  }

  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? defaultValue;
  }

  Future<bool> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setBool(key, value);
  }

  /// Stable id for device-scoped notification prefs (care-reminders).
  Future<String> getOrCreateDeviceId() async {
    final existing = await getString(deviceId);
    if (existing.isNotEmpty) return existing;

    final fcm = await getString(fcmToken);
    final id = (fcm.isNotEmpty)
        ? 'fcm-${fcm.length > 24 ? fcm.substring(0, 24) : fcm}'
        : 'device-${DateTime.now().millisecondsSinceEpoch}';
    await setString(deviceId, id);
    return id;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<bool> setUserDetails(Map<String, dynamic> dictData) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(userProfile, json.encode(dictData));
    return true;
  }

  Future<bool> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(key, value);
    return true;
  }

  Future<bool> setDouble(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setDouble(key, value);
  }

  Future<double?> getDouble(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(key);
  }

  // Save list of addresses
  Future<bool> saveAddressesList(List<Map<String, dynamic>> addresses) async {
    final prefs = await SharedPreferences.getInstance();
    String jsonString = json.encode(addresses);
    return await prefs.setString(savedAddresses, jsonString);
  }

  // Get list of addresses
  Future<List<Map<String, dynamic>>> getAddressesList() async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString(savedAddresses);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    List<dynamic> decoded = json.decode(jsonString);
    return decoded.cast<Map<String, dynamic>>();
  }

  // Save selected address
  Future<bool> saveSelectedAddress(
      String name,
      String mobile,
      String address,
      String pincode,
      double? latitude,
      double? longitude,
      ) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> selectedAddr = {
      'name': name,
      'mobile': mobile,
      'address': address,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
    };

    currentSelectedAddress = address;
    currentSelectedAddressName = name;
    currentSelectedMobile = mobile;
    currentSelectedPincode = pincode;
    currentSelectedLatitude = latitude;
    currentSelectedLongitude = longitude;

    await prefs.setString(lastAddress, address);
    await prefs.setString(lastPincode, pincode);
    if (latitude != null) await prefs.setDouble(lastLatitude, latitude);
    if (longitude != null) await prefs.setDouble(lastLongitude, longitude);

    return await prefs.setString(selectedAddress, json.encode(selectedAddr));
  }

  Future<Map<String, dynamic>> getSelectedAddress() async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString(selectedAddress);
    if (jsonString == null || jsonString.isEmpty) return {};
    Map<String, dynamic> decoded = json.decode(jsonString);

    currentSelectedAddress = decoded['address'] ?? "";
    currentSelectedAddressName = decoded['name'] ?? "";
    currentSelectedMobile = decoded['mobile'] ?? "";
    currentSelectedPincode = decoded['pincode'] ?? "";

    if (decoded['latitude'] != null) {
      currentSelectedLatitude = (decoded['latitude'] as num).toDouble();
    }
    if (decoded['longitude'] != null) {
      currentSelectedLongitude = (decoded['longitude'] as num).toDouble();
    }

    return decoded;
  }

  Future<bool> clearSelectedAddress() async {
    final prefs = await SharedPreferences.getInstance();
    currentSelectedAddress = "";
    currentSelectedAddressName = "";
    currentSelectedMobile = "";
    currentSelectedPincode = "";
    currentSelectedLatitude = null;
    currentSelectedLongitude = null;

    await prefs.remove(lastLatitude);
    await prefs.remove(lastLongitude);
    return await prefs.remove(selectedAddress);
  }

  Future<List<String>> getReviewedPlaceIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(reviewedPlaceIds) ?? <String>[];
  }

  Future<bool> hasReviewedPlace(String placeId) async {
    final id = placeId.trim();
    if (id.isEmpty) return false;
    final ids = await getReviewedPlaceIds();
    return ids.contains(id);
  }

  Future<void> markPlaceReviewed(String placeId) async {
    final id = placeId.trim();
    if (id.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(reviewedPlaceIds) ?? <String>[];
    if (ids.contains(id)) return;
    ids.add(id);
    await prefs.setStringList(reviewedPlaceIds, ids);
  }
}
