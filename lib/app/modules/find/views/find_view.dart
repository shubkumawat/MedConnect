import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../core/widgets/healora_logo.dart';
import '../../../data/models/doctor_model.dart';
import '../controllers/find_controller.dart';
import 'hospital_detail_view.dart';

/// Care discovery dashboard:
/// Search doctor, clinic, or hospital anywhere (Google Places). No nearby list until search.
class FindScreen extends StatefulWidget {
  const FindScreen({super.key});

  @override
  State<FindScreen> createState() => _FindScreenState();
}

class _FindScreenState extends State<FindScreen> {
  final FindController controller = Get.put(FindController());
  final TextEditingController _searchCtrl = TextEditingController();
  final PageController _mapCardsPage = PageController();
  GoogleMapController? mapController;
  Worker? _userPosWorker;
  Worker? _searchQueryWorker;

  BitmapDescriptor? _hospitalMarker;
  BitmapDescriptor? _clinicMarker;
  BitmapDescriptor? _doctorMarker;

  static const double _myLocationZoom = 15;
  /// Matches Dashboard floating nav: height 90 + bottom margin 28.
  static const double _navClearance = 118;
  static const double _mapCardHeight = 148;

  @override
  void initState() {
    super.initState();
    _loadMarkerIcons();
    // Whenever location arrives (or map opens), keep camera on the user.
    _userPosWorker = ever(controller.userPosition, (_) => _goToMyLocation());
    _searchQueryWorker = ever(controller.searchQuery, (q) {
      if (_searchCtrl.text != q) {
        _searchCtrl.value = TextEditingValue(
          text: q,
          selection: TextSelection.collapsed(offset: q.length),
        );
      }
    });
  }

