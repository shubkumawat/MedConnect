import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../Colors/colors.dart';
import '../Font/font_family.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Ek hi text field jisme left side mein tappable country code (flag)
/// hota hai aur usi field ke andar right side mein phone number type hota hai.
/// Do alag boxes ki jagah — ek unified look.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:healora/app/core/theme/app_colors.dart';

/// Ek hi text field jisme left side mein tappable country code (flag)
/// hota hai aur usi field ke andar right side mein phone number type hota hai.
/// Do alag boxes ki jagah — ek unified look.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:healora/app/core/theme/app_colors.dart';

/// Ek hi text field jisme left side mein tappable country code (flag)
/// hota hai aur usi field ke andar right side mein phone number type hota hai.
/// Do alag boxes ki jagah — ek unified look.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:healora/app/core/theme/app_colors.dart';

/// Ek hi text field jisme left side mein tappable country code (flag)
/// hota hai aur usi field ke andar right side mein phone number type hota hai.
/// Do alag boxes ki jagah — ek unified look.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:healora/app/core/theme/app_colors.dart';

/// Ek hi text field jisme left side mein tappable country code (flag)
/// hota hai aur usi field ke andar right side mein phone number type hota hai.
/// Do alag boxes ki jagah — ek unified look.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:healora/app/core/theme/app_colors.dart';

/// Ek hi text field jisme left side mein tappable country code (flag)
/// hota hai aur usi field ke andar right side mein phone number type hota hai.
/// Do alag boxes ki jagah — ek unified look.
class PhoneInputWithCountry<T> extends StatefulWidget {
  final List<T> items;
  final T? value;
  final String Function(T)? itemLabel;
  final Widget Function(T)? selectedItemBuilder;
  final String Function(T)? countryName; // 🔑 dropdown me naam dikhane ke liye
  final ValueChanged<T?> onCountryChanged;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final String hint;
  final bool isCountryLoading;

  const PhoneInputWithCountry({
    super.key,
    required this.items,
    required this.onCountryChanged,
    required this.controller,
    this.value,
    this.itemLabel,
    this.selectedItemBuilder,
    this.countryName,
    this.keyboardType = TextInputType.phone,
    this.inputFormatters,
    this.maxLength,
    this.hint = 'Mobile number',
    this.isCountryLoading = false,
  });

  @override
  State<PhoneInputWithCountry<T>> createState() => _PhoneInputWithCountryState<T>();
}

