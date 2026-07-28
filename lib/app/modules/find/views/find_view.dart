import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:digitalhealth/app/core/Util/AdditionalWidget/AdditionalWidget.dart';
import 'package:digitalhealth/app/core/Util/CustomButton/CustomButton.dart';
import 'package:digitalhealth/app/core/Util/CustomCardWidgets/CustomCardWidgets.dart';
import 'package:digitalhealth/app/core/Util/CustomTextField/CustomTextField.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../controllers/find_controller.dart';
import 'hospital_detail_view.dart';

class FindScreen extends StatefulWidget {
  const FindScreen({super.key});
  @override
  State<FindScreen> createState() => _FindScreenState();
}

class _FindScreenState extends State<FindScreen> {
  final FindController controller = Get.put(FindController());
  GoogleMapController? mapController;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    controller.fetchHospitals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.tealDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Find Doctor',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: McSearchBar(hint: 'Search doctor, specialty, hospital...'),
          ),
          const SizedBox(height: 16),
          // Map/List Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 45,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.bgCardNavy,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Obx(() => Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => controller.showMap.value = false,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: !controller.showMap.value ? AppColors.teal : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.list_rounded, 
                                  size: 18, 
                                  color: !controller.showMap.value ? Colors.white : AppColors.textMuted),
                                const SizedBox(width: 8),
                                Text(
                                  'List View',
                                  style: TextStyle(
                                    color: !controller.showMap.value ? Colors.white : AppColors.textMuted,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => controller.showMap.value = true,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: controller.showMap.value ? AppColors.teal : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.map_rounded, 
                                  size: 18, 
                                  color: controller.showMap.value ? Colors.white : AppColors.textMuted),
                                const SizedBox(width: 8),
                                Text(
                                  'Map View',
                                  style: TextStyle(
                                    color: controller.showMap.value ? Colors.white : AppColors.textMuted,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  )),
            ),
          ),
          const SizedBox(height: 16),
          // Spec filter
          Obx(() => SizedBox(
                height: 38,
                child: controller.isLoading.value
                    ? const Center(child: LinearProgressIndicator())
                    : ListView.builder(
                        padding: const EdgeInsets.only(left: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: controller.specializations.length,
                        itemBuilder: (_, i) {
                          final spec = controller.specializations[i];
                          return GestureDetector(
                            onTap: () => controller.selectedSpecIndex.value = i,
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: controller.selectedSpecIndex.value == i ? AppColors.teal : AppColors.bgCardNavy,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: controller.selectedSpecIndex.value == i ? AppColors.teal : AppColors.border.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                spec.name,
                                style: TextStyle(
                                  color: controller.selectedSpecIndex.value == i ? Colors.white : AppColors.textMuted,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              )),
          const SizedBox(height: 20),
          Expanded(
            child: Obx(() {
              if (controller.showMap.value) {
                return _buildMapView();
              } else {
                return _buildListView();
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return Obx(() {
      if (controller.isHospitalLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.hospitals.isEmpty) {
        return const Center(child: Text("No hospitals found"));
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: controller.hospitals.length,
        itemBuilder: (context, i) {
          final h = controller.hospitals[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: McCard(
              onTap: () => Get.to(() => HospitalDetailView(hospitalId: h.hospitalId)),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.bgDeepNavy,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: h.logoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(h.logoUrl!, fit: BoxFit.cover),
                          )
                        : const Icon(Icons.business_rounded, color: AppColors.teal, size: 40),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(h.hospitalId, style: AppTextStyles.bodyBold.copyWith(fontSize: 17)),
                        Text(h.name, style: AppTextStyles.bodyBold.copyWith(fontSize: 17)),
                        const SizedBox(height: 4),
                        Text('${h.hospitalType} · ${h.cityName}', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 16),
                            const SizedBox(width: 4),
                            Text(h.averageRating, style: AppTextStyles.captionBold),
                            const SizedBox(width: 12),
                            const Icon(Icons.location_on_rounded, color: AppColors.teal, size: 16),
                            const SizedBox(width: 4),
                            Text('Nearby', style: AppTextStyles.caption),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 18),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildMapView() {
    return Obx(() {
      final markers = controller.hospitals.where((h) => h.latitude != null && h.longitude != null).map((h) {
        return Marker(
          markerId: MarkerId(h.hospitalId),
          position: LatLng(double.parse(h.latitude!), double.parse(h.longitude!)),
          infoWindow: InfoWindow(
            title: h.name,
            snippet: h.hospitalType,
            onTap: () => Get.to(() => HospitalDetailView(hospitalId: h.hospitalId)),
          ),
        );
      }).toSet();

      LatLng initialCenter = const LatLng(28.6139, 77.2090); // Default (New Delhi)
      if (controller.userPosition.value != null) {
        initialCenter = LatLng(controller.userPosition.value!.latitude, controller.userPosition.value!.longitude);
      } else if (markers.isNotEmpty) {
        initialCenter = markers.first.position;
      }

      return GoogleMap(
        initialCameraPosition: CameraPosition(
          target: initialCenter,
          zoom: 14,
        ),
        markers: {
          ...markers,
          if (controller.userPosition.value != null)
            Marker(
              markerId: const MarkerId('user_location'),
              position: LatLng(controller.userPosition.value!.latitude, controller.userPosition.value!.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
              infoWindow: const InfoWindow(title: 'Your Location'),
            ),
        },
        onMapCreated: (GoogleMapController c) {
          mapController = c;
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: false,
        mapType: MapType.normal,
      );
    });
  }
}
