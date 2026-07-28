// import 'package:geocoding/geocoding.dart';
// import 'package:geolocator/geolocator.dart';

class LocationsUtils {
  Future<Map<String,dynamic>> getCurrentLocation() async {
    Map<String,dynamic> currentLocation = {};
    // String _address = '';
    // Position _position;
    // bool serviceEnabled;
    // LocationPermission permission;
    //
    // // Check if location services are enabled
    // serviceEnabled = await Geolocator.isLocationServiceEnabled();
    // if (!serviceEnabled) {
    //   _address = 'Location services are disabled.';
    //   currentLocation = {
    //     "address":_address,
    //     "lat":0,
    //     "lng":0,
    //   };
    //   return currentLocation;
    // }
    //
    // // Check for location permission
    // permission = await Geolocator.checkPermission();
    // if (permission == LocationPermission.denied) {
    //   permission = await Geolocator.requestPermission();
    //   if (permission == LocationPermission.denied) {
    //     _address = 'Location permissions are denied';
    //     currentLocation = {
    //       "address":_address,
    //       "lat":0,
    //       "lng":0,
    //     };
    //     return currentLocation;
    //   }
    // }
    //
    // if (permission == LocationPermission.deniedForever) {
    //   _address =
    //   'Location permissions are permanently denied, we cannot request permissions.';
    //   currentLocation = {
    //     "address":_address,
    //     "lat":0,
    //     "lng":0,
    //   };
    //   return currentLocation;
    // }
    //
    // // Get current position
    // Position position = await Geolocator.getCurrentPosition(
    //     desiredAccuracy: LocationAccuracy.high);
    //
    // _position = position;
    //
    // // Get address from coordinates
    // List<Placemark> placemarks =
    // await placemarkFromCoordinates(position.latitude, position.longitude);
    //
    // Placemark place = placemarks[0];
    // _address =
    // '${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}';
    //
    // currentLocation = {
    //   "address":_address,
    //   "lat":_position.latitude,
    //   "lng":_position.longitude,
    // };
    return currentLocation;

  }
}
