import 'package:flutter/material.dart';

/// A selectable account-type pill, sized for a dark or coloured header.
///
/// Selection state belongs to the caller. A widget like this cannot own it: the
/// build method has already returned by the time a tap arrives, so a variable
/// declared inside it could never survive to the next frame.
///
/// ```dart
/// class _HeaderState extends State<Header> {
///   String _selected = 'Farmer';
///
///   @override
///   Widget build(BuildContext context) {
///     return Row(
///       children: [
///         for (final (title, icon) in const [
///           ('Farmer', Icons.eco_outlined),
///           ('Buyer', Icons.shopping_bag_outlined),
///         ])
///           AccountTypeButton(
///             title: title,
///             icon: icon,
///             isSelected: _selected == title,
///             onTap: () => setState(() => _selected = title),
///           ),
///       ],
///     );
///   }
/// }
/// ```
class AccountTypeButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  /// Colour of the label and icon once selected, against the white pill.
  final Color selectedColor;

  /// Colour used while unselected, for a coloured background.
  final Color unselectedColor;

  const AccountTypeButton({
    super.key,
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.selectedColor = const Color(0xFF135D39),
    this.unselectedColor = Colors.white70,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = isSelected ? selectedColor : unselectedColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
