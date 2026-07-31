import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../data/models/doctor_model.dart';
import '../controllers/find_controller.dart';
import 'hospital_detail_view.dart';

/// Care discovery dashboard:
/// Search → specialty → list/map of nearby hospitals (API data unchanged).
class FindScreen extends StatefulWidget {
  const FindScreen({super.key});

  @override
  State<FindScreen> createState() => _FindScreenState();
}

class _FindScreenState extends State<FindScreen> {
  final FindController controller = Get.put(FindController());
  final TextEditingController _searchCtrl = TextEditingController();
  final PageController _mapCardsPage = PageController(viewportFraction: 0.88);
  GoogleMapController? mapController;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _mapCardsPage.dispose();
    mapController?.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await Future.wait([
      controller.fetchSpecializations(),
      controller.fetchHospitals(),
    ]);
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
            onSearch: (query) => controller.setSearch(query),
            onRefreshLocation: () => controller.fetchHospitals(),
          ),
          Expanded(
            child: Obx(() {
              if (controller.showMap.value) {
                return _buildMapExperience();
              }
              return RefreshIndicator(
                color: AppColors.teal,
                onRefresh: _refresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ViewToggle(controller: controller)
                                .animate()
                                .fadeIn(duration: 350.ms)
                                .slideY(begin: 0.06, end: 0),
                            const SizedBox(height: 18),
                            _SpecialtyStrip(controller: controller)
                                .animate()
                                .fadeIn(delay: 60.ms, duration: 350.ms),
                            const SizedBox(height: 18),
                            _ResultsHeader(
                              controller: controller,
                              onSort: _showSortSheet,
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                    _buildFeaturedRail(),
                    _buildListSliver(),
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedRail() {
    return Obx(() {
      if (controller.isHospitalLoading.value) {
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      }
      final featured = controller.filteredHospitals
          .where((h) => h.isFeatured)
          .take(8)
          .toList();
      if (featured.isEmpty) {
        // Fallback: top rated nearby as spotlight
        final list = controller.filteredHospitals.take(5).toList();
        if (list.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
        return SliverToBoxAdapter(
          child: _SpotlightRail(
            title: 'Top nearby',
            hospitals: list,
          ),
        );
      }
      return SliverToBoxAdapter(
        child: _SpotlightRail(
          title: 'Featured care',
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
      final list = controller.filteredHospitals;
      if (list.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyState(
            hasLocation: controller.userPosition.value != null,
            onRetry: () => controller.fetchHospitals(),
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
        return Marker(
          markerId: MarkerId(h.hospitalId),
          position: LatLng(double.parse(h.latitude!), double.parse(h.longitude!)),
          infoWindow: InfoWindow(title: h.name, snippet: h.hospitalType),
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

      LatLng center = const LatLng(28.6139, 77.2090);
      if (controller.userPosition.value != null) {
        center = LatLng(
          controller.userPosition.value!.latitude,
          controller.userPosition.value!.longitude,
        );
      } else if (markers.isNotEmpty) {
        center = markers.first.position;
      }

      return Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: center, zoom: 13.5),
              markers: {
                ...markers,
                if (controller.userPosition.value != null)
                  Marker(
                    markerId: const MarkerId('user_location'),
                    position: LatLng(
                      controller.userPosition.value!.latitude,
                      controller.userPosition.value!.longitude,
                    ),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueAzure,
                    ),
                    infoWindow: const InfoWindow(title: 'You are here'),
                  ),
              },
              onMapCreated: (c) => mapController = c,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
            ),
          ),
          // Floating controls over map
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Column(
              children: [
                _ViewToggle(controller: controller),
                const SizedBox(height: 10),
                _SpecialtyStrip(controller: controller, compact: true),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: withCoords.isEmpty ? 24 : 200,
            child: Column(
              children: [
                _MapFab(
                  icon: Icons.my_location_rounded,
                  onTap: () async {
                    await controller.fetchHospitals();
                    final p = controller.userPosition.value;
                    if (p != null && mapController != null) {
                      mapController!.animateCamera(
                        CameraUpdate.newLatLngZoom(
                          LatLng(p.latitude, p.longitude),
                          14,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 10),
                _MapFab(
                  icon: Icons.refresh_rounded,
                  onTap: () => controller.fetchHospitals(),
                ),
              ],
            ),
          ),
          if (controller.isHospitalLoading.value)
            const Positioned(
              top: 120,
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
          if (withCoords.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 100,
              child: SizedBox(
                height: 148,
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
                    padding: const EdgeInsets.symmetric(horizontal: 6),
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
          else if (!controller.isHospitalLoading.value)
            Positioned(
              left: 20,
              right: 20,
              bottom: 110,
              child: _EmptyState(
                hasLocation: controller.userPosition.value != null,
                onRetry: () => controller.fetchHospitals(),
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
              tile(FindSortMode.nearest, 'Nearest / Featured', 'Best nearby matches first', Icons.near_me_rounded),
              tile(FindSortMode.rating, 'Top rated', 'Highest rating first', Icons.star_rounded),
              tile(FindSortMode.reviews, 'Most reviewed', 'Most patient reviews', Icons.reviews_rounded),
              tile(FindSortMode.name, 'Name A–Z', 'Alphabetical', Icons.sort_by_alpha_rounded),
            ],
          );
        }),
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
  final ValueChanged<String> onSearch;
  final VoidCallback onRefreshLocation;

  const _HeroHeader({
    required this.topPad,
    required this.searchController,
    required this.onSearch,
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
              Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  'assets/logo/ic_logo_icon.png',
                  fit: BoxFit.contain,
                ),
              ),
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
                      'Hospitals & clinics near you',
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
              onChanged: widget.onSearch,
              style: AppTextStyles.body.copyWith(color: AppColors.textDark),
              decoration: InputDecoration(
                hintText: 'Search hospital, city, specialty…',
                hintStyle: AppTextStyles.body.copyWith(color: AppColors.textGray),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.teal),
                suffixIcon: widget.searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          widget.searchController.clear();
                          widget.onSearch('');
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

// ═══════════════════════════════════════════════════════════════════════════
// TOGGLE / CHIPS / HEADERS
// ═══════════════════════════════════════════════════════════════════════════

class _ViewToggle extends StatelessWidget {
  final FindController controller;
  const _ViewToggle({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final map = controller.showMap.value;
      return Container(
        height: 46,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
          boxShadow: [
            BoxShadow(
              color: AppColors.teal.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _toggleBtn(
              label: 'List',
              icon: Icons.view_agenda_rounded,
              active: !map,
              onTap: () => controller.showMap.value = false,
            ),
            _toggleBtn(
              label: 'Map',
              icon: Icons.map_rounded,
              active: map,
              onTap: () => controller.showMap.value = true,
            ),
          ],
        ),
      );
    });
  }

  Widget _toggleBtn({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: 200.ms,
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(
                    colors: [Color(0xFF0B6E4F), Color(0xFF1B9E8E)],
                  )
                : null,
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: active ? Colors.white : AppColors.textGray),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpecialtyStrip extends StatelessWidget {
  final FindController controller;
  final bool compact;
  const _SpecialtyStrip({required this.controller, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.specializations.isEmpty) {
        return const SizedBox(
          height: 36,
          child: Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal),
            ),
          ),
        );
      }
      final labels = ['All', ...controller.specializations.map((e) => e.name)];
      final selected = controller.selectedSpecIndex.value;

      return SizedBox(
        height: compact ? 36 : 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: labels.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final active = selected == i;
            return GestureDetector(
              onTap: () => controller.selectSpecialty(i),
              child: AnimatedContainer(
                duration: 200.ms,
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 12 : 14,
                  vertical: compact ? 7 : 9,
                ),
                decoration: BoxDecoration(
                  color: active ? AppColors.tealDark : (compact ? Colors.white : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active
                        ? Colors.transparent
                        : AppColors.border.withValues(alpha: 0.9),
                  ),
                  boxShadow: compact
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  labels[i],
                  style: AppTextStyles.captionBold.copyWith(
                    color: active ? Colors.white : AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }
}

class _ResultsHeader extends StatelessWidget {
  final FindController controller;
  final VoidCallback onSort;
  const _ResultsHeader({required this.controller, required this.onSort});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final count = controller.filteredHospitals.length;
      return Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nearby care', style: AppTextStyles.heading3),
                Text(
                  controller.isHospitalLoading.value
                      ? 'Locating hospitals…'
                      : '$count ${count == 1 ? 'place' : 'places'} found',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textGray),
                ),
              ],
            ),
          ),
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
          child: Text('All nearby', style: AppTextStyles.heading3),
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
                        child: Text(
                          hospital.hospitalType,
                          style: AppTextStyles.captionBold.copyWith(
                            color: AppColors.tealDark,
                            fontSize: 11,
                          ),
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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A5C45), Color(0xFF1B9E8E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.local_hospital_rounded, color: Colors.white54, size: 42),
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
                          child: const Icon(Icons.local_hospital_rounded, color: AppColors.teal),
                        ),
                      )
                    : Container(
                        color: AppColors.teal.withValues(alpha: 0.15),
                        child: const Icon(Icons.local_hospital_rounded, color: AppColors.teal),
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
                          : (hospital.cityName.isNotEmpty ? hospital.cityName : 'Hospital'),
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
  final VoidCallback onRetry;
  final bool compact;
  const _EmptyState({
    required this.hasLocation,
    required this.onRetry,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
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
            hasLocation ? Icons.local_hospital_outlined : Icons.location_off_rounded,
            size: compact ? 36 : 48,
            color: AppColors.teal.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 12),
          Text(
            hasLocation ? 'No matching places' : 'Location needed',
            style: AppTextStyles.bodyBold,
          ),
          const SizedBox(height: 6),
          Text(
            hasLocation
                ? 'Try another specialty or clear your search.'
                : 'Enable location to discover care near you.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(color: AppColors.textGray),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: AppColors.teal),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(hasLocation ? 'Refresh' : 'Enable & search'),
          ),
        ],
      ),
    );
  }
}
