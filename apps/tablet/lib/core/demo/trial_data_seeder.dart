import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/local_database.dart';

class TrialDataSeeder {
  const TrialDataSeeder(this.database);

  final LocalDatabase database;

  Future<void> seedIfEmpty() async {
    final existingProducts = await database
        .select(database.localProducts)
        .get();
    if (existingProducts.isNotEmpty) return;

    final now = DateTime.now();
    final sessionStart = now.subtract(const Duration(hours: 2));
    final firstCapture = now.subtract(const Duration(hours: 1, minutes: 35));
    final secondCapture = now.subtract(const Duration(hours: 1, minutes: 18));
    final thirdCapture = now.subtract(const Duration(minutes: 42));
    final dispatchTime = now.subtract(const Duration(minutes: 20));

    final productA = _product(
      id: 'demo_product_polymer',
      name: 'Industrial Polymer Grade A-12',
      code: 'POLY-A12',
      tare: '0.800',
      min: '10.000',
      max: '18.000',
      target: '14.500',
      variants: [
        _variant(
          id: 'demo_variant_polymer_b900',
          productId: 'demo_product_polymer',
          name: 'Batch B-900 (High Density)',
          code: 'B900-HD',
          tare: '0.800',
          min: '10.000',
          max: '18.000',
          target: '14.500',
          piecesPerKg: '6',
        ),
        _variant(
          id: 'demo_variant_polymer_standard',
          productId: 'demo_product_polymer',
          name: 'Standard Density',
          code: 'STD-DEN',
          tare: '0.500',
          min: '8.000',
          max: '16.000',
          target: '12.000',
          piecesPerKg: '4',
        ),
      ],
    );

    final productB = _product(
      id: 'demo_product_ingot',
      name: 'Aluminium Ingot A-42',
      code: 'AL-A42',
      tare: '0.000',
      min: '5.000',
      max: '25.000',
      target: '12.500',
      variants: [
        _variant(
          id: 'demo_variant_ingot_density',
          productId: 'demo_product_ingot',
          name: 'Standard Density (2.70 g/cm3)',
          code: 'AL-STD',
          tare: '0.000',
          min: '5.000',
          max: '25.000',
          target: '12.500',
          piecesPerKg: '1',
        ),
      ],
    );

    await database.transaction(() async {
      for (final product in [productA, productB]) {
        await database
            .into(database.localProducts)
            .insert(
              LocalProductsCompanion.insert(
                id: product['id'] as String,
                name: product['name'] as String,
                productCode: product['product_code'] as String,
                sku: Value(product['sku'] as String?),
                payloadJson: jsonEncode(product),
                isActive: const Value(true),
                configurationVersion: const Value(1),
              ),
            );

        for (final variant
            in (product['variants'] as List<Map<String, dynamic>>)) {
          await database
              .into(database.localProductVariants)
              .insert(
                LocalProductVariantsCompanion.insert(
                  id: variant['id'] as String,
                  productId: variant['product_id'] as String,
                  name: variant['name'] as String,
                  variantCode: variant['variant_code'] as String,
                  payloadJson: jsonEncode(variant),
                  isActive: const Value(true),
                ),
              );
        }
      }

      for (final field in _dynamicFields) {
        await database
            .into(database.localDynamicFields)
            .insert(
              LocalDynamicFieldsCompanion.insert(
                id: field['id'] as String,
                entityType: field['entity_type'] as String,
                internalKey: field['internal_key'] as String,
                fieldLabel: field['field_label'] as String,
                dataType: field['data_type'] as String,
                payloadJson: jsonEncode(field),
                visibleInFlutter: const Value(true),
                sortOrder: Value(field['sort_order'] as int),
              ),
            );
      }

      await database
          .into(database.localLabelTemplates)
          .insert(
            LocalLabelTemplatesCompanion.insert(
              id: 'demo_label_75x75',
              code: 'DEMO-75X75',
              name: 'Demo 75 x 75 Product Label',
              scope: 'tenant',
              activeVersion: const Value(1),
              isDefault: const Value(true),
              payloadJson: jsonEncode(_labelTemplate),
            ),
          );

      await database
          .into(database.localScaleProfiles)
          .insert(
            LocalScaleProfilesCompanion.insert(
              id: 'demo_scale_profile_spp',
              name: 'Demo SPP Scale Profile',
              payloadJson: jsonEncode({
                'id': 'demo_scale_profile_spp',
                'name': 'Demo SPP Scale Profile',
                'transport_type': 'classic_spp',
                'line_delimiter': '\\n',
                'weight_start': 2,
                'weight_length': 7,
                'explicit_decimal': true,
                'stable_character': 'S',
                'unstable_character': 'U',
                'unit_mapping': {'kg': 'kg', 'g': 'g'},
                'sample_raw_packets': ['S 012.480 kg', 'U 012.472 kg'],
              }),
            ),
          );

      await database
          .into(database.localCustomers)
          .insert(
            LocalCustomersCompanion.insert(
              id: 'demo_customer_hienergy',
              name: 'Hi-Energy Wires',
              code: const Value('CUST-HEW'),
              payloadJson: jsonEncode({
                'id': 'demo_customer_hienergy',
                'name': 'Hi-Energy Wires',
                'code': 'CUST-HEW',
                'contact_person': 'Production Manager',
                'phone': '+91 98765 43210',
                'shipping_address': 'KIADB Industrial Area, Vemgal',
                'is_active': true,
              }),
            ),
          );

      await database
          .into(database.localInwardSessions)
          .insert(
            LocalInwardSessionsCompanion.insert(
              id: 'demo_inward_session',
              sessionNumber: 'INW-DEMO-${_date(now)}',
              status: const Value('saved'),
              entryCount: const Value(3),
              totalGrossWeight: const Value(39.536),
              totalTareWeight: const Value(1.600),
              totalNetWeight: const Value(37.936),
              totalPieceQuantity: const Value(228),
              startedAt: sessionStart,
              endedAt: Value(now.subtract(const Duration(minutes: 38))),
            ),
          );

      final productionRows = [
        _production(
          id: 'demo_prod_001',
          serial: 'SN-92834',
          barcode: 'DEMO-BC-92834',
          product: productA,
          variant: (productA['variants'] as List<Map<String, dynamic>>).first,
          gross: 14.400,
          tare: 0.800,
          net: 13.600,
          pieces: 82,
          capturedAt: firstCapture,
          dynamicValues: {
            'size': '16',
            'color': 'Blue',
            'micron': '80',
            'width': '5600',
            'packing': 'Roll',
          },
        ),
        _production(
          id: 'demo_prod_002',
          serial: 'SN-92833',
          barcode: 'DEMO-BC-92833',
          product: productA,
          variant: (productA['variants'] as List<Map<String, dynamic>>).first,
          gross: 15.255,
          tare: 0.800,
          net: 14.455,
          pieces: 87,
          capturedAt: secondCapture,
          dynamicValues: {
            'size': '18',
            'color': 'Red',
            'micron': '100',
            'width': '8000',
            'packing': 'Bag',
          },
        ),
        _production(
          id: 'demo_prod_003',
          serial: 'SN-92835',
          barcode: 'DEMO-BC-92835',
          product: productB,
          variant: (productB['variants'] as List<Map<String, dynamic>>).first,
          gross: 12.481,
          tare: 0.000,
          net: 12.481,
          pieces: 12,
          capturedAt: thirdCapture,
          dynamicValues: {
            'size': '1m',
            'color': 'Natural',
            'micron': 'N/A',
            'width': 'Standard',
            'packing': 'Box',
          },
        ),
      ];

      for (final row in productionRows) {
        await database
            .into(database.localProductionTransactions)
            .insert(row.transaction);
        await database.into(database.localInventoryLedger).insert(row.ledger);
      }

      await database
          .into(database.localDispatches)
          .insert(
            LocalDispatchesCompanion.insert(
              id: 'demo_dispatch_001',
              dispatchNumber: 'DSP-DEMO-${_date(now)}',
              customerId: 'demo_customer_hienergy',
              customerSnapshotJson: jsonEncode({
                'id': 'demo_customer_hienergy',
                'name': 'Hi-Energy Wires',
                'code': 'CUST-HEW',
                'shipping_address': 'KIADB Industrial Area, Vemgal',
              }),
              status: const Value('confirmed'),
              totalWeight: const Value(13.600),
              totalPieces: const Value(82),
              syncStatus: const Value('synced'),
              idempotencyKey: 'idem_demo_dispatch_001',
              createdAt: dispatchTime,
              confirmedAt: Value(dispatchTime),
            ),
          );
      await database
          .into(database.localDispatchItems)
          .insert(
            LocalDispatchItemsCompanion.insert(
              id: 'demo_dispatch_item_001',
              dispatchId: 'demo_dispatch_001',
              productionTransactionId: 'demo_prod_001',
              barcodeValue: 'DEMO-BC-92834',
              weightQuantity: 13.600,
              pieceQuantity: const Value(82),
            ),
          );
      await database
          .into(database.localInventoryLedger)
          .insert(
            LocalInventoryLedgerCompanion.insert(
              id: 'demo_inv_dispatch_001',
              productId: 'demo_product_polymer',
              variantId: const Value('demo_variant_polymer_b900'),
              serialNumber: const Value('SN-92834'),
              barcodeValue: const Value('DEMO-BC-92834'),
              transactionType: 'dispatch_deduction',
              weightQuantity: 13.600,
              pieceQuantity: const Value(82),
              referenceType: 'dispatch',
              referenceId: 'demo_dispatch_001',
              syncStatus: const Value('synced'),
              occurredAt: dispatchTime,
            ),
          );

      await database
          .into(database.localConfigurationVersions)
          .insert(
            LocalConfigurationVersionsCompanion.insert(
              id: 'products',
              scope: 'products',
              version: 1,
              activatedAt: now,
            ),
          );
      await database
          .into(database.localConfigurationVersions)
          .insert(
            LocalConfigurationVersionsCompanion.insert(
              id: 'label_templates',
              scope: 'label_templates',
              version: 1,
              activatedAt: now,
            ),
          );
    });
  }

