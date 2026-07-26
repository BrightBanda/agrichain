import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// A dropdown styled as an outlined pill.
///
/// Generic over the value so it serves both the loan-type and institution
/// filters. A null value means "all".
class FilterDropdown<T> extends StatelessWidget {
  final String allLabel;
  final T? value;
  final List<T> options;
  final String Function(T option) labelOf;
  final ValueChanged<T?> onChanged;

  /// Draws the green treatment used for the primary filter in the mockup.
  final bool emphasised;

  const FilterDropdown({
    super.key,
    required this.allLabel,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
    this.emphasised = false,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = emphasised ? AppColors.primary : AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: emphasised ? AppColors.primary : AppColors.cardBorder,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T?>(
          value: value,
          isExpanded: true,
          isDense: true,
          borderRadius: BorderRadius.circular(12),
          icon: Icon(Icons.keyboard_arrow_down, size: 18, color: foreground),
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: foreground,
          ),
          padding: const EdgeInsets.symmetric(vertical: 9),
          items: [
            DropdownMenuItem<T?>(value: null, child: Text(allLabel)),
            for (final option in options)
              DropdownMenuItem<T?>(value: option, child: Text(labelOf(option))),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// The square icon button that sits beside the filter dropdowns.
class FilterIconButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool active;

  const FilterIconButton({super.key, this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.cardBorder,
          ),
        ),
        child: Icon(
          Icons.filter_list,
          size: 19,
          color: active ? Colors.white : AppColors.primary,
        ),
      ),
    );
  }
}

/// Rounded search input used by the marketplace.
class SearchField extends StatelessWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  const SearchField({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        prefixIcon: const Icon(Icons.search, size: 19, color: AppColors.textMuted),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}

/// A horizontally scrolling row of selectable category chips.
class CategoryChipRow extends StatelessWidget {
  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Categories that exist in the design but have no backend source yet; these
  /// render dimmed and are not tappable.
  final Set<String> unavailable;

  const CategoryChipRow({
    super.key,
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
    this.unavailable = const {},
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < categories.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _Chip(
              label: categories[i],
              selected: i == selectedIndex,
              disabled: unavailable.contains(categories[i]),
              onTap: () => onSelected(i),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.cardBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: selected ? Colors.white : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