  Future<void> _goToMyLocation({double zoom = _myLocationZoom}) async {
    final p = controller.userPosition.value;
    final map = mapController;
    if (p == null || map == null) return;
    try {
      await map.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(p.latitude, p.longitude),
          zoom,
        ),
      );
    } catch (_) {
      // Map may be disposed during tab switch.
    }
  }

  Future<void> _loadMarkerIcons() async {
    final results = await Future.wait([
      _createCareMarkerIcon(
        Icons.local_hospital_rounded,
        AppColors.tealDark,
      ),
      _createCareMarkerIcon(
        Icons.medical_services_rounded,
        const Color(0xFFE67E22),
      ),
      _createCareMarkerIcon(
        Icons.person_rounded,
        const Color(0xFF2E86DE),
      ),
    ]);
    if (!mounted) return;
    setState(() {
      _hospitalMarker = results[0];
      _clinicMarker = results[1];
      _doctorMarker = results[2];
    });
  }

  BitmapDescriptor _markerFor(Hospital h) {
    switch (carePlaceKind(h)) {
      case CarePlaceKind.clinic:
        return _clinicMarker ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case CarePlaceKind.doctor:
        return _doctorMarker ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
      case CarePlaceKind.hospital:
        return _hospitalMarker ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose);
    }
  }

  @override
  void dispose() {
    _userPosWorker?.dispose();
    _searchQueryWorker?.dispose();
    _searchCtrl.dispose();
    _mapCardsPage.dispose();
    mapController?.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (controller.hasSearched.value) {
      await controller.submitSearch(controller.searchQuery.value);
    } else {
      await controller.locateUser(requestIfNeeded: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F5),
      body: Column(
        children: [
          _HeroHeader(
            topPad: top,
            searchController: _searchCtrl,
            onQueryChanged: (query) => controller.setSearch(query),
            onSubmitted: (query) => controller.submitSearch(query),
            onRefreshLocation: () =>
                controller.locateUser(requestIfNeeded: true),
          ),
          Expanded(
            child: _buildMapExperience(),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedRail() {
    return Obx(() {
      if (!controller.hasSearched.value || controller.isHospitalLoading.value) {
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      }
      final featured = controller.filteredHospitals
          .where((h) => h.isFeatured)
          .take(8)
          .toList();
      if (featured.isEmpty) {
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      }
      return SliverToBoxAdapter(
        child: _SpotlightRail(
          title: 'Top matches',
          hospitals: featured,
        ),
      );
    });
  }

  Widget _buildListSliver() {
    return Obx(() {
      if (controller.isHospitalLoading.value) {
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator(color: AppColors.teal)),
        );
      }
      if (!controller.hasSearched.value) {
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyState(
            hasLocation: true,
            searched: false,
            onRetry: null,
          ),
        );
      }
      final list = controller.filteredHospitals;
      if (list.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyState(
            hasLocation: true,
            searched: true,
            onRetry: () =>
                controller.submitSearch(controller.searchQuery.value),
          ),
        );
      }
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              final h = list[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _HospitalCard(
                  hospital: h,
                  onTap: () =>
                      Get.to(() => HospitalDetailView(hospitalId: h.hospitalId)),
                )
                    .animate()
                    .fadeIn(delay: (40 * (i % 8)).ms, duration: 320.ms)
                    .slideY(begin: 0.05, end: 0),
              );
            },
            childCount: list.length,
          ),
        ),
      );
    });
  }

  Widget _buildMapExperience() {
    return Obx(() {
      final list = controller.filteredHospitals;
      final withCoords = list
          .where((h) => h.latitude != null && h.longitude != null)
          .toList();

      final markers = withCoords.map((h) {
        final kind = carePlaceKind(h);
        return Marker(
          markerId: MarkerId(h.hospitalId),
          position: LatLng(double.parse(h.latitude!), double.parse(h.longitude!)),
          icon: _markerFor(h),
          infoWindow: InfoWindow(
            title: h.name,
            snippet: h.hospitalType.isNotEmpty
                ? h.hospitalType
                : carePlaceLabel(kind),
          ),
          onTap: () {
            final idx = withCoords.indexWhere((e) => e.hospitalId == h.hospitalId);
            if (idx >= 0 && _mapCardsPage.hasClients) {
              _mapCardsPage.animateToPage(
                idx,
                duration: 280.ms,
                curve: Curves.easeOutCubic,
              );
            }
          },
        );
      }).toSet();

      final pos = controller.userPosition.value;
      final LatLng center = pos != null
          ? LatLng(pos.latitude, pos.longitude)
          : (markers.isNotEmpty
              ? markers.first.position
              : const LatLng(28.6139, 77.2090));

      return Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              // Remount once location is known so camera starts on the user.
              key: ValueKey(pos == null ? 'map-waiting' : 'map-ready'),
              initialCameraPosition: CameraPosition(
                target: center,
                zoom: pos != null ? _myLocationZoom : 13.5,
              ),
              markers: {
                ...markers,
                if (pos != null)
                  Marker(
                    markerId: const MarkerId('user_location'),
                    position: LatLng(pos.latitude, pos.longitude),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueAzure,
                    ),
                    infoWindow: const InfoWindow(title: 'You are here'),
                  ),
              },
              onMapCreated: (c) {
                mapController = c;
                _goToMyLocation();
              },
              padding: const EdgeInsets.only(bottom: _navClearance),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
            ),
          ),
          Positioned(
            right: 16,
            bottom: (controller.hasSearched.value && withCoords.isNotEmpty)
                ? _navClearance + _mapCardHeight + 20
                : _navClearance + 16,
            child: Column(
              children: [
                _MapFab(
                  icon: Icons.my_location_rounded,
                  onTap: () async {
                    await controller.locateUser(requestIfNeeded: true);
                    await _goToMyLocation();
                  },
                ),
                const SizedBox(height: 10),
                _MapFab(
                  icon: Icons.refresh_rounded,
                  onTap: () {
                    if (controller.hasSearched.value) {
                      controller.submitSearch(controller.searchQuery.value);
                    } else {
                      controller.locateUser(requestIfNeeded: true);
                    }
                  },
                ),
              ],
            ),
          ),
          if (controller.isHospitalLoading.value)
            const Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.teal,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (controller.hasSearched.value && withCoords.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: _navClearance + 8,
              child: SizedBox(
                height: _mapCardHeight,
                child: PageView.builder(
                  controller: _mapCardsPage,
                  onPageChanged: (i) {
                    final h = withCoords[i];
                    if (h.latitude != null &&
                        h.longitude != null &&
                        mapController != null) {
                      mapController!.animateCamera(
                        CameraUpdate.newLatLng(
                          LatLng(
                            double.parse(h.latitude!),
                            double.parse(h.longitude!),
                          ),
                        ),
                      );
                    }
                  },
                  itemCount: withCoords.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _MapHospitalCard(
                      hospital: withCoords[i],
                      onTap: () => Get.to(
                        () => HospitalDetailView(
                          hospitalId: withCoords[i].hospitalId,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          else if (controller.hasSearched.value &&
              !controller.isHospitalLoading.value)
            Positioned(
              left: 20,
              right: 20,
              bottom: _navClearance + 8,
              child: _EmptyState(
                hasLocation: true,
                onRetry: () =>
                    controller.submitSearch(controller.searchQuery.value),
                compact: true,
              ),
            ),
        ],
      );
    });
  }

  void _showSortSheet() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Obx(() {
          final current = controller.sortMode.value;
          Widget tile(FindSortMode mode, String title, String subtitle, IconData icon) {
            final selected = current == mode;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.teal.withValues(alpha: 0.12)
                      : const Color(0xFFF3F7F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: selected ? AppColors.teal : AppColors.textGray),
              ),
              title: Text(title, style: AppTextStyles.bodyBold),
              subtitle: Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.textGray)),
              trailing: selected
                  ? const Icon(Icons.check_circle_rounded, color: AppColors.teal)
                  : null,
              onTap: () {
                controller.setSort(mode);
                Get.back();
              },
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text('Sort results', style: AppTextStyles.heading3),
              const SizedBox(height: 8),
              tile(FindSortMode.nearest, 'Nearest / Featured', 'Closest matches first', Icons.near_me_rounded),
              tile(FindSortMode.rating, 'Top rated', 'Highest rating first', Icons.star_rounded),
              tile(FindSortMode.reviews, 'Most reviewed', 'Most patient reviews', Icons.reviews_rounded),
              tile(FindSortMode.name, 'Name A–Z', 'Alphabetical', Icons.sort_by_alpha_rounded),
            ],
          );
        }),
      ),
    );
  }

  void _showSmartFiltersSheet() {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(Get.context!).size.height * 0.88,
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Obx(() {
            final cities = controller.availableCities;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text('Smart Filters', style: AppTextStyles.heading3),
                    ),
                    TextButton(
                      onPressed: controller.clearSmartFilters,
                      child: Text(
                        'Clear all',
                        style: AppTextStyles.tealLabel.copyWith(fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: ListView(
                    children: [
                      Text('Specialization', style: AppTextStyles.captionBold),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: controller.specializations.map((s) {
                          final sel =
                              controller.selectedSpecialties.contains(s.name);
                          return FilterChip(
                            label: Text(s.name),
                            selected: sel,
                            onSelected: (_) =>
                                controller.toggleSpecialtyFilter(s.name),
                            selectedColor:
                                AppColors.teal.withValues(alpha: 0.18),
                            checkmarkColor: AppColors.tealDark,
                            labelStyle: TextStyle(
                              color: sel
                                  ? AppColors.tealDark
                                  : AppColors.textMuted,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      Text('Location', style: AppTextStyles.captionBold),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _FilterChoice(
                              label: 'Near Me',
                              selected: controller.locationMode.value ==
                                  FindLocationMode.nearMe,
                              onTap: () => controller
                                  .setLocationMode(FindLocationMode.nearMe),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _FilterChoice(
                              label: 'City',
                              selected: controller.locationMode.value ==
                                  FindLocationMode.city,
                              onTap: () => controller
                                  .setLocationMode(FindLocationMode.city),
                            ),
                          ),
                        ],
                      ),
                      if (controller.locationMode.value ==
                          FindLocationMode.city) ...[
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: controller.selectedCity.value.isEmpty
                              ? null
                              : controller.selectedCity.value,
                          decoration: InputDecoration(
                            hintText: cities.isEmpty
                                ? 'No cities in results yet'
                                : 'Select city',
                            filled: true,
                            fillColor: const Color(0xFFF3F7F5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: cities
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ))
                              .toList(),
                          onChanged: cities.isEmpty
                              ? null
                              : controller.setSelectedCity,
                        ),
                      ],
                      const SizedBox(height: 18),
                      Text('Minimum rating', style: AppTextStyles.captionBold),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _FilterChoice(
                            label: 'Any',
                            selected: controller.minRating.value == null,
                            onTap: () => controller.setMinRating(null),
                          ),
                          ...FindController.ratingOptions.map((r) {
                            final label = '≥${r == r.roundToDouble() ? r.toInt() : r}';
                            return _FilterChoice(
                              label: label,
                              selected: controller.minRating.value == r,
                              onTap: () => controller.setMinRating(r),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text('Consultation type',
                          style: AppTextStyles.captionBold),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _FilterChoice(
                            label: 'Any',
                            selected: controller.consultationType.value.isEmpty,
                            onTap: () => controller.setConsultationType(''),
                          ),
                          ...FindController.consultationOptions.map((o) {
                            return _FilterChoice(
                              label: o['label']!,
                              selected: controller.consultationType.value ==
                                  o['value'],
                              onTap: () =>
                                  controller.setConsultationType(o['value']),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text('Gender preference',
                          style: AppTextStyles.captionBold),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: FindController.genderOptions.map((o) {
                          final selected =
                              controller.genderPreference.value == o['value'] ||
                                  (o['value'] == 'any' &&
                                      controller
                                          .genderPreference.value.isEmpty);
                          return _FilterChoice(
                            label: o['label']!,
                            selected: selected,
                            onTap: () => controller
                                .setGenderPreference(o['value'] == 'any' ? '' : o['value']),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      Text('Language', style: AppTextStyles.captionBold),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _FilterChoice(
                            label: 'Any',
                            selected:
                                controller.languagePreference.value.isEmpty,
                            onTap: () =>
                                controller.setLanguagePreference(''),
                          ),
                          ...FindController.languageOptions.map((lang) {
                            return _FilterChoice(
                              label: lang,
                              selected:
                                  controller.languagePreference.value == lang,
                              onTap: () =>
                                  controller.setLanguagePreference(lang),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.tealDark,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Show ${controller.filteredHospitals.length} results',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

class _FilterChoice extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.tealDark : const Color(0xFFF3F7F5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.tealDark : const Color(0xFFE3EBE7),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textMuted,
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HERO
// ═══════════════════════════════════════════════════════════════════════════

class _HeroHeader extends StatefulWidget {
  final double topPad;
  final TextEditingController searchController;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onRefreshLocation;

  const _HeroHeader({
    required this.topPad,
    required this.searchController,
    required this.onQueryChanged,
    required this.onSubmitted,
    required this.onRefreshLocation,
  });

  @override
  State<_HeroHeader> createState() => _HeroHeaderState();
}

class _HeroHeaderState extends State<_HeroHeader> {
  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(_onText);
  }

  void _onText() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_onText);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, widget.topPad + 10, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A5C45), Color(0xFF147A68), Color(0xFF1B9E8E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const HealoraLogo.chip(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Find Care',
                      style: AppTextStyles.heading3.copyWith(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Nearby doctor, clinic, or hospital',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: widget.onRefreshLocation,
                  borderRadius: BorderRadius.circular(12),
                  child: const SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(Icons.my_location_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 350.ms)
              .slideY(begin: -0.08, end: 0),
          const SizedBox(height: 16),
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: TextField(
              controller: widget.searchController,
              textInputAction: TextInputAction.search,
              onChanged: widget.onQueryChanged,
              onSubmitted: widget.onSubmitted,
              style: AppTextStyles.body.copyWith(color: AppColors.textDark),
              decoration: InputDecoration(
                hintText: 'Search nearby doctor, clinic, or hospital…',
                hintStyle: AppTextStyles.body.copyWith(color: AppColors.textGray),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.teal),
                suffixIcon: widget.searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          widget.searchController.clear();
                          widget.onQueryChanged('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 80.ms, duration: 400.ms)
              .slideY(begin: 0.1, end: 0),
        ],
      ),
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  final FindController controller;
  final VoidCallback onSort;
  final VoidCallback onFilters;
  const _ResultsHeader({
    required this.controller,
    required this.onSort,
    required this.onFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final count = controller.filteredHospitals.length;
      final filters = controller.activeFilterCount;
      return Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Search results', style: AppTextStyles.heading3),
                Text(
                  controller.isHospitalLoading.value
                      ? 'Searching…'
                      : controller.hasSearched.value
                          ? '$count ${count == 1 ? 'place' : 'places'} found'
                          : 'Search nearby doctor, clinic, or hospital',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textGray),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onFilters,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: filters > 0
                        ? AppColors.tealDark
                        : AppColors.teal.withValues(alpha: 0.25),
                  ),
                  color: filters > 0
                      ? AppColors.teal.withValues(alpha: 0.08)
                      : Colors.white,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.filter_list_rounded,
                        size: 16, color: AppColors.teal),
                    const SizedBox(width: 4),
                    Text(
                      filters > 0 ? 'Filters ($filters)' : 'Filters',
                      style: AppTextStyles.tealLabel.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onSort,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.teal.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tune_rounded, size: 16, color: AppColors.teal),
                    const SizedBox(width: 6),
                    Text(
                      controller.sortLabel,
                      style: AppTextStyles.tealLabel.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CARDS
// ═══════════════════════════════════════════════════════════════════════════

class _SpotlightRail extends StatelessWidget {
  final String title;
  final List<Hospital> hospitals;
  const _SpotlightRail({required this.title, required this.hospitals});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Text(title, style: AppTextStyles.heading3),
        ),
        SizedBox(
          height: 178,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: hospitals.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final h = hospitals[i];
              return _SpotlightCard(
                hospital: h,
                onTap: () =>
                    Get.to(() => HospitalDetailView(hospitalId: h.hospitalId)),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Text('Results', style: AppTextStyles.heading3),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _SpotlightCard extends StatelessWidget {
  final Hospital hospital;
  final VoidCallback onTap;
  const _SpotlightCard({required this.hospital, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rating = double.tryParse(hospital.averageRating) ?? 0;
    final cover = hospital.bannerUrl ?? hospital.logoUrl;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.tealDark.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (cover != null && cover.isNotEmpty)
                Image.network(
                  cover,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0A5C45), Color(0xFF1B9E8E)],
                      ),
                    ),
                  ),
                )
              else
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0A5C45), Color(0xFF1B9E8E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.75),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hospital.isFeatured || hospital.isVerified)
                      Row(
                        children: [
                          if (hospital.isFeatured)
                            _MiniBadge(label: 'FEATURED', color: AppColors.orange),
                          if (hospital.isFeatured && hospital.isVerified)
                            const SizedBox(width: 6),
                          if (hospital.isVerified)
                            const _MiniBadge(label: 'VERIFIED', color: AppColors.teal),
                        ],
                      ),
                    const SizedBox(height: 6),
                    Text(
                      hospital.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 15),
                        const SizedBox(width: 3),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            hospital.cityName.isNotEmpty
                                ? hospital.cityName
                                : hospital.hospitalType,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _HospitalCard extends StatelessWidget {
  final Hospital hospital;
  final VoidCallback onTap;
  const _HospitalCard({required this.hospital, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rating = double.tryParse(hospital.averageRating) ?? 0;
    final cover = hospital.bannerUrl ?? hospital.logoUrl;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.65)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                child: SizedBox(
                  height: 128,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (cover != null && cover.isNotEmpty)
                        Image.network(
                          cover,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _coverFallback(),
                        )
                      else
                        _coverFallback(),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.45),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Row(
                          children: [
                            if (hospital.isFeatured)
                              const _MiniBadge(label: 'FEATURED', color: AppColors.orange),
                            if (hospital.isFeatured && hospital.isVerified)
                              const SizedBox(width: 6),
                            if (hospital.isVerified)
                              const _MiniBadge(label: 'VERIFIED', color: AppColors.teal),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 14),
                              const SizedBox(width: 3),
                              Text(
                                rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
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
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hospital.name,
                      style: AppTextStyles.bodyBold.copyWith(fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    if (hospital.hospitalType.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.teal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              carePlaceIcon(carePlaceKind(hospital)),
                              size: 12,
                              color: AppColors.tealDark,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              hospital.hospitalType,
                              style: AppTextStyles.captionBold.copyWith(
                                color: AppColors.tealDark,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 14, color: AppColors.textGray.withValues(alpha: 0.9)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            [
                              if (hospital.cityName.isNotEmpty) hospital.cityName,
                              if (hospital.address.isNotEmpty) hospital.address,
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(color: AppColors.textGray),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          '${hospital.totalReviews} reviews',
                          style: AppTextStyles.caption.copyWith(color: AppColors.textGray),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0B6E4F), Color(0xFF1B9E8E)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Text(
                                'View details',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _coverFallback() {
    final kind = carePlaceKind(hospital);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A5C45), Color(0xFF1B9E8E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(carePlaceIcon(kind), color: Colors.white54, size: 42),
      ),
    );
  }
}

class _MapHospitalCard extends StatelessWidget {
  final Hospital hospital;
  final VoidCallback onTap;
  const _MapHospitalCard({required this.hospital, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rating = double.tryParse(hospital.averageRating) ?? 0;
    final cover = hospital.bannerUrl ?? hospital.logoUrl;
    final kind = carePlaceKind(hospital);
    final placeIcon = carePlaceIcon(kind);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 8,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
              child: SizedBox(
                width: 96,
                height: double.infinity,
                child: cover != null && cover.isNotEmpty
                    ? Image.network(
                        cover,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.teal.withValues(alpha: 0.15),
                          child: Icon(placeIcon, color: AppColors.teal),
                        ),
                      )
                    : Container(
                        color: AppColors.teal.withValues(alpha: 0.15),
                        child: Icon(placeIcon, color: AppColors.teal),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      hospital.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyBold.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hospital.hospitalType.isNotEmpty
                          ? hospital.hospitalType
                          : (hospital.cityName.isNotEmpty
                              ? hospital.cityName
                              : carePlaceLabel(kind)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(color: AppColors.textGray),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 15),
                        const SizedBox(width: 3),
                        Text(
                          rating.toStringAsFixed(1),
                          style: AppTextStyles.captionBold.copyWith(color: AppColors.textDark),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0B6E4F), Color(0xFF1B9E8E)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Details',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapFab extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapFab({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: AppColors.tealDark, size: 20),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasLocation;
  final VoidCallback? onRetry;
  final bool compact;
  final bool searched;
  const _EmptyState({
    required this.hasLocation,
    this.onRetry,
    this.compact = false,
    this.searched = true,
  });

  @override
  Widget build(BuildContext context) {
    final title = !searched
        ? 'Search to see results'
        : hasLocation
            ? 'No matching places'
            : 'Location needed';
    final subtitle = !searched
        ? 'Type a name and press search to see places near you.'
        : hasLocation
            ? 'No matching doctor, clinic, or hospital within 20 km.'
            : 'Enable location to see nearby results.';
    return Container(
      padding: EdgeInsets.all(compact ? 16 : 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            !searched
                ? Icons.search_rounded
                : hasLocation
                    ? Icons.local_hospital_outlined
                    : Icons.location_off_rounded,
            size: compact ? 36 : 48,
            color: AppColors.teal.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 12),
          Text(title, style: AppTextStyles.bodyBold),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(color: AppColors.textGray),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: AppColors.teal),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(searched ? 'Search again' : 'Search'),
            ),
          ],
        ],
      ),
    );
  }
}

enum CarePlaceKind { hospital, clinic, doctor }

CarePlaceKind carePlaceKind(Hospital h) {
  final t = '${h.hospitalType} ${h.name}'.toLowerCase();
  if (t.contains('clinic') ||
      t.contains('polyclinic') ||
      t.contains('dispensary') ||
      t.contains('nursing home')) {
    return CarePlaceKind.clinic;
  }
  if (t.contains('doctor') ||
      t.contains('physician') ||
      t.contains('practitioner') ||
      t.contains('dr ') ||
      t.contains('dr.')) {
    return CarePlaceKind.doctor;
  }
  return CarePlaceKind.hospital;
}

IconData carePlaceIcon(CarePlaceKind kind) {
  switch (kind) {
    case CarePlaceKind.clinic:
      return Icons.medical_services_rounded;
    case CarePlaceKind.doctor:
      return Icons.person_rounded;
    case CarePlaceKind.hospital:
      return Icons.local_hospital_rounded;
  }
}

String carePlaceLabel(CarePlaceKind kind) {
  switch (kind) {
    case CarePlaceKind.clinic:
      return 'Clinic';
    case CarePlaceKind.doctor:
      return 'Doctor';
    case CarePlaceKind.hospital:
      return 'Hospital';
  }
}

Future<BitmapDescriptor> _createCareMarkerIcon(
  IconData iconData,
  Color color,
) async {
  const double size = 72;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final center = const Offset(size / 2, size / 2 - 6);

  // Soft shadow
  canvas.drawCircle(
    center.translate(0, 2),
    22,
    Paint()..color = Colors.black.withValues(alpha: 0.18),
  );

  // Pin head
  canvas.drawCircle(center, 20, Paint()..color = color);
  canvas.drawCircle(center, 16, Paint()..color = Colors.white);

  // Pin tip
  final tip = Path()
    ..moveTo(size / 2 - 9, size / 2 + 10)
    ..lineTo(size / 2, size - 4)
    ..lineTo(size / 2 + 9, size / 2 + 10)
    ..close();
  canvas.drawPath(tip, Paint()..color = color);

  final textPainter = TextPainter(textDirection: TextDirection.ltr)
    ..text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: 18,
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        color: color,
      ),
    )
    ..layout();
  textPainter.paint(
    canvas,
    Offset(
      (size - textPainter.width) / 2,
      center.dy - textPainter.height / 2,
    ),
  );

  final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
}
