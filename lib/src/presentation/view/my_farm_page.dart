import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/enums.dart';
import '../../data/models/harvest.dart';
import '../../data/repositories/farm_repository.dart';
import '../../utils/pill_badge.dart';
import '../../utils/responsive.dart';
import '../../utils/section_header.dart';
import '../../utils/stat_tile.dart';
import '../../utils/status_notice_card.dart';
import '../../utils/work_log_tile.dart';
import '../viewmodel/auth_view_model.dart';
import '../viewmodel/farmer_dashboard_view_model.dart';
import 'record_harvest_page.dart';
import 'widgets/app_header.dart';
import 'widgets/ledger_widgets.dart';

/// My Farm: the farmer's agricultural record (FR-07, FR-08).
///
/// Plots, sizes and GPS boundaries would come from the farm module (FR-04),
/// which is not implemented, so this covers what the backend actually supports:
/// recording harvests, seeing which have been independently verified, and
/// understanding why verification matters to the lending score.
class MyFarmPage extends ConsumerWidget {
  const MyFarmPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final state = ref.watch(farmerDashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Record Harvest'),
        onPressed: () => _openRecordForm(context, ref),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.read(farmerDashboardProvider.notifier).refresh(),
          child: PageWidth(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
              children: [
                const AppHeader(subtitle: 'My Farm'),
                const SizedBox(height: 16),

                switch (state) {
                  AsyncValue(hasError: true, :final error) => LedgerErrorState(
                    message: '$error',
                    onRetry: () => ref.invalidate(farmerDashboardProvider),
                  ),
                  AsyncValue(hasValue: true, :final value?) => _FarmBody(
                    dashboard: value,
                    district: user?.farmerProfile?.district,
                    onRecord: () => _openRecordForm(context, ref),
                  ),
                  _ => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openRecordForm(BuildContext context, WidgetRef ref) async {
    final recorded = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const RecordHarvestPage()),
    );
    if (recorded ?? false) {
      await ref.read(farmerDashboardProvider.notifier).refresh();
    }
  }
}

class _FarmBody extends StatelessWidget {
  final FarmerDashboard dashboard;
  final String? district;
  final VoidCallback onRecord;

  const _FarmBody({
    required this.dashboard,
    required this.onRecord,
    this.district,
  });

  @override
  Widget build(BuildContext context) {
    final harvests = _sorted(dashboard.harvests);
    final pending = harvests.where((h) => !h.isVerified).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatTileRow(
          tiles: [
            StatTile(
              label: 'Recorded Crop',
              value: harvests.isEmpty
                  ? '—'
                  : '${formatQuantity(dashboard.totalHarvestQuantity)} '
                        '${dashboard.harvestUnitLabel}',
              caption: dashboard.hasMixedHarvestUnits
                  ? 'Mixed units'
                  : '${harvests.length} record(s)',
            ),
            StatTile(
              label: 'Verified',
              value: '${dashboard.verifiedHarvestCount}',
              caption: pending == 0 ? 'All confirmed' : '$pending awaiting',
              captionColor: dashboard.verifiedHarvestCount > 0
                  ? AppColors.positive
                  : AppColors.textMuted,
            ),
            const StatTile(
              label: 'Registered Plots',
              // The farm module (FR-04) does not exist, so there is no plot to
              // count. Shown as absent rather than invented.
              value: '—',
              caption: 'Not yet supported',
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (dashboard.verifiedHarvestCount == 0)
          StatusNoticeCard(
            icon: Icons.lightbulb_outline,
            title: 'Verification raises your score',
            message:
                'A harvest counts towards your lending score once a cooperative '
                'or agricultural officer confirms it. Record your harvest here, '
                'then ask them to verify it.',
          )
        else
          StatusNoticeCard.positive(
            icon: Icons.verified_outlined,
            title: '${dashboard.verifiedHarvestCount} harvest(s) verified',
            message:
                'Verified harvests are anchored to the ledger and count towards '
                'your lending score.',
            badgeText: 'On the ledger',
          ),
        const SizedBox(height: 20),

        SectionHeader(
          title: 'Harvest Records',
          actionLabel: 'Record',
          onAction: onRecord,
        ),
        const SizedBox(height: 10),

        if (harvests.isEmpty)
          _NoHarvests(onRecord: onRecord)
        else
          for (final harvest in harvests)
            WorkLogTile(
              icon: Icons.agriculture_outlined,
              title: harvest.cropName,
              subtitle:
                  '${formatQuantity(harvest.quantity)} '
                  '${harvest.unitType.label} • ${harvest.season} • '
                  '${harvest.district}',
              trailing: harvest.harvestDate == null
                  ? ''
                  : formatShortDate(harvest.harvestDate!),
              statusLabel: harvest.isVerified ? 'Verified' : 'Pending',
              isVerified: harvest.isVerified,
            ),

        const SizedBox(height: 18),
        _PlotsNotice(district: district),
      ],
    );
  }

  List<Harvest> _sorted(List<Harvest> harvests) {
    final sorted = [...harvests];
    sorted.sort((a, b) {
      final left = a.harvestDate ?? a.createdAt ?? DateTime(1970);
      final right = b.harvestDate ?? b.createdAt ?? DateTime(1970);
      return right.compareTo(left);
    });
    return sorted;
  }
}

/// States plainly what this screen cannot do yet, rather than leaving an
/// unexplained gap where plot management would be.
class _PlotsNotice extends StatelessWidget {
  final String? district;

  const _PlotsNotice({this.district});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.map_outlined,
                size: 16,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Gardens & plots',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              const PillBadge(
                text: 'Not built',
                background: AppColors.warningSoft,
                foreground: AppColors.warning,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            district == null || district!.isEmpty
                ? 'Registering gardens with sizes and GPS boundaries needs the '
                      'farm module, which is not implemented on the backend yet. '
                      'Harvests are recorded without a plot for now.'
                : 'Your district is recorded as $district. Registering '
                      'individual gardens with sizes and GPS boundaries needs '
                      'the farm module, which is not implemented yet.',
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoHarvests extends StatelessWidget {
  final VoidCallback onRecord;

  const _NoHarvests({required this.onRecord});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Icon(
            Icons.agriculture_outlined,
            size: 34,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 10),
          const Text(
            'No harvests recorded yet',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
          ),
          const SizedBox(height: 6),
          const Text(
            'Recording a harvest is the first step towards a lending score.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRecord,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Record Harvest'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Units a farmer would plausibly measure a harvest in.
const List<UnitType> harvestUnits = [
  UnitType.bag50kg,
  UnitType.bag25kg,
  UnitType.bag10kg,
  UnitType.kilogram,
  UnitType.crate,
  UnitType.bunch,
  UnitType.piece,
];

/// Shared by the record form and any future harvest editing.
final harvestRepositoryProvider = farmRepositoryProvider;
