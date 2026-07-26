import 'package:flutter/material.dart';

import '../../utils/farm_bottom_nav.dart';
import 'analytics_page.dart';
import 'coming_soon_page.dart';
import 'farmer_home_page.dart';
import 'loans_page.dart';
import 'marketplace_page.dart';

/// Hosts the five farmer destinations behind the bottom navigation bar.
///
/// An [IndexedStack] keeps each tab's scroll position and avoids refetching
/// when the farmer moves between them.
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
    return Scaffold(
      body: IndexedStack(
        index: FarmNavTab.values.indexOf(_current),
        children: [
          const ComingSoonPage(
            title: 'My Farm',
            icon: Icons.grass_outlined,
            explanation:
                'Registering gardens, plot sizes and GPS boundaries needs the '
                'farm module (FR-04), which is not implemented on the backend '
                'yet. Harvests are recorded without a plot for now.',
          ),
          const MarketplacePage(),
          FarmerHomePage(onNavigateToTab: _selectIndex),
          const LoansPage(),
          const MyAnalyticsPage(),
        ],
      ),
      bottomNavigationBar: FarmBottomNav(current: _current, onSelected: _select),
    );
  }
}
