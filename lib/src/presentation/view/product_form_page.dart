import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../data/models/enums.dart';
import '../../data/models/requests.dart';
import '../viewmodel/auth_view_model.dart';
import '../viewmodel/product_form_view_model.dart';
import 'widgets/app_text_field.dart';
import 'widgets/submit_button.dart';

/// `POST /products` — the only authenticated write the backend exposes today.
class ProductFormPage extends ConsumerStatefulWidget {
  const ProductFormPage({super.key});

  @override
  ConsumerState<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends ConsumerState<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _district = TextEditingController();
  final _price = TextEditingController();
  final _quantity = TextEditingController();
  final _description = TextEditingController();

  ProductType? _productType;
  UnitType _unitType = UnitType.bag50kg;

  /// Only the categories this account is entitled to list.
  ///
  /// The backend rejects anything else with a 403, so offering the full enum
  /// would just produce avoidable errors.
  List<ProductType> get _allowedTypes =>
      ref.read(currentUserProvider)?.listableProductTypes ?? const [];

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);

    // Default the listing to the seller's own district.
    final district =
        user?.farmerProfile?.district ?? user?.supplierProfile?.district;
    if (district != null) _district.text = district;

    final allowed = user?.listableProductTypes ?? const <ProductType>[];
    if (allowed.isNotEmpty) _productType = allowed.first;
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _district,
      _price,
      _quantity,
      _description,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final productType = _productType ?? _allowedTypes.firstOrNull;
    if (productType == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Your account has no categories it can list. Register the '
              'services you supply first.',
            ),
          ),
        );
      return;
    }

    FocusScope.of(context).unfocus();

    final created = await ref
        .read(productFormViewModelProvider.notifier)
        .submit(
          ProductCreateRequest(
            productType: productType,
            productName: _name.text.trim(),
            unitType: _unitType,
            district: _district.text.trim(),
            pricePerUnit: double.parse(_price.text.trim()),
            quantityAvailable: int.parse(_quantity.text.trim()),
            description: _description.text.trim(),
          ),
        );

    if (!mounted) return;
    if (created) {
      ref.read(productFormViewModelProvider.notifier).reset();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Product listed on the marketplace.'),
            backgroundColor: AppColors.primary,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(productFormViewModelProvider);

    ref.listen(productFormViewModelProvider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('${next.error}'),
              backgroundColor: Colors.red.shade700,
            ),
          );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textHeading,
        title: const Text(
          'List a Product',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sell directly to buyers',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your listing appears in the AgriChain marketplace right away.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 22),

                AppDropdownField<ProductType>(
                  label: 'Category',
                  value: _productType ?? _allowedTypes.firstOrNull,
                  icon: Icons.category_outlined,
                  items: _allowedTypes
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() {
                    if (value != null) _productType = value;
                  }),
                ),
                AppTextField(
                  controller: _name,
                  label: 'Product Name',
                  hint: 'Dry White Hybrid Maize',
                  icon: Icons.inventory_2_outlined,
                  validator: (value) =>
                      Validators.required(value, 'Product name'),
                ),
                AppDropdownField<UnitType>(
                  label: 'Unit',
                  value: _unitType,
                  icon: Icons.scale_outlined,
                  items: UnitType.values
                      .map(
                        (unit) => DropdownMenuItem(
                          value: unit,
                          child: Text(unit.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _unitType = value ?? UnitType.kilogram),
                ),
                AppTextField(
                  controller: _price,
                  label: 'Price per Unit (MK)',
                  hint: '45000',
                  icon: Icons.payments_outlined,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) =>
                      Validators.positiveNumber(value, 'Price'),
                ),
                AppTextField(
                  controller: _quantity,
                  label: 'Quantity Available',
                  hint: '25',
                  icon: Icons.numbers_outlined,
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      Validators.positiveInteger(value, 'Quantity'),
                ),
                AppTextField(
                  controller: _district,
                  label: 'District',
                  hint: 'Lilongwe',
                  icon: Icons.map_outlined,
                  validator: (value) => Validators.required(value, 'District'),
                ),
                AppTextField(
                  controller: _description,
                  label: 'Description (optional)',
                  hint: 'High quality verified farm product direct from farm.',
                  maxLines: 3,
                ),
                const SizedBox(height: 10),

                SubmitButton(
                  label: 'Publish Listing',
                  isLoading: formState.isLoading,
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
