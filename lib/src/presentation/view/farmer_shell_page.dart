import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../utils/farm_bottom_nav.dart';
import '../../utils/responsive.dart';
import 'analytics_page.dart';
import 'farmer_home_page.dart';
import 'loans_page.dart';
import 'marketplace_page.dart';
import 'my_farm_page.dart';

/// Hosts the five farmer destinations.
///
/// An [IndexedStack] keeps each tab's scroll position and avoids refetching when
/// the farmer moves between them.
///
/// Navigation adapts to the window: a bottom bar on phones, a side rail once
/// there is room, which is the convention on desktop and avoids a bottom bar
/// stretched across a 1920px window.
class FarmerShellPage extends StatefulWidget {
  const FarmerShellPage({super.key});

  @override
  State<FarmerShellPage> createState() => _FarmerShellPageState();
}

class _FarmerShellPageState extends State<FarmerShellPage> {
  // Home is the landing destination.
  FarmNavTab _current = FarmNavTab.home;

  void _select(FarmNavTab tab) => setState(() => _current = tab);

  void _selectIndex(int index) {
    if (index < 0 || index >= FarmNavTab.values.length) return;
    _select(FarmNavTab.values[index]);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = IndexedStack(
      index: FarmNavTab.values.indexOf(_current),
      children: [
        const MyFarmPage(),
        const MarketplacePage(),
        FarmerHomePage(onNavigateToTab: _selectIndex),
        const LoansPage(),
        const MyAnalyticsPage(),
      ],
    );

    if (!Breakpoints.isWide(context)) {
      return Scaffold(
        body: tabs,
        bottomNavigationBar: FarmBottomNav(
          current: _current,
          onSelected: _select,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          _FarmNavRail(current: _current, onSelected: _select),
          const VerticalDivider(width: 1, color: AppColors.cardBorder),
          Expanded(child: tabs),
        ],
      ),
    );
  }
}

/// Side navigation for wide windows.
class _FarmNavRail extends StatelessWidget {
  final FarmNavTab current;
  final ValueChanged<FarmNavTab> onSelected;

  const _FarmNavRail({required this.current, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      backgroundColor: Colors.white,
      selectedIndex: FarmNavTab.values.indexOf(current),
      onDestinationSelected: (index) =>
          onSelected(FarmNavTab.values[index]),
      labelType: NavigationRailLabelType.all,
      indicatorColor: AppColors.cardTint,
      selectedIconTheme: const IconThemeData(
        color: AppColors.primary,
        size: 23,
      ),
      unselectedIconTheme: const IconThemeData(
        color: AppColors.textMuted,
        size: 22,
      ),
      selectedLabelTextStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
      unselectedLabelTextStyle: const TextStyle(
        fontSize: 11,
        color: AppColors.textMuted,
      ),
      leading: const Padding(
        padding: EdgeInsets.only(top: 8, bottom: 16),
        child: Icon(Icons.eco, size: 26, color: AppColors.primaryMuted),
      ),
      destinations: [
        for (final tab in FarmNavTab.values)
          NavigationRailDestination(
            icon: Icon(tab.icon),
            selectedIcon: Icon(tab.icon),
            label: Text(tab.label),
          ),
      ],
    );
  }
}
