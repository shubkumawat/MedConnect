import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:digitalhealth/app/core/Util/AdditionalWidget/AdditionalWidget.dart';
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

          // ---- List View / Map View tab (wapas original wala) ----
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
                            Flexible(
                              child: Text(
                                'List View',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: !controller.showMap.value ? Colors.white : AppColors.textMuted,
                                  fontWeight: FontWeight.bold,
                                ),
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
                            Flexible(
                              child: Text(
                                'Map View',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: controller.showMap.value ? Colors.white : AppColors.textMuted,
                                  fontWeight: FontWeight.bold,
                                ),
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

          // ---- Specialization filter chips ----
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
                      color: controller.selectedSpecIndex.value == i
                          ? AppColors.teal
                          : AppColors.bgCardNavy,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: controller.selectedSpecIndex.value == i
                            ? AppColors.teal
                            : AppColors.border.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      spec.name,
                      style: TextStyle(
                        color: controller.selectedSpecIndex.value == i
                            ? Colors.white
                            : AppColors.textMuted,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          )),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${controller.hospitals.length} specialists nearby',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                ),
                GestureDetector(
                  onTap: () => _showSortSheet(),
                  child: Row(
                    children: const [
                      Icon(Icons.tune_rounded, size: 18, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text('Sort', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            )),
          ),
          const SizedBox(height: 12),

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
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: controller.hospitals.length,
        itemBuilder: (context, i) {
          final h = controller.hospitals[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _SpecialistCard(
              name: h.name,
              specialty: h.hospitalType ?? 'Specialist',
              subLabel: h.cityName ?? '',
              rating: h.averageRating,
              imageUrl: h.logoUrl,
              consultationFee: null, // TODO: model me field add karo
              isAvailableToday: true, // TODO: model me field add karo
              availabilityText: 'Available Today',
              onTap: () => Get.to(() => HospitalDetailView(hospitalId: h.hospitalId)),
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

      LatLng initialCenter = const LatLng(28.6139, 77.2090);
      if (controller.userPosition.value != null) {
        initialCenter = LatLng(controller.userPosition.value!.latitude, controller.userPosition.value!.longitude);
      } else if (markers.isNotEmpty) {
        initialCenter = markers.first.position;
      }

      return GoogleMap(
        initialCameraPosition: CameraPosition(target: initialCenter, zoom: 14),
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
        onMapCreated: (GoogleMapController c) => mapController = c,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: false,
        mapType: MapType.normal,
      );
    });
  }

  void _showSortSheet() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            ListTile(title: Text('Rating: High to Low')),
            ListTile(title: Text('Fee: Low to High')),
            ListTile(title: Text('Nearest First')),
          ],
        ),
      ),
    );
  }
}

// ---------------- Specialist Card ----------------
class _SpecialistCard extends StatelessWidget {
  final String name;
  final String specialty;
  final String subLabel;
  final String? rating;
  final String? imageUrl;
  final num? consultationFee;
  final bool isAvailableToday;
  final String availabilityText;
  final VoidCallback onTap;

  const _SpecialistCard({
    required this.name,
    required this.specialty,
    required this.subLabel,
    required this.rating,
    required this.imageUrl,
    required this.consultationFee,
    required this.isAvailableToday,
    required this.availabilityText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isAvailableToday ? AppColors.teal : const Color(0xFFF5A623);

    return GestureDetector(
      onTap: onTap,
      child: McCard(
        padding: EdgeInsets.zero,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: imageUrl != null
                            ? Image.network(imageUrl!, width: 64, height: 64, fit: BoxFit.cover)
                            : Container(
                          width: 64,
                          height: 64,
                          color: AppColors.bgDeepNavy,
                          child: const Icon(Icons.person_rounded, color: AppColors.teal, size: 32),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name + rating — name Expanded lekar rating ko push nahi hone deta
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    style: AppTextStyles.bodyBold.copyWith(fontSize: 16),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (rating != null) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 16),
                                  const SizedBox(width: 2),
                                  Text(rating!, style: AppTextStyles.captionBold),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),

                            // FIX: specialty pill fixed-size hai, subLabel ab Flexible+ellipsis
                            // hai isliye lamba naam aane par overflow nahi hoga
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.teal.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    specialty.toUpperCase(),
                                    style: const TextStyle(
                                      color: AppColors.tealDark,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                if (subLabel.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      '· $subLabel',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 10),

                            // FIX: fee block Flexible, badge ko bhi Flexible diya taaki
                            // dono milke row-width se zyada na le paayein
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(top: 6, right: 6),
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(color: borderColor, shape: BoxShape.circle),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('Consultation Fee',
                                              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                                          Text(
                                            consultationFee != null ? '\$${consultationFee.toString()}' : '—',
                                            style: AppTextStyles.bodyBold.copyWith(
                                              color: AppColors.primary,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Flexible(
                                //   child: Container(
                                //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                //     decoration: BoxDecoration(
                                //       color: isAvailableToday
                                //           ? AppColors.teal.withOpacity(0.15)
                                //           : AppColors.bgCardNavy,
                                //       borderRadius: BorderRadius.circular(20),
                                //     ),
                                //     child: Text(
                                //       availabilityText,
                                //       textAlign: TextAlign.center,
                                //       maxLines: 2,
                                //       overflow: TextOverflow.ellipsis,
                                //       style: TextStyle(
                                //         color: isAvailableToday ? AppColors.tealDark : AppColors.textMuted,
                                //         fontWeight: FontWeight.bold,
                                //         fontSize: 12,
                                //       ),
                                //     ),
                                //   ),
                                // ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}