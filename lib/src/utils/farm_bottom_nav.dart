import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// The five destinations of the farmer app.
enum FarmNavTab {
  myFarm('My Farm', Icons.grass_outlined),
  marketplace('Marketplace', Icons.storefront_outlined),
  home('Home', Icons.home_rounded),
  loans('Loans', Icons.account_balance_outlined),
  analytics('My Analytics', Icons.bar_chart_outlined);

  const FarmNavTab(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Bottom navigation with the centre destination raised into a filled circle.
///
/// Built by hand rather than with [BottomNavigationBar] because the raised
/// centre item cannot be expressed through that widget's item model.
class FarmBottomNav extends StatelessWidget {
  final FarmNavTab current;
  final ValueChanged<FarmNavTab> onSelected;

  const FarmBottomNav({
    super.key,
    required this.current,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (final tab in FarmNavTab.values)
                Expanded(
                  child: tab == FarmNavTab.home
                      ? _RaisedItem(
                          tab: tab,
                          selected: current == tab,
                          onTap: () => onSelected(tab),
                        )
                      : _NavItem(
                          tab: tab,
                          selected: current == tab,
                          onTap: () => onSelected(tab),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final FarmNavTab tab;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textMuted;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(tab.icon, size: 21, color: color),
          const SizedBox(height: 3),
          Text(
            tab.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RaisedItem extends StatelessWidget {
  final FarmNavTab tab;
  final bool selected;
  final VoidCallback onTap;

  const _RaisedItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Lifted above the bar so it reads as the primary destination.
          Transform.translate(
            offset: const Offset(0, -8),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.cardBorder,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                tab.icon,
                size: 22,
                color: selected ? Colors.white : AppColors.primaryMuted,
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -6),
            child: Text(
              tab.label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: selected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
