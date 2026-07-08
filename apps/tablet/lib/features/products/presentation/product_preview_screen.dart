import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/local_database.dart';
import '../data/product_repository.dart';
import '../domain/product_models.dart';

class ProductPreviewScreen extends StatefulWidget {
  const ProductPreviewScreen({super.key});

  @override
  State<ProductPreviewScreen> createState() => _ProductPreviewScreenState();
}

class _ProductPreviewScreenState extends State<ProductPreviewScreen> {
  late final LocalDatabase database;
  late final ProductRepository repository;
  List<ProductConfig> products = [];
  List<DynamicFieldConfig> fields = [];
  ProductConfig? selectedProduct;
  ProductVariantConfig? selectedVariant;

  @override
  void initState() {
    super.initState();
    database = LocalDatabase();
    repository = ProductRepository(database: database);
    _load();
  }

  Future<void> _load() async {
    final loadedProducts = await repository.cachedProducts();
    final loadedFields = await repository.cachedFields();
    setState(() {
      products = loadedProducts;
      fields = loadedFields;
      selectedProduct = loadedProducts.isEmpty ? null : loadedProducts.first;
      selectedVariant = selectedProduct?.variants.isEmpty ?? true
          ? null
          : selectedProduct!.variants.first;
    });
  }

  @override
  Widget build(BuildContext context) {
    final effective = selectedVariant?.effective ?? selectedProduct?.effective;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Product Configuration Preview'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final selector = _selectorPanel();
          final details = _detailsPanel(effective);

          if (compact) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [selector, const SizedBox(height: 16), details],
            );
          }

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                SizedBox(width: 360, child: selector),
                const SizedBox(width: 24),
                Expanded(child: details),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _selectorPanel() {
    return SizedBox(
      height: 520,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<ProductConfig>(
            initialValue: selectedProduct,
            decoration: const InputDecoration(labelText: 'Product'),
            items: products
                .map(
                  (product) => DropdownMenuItem(
                    value: product,
                    child: Text(product.name),
                  ),
                )
                .toList(),
            onChanged: (product) => setState(() {
              selectedProduct = product;
              selectedVariant = product?.variants.isEmpty ?? true
                  ? null
                  : product!.variants.first;
            }),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ProductVariantConfig>(
            initialValue: selectedVariant,
            decoration: const InputDecoration(labelText: 'Variant'),
            items: (selectedProduct?.variants ?? const [])
                .map(
                  (variant) => DropdownMenuItem(
                    value: variant,
                    child: Text(variant.name),
                  ),
                )
                .toList(),
            onChanged: (variant) => setState(() => selectedVariant = variant),
          ),
          const SizedBox(height: 24),
          Text('Dynamic Fields', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(children: fields.map(_fieldPreview).toList()),
          ),
        ],
      ),
    );
  }

  Widget _detailsPanel(EffectiveProductValues? effective) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            selectedProduct?.name ?? 'No cached product',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          _metric('Effective tare', effective?.tareWeight ?? '-'),
          _metric(
            'Weight range',
            '${effective?.minimumWeight ?? '-'} - ${effective?.maximumWeight ?? '-'}',
          ),
          _metric('Target', effective?.targetWeight ?? '-'),
          _metric(
            'Conversion',
            effective?.conversionRule?['method']?.toString() ?? 'None',
          ),
          _metric('Product lock', effective?.productLockMode ?? 'none'),
          _metric('Variant lock', effective?.variantLockMode ?? 'none'),
        ],
      ),
    );
  }

  Widget _fieldPreview(DynamicFieldConfig field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        enabled: field.editable,
        decoration: InputDecoration(
          labelText: field.fieldLabel,
          helperText: field.required ? 'Required' : field.dataType,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
