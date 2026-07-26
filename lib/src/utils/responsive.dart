import 'package:flutter/material.dart';

/// Layout breakpoints.
///
/// The app was designed phone-first. On a desktop browser an unconstrained
/// column stretches to the full window, which leaves cards metres wide and text
/// lines too long to read, so content is capped and centred instead.
class Breakpoints {
  const Breakpoints._();

  /// Above this, side navigation replaces the bottom bar.
  static const double wide = 900;

  /// Above this, grids gain extra columns.
  static const double medium = 640;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= wide;

  static bool isMedium(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= medium;
}

/// Caps a page's content width and centres it.
///
/// A no-op on phones, where the viewport is already narrower than [maxWidth].
class PageWidth extends StatelessWidget {
  final Widget child;

  /// Chosen for readable line length rather than to fill the window.
  final double maxWidth;

  const PageWidth({super.key, required this.child, this.maxWidth = 720});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Column count for a card grid, from the width actually available.
///
/// Uses the constraint handed down rather than the window size, so a grid inside
/// a [PageWidth] gets the right answer instead of counting pixels it cannot use.
int gridColumnsFor(double availableWidth, {double targetTileWidth = 180}) {
  final columns = (availableWidth / targetTileWidth).floor();
  return columns.clamp(2, 4);
}