  Map<String, dynamic> _product({
    required String id,
    required String name,
    required String code,
    required String tare,
    required String min,
    required String max,
    required String target,
    required List<Map<String, dynamic>> variants,
  }) {
    return {
      'id': id,
      'name': name,
      'product_code': code,
      'sku': code,
      'is_active': true,
      'configuration_version': 1,
      'effective': {
        'tare_weight': tare,
        'minimum_weight': min,
        'maximum_weight': max,
        'target_weight': target,
        'product_lock_mode': 'none',
        'variant_lock_mode': 'none',
        'conversion_rule': {
          'method': 'pieces_per_kg',
          'pieces_per_kg': '5',
          'rounding_method': 'nearest',
          'decimal_places': 0,
        },
      },
      'variants': variants,
    };
  }

  Map<String, dynamic> _variant({
    required String id,
    required String productId,
    required String name,
    required String code,
    required String tare,
    required String min,
    required String max,
    required String target,
    required String piecesPerKg,
  }) {
    return {
      'id': id,
      'product_id': productId,
      'name': name,
      'variant_code': code,
      'is_active': true,
      'effective': {
        'tare_weight': tare,
        'minimum_weight': min,
        'maximum_weight': max,
        'target_weight': target,
        'product_lock_mode': 'none',
        'variant_lock_mode': 'none',
        'conversion_rule': {
          'method': 'pieces_per_kg',
          'pieces_per_kg': piecesPerKg,
          'rounding_method': 'nearest',
          'decimal_places': 0,
        },
      },
    };
  }

