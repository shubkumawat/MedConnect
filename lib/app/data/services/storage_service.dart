import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const isLogin = "isLogin";
  static const isIntro = "isIntro";
  static const usertype = "usertype";
  static const token = "token";
  static const userID = "userID";
  static const mobileNo = "mobileNo";
  static const email = "email";
  static const userName = "userName";
  static const accessType = "accessType";
  static const otpToken = "otpToken";
  static const userData = "userData";
  static const userProfile = "userProfile";
  static const kycStatus = "kycStatus";
  static const walletBalance = "walletBalance";

  // Reminder settings
  static const medReminders = "medReminders";
  static const vacReminders = "vacReminders";
  static const qrAlerts = "qrAlerts";

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

  Future<bool> getBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }

  Future<bool> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setBool(key, value);
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
}