class _PhoneInputWithCountryState<T> extends State<PhoneInputWithCountry<T>> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final GlobalKey _fieldKey = GlobalKey();

  void _toggleDropdown() {
    if (_overlayEntry != null) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    final renderBox = _fieldKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _closeDropdown, // bahar tap karne pe close ho jaye
          child: Stack(
            children: [
              Positioned.fill(child: Container(color: Colors.transparent)),
              CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(0, size.height + 6), // field ke thoda neeche
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(12),
                  child: _CountryDropdownList<T>(
                    width:220, // dropdown ki width
                    items: widget.items,
                    itemLabel: widget.itemLabel,
                    countryName: widget.countryName,
                    selectedValue: widget.value,
                    onSelected: (item) {
                      widget.onCountryChanged(item);
                      _closeDropdown();
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {});
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        key: _fieldKey,
        decoration: BoxDecoration(
          color: AppColors.textFieldColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.transparent, width: 1.4),
        ),
        child: Row(
          children: [
            // ── Left side: tappable country code ──────────────────────
            InkWell(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              onTap: widget.isCountryLoading ? null : _toggleDropdown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: widget.isCountryLoading && widget.items.isEmpty
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CupertinoActivityIndicator(radius: 8),
                )
                    : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    widget.value != null && widget.selectedItemBuilder != null
                        ? widget.selectedItemBuilder!(widget.value as T)
                        : Text(
                      widget.value != null
                          ? (widget.itemLabel != null
                          ? widget.itemLabel!(widget.value as T)
                          : widget.value.toString())
                          : "🌐",
                      style: const TextStyle(fontSize: 18, color: Colors.black87),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _overlayEntry != null
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: Colors.black87,
                    ),
                  ],
                ),
              ),
            ),

            // ── Divider ─────────────────────────────────────────────────
            Container(
              width: 1,
              height: 28,
              color: AppColors.teal.withOpacity(0.4),
            ),

            // ── Right side: phone number input ──────────────────────────
// ── Right side: phone number input ──────────────────────────
            Expanded(
              child: TextField(
                controller: widget.controller,
                keyboardType: widget.keyboardType,
                inputFormatters: widget.inputFormatters,
                maxLength: widget.maxLength,
                textAlign: TextAlign.left,
                textDirection: TextDirection.ltr,
                cursorColor: AppColors.teal,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: TextStyle(color: Colors.black.withOpacity(0.1)),
                  border: InputBorder.none,
                  counterText: '',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dropdown list with search ─────────────────────────────────────────
class _CountryDropdownList<T> extends StatefulWidget {
  final double width;
  final List<T> items;
  final String Function(T)? itemLabel;
  final String Function(T)? countryName;
  final T? selectedValue;
  final ValueChanged<T> onSelected;

  const _CountryDropdownList({
    required this.width,
    required this.items,
    required this.onSelected,
    this.itemLabel,
    this.countryName,
    this.selectedValue,
  });

  @override
  State<_CountryDropdownList<T>> createState() => _CountryDropdownListState<T>();
}

class _CountryDropdownListState<T> extends State<_CountryDropdownList<T>> {
  final TextEditingController _searchController = TextEditingController();
  late List<T> _filteredItems;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items.where((item) {
          final label = widget.itemLabel != null ? widget.itemLabel!(item) : item.toString();
          final name = widget.countryName != null ? widget.countryName!(item) : '';
          return label.toLowerCase().contains(query) || name.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      constraints: const BoxConstraints(maxHeight: 320),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Search bar ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: "Search country...",
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.teal),
                ),
              ),
            ),
          ),
          const Divider(height: 1),

          // ── List ────────────────────────────────────────────────
          Flexible(
            child: _filteredItems.isEmpty
                ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text("No country found", style: TextStyle(color: Colors.grey)),
            )
                : ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                final label = widget.itemLabel != null ? widget.itemLabel!(item) : item.toString();
                final name = widget.countryName != null ? widget.countryName!(item) : null;
                final isSelected = item == widget.selectedValue;
                return ListTile(
                  dense: true,
                  title: name != null
                      ? Text(name, style: const TextStyle(fontSize: 14))
                      : Text(label, style: const TextStyle(fontSize: 14)),
                  subtitle: name != null
                      ? Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey))
                      : null,
                  trailing: isSelected ? const Icon(Icons.check, color: Colors.teal, size: 18) : null,
                  onTap: () => widget.onSelected(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
// class _CountryPickerSheet<T> extends StatelessWidget {
//   final List<T> items;
//   final String Function(T)? itemLabel;
//   final T? selectedValue;
//
//   const _CountryPickerSheet({
//     required this.items,
//     this.itemLabel,
//     this.selectedValue,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Container(
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//         ),
//         constraints: BoxConstraints(
//           maxHeight: MediaQuery.of(context).size.height * 0.6,
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const SizedBox(height: 12),
//             Container(
//               width: 40,
//               height: 4,
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade300,
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//             const SizedBox(height: 16),
//             const Text(
//               "Select Country",
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//             ),
//             const SizedBox(height: 8),
//             Flexible(
//               child: ListView.builder(
//                 shrinkWrap: true,
//                 itemCount: items.length,
//                 itemBuilder: (context, index) {
//                   final item = items[index];
//                   final label = itemLabel != null ? itemLabel!(item) : item.toString();
//                   final isSelected = item == selectedValue;
//                   return ListTile(
//                     title: Text(label),
//                     trailing: isSelected ? const Icon(Icons.check, color: Colors.teal) : null,
//                     onTap: () => Navigator.pop(context, item),
//                   );
//                 },
//               ),
//             ),
//             const SizedBox(height: 12),
//           ],
//         ),
//       ),
//     );
//   }
// }
// ─── Custom App Bar ───────────────────────────────────────────────────────────
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final List<Widget>? actions;
  final Color? bgColor;
  final Widget? leading;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBack = false,
    this.actions,
    this.bgColor,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.tealDark,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      centerTitle: false,
      automaticallyImplyLeading: false,
      leading: showBack
          ? GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
      )
          : leading,
      title: Text(title, style: AppTextStyles.appBar),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}