  _SeedProduction _production({
    required String id,
    required String serial,
    required String barcode,
    required Map<String, dynamic> product,
    required Map<String, dynamic> variant,
    required double gross,
    required double tare,
    required double net,
    required double pieces,
    required DateTime capturedAt,
    required Map<String, String> dynamicValues,
  }) {
    final snapshot = {'product': product, 'variant': variant};
    return _SeedProduction(
      transaction: LocalProductionTransactionsCompanion.insert(
        id: id,
        serialNumber: serial,
        barcodeValue: barcode,
        productId: product['id'] as String,
        variantId: Value(variant['id'] as String),
        inwardSessionId: const Value('demo_inward_session'),
        productSnapshotJson: jsonEncode(snapshot),
        dynamicValuesJson: Value(jsonEncode(dynamicValues)),
        grossWeight: gross,
        tareWeight: tare,
        netWeight: net,
        pieceQuantity: Value(pieces),
        unit: const Value('kg'),
        status: const Value('local_demo'),
        syncStatus: const Value('synced'),
        idempotencyKey: 'idem_$id',
        rawReadingJson: jsonEncode({
          'weight': gross,
          'unit': 'kg',
          'stable': true,
          'raw': 'S ${gross.toStringAsFixed(3)} kg',
          'receivedAt': capturedAt.toIso8601String(),
        }),
        capturedAt: capturedAt,
      ),
      ledger: LocalInventoryLedgerCompanion.insert(
        id: 'demo_inv_$id',
        productId: product['id'] as String,
        variantId: Value(variant['id'] as String),
        serialNumber: Value(serial),
        barcodeValue: Value(barcode),
        transactionType: 'production_addition',
        weightQuantity: net,
        pieceQuantity: Value(pieces),
        referenceType: 'production',
        referenceId: id,
        syncStatus: const Value('synced'),
        occurredAt: capturedAt,
      ),
    );
  }

