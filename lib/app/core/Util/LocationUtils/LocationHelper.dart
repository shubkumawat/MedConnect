// import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../Print/print_log.dart';

class LocationHelper {
  /// Request permission and get the current location with Google policy compliant rationale
  ///
  static Future<bool> showPermissionDialog(BuildContext context) async {
    final userAccepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on, size: 48, color: Colors.green),
              const SizedBox(height: 16),
              const Text(
                "Enable Location Access",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "To deliver your grocery items to the correct address, we need access to your current location.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.black87),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false), // Denied
                      child: const Text("No, Thanks"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(true), // Accepted
                      icon: const Icon(Icons.check_circle),
                      label: const Text("Allow"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // If user accepted, handle permission
    if (userAccepted == true) {
      await _handlePermissionRequest(context);
      return true;
    } else {
      return false;
    }
  }

  /// Show service not available dialog
  static Future<bool> showServiceNotAvailableDialog(BuildContext context, String currentPincode) async {
    final userChoice = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_off, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                "Service Not Available",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const SizedBox(height: 12),
              Text(
                "Sorry, our service is not available in your area (Pincode: $currentPincode).\n\nWe currently serve only pincode 302020.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false), // Continue with current location
                      child: const Text("Continue"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Expanded(
                  //   child: ElevatedButton.icon(
                  //     onPressed: () => Navigator.of(context).pop(true), // Change address
                  //     icon: const Icon(Icons.edit_location),
                  //     label: const Text("Change Address"),
                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor: Colors.blue,
                  //       foregroundColor: Colors.white,
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return userChoice ?? false;
  }

  /// Show address change dialog
  static Future<Position?> showAddressChangeDialog(BuildContext context) async {
    final TextEditingController addressController = TextEditingController();
    final TextEditingController pincodeController = TextEditingController();

    return await showDialog<Position?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.edit_location, size: 32, color: Colors.blue),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Change Address",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Address TextField
              const Text(
                "Enter Complete Address:",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: addressController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "House no, Street, Area, City...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.home),
                ),
              ),
              const SizedBox(height: 16),

              // Pincode TextField
              const Text(
                "Enter Pincode:",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: pincodeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "Enter 6-digit pincode",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.location_pin),
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        String address = addressController.text.trim();
                        String pincode = pincodeController.text.trim();

                        if (address.isEmpty || pincode.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please enter both address and pincode"),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        if (pincode.length != 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please enter a valid 6-digit pincode"),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // Check if new pincode is serviceable
                        if (!isPincodeServiceable(pincode)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Service not available for pincode: $pincode"),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // Convert address to coordinates
                        try {
                          Position? position = await getPositionFromAddress(address + ", $pincode");
                          if (position != null) {
                            Navigator.of(context).pop(position);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Could not find location for the given address"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Error: ${e.toString()}"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Confirm"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Convert address to Position
  static Future<Position?> getPositionFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        Location location = locations.first;
        return Position(
          latitude: location.latitude,
          longitude: location.longitude,
          timestamp: DateTime.now(),
          accuracy: 0.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
      }
      return null;
    } catch (e) {
      PrintLog.printLog("Error converting address to position: $e");
      return null;
    }
  }

  /// Check if pincode is serviceable
  static bool isPincodeServiceable(String pincode) {
    // Add your serviceable pincodes here
    // List<String> serviceablePincodes = ['302012'];
    List<String> serviceablePincodes = ['302020'];
    return serviceablePincodes.contains(pincode);
  }

  static Future<Position> getCurrentPosition(BuildContext context) async {
    PrintLog.printLog("Location Started");
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }
    PrintLog.printLog("Location Started1");
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      bool dataPermission = await showPermissionDialog(context);
      LocationPermission permission2 = await Geolocator.checkPermission();
      if (permission2 == LocationPermission.denied) {
        throw Exception(
          'Location permissions are permanently denied. Please enable it from app settings.',
        );
      } else {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        // Check pincode after getting location
        Position? finalPosition = await _checkPincodeServiceability(context, position);
        return finalPosition ?? position;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permissions are permanently denied. Please enable it from app settings.',
      );
    }

    PrintLog.printLog("Location Started3");
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Check pincode after getting location
    Position? finalPosition = await _checkPincodeServiceability(context, position);
    return finalPosition ?? position;
  }

  /// Check pincode serviceability after getting location
  static Future<Position?> _checkPincodeServiceability(BuildContext context, Position position) async {
    try {
      // Get pincode from coordinates
      String rawPincode = await getPincodeFromLatLng(position);
      String pincode = rawPincode.trim()/*"302020"*/;
      PrintLog.printLog("Current Pincode: $pincode");

      // Check if serviceable
      if (!isPincodeServiceable(pincode)) {
        // Show service not available dialog
        bool changeAddress = await showServiceNotAvailableDialog(context, pincode);

        if (changeAddress) {
          // Show address change dialog
          PrintLog.printLog("User wants to change address");
          Position? newPosition = await showAddressChangeDialog(context);

          if (newPosition != null) {
            // Verify new position pincode
            String newPincode = await getPincodeFromLatLng(newPosition);
            if (isPincodeServiceable(newPincode)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Address updated successfully!"),
                  backgroundColor: Colors.green,
                ),
              );
              return newPosition;
            }
          }

          return position; // Return original if change failed
        } else {
          // User wants to continue anyway
          PrintLog.printLog("User continues with non-serviceable area");
          return position;
        }
      } else {
        PrintLog.printLog("Service available in this area");
        return position;
      }
    } catch (e) {
      PrintLog.printLog("Error checking pincode serviceability: $e");
      return position;
    }
  }

  /// Get only pincode from coordinates
  static Future<String> getPincodeFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return place.postalCode ?? "NA";
      } else {
        return "NA";
      }
    } catch (e) {
      throw Exception('Failed to get pincode: $e');
    }
  }

  /// Convert coordinates into a full human-readable address
  static Future<String> getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return "${place.name}, ${place.street}, "
            "${place.subLocality}, ${place.locality}, "
            " ${place.postalCode}";
      } else {
        return "No address found";
      }
    } catch (e) {
      throw Exception('Failed to get address: $e');
    }
  }

  static Future<void> _handlePermissionRequest(BuildContext context) async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission granted.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission denied.")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permission already granted.")),
      );
    }
  }
}