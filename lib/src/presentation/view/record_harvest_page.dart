import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/farm_repository.dart';
import '../../utils/responsive.dart';
import '../viewmodel/auth_view_model.dart';
import 'my_farm_page.dart' show harvestUnits;
import 'widgets/app_text_field.dart';
import 'widgets/submit_button.dart';

/// `POST /harvests` — records a harvest and anchors it to the ledger (FR-07).
///
/// Pops `true` when something was recorded, so the caller knows to refresh.
class RecordHarvestPage extends ConsumerStatefulWidget {
  const RecordHarvestPage({super.key});

  @override
  ConsumerState<RecordHarvestPage> createState() => _RecordHarvestPageState();
}

class _RecordHarvestPageState extends ConsumerState<RecordHarvestPage> {
  final _formKey = GlobalKey<FormState>();
  final _cropName = TextEditingController();
  final _quantity = TextEditingController();
  final _district = TextEditingController();
  final _season = TextEditingController();

  UnitType _unit = UnitType.bag50kg;
  DateTime _harvestDate = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(currentUserProvider)?.farmerProfile;
    if (profile?.district != null) _district.text = profile!.district;
    _season.text = _currentSeason();
  }

  /// Malawi's growing season spans two calendar years, so a harvest in the first
  /// half of the year belongs to the season that began the previous November.
  static String _currentSeason() {
    final now = DateTime.now();
    final startYear = now.month >= 10 ? now.year : now.year - 1;
    return '$startYear/${startYear + 1}';
  }

  @override
  void dispose() {
    for (final controller in [_cropName, _quantity, _district, _season]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _harvestDate,
      // A harvest cannot be in the future, and five years back is plenty.
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime.now(),
      helpText: 'When did you harvest?',
    );
    if (picked != null) setState(() => _harvestDate = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final result = await ref.read(farmRepositoryProvider).recordHarvest(
        cropName: _cropName.text.trim(),
        quantity: double.parse(_quantity.text.trim()),
        unitType: _unit,
        harvestDate: _harvestDate,
        season: _season.text.trim(),
        district: _district.text.trim(),
      );

      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 5),
            content: Text(
              result.blockIndex == null
                  ? 'Harvest recorded.'
                  : 'Harvest recorded and anchored in block '
                        '${result.blockIndex}. Ask your cooperative to verify '
                        'it so it counts towards your score.',
            ),
          ),
        );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 6),
            content: Text('$error'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textHeading,
        centerTitle: true,
        title: const Text(
          'Record Harvest',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: SafeArea(
        child: PageWidth(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                const Text(
                  'Record what you harvested. Once a cooperative or '
                  'agricultural officer verifies it, it counts towards your '
                  'lending score.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textMuted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),

                AppTextField(
                  controller: _cropName,
                  label: 'What did you harvest?',
                  hint: 'Dry White Hybrid Maize',
                  icon: Icons.grass_outlined,
                  validator: (value) => Validators.required(value, 'Crop name'),
                ),
                AppTextField(
                  controller: _quantity,
                  label: 'How much?',
                  hint: '120',
                  icon: Icons.numbers_outlined,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    final parsed = double.tryParse((value ?? '').trim());
                    if (parsed == null) return 'Enter a number';
                    // The API rejects anything not greater than zero.
                    if (parsed <= 0) return 'Must be more than zero';
                    return null;
                  },
                ),
                AppDropdownField<UnitType>(
                  label: 'Measured in',
                  value: _unit,
                  icon: Icons.scale_outlined,
                  items: harvestUnits
                      .map(
                        (unit) => DropdownMenuItem(
                          value: unit,
                          child: Text(unit.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _unit = value ?? UnitType.bag50kg),
                ),

                _DateField(date: _harvestDate, onTap: _pickDate),
                const SizedBox(height: 14),

                AppTextField(
                  controller: _season,
                  label: 'Season',
                  hint: '2025/2026',
                  icon: Icons.calendar_month_outlined,
                  validator: (value) => Validators.required(value, 'Season'),
                ),
                AppTextField(
                  controller: _district,
                  label: 'District',
                  hint: 'Lilongwe',
                  icon: Icons.location_on_outlined,
                  validator: (value) => Validators.required(value, 'District'),
                ),
                const SizedBox(height: 6),

                SubmitButton(
                  label: 'Record Harvest',
                  isLoading: _saving,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tappable date row styled to match [AppTextField].
class _DateField extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;

  const _DateField({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.event_outlined,
              size: 20,
              color: AppColors.primaryMuted,
            ),
            const SizedBox(width: 12),
            const Text(
              'Harvest date',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const Spacer(),
            Text(
              formatFullDate(date),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textHeading,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