  static String _date(DateTime date) =>
      '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';

  static final List<Map<String, dynamic>> _dynamicFields = [
    _field('demo_field_size', 'size', 'Size', 1, ['16', '18', '20', '1m']),
    _field('demo_field_color', 'color', 'Color', 2, ['Red', 'Blue', 'Natural']),
    _field('demo_field_micron', 'micron', 'Micron', 3, ['80', '100', 'N/A']),
    _field('demo_field_width', 'width', 'Width', 4, [
      '5600',
      '8000',
      'Standard',
    ]),
    _field('demo_field_packing', 'packing', 'Packing', 5, [
      'Roll',
      'Bag',
      'Box',
    ]),
  ];

  static Map<String, dynamic> _field(
    String id,
    String key,
    String label,
    int sortOrder,
    List<String> options,
  ) {
    return {
      'id': id,
      'entity_type': 'product',
      'internal_key': key,
      'field_label': label,
      'data_type': 'dropdown',
      'is_required': false,
      'visible_in_flutter': true,
      'editable_in_flutter': true,
      'printable_on_label': true,
      'visible_in_reports': true,
      'sort_order': sortOrder,
      'dropdown_options': options
          .map((value) => {'label': value, 'value': value})
          .toList(),
    };
  }

  static final Map<String, dynamic> _labelTemplate = {
    'id': 'demo_label_75x75',
    'name': 'Demo 75 x 75 Product Label',
    'code': 'DEMO-75X75',
    'scope': 'tenant',
    'isDefault': true,
    'activeVersion': 1,
    'templateJson': {
      'widthMm': 75,
      'heightMm': 75,
      'gridMm': 2.5,
      'elements': [
        {
          'key': 'company',
          'type': 'static_text',
          'bindingKey': 'PUNIT ERP',
          'x': 5,
          'y': 4,
          'width': 65,
          'height': 6,
        },
        {
          'key': 'product',
          'type': 'binding_text',
          'bindingKey': 'product.name',
          'x': 5,
          'y': 12,
          'width': 65,
          'height': 8,
        },
        {
          'key': 'net',
          'type': 'binding_text',
          'bindingKey': 'weight.net',
          'x': 5,
          'y': 22,
          'width': 30,
          'height': 7,
        },
        {
          'key': 'pieces',
          'type': 'binding_text',
          'bindingKey': 'pieces.quantity',
          'x': 40,
          'y': 22,
          'width': 30,
          'height': 7,
        },
        {
          'key': 'barcode',
          'type': 'barcode',
          'bindingKey': 'barcode.value',
          'x': 8,
          'y': 42,
          'width': 58,
          'height': 20,
        },
      ],
    },
  };
}

class _SeedProduction {
  const _SeedProduction({required this.transaction, required this.ledger});

  final LocalProductionTransactionsCompanion transaction;
  final LocalInventoryLedgerCompanion ledger;
}