// ─── Dropdown ──────────────────────────────────────────────────────────────
class _DropdownSelection<T> {
  final T? value;
  const _DropdownSelection(this.value);
}

class McDropdown<T> extends StatelessWidget {
  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T)? itemLabel;
  final Widget Function(T)? selectedItemBuilder; // Naya field sirf selected value ke liye
  final ValueChanged<T?> onChanged;
  final IconData? prefixIcon;
  final Color? borderColor;

  const McDropdown({
    super.key,
    required this.hint,
    required this.items,
    required this.onChanged,
    this.value,
    this.itemLabel,
    this.selectedItemBuilder,
    this.prefixIcon,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await showModalBottomSheet<_DropdownSelection<T>>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          barrierColor: Colors.black.withValues(alpha: 0.45),
          builder: (context) => _DropdownBottomSheet<T>(
            title: hint,
            items: items,
            itemLabel: itemLabel,
            selectedValue: value,
          ),
        );
        // null = sheet dismissed (no change). Otherwise apply pick / clear.
        if (result != null) {
          onChanged(result.value);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgCardNavy,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor ?? AppColors.teal,
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            if (prefixIcon != null) ...[
              Icon(prefixIcon, color: AppColors.textMuted, size: 20),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: value != null && selectedItemBuilder != null
                  ? selectedItemBuilder!(value!)
                  : Text(
                      value != null
                          ? (itemLabel != null
                              ? itemLabel!(value!)
                              : value.toString())
                          : hint,
                      style: TextStyle(
                        color: value != null
                            ? AppColors.textDark
                            : AppColors.textMuted,
                        fontSize: 15,
                        fontWeight:
                            value != null ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F7F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.tealDark,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownBottomSheet<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T)? itemLabel;
  final T? selectedValue;

  const _DropdownBottomSheet({
    required this.title,
    required this.items,
    this.itemLabel,
    this.selectedValue,
  });

  @override
  State<_DropdownBottomSheet<T>> createState() => _DropdownBottomSheetState<T>();
}

class _DropdownBottomSheetState<T> extends State<_DropdownBottomSheet<T>> {
  late List<T> filteredItems;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredItems = widget.items;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredItems = widget.items;
      } else {
        filteredItems = widget.items.where((item) {
          final label = widget.itemLabel != null
              ? widget.itemLabel!(item)
              : item.toString();
          return label.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  String _labelOf(T item) =>
      widget.itemLabel != null ? widget.itemLabel!(item) : item.toString();

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final showSearch = widget.items.length > 6;

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: const BoxDecoration(
        color: Color(0xFFF2F6F4),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 12, 14, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0A5C45),
                  Color(0xFF147A68),
                  Color(0xFF1B9E8E)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.checklist_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            '${widget.items.length} options · tap to select',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(12),
                        child: const SizedBox(
                          width: 36,
                          height: 36,
                          child: Icon(Icons.close_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (showSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: TextField(
                controller: searchController,
                onChanged: _filterItems,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
                decoration: InputDecoration(
                  hintText: 'Search ${widget.title.toLowerCase()}…',
                  hintStyle: TextStyle(
                    color: AppColors.textGray.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.tealDark),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE3EBE7)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE3EBE7)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: AppColors.tealDark, width: 1.2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          Expanded(
            child: filteredItems.isEmpty
                ? Center(
                    child: Text(
                      'No matches found',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textGray,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(16, 14, 16, 16 + bottom),
                    itemCount: filteredItems.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final label = _labelOf(item);
                      final isSelected = widget.selectedValue != null &&
                          (widget.selectedValue == item ||
                              identical(widget.selectedValue, item) ||
                              (widget.itemLabel != null &&
                                  widget.itemLabel!(
                                          widget.selectedValue as T) ==
                                      label));

                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: () {
                            // Re-tap selected item → clear selection.
                            if (isSelected) {
                              Navigator.pop(
                                context,
                                _DropdownSelection<T>(null),
                              );
                            } else {
                              Navigator.pop(
                                context,
                                _DropdownSelection<T>(item),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 13),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.tealDark
                                        .withValues(alpha: 0.45)
                                    : const Color(0xFFE3EBE7),
                              ),
                              color: isSelected
                                  ? AppColors.teal.withValues(alpha: 0.06)
                                  : Colors.white,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.tealDark
                                        : const Color(0xFFF3F7F5),
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: Icon(
                                    isSelected
                                        ? Icons.check_rounded
                                        : Icons.circle_outlined,
                                    size: 18,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textGray,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      color: AppColors.textDark,
                                      fontWeight: isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Text(
                                    'Tap to clear',
                                    style: TextStyle(
                                      color: AppColors.tealDark
                                          .withValues(alpha: 0.9),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11.5,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.heading3),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(actionLabel!, style: AppTextStyles.tealLabel),
          ),
      ],
    );
  }
}

// ─── Divider ─────────────────────────────────────────────────────────────────
class McDivider extends StatelessWidget {
  final EdgeInsetsGeometry? margin;
  const McDivider({super.key, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 12),
      height: 1,
      color: AppColors.border,
    );
  }
}

// ─── Avatar with teal ring ────────────────────────────────────────────────────
class PatientAvatar extends StatelessWidget {
  final String initials;
  final Color color;
  final bool isActive;
  final double size;
  final String? label;

  const PatientAvatar({
    super.key,
    required this.initials,
    required this.color,
    this.isActive = false,
    this.size = 50,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? AppColors.accentTeal : Colors.transparent,
              width: 3,
            ),
          ),
          child: CircleAvatar(
            backgroundColor: color,
            radius: size / 2 - 3,
            child: Text(
              initials,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.3,
              ),
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 4),
          Text(
            label!,
            style: AppTextStyles.caption.copyWith(
              color: isActive ? AppColors.accentTeal : AppColors.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Pill / Filter Chip ───────────────────────────────────────────────────────
class McFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? activeColor;
  final VoidCallback onTap;

  const McFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final ac = activeColor ?? AppColors.tealDark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? ac : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? ac : const Color(0xFFE3EBE7),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: ac.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTextStyles.captionBold.copyWith(
            color: isSelected ? Colors.white : AppColors.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─── Progress bar ─────────────────────────────────────────────────────────────
class McProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final Color? color;
  final double height;
  final String? label;

  const McProgressBar({
    super.key,
    required this.value,
    this.color,
    this.height = 6,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: AppTextStyles.caption),
          const SizedBox(height: 6),
        ],
        Container(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(height),
          ),
          child: FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: color ?? AppColors.teal,
                borderRadius: BorderRadius.circular(height),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Setting Row ──────────────────────────────────────────────────────────────
class SettingRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? iconColor;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? bgColor;

  const SettingRow({
    super.key,
    required this.icon,
    required this.title,
    this.iconColor,
    this.onTap,
    this.trailing,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor ?? AppColors.bgCardNavy,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? AppColors.accentTeal, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title, style: AppTextStyles.body.copyWith(color: AppColors.textTail)),
            ),
            trailing ?? const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Timeline Event Row ───────────────────────────────────────────────────────
class TimelineEventRow extends StatelessWidget {
  final String title;
  final String time;
  final IconData icon;
  final Color iconColor;
  final bool isLast;

  const TimelineEventRow({
    super.key,
    required this.title,
    required this.time,
    required this.icon,
    required this.iconColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: iconColor.withValues(alpha: 0.22)),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 36,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: const Color(0xFFE3EBE7),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE3EBE7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textGray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import '../Colors/colors.dart';
// import '../Font/font_family.dart';
// import '../StringDefine/strings.dart';
//
// Text buildText(String S, double size, String fontFamily, color) => Text(S, style: TextStyle(fontSize: size, color: color, fontFamily: fontFamily),overflow: TextOverflow.ellipsis,);
//
// Text buildTextWithWeight({String? S, double? size, String? fontFamily, color, weight, height}) => Text(S ?? "", style: TextStyle(fontSize: size, color: color, fontFamily: fontFamily,fontWeight: weight, height: height),overflow: TextOverflow.ellipsis,);
// Text buildTextWithWeightAlign({String? S, double? size, String? fontFamily, color, weight, height,   align}) => Text(S ?? "", style: TextStyle(fontSize: size, color: color, fontFamily: fontFamily,fontWeight: weight, height: height),overflow: TextOverflow.clip,textAlign: align,);
//
// Text buildTextWithWeightSpace({String? S, double? size, String? fontFamily, color, weight,space}) => Text(S ?? "", style: TextStyle(fontSize: size, color: color, fontFamily: fontFamily,fontWeight: weight,letterSpacing: space),overflow: TextOverflow.clip,);
//
// Widget buildTextIntroStyle1({String? S}) => FittedBox(child: Text(S ?? "", style: TextStyle(fontSize: 35.0, color: CustomColors.blackColor, fontFamily: FontFamily.PoppinsRegular),overflow: TextOverflow.ellipsis,));
//
// Widget buildTextIntroStyle2({String? S}) => FittedBox(child: Text(S ?? "", style: TextStyle(fontSize: 35.0, color: CustomColors.darkBlueColor, fontFamily: FontFamily.PoppinsBold),overflow: TextOverflow.ellipsis,));
//
// AppBar buildAppBar({S,onTap}) => AppBar(
//
//   title:  Row(
//     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//     children: [
//       Expanded(child: buildTextWithWeight(S: S,size: 18.0,color: CustomColors.blackColor,weight: FontWeight.w800,fontFamily: FontFamily.PoppinsBold)),
//       // const Spacer(),
//       InkWell(onTap: onTap,child: Icon(Icons.notifications,color: CustomColors.greyColor,))
//     ],
//   ),
//   automaticallyImplyLeading: false,
//   backgroundColor: CustomColors.whiteColor,
//   elevation: 2,
// );
//
// AppBar buildAppBarWithBackBtn({S,onTap}) => AppBar(
//
//   title:  Row(
//     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//     children: [
//       InkWell(onTap: onTap,
//           child: Icon(
//             Icons.arrow_back_ios,
//             color: CustomColors.blackColor,
//             size: 19.0,
//           ),
//           // Icon(Icons.arrow_circle_left_outlined,color: CustomColors.greyColor,)
//       ),
//       const SizedBox(width: 15,),
//       Expanded(child: buildTextWithWeight(S: S,size: 18.0,color: CustomColors.blackColor,weight: FontWeight.w600,fontFamily: FontFamily.PoppinsBold)),
//     ],
//   ),
//   automaticallyImplyLeading: false,
//   backgroundColor: CustomColors.whiteColor,
//   elevation: 1,
// );
//
// AppBar buildAppBarWithLeadingActions({S,onTap}) => AppBar(
//   title: buildTextWithWeight(S: S,size: 18.0,color: CustomColors.blackColor,weight: FontWeight.w600,fontFamily: FontFamily.PoppinsBold),
//   leading: InkWell(onTap: onTap,
//     child: Icon(
//       Icons.arrow_back_ios,
//       color: CustomColors.blackColor,
//       size: 19.0,
//     ),
//     // Icon(Icons.arrow_circle_left_outlined,color: CustomColors.greyColor,)
//   ),
//   actions: [
//     Image.asset(str_logo)
//   ],
//   automaticallyImplyLeading: false,
//   backgroundColor: CustomColors.whiteColor,
//   elevation: 0,
// );