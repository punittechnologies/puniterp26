import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/database/local_database.dart';
import '../../products/data/product_repository.dart';
import '../../products/domain/product_models.dart';
import '../data/label_template_repository.dart';
import '../domain/label_template_models.dart';

class LabelPreviewScreen extends StatefulWidget {
  const LabelPreviewScreen({super.key});

  @override
  State<LabelPreviewScreen> createState() => _LabelPreviewScreenState();
}

class _LabelPreviewScreenState extends State<LabelPreviewScreen> {
  late final LocalDatabase database;
  late final LabelTemplateRepository labelRepository;
  late final ProductRepository productRepository;

  final templateName = TextEditingController(text: 'Default Tablet Label');
  final companyName = TextEditingController(text: 'PUNIT ERP');
  final headerLine1 = TextEditingController();
  final headerLine2 = TextEditingController();
  final footerText = TextEditingController();

  String labelSize = '75x75';
  String? selectedTemplateId;
  String headerAlign = 'center';
  String footerAlign = 'center';
  int headerFontSize = 10;
  int footerFontSize = 8;
  bool printGross = true;
  bool printTare = true;
  bool printNet = true;
  bool printPieces = false;
  bool printDateTime = false;
  bool printSerialNumber = true;
  bool printBorder = false;
  bool printLogo = false;
  String? logoImagePath;
  String? logoImageBase64;
  String? selectedElementKey;
  final elementLayouts = <String, Map<String, double>>{};
  Map<String, double>? gestureStartLayout;
  double gestureStartFontSize = 9;
  List<LabelTemplateConfig> templates = [];
  List<DynamicFieldConfig> fields = [];
  final selectedBindings = <String>['product.name'];
  final fieldFontSizes = <String, int>{'product.name': 10};
  final fieldAlignments = <String, String>{'product.name': 'left'};
  bool saved = false;

  static const sizes = <String, (double, double)>{
    '75x75': (75, 75),
    '100x100': (100, 100),
    '75x100': (75, 100),
    '50x75': (75, 50),
    '100x150': (100, 150),
  };

  @override
  void initState() {
    super.initState();
    database = LocalDatabase();
    labelRepository = LabelTemplateRepository(database: database);
    productRepository = ProductRepository(database: database);
    _load();
  }

  @override
  void dispose() {
    templateName.dispose();
    companyName.dispose();
    headerLine1.dispose();
    headerLine2.dispose();
    footerText.dispose();
    database.close();
    super.dispose();
  }

  Future<void> _load() async {
    await labelRepository.sync();
    templates = await labelRepository.cachedTemplates();
    selectedTemplateId = await labelRepository.selectedTemplateId();
    fields = await _labelFields();
    final existing = await labelRepository.effective();
    if (existing != null) {
      selectedTemplateId ??= existing.id;
      _applyTemplate(existing);
    }
    if (mounted) setState(() {});
  }

  void _applyTemplate(LabelTemplateConfig template) {
    final structured = template.templateJson['structured'];
    templateName.text = template.name;
    if (structured is! Map<String, dynamic>) {
      _applyRawTemplateJson(template.templateJson);
      return;
    }

    labelSize = structured['labelSize']?.toString() ?? labelSize;
    companyName.text =
        structured['companyName']?.toString() ?? companyName.text;
    headerLine1.text = structured['headerLine1']?.toString() ?? '';
    headerLine2.text = structured['headerLine2']?.toString() ?? '';
    footerText.text = structured['footerText']?.toString() ?? '';
    headerAlign = structured['headerAlign']?.toString() ?? headerAlign;
    footerAlign = structured['footerAlign']?.toString() ?? footerAlign;
    headerFontSize =
        int.tryParse('${structured['headerFontSize']}') ?? headerFontSize;
    footerFontSize =
        int.tryParse('${structured['footerFontSize']}') ?? footerFontSize;
    printBorder =
        structured['printBorder'] == true || structured['autoBorder'] == true;
    printLogo =
        structured['printLogo'] == true ||
        structured['printPhotoBackground'] == true;
    logoImagePath =
        structured['logoImagePath']?.toString() ??
        structured['sourceImagePath']?.toString();
    logoImageBase64 = structured['logoImageBase64']?.toString();

    final layouts = structured['elementLayouts'];
    elementLayouts.clear();
    if (layouts is Map) {
      for (final entry in layouts.entries) {
        final raw = entry.value;
        if (raw is Map) {
          elementLayouts[entry.key.toString()] = raw.map(
            (key, value) => MapEntry(
              key.toString(),
              double.tryParse(value.toString()) ?? 0,
            ),
          );
        }
      }
    }

    final selected = structured['selectedBindings'];
    if (selected is List) {
      selectedBindings
        ..clear()
        ..addAll(selected.map((item) => _normalizeBinding(item.toString())));
    }
    if (selectedBindings.isEmpty) selectedBindings.add('product.name');

    final weights = structured['weights'];
    if (weights is Map) {
      printGross = weights['gross'] == true;
      printTare = weights['tare'] == true;
      printNet = weights['net'] != false;
      printPieces = weights['pieces'] == true;
      printDateTime = weights['dateTime'] == true;
      printSerialNumber = weights['serialNumber'] != false;
    }

    final fontSizes = structured['fieldFontSizes'];
    if (fontSizes is Map) {
      fieldFontSizes
        ..clear()
        ..addEntries(
          fontSizes.entries.map(
            (entry) => MapEntry(
              _normalizeBinding(entry.key.toString()),
              int.tryParse('${entry.value}') ?? 9,
            ),
          ),
        );
    }
    final alignments = structured['fieldAlignments'];
    if (alignments is Map) {
      fieldAlignments
        ..clear()
        ..addEntries(
          alignments.entries.map(
            (entry) => MapEntry(
              _normalizeBinding(entry.key.toString()),
              entry.value.toString(),
            ),
          ),
        );
    }
  }

  void _applyRawTemplateJson(Map<String, dynamic> templateJson) {
    labelSize = _sizeKeyFromDimensions(
      _asDouble(templateJson['widthMm']) ?? sizes[labelSize]?.$1 ?? 75,
      _asDouble(templateJson['heightMm']) ?? sizes[labelSize]?.$2 ?? 75,
    );
    selectedBindings
      ..clear()
      ..add('product.name');
    fieldFontSizes
      ..clear()
      ..addAll({'product.name': 10});
    fieldAlignments
      ..clear()
      ..addAll({'product.name': 'left'});
    elementLayouts.clear();
    headerLine1.clear();
    headerLine2.clear();
    footerText.clear();
    printBorder = false;
    printLogo = false;
    logoImagePath = null;
    logoImageBase64 = null;
    printGross = false;
    printTare = false;
    printNet = false;
    printPieces = false;
    printDateTime = false;
    printSerialNumber = false;

    final elements = templateJson['elements'];
    if (elements is! List) return;

    var headerIndex = 0;
    final footerLines = <String>[];
    for (final raw in elements) {
      if (raw is! Map) continue;
      final element = raw.map((key, value) => MapEntry(key.toString(), value));
      final type = element['type']?.toString();
      final binding = element['bindingKey']?.toString();
      final rawKey = element['key']?.toString() ?? '';
      final key = binding == null || binding.isEmpty
          ? rawKey
          : _elementKeyForBinding(_normalizeBinding(binding));
      _storeElementLayout(key, element);

      if (type == 'rectangle') {
        printBorder = true;
      } else if (type == 'image') {
        printLogo = true;
        logoImagePath = element['imagePath']?.toString();
        logoImageBase64 = element['imageBase64']?.toString();
      } else if (type == 'barcode') {
        _storeElementLayout('barcode', element);
      } else if (type == 'text') {
        final text = element['text']?.toString().trim() ?? '';
        if (text.isEmpty) continue;
        if (rawKey.startsWith('footer')) {
          footerLines.add(text);
        } else if (headerIndex == 0) {
          companyName.text = text;
          headerIndex++;
        } else if (headerIndex == 1) {
          headerLine1.text = text;
          headerIndex++;
        } else if (headerIndex == 2) {
          headerLine2.text = text;
          headerIndex++;
        } else {
          footerLines.add(text);
        }
      } else if (binding != null && binding.isNotEmpty) {
        final normalized = _normalizeBinding(binding);
        final style = element['style'];
        final font = style is Map
            ? int.tryParse(style['fontSize']?.toString() ?? '')
            : null;
        final align = style is Map ? style['align']?.toString() : null;
        switch (normalized) {
          case 'product.name':
            if (!selectedBindings.contains(normalized)) {
              selectedBindings.add(normalized);
            }
          case 'batch.number':
            if (!selectedBindings.contains(normalized)) {
              selectedBindings.add(normalized);
            }
          case 'weight.gross':
            printGross = true;
          case 'weight.tare':
            printTare = true;
          case 'weight.net':
            printNet = true;
          case 'pieces.quantity':
            printPieces = true;
          case 'serial.number':
            printSerialNumber = true;
          case 'date.current':
          case 'time.current':
            printDateTime = true;
          default:
            if (normalized.startsWith('dynamic.') &&
                !selectedBindings.contains(normalized)) {
              selectedBindings.add(normalized);
            }
        }
        fieldFontSizes[normalized] = font ?? fieldFontSizes[normalized] ?? 9;
        fieldAlignments[normalized] =
            align ?? fieldAlignments[normalized] ?? 'left';
      }
    }

    if (selectedBindings.isEmpty) selectedBindings.add('product.name');
    if (!printGross && !printTare && !printNet && !printPieces) {
      printNet = true;
    }
    if (footerLines.isNotEmpty) {
      footerText.text = footerLines.take(2).join('\n');
    }
  }

  void _storeElementLayout(String key, Map<String, dynamic> element) {
    final layout = <String, double>{};
    for (final property in ['x', 'y', 'width', 'height']) {
      final value = _asDouble(element[property]);
      if (value != null) layout[property] = value;
    }
    final style = element['style'];
    if (style is Map) {
      final fontSize = _asDouble(style['fontSize']);
      if (fontSize != null) layout['fontSize'] = fontSize;
    }
    if (layout.isNotEmpty) elementLayouts[key] = layout;
  }

  String _sizeKeyFromDimensions(double width, double height) {
    for (final entry in sizes.entries) {
      if ((entry.value.$1 - width).abs() < 0.5 &&
          (entry.value.$2 - height).abs() < 0.5) {
        return entry.key;
      }
    }
    if ((width - 50).abs() < 0.5 && (height - 75).abs() < 0.5) {
      return '50x75';
    }
    return sizes.entries.reduce((best, next) {
      final bestScore =
          (best.value.$1 - width).abs() + (best.value.$2 - height).abs();
      final nextScore =
          (next.value.$1 - width).abs() + (next.value.$2 - height).abs();
      return nextScore < bestScore ? next : best;
    }).key;
  }

  double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  Future<List<DynamicFieldConfig>> _labelFields() async {
    final productFields = await productRepository.cachedFields(
      entityType: 'product',
    );
    final variantFields = await productRepository.cachedFields(
      entityType: 'product_variant',
    );
    final byKey = <String, DynamicFieldConfig>{};
    for (final field in [...productFields, ...variantFields]) {
      byKey.putIfAbsent(field.internalKey, () => field);
    }
    return byKey.values.toList()
      ..sort((a, b) => a.fieldLabel.compareTo(b.fieldLabel));
  }

  Map<String, dynamic> _templateJson() {
    final size = sizes[labelSize] ?? sizes['75x75']!;
    final width = size.$1;
    final height = size.$2;
    final contentRows = _contentRows().take(_maxContentRows()).toList();

    final elements = <Map<String, dynamic>>[];
    var order = 1;
    if (printBorder) {
      elements.add(
        _withLayout({
          'key': 'label_border',
          'type': 'rectangle',
          'x': 1.2,
          'y': 1.2,
          'width': width - 2.4,
          'height': height - 2.4,
          'border': {'width': 0.35},
          'layerOrder': order++,
        }),
      );
    }
    final hasLogo =
        printLogo &&
        (logoImagePath?.isNotEmpty == true ||
            logoImageBase64?.isNotEmpty == true);
    if (hasLogo) {
      elements.add(
        _withLayout({
          'key': 'logo_image',
          'type': 'image',
          'imagePath': logoImagePath,
          'imageBase64': logoImageBase64,
          'x': 3,
          'y': 3,
          'width': width >= 100 ? 24 : 18,
          'height': 10,
          'layerOrder': order++,
        }),
      );
    }
    var y = 3.0;
    for (var index = 0; index < _headerLines().length; index++) {
      final line = _headerLines()[index];
      elements.add(
        _withLayout(
          _text(
            index == 0 ? 'header_company' : 'header_line_$index',
            line,
            hasLogo ? 23 : 3,
            y,
            hasLogo ? width - 26 : width - 6,
            5.6,
            order++,
            align: headerAlign,
            weight: line == companyName.text.trim() ? '800' : '600',
            font: line == companyName.text.trim()
                ? headerFontSize + 1
                : headerFontSize,
          ),
        ),
      );
      y += 6.2;
    }

    final barcodeHeight = height >= 100 ? 16.0 : 12.5;
    final barcodeY = height - barcodeHeight - 5;
    final footerLines = _lines(footerText.text, 2);
    final contentTop = (y + 2).clamp(12.0, height * 0.32);
    final contentBottom = barcodeY - (footerLines.length * 5.4) - 2;
    final rowHeight =
        ((contentBottom - contentTop) / contentRows.length.clamp(1, 20)).clamp(
          4.6,
          8.2,
        );
    y = contentTop;

    for (final key in contentRows) {
      final font = fieldFontSizes[key] ?? (key == 'weight.net' ? 11 : 9);
      elements.add(
        _withLayout(
          _binding(
            _elementKeyForBinding(key),
            key,
            4,
            y,
            width - 8,
            rowHeight,
            order++,
            prefix: '${_labelFor(key)}: ',
            suffix: key.startsWith('weight.') ? ' kg' : '',
            weight: key == 'weight.net' ? '800' : '600',
            font: font,
            align: fieldAlignments[key] ?? 'left',
          ),
        ),
      );
      y += rowHeight;
    }

    var footerY = barcodeY - footerLines.length * 5.4 - 1;
    for (var index = 0; index < footerLines.length; index++) {
      final line = footerLines[index];
      elements.add(
        _withLayout(
          _text(
            'footer_line_$index',
            line,
            3,
            footerY,
            width - 6,
            5,
            order++,
            align: footerAlign,
            weight: '500',
            font: footerFontSize,
          ),
        ),
      );
      footerY += 5.4;
    }

    elements.add(
      _withLayout({
        'key': 'barcode',
        'type': 'barcode',
        'bindingKey': 'barcode.value',
        'x': 5,
        'y': barcodeY,
        'width': width - 10,
        'height': barcodeHeight,
        'layerOrder': order,
      }),
    );

    return {
      'widthMm': width,
      'heightMm': height,
      'gridMm': 2.5,
      'mode': 'structured',
      'structured': {
        'labelSize': labelSize,
        'companyName': companyName.text,
        'headerLine1': headerLine1.text,
        'headerLine2': headerLine2.text,
        'footerText': footerText.text,
        'headerAlign': headerAlign,
        'footerAlign': footerAlign,
        'headerFontSize': headerFontSize,
        'footerFontSize': footerFontSize,
        'printBorder': printBorder,
        'printLogo': printLogo,
        'logoImagePath': logoImagePath,
        'logoImageBase64': logoImageBase64,
        'elementLayouts': elementLayouts,
        'selectedBindings': selectedBindings
            .map((key) => _normalizeBinding(key))
            .toList(),
        'fieldFontSizes': fieldFontSizes,
        'fieldAlignments': fieldAlignments,
        'weights': {
          'gross': printGross,
          'tare': printTare,
          'net': printNet,
          'pieces': printPieces,
          'dateTime': printDateTime,
          'serialNumber': printSerialNumber,
        },
      },
      'elements': elements,
    };
  }

  Future<void> _save() async {
    try {
      await labelRepository.saveLocalTenantDefault(
        name: templateName.text.trim().isEmpty
            ? 'Default Tablet Label'
            : templateName.text.trim(),
        templateJson: _templateJson(),
      );
      await labelRepository.sync();
      templates = await labelRepository.cachedTemplates();
      selectedTemplateId =
          await labelRepository.selectedTemplateId() ??
          await labelRepository.currentLocalTemplateId();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Template not saved to server: $error'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFB42318),
        ),
      );
      return;
    }
    if (!mounted) return;
    setState(() => saved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Label template saved and selected for printing.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF087A4A),
      ),
    );
  }

  Future<void> _pickLogoImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      logoImagePath = picked.path;
      logoImageBase64 = base64Encode(bytes);
      printLogo = true;
      selectedElementKey = 'logo_image';
      saved = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 780;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Label Designer'),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('SAVE'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (compact) ...[
            _editor(),
            const SizedBox(height: 16),
            _preview(),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _editor()),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _preview()),
              ],
            ),
        ],
      ),
    );
  }

  Widget _editor() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (templates.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                initialValue:
                    templates.any((item) => item.id == selectedTemplateId)
                    ? selectedTemplateId
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Selected print template',
                  border: OutlineInputBorder(),
                ),
                items: templates
                    .map(
                      (template) => DropdownMenuItem(
                        value: template.id,
                        child: Text(template.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) async {
                  if (value == null) return;
                  final template = templates.firstWhere(
                    (item) => item.id == value,
                  );
                  await labelRepository.selectTemplate(value);
                  setState(() {
                    selectedTemplateId = value;
                    _applyTemplate(template);
                    saved = false;
                  });
                },
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: templateName,
              decoration: const InputDecoration(
                labelText: 'Template name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey('label-size-$labelSize'),
              initialValue: labelSize,
              decoration: const InputDecoration(
                labelText: 'Label size',
                border: OutlineInputBorder(),
              ),
              items: sizes.keys
                  .map(
                    (size) => DropdownMenuItem(
                      value: size,
                      child: Text(_sizeLabel(size)),
                    ),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => labelSize = value ?? labelSize),
            ),
            const SizedBox(height: 18),
            _sectionTitle('Logo, Image & Border'),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickLogoImage,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('UPLOAD LOGO / IMAGE'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() {
                      printBorder = !printBorder;
                      selectedElementKey = printBorder ? 'label_border' : null;
                      saved = false;
                    }),
                    icon: Icon(
                      printBorder
                          ? Icons.check_box_outlined
                          : Icons.crop_square_rounded,
                    ),
                    label: Text(printBorder ? 'BORDER ON' : 'ADD BORDER'),
                  ),
                ),
              ],
            ),
            if (logoImagePath?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Print uploaded image'),
                subtitle: const Text(
                  'Drag and pinch this image in the preview. It will print in the same position.',
                ),
                value: printLogo,
                onChanged: (value) => setState(() {
                  printLogo = value;
                  if (value) selectedElementKey = 'logo_image';
                  saved = false;
                }),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Tap any item in preview, drag with one finger, pinch with two fingers to resize.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 18),
            _sectionTitle('Header'),
            TextField(
              controller: companyName,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Company name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: headerLine1,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Header line 2',
                hintText: 'Phone / GST / location',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: headerLine2,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Header line 3',
                hintText: 'Optional',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _fontDropdown(
                    label: 'Header font',
                    value: headerFontSize,
                    onChanged: (value) =>
                        setState(() => headerFontSize = value),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _alignDropdown(
                    label: 'Header align',
                    value: headerAlign,
                    onChanged: (value) => setState(() => headerAlign = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _sectionTitle('Content Fields'),
            Text(
              'Selected fields print in this order. Use arrows to move fields up or down.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            _fieldPicker(),
            const SizedBox(height: 10),
            ..._contentRows().map(_fieldSettings),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 2,
              children: [
                _weightCheck('Gross', printGross, (v) => printGross = v),
                _weightCheck('Tare', printTare, (v) => printTare = v),
                _weightCheck('Net', printNet, (v) => printNet = v),
                _weightCheck('Pieces', printPieces, (v) => printPieces = v),
                _weightCheck(
                  'Date & Time',
                  printDateTime,
                  (v) => printDateTime = v,
                ),
                _weightCheck(
                  'Sr. No',
                  printSerialNumber,
                  (v) => printSerialNumber = v,
                ),
              ],
            ),
            const SizedBox(height: 18),
            _sectionTitle('Footer'),
            TextField(
              controller: footerText,
              minLines: 2,
              maxLines: 3,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Optional footer text',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _fontDropdown(
                    label: 'Footer font',
                    value: footerFontSize,
                    onChanged: (value) =>
                        setState(() => footerFontSize = value),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _alignDropdown(
                    label: 'Footer align',
                    value: footerAlign,
                    onChanged: (value) => setState(() => footerAlign = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(saved ? 'SAVED - UPDATE TEMPLATE' : 'SAVE TEMPLATE'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldPicker() {
    final available = <MapEntry<String, String>>[
      const MapEntry('product.name', 'Product name'),
      ...fields.map((field) => MapEntry(_dynamicKey(field), field.fieldLabel)),
    ];
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: available.map((entry) {
          final selected = selectedBindings.contains(entry.key);
          return FilterChip(
            selected: selected,
            label: Text(entry.value, overflow: TextOverflow.ellipsis),
            onSelected: (value) => _toggle(entry.key, value),
          );
        }).toList(),
      ),
    );
  }

  Widget _fieldSettings(String key) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final title = Row(
          children: [
            Expanded(
              child: Text(
                _labelFor(key),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            IconButton(
              tooltip: 'Move up',
              onPressed: selectedBindings.contains(key)
                  ? () => _moveField(key, -1)
                  : null,
              icon: const Icon(Icons.keyboard_arrow_up_rounded),
            ),
            IconButton(
              tooltip: 'Move down',
              onPressed: selectedBindings.contains(key)
                  ? () => _moveField(key, 1)
                  : null,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
            ),
          ],
        );
        final controls = Row(
          children: [
            Expanded(
              child: _fontDropdown(
                label: 'Font',
                value: fieldFontSizes[key] ?? (key == 'weight.net' ? 11 : 9),
                onChanged: (value) =>
                    setState(() => fieldFontSizes[key] = value),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _alignDropdown(
                label: 'Align',
                value: fieldAlignments[key] ?? 'left',
                onChanged: (value) =>
                    setState(() => fieldAlignments[key] = value),
              ),
            ),
          ],
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: compact
              ? Column(children: [title, const SizedBox(height: 8), controls])
              : Row(
                  children: [
                    Expanded(flex: 2, child: title),
                    const SizedBox(width: 10),
                    Expanded(flex: 3, child: controls),
                  ],
                ),
        );
      },
    );
  }

  Widget _fieldLimitNotice() {
    final total = _contentRows().length;
    final limit = _maxContentRows();
    if (total <= limit) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        'This label size can print $limit content rows clearly. $total are selected, so extra rows are not printed.',
        style: const TextStyle(
          color: Color(0xFFB45309),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _fontDropdown({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    final sizes = [7, 8, 9, 10, 11, 12, 14, 16];
    return DropdownButtonFormField<int>(
      key: ValueKey('$label-$value'),
      initialValue: sizes.contains(value) ? value : 9,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      items: sizes
          .map((size) => DropdownMenuItem(value: size, child: Text('$size')))
          .toList(),
      onChanged: (value) => onChanged(value ?? 9),
    );
  }

  Widget _alignDropdown({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    const values = ['left', 'center', 'right', 'justify'];
    return DropdownButtonFormField<String>(
      key: ValueKey('$label-$value'),
      initialValue: values.contains(value) ? value : 'left',
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      items: values
          .map(
            (align) => DropdownMenuItem(
              value: align,
              child: Text(align.toUpperCase()),
            ),
          )
          .toList(),
      onChanged: (value) => onChanged(value ?? 'left'),
    );
  }

  Widget _preview() {
    final json = _templateJson();
    final widthMm = json['widthMm'] as double;
    final heightMm = json['heightMm'] as double;
    final elements = (json['elements'] as List).cast<Map<String, dynamic>>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Interactive Label Preview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap, drag, and pinch items here. This exact layout is used for printing.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            if (selectedElementKey != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Selected: ${_friendlyElementName(selectedElementKey!)}',
                      style: const TextStyle(
                        color: Color(0xFF0B57D0),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _deleteSelectedElement,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Remove'),
                  ),
                ],
              ),
              _selectedElementControls(elements, widthMm, heightMm),
            ],
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final scale = (constraints.maxWidth / widthMm).clamp(1.4, 4.4);
                final width = widthMm * scale;
                final height = heightMm * scale;
                return Center(
                  child: Container(
                    width: width,
                    height: height,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: const Color(0xFF0B57D0),
                        width: 2,
                      ),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 16),
                      ],
                    ),
                    child: Stack(
                      children: elements.map((element) {
                        final key = element['key'].toString();
                        final selected = selectedElementKey == key;
                        return Positioned(
                          left: (element['x'] as num).toDouble() * scale,
                          top: (element['y'] as num).toDouble() * scale,
                          width: (element['width'] as num).toDouble() * scale,
                          height: (element['height'] as num).toDouble() * scale,
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () =>
                                setState(() => selectedElementKey = key),
                            onScaleStart: (details) =>
                                setState(() => _startElementGesture(element)),
                            onScaleUpdate: (details) => _updateElementGesture(
                              element,
                              details,
                              widthMm,
                              heightMm,
                              scale,
                            ),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xFF0B57D0)
                                      : Colors.transparent,
                                  width: selected ? 1.4 : 0,
                                ),
                              ),
                              child: _PreviewElement(
                                element: element,
                                label: _previewText(element),
                                scale: scale,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
            _fieldLimitNotice(),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _withLayout(Map<String, dynamic> element) {
    final key = element['key']?.toString() ?? '';
    final layout = elementLayouts[key];
    if (layout == null) return element;
    final copy = Map<String, dynamic>.from(element);
    for (final property in ['x', 'y', 'width', 'height']) {
      final value = layout[property];
      if (value != null) copy[property] = value;
    }
    final fontSize = layout['fontSize'];
    if (fontSize != null && copy['style'] is Map) {
      copy['style'] = Map<String, dynamic>.from(copy['style'] as Map)
        ..['fontSize'] = fontSize.round();
    }
    return copy;
  }

  void _startElementGesture(Map<String, dynamic> element) {
    final key = element['key'].toString();
    selectedElementKey = key;
    gestureStartLayout = {
      'x': (element['x'] as num).toDouble(),
      'y': (element['y'] as num).toDouble(),
      'width': (element['width'] as num).toDouble(),
      'height': (element['height'] as num).toDouble(),
      'fontSize': _elementFontSize(element),
    };
    gestureStartFontSize = _elementFontSize(element);
  }

  void _updateElementGesture(
    Map<String, dynamic> element,
    ScaleUpdateDetails details,
    double labelWidth,
    double labelHeight,
    double scale,
  ) {
    final start = gestureStartLayout;
    if (start == null) return;
    final key = element['key'].toString();
    final dx = details.focalPointDelta.dx / scale;
    final dy = details.focalPointDelta.dy / scale;
    final next = Map<String, double>.from(elementLayouts[key] ?? start);

    next['x'] = ((next['x'] ?? start['x']!) + dx).clamp(0, labelWidth - 2);
    next['y'] = ((next['y'] ?? start['y']!) + dy).clamp(0, labelHeight - 2);

    if ((details.scale - 1).abs() > .01) {
      final width = (start['width']! * details.scale).clamp(3, labelWidth);
      final height = (start['height']! * details.scale).clamp(3, labelHeight);
      next['width'] = width.toDouble();
      next['height'] = height.toDouble();
      if (_isTextElement(element)) {
        next['fontSize'] = (gestureStartFontSize * details.scale)
            .clamp(6, 24)
            .toDouble();
      }
    }

    next['x'] = (next['x'] ?? 0).clamp(0, labelWidth - (next['width'] ?? 2));
    next['y'] = (next['y'] ?? 0).clamp(0, labelHeight - (next['height'] ?? 2));

    setState(() {
      selectedElementKey = key;
      elementLayouts[key] = next;
      saved = false;
    });
  }

  void _nudgeSelected(
    Map<String, dynamic> element,
    double labelWidth,
    double labelHeight, {
    double dx = 0,
    double dy = 0,
  }) {
    final key = element['key'].toString();
    final next = _layoutFromElement(element);
    next['x'] = ((next['x'] ?? 0) + dx).clamp(
      0,
      labelWidth - (next['width'] ?? 2),
    );
    next['y'] = ((next['y'] ?? 0) + dy).clamp(
      0,
      labelHeight - (next['height'] ?? 2),
    );
    setState(() {
      selectedElementKey = key;
      elementLayouts[key] = next;
      saved = false;
    });
  }

  void _resizeSelected(
    Map<String, dynamic> element,
    double labelWidth,
    double labelHeight, {
    double dw = 0,
    double dh = 0,
  }) {
    final key = element['key'].toString();
    final next = _layoutFromElement(element);
    next['width'] = ((next['width'] ?? 3) + dw).clamp(3, labelWidth);
    next['height'] = ((next['height'] ?? 3) + dh).clamp(3, labelHeight);
    next['x'] = (next['x'] ?? 0).clamp(0, labelWidth - (next['width'] ?? 3));
    next['y'] = (next['y'] ?? 0).clamp(0, labelHeight - (next['height'] ?? 3));
    setState(() {
      selectedElementKey = key;
      elementLayouts[key] = next;
      saved = false;
    });
  }

  void _fontSelected(Map<String, dynamic> element, int delta) {
    final key = element['key'].toString();
    final next = _layoutFromElement(element);
    next['fontSize'] = ((next['fontSize'] ?? _elementFontSize(element)) + delta)
        .clamp(6, 24)
        .toDouble();
    setState(() {
      selectedElementKey = key;
      elementLayouts[key] = next;
      saved = false;
    });
  }

  Map<String, double> _layoutFromElement(Map<String, dynamic> element) {
    final key = element['key'].toString();
    return Map<String, double>.from(
      elementLayouts[key] ??
          {
            'x': (element['x'] as num).toDouble(),
            'y': (element['y'] as num).toDouble(),
            'width': (element['width'] as num).toDouble(),
            'height': (element['height'] as num).toDouble(),
            'fontSize': _elementFontSize(element),
          },
    );
  }

  bool _isTextElement(Map<String, dynamic> element) =>
      element['type'] == 'text' || element['type'] == 'binding_text';

  double _elementFontSize(Map<String, dynamic> element) {
    final style = element['style'];
    if (style is Map) {
      return double.tryParse(style['fontSize']?.toString() ?? '') ?? 9;
    }
    return 9;
  }

  void _deleteSelectedElement() {
    final key = selectedElementKey;
    if (key == null) return;
    setState(() {
      if (key == 'logo_image') {
        printLogo = false;
      } else if (key == 'label_border') {
        printBorder = false;
      } else if (key == 'header_company') {
        companyName.clear();
      } else if (key == 'header_line_1') {
        headerLine1.clear();
      } else if (key == 'header_line_2') {
        headerLine2.clear();
      } else if (key.startsWith('footer_line_')) {
        footerText.clear();
      } else if (key == 'field_weight_gross') {
        printGross = false;
      } else if (key == 'field_weight_tare') {
        printTare = false;
      } else if (key == 'field_weight_net') {
        printNet = false;
      } else if (key == 'field_pieces_quantity') {
        printPieces = false;
      } else if (key == 'field_serial_number') {
        printSerialNumber = false;
      } else if (key == 'field_date_current' || key == 'field_time_current') {
        printDateTime = false;
      } else if (key == 'barcode') {
        elementLayouts.remove(key);
      } else if (key.startsWith('field_')) {
        selectedBindings.remove(_bindingFromElementKey(key));
      }
      elementLayouts.remove(key);
      selectedElementKey = null;
      saved = false;
    });
  }

  String _friendlyElementName(String key) {
    if (key == 'logo_image') return 'Logo / image';
    if (key == 'label_border') return 'Border';
    if (key == 'barcode') return 'Barcode';
    if (key == 'header_company') return 'Company name';
    if (key.startsWith('header_line_')) return 'Header line';
    if (key.startsWith('footer_line_')) return 'Footer';
    if (key.startsWith('field_')) return _labelFor(_bindingFromElementKey(key));
    return key;
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
    ),
  );

  String _sizeLabel(String size) {
    final mm = sizes[size] ?? sizes['75x75']!;
    if (size == '50x75') {
      return '75 x 50 mm (50 height x 75 width)';
    }
    return '${mm.$1.toStringAsFixed(0)} x ${mm.$2.toStringAsFixed(0)} mm';
  }

  Widget _weightCheck(String label, bool value, ValueChanged<bool> update) {
    return FilterChip(
      selected: value,
      label: Text(label),
      onSelected: (selected) => setState(() => update(selected)),
    );
  }

  Widget _selectedElementControls(
    List<Map<String, dynamic>> elements,
    double labelWidth,
    double labelHeight,
  ) {
    final key = selectedElementKey;
    if (key == null) return const SizedBox.shrink();
    final matches = elements.where((element) => element['key'] == key).toList();
    if (matches.isEmpty) return const SizedBox.shrink();
    final element = matches.first;
    final isText = _isTextElement(element);

    Widget button(IconData icon, String label, VoidCallback onPressed) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          button(
            Icons.keyboard_arrow_left_rounded,
            'Left',
            () => _nudgeSelected(element, labelWidth, labelHeight, dx: -1),
          ),
          button(
            Icons.keyboard_arrow_right_rounded,
            'Right',
            () => _nudgeSelected(element, labelWidth, labelHeight, dx: 1),
          ),
          button(
            Icons.keyboard_arrow_up_rounded,
            'Up',
            () => _nudgeSelected(element, labelWidth, labelHeight, dy: -1),
          ),
          button(
            Icons.keyboard_arrow_down_rounded,
            'Down',
            () => _nudgeSelected(element, labelWidth, labelHeight, dy: 1),
          ),
          button(
            Icons.width_normal_rounded,
            'Wider',
            () => _resizeSelected(element, labelWidth, labelHeight, dw: 2),
          ),
          button(
            Icons.height_rounded,
            'Taller',
            () => _resizeSelected(element, labelWidth, labelHeight, dh: 2),
          ),
          if (isText)
            button(
              Icons.text_increase_rounded,
              'Text +',
              () => _fontSelected(element, 1),
            ),
          if (isText)
            button(
              Icons.text_decrease_rounded,
              'Text -',
              () => _fontSelected(element, -1),
            ),
        ],
      ),
    );
  }

  void _toggle(String key, bool value) {
    key = _normalizeBinding(key);
    setState(() {
      if (value) {
        if (!selectedBindings.contains(key)) selectedBindings.add(key);
        fieldFontSizes.putIfAbsent(key, () => key == 'weight.net' ? 11 : 9);
        fieldAlignments.putIfAbsent(key, () => 'left');
      } else {
        selectedBindings.remove(key);
      }
    });
  }

  void _moveField(String key, int delta) {
    key = _normalizeBinding(key);
    final index = selectedBindings.indexOf(key);
    if (index < 0) return;
    final next = (index + delta).clamp(0, selectedBindings.length - 1);
    if (next == index) return;
    setState(() {
      selectedBindings
        ..removeAt(index)
        ..insert(next, key);
    });
  }

  List<String> _contentRows() => [
    if (printSerialNumber) 'serial.number',
    ...selectedBindings,
    if (printGross) 'weight.gross',
    if (printTare) 'weight.tare',
    if (printNet) 'weight.net',
    if (printPieces) 'pieces.quantity',
    if (printDateTime) 'date.current',
    if (printDateTime) 'time.current',
  ];

  int _maxContentRows() {
    final height = sizes[labelSize]?.$2 ?? 75;
    if (height >= 150) return 14;
    if (height >= 100) return 12;
    return 10;
  }

  List<String> _headerLines() =>
      [
            companyName.text.trim(),
            headerLine1.text.trim(),
            headerLine2.text.trim(),
          ]
          .where((line) => line.isNotEmpty)
          .take(labelSize == '50x75' ? 2 : 3)
          .toList();

  String _dynamicKey(DynamicFieldConfig field) =>
      'dynamic.${field.internalKey}';

  String _elementKeyForBinding(String key) =>
      'field_${_normalizeBinding(key).replaceAll('.', '_')}';

  String _bindingFromElementKey(String key) =>
      key.replaceFirst('field_', '').replaceAll('_', '.');

  String _normalizeBinding(String key) {
    if (!key.startsWith('dynamic.')) return key;
    return 'dynamic.${key.split('.').last}';
  }

  String _labelFor(String key) {
    if (key == 'product.name') return 'Product';
    if (key == 'weight.gross') return 'Gross';
    if (key == 'weight.tare') return 'Tare';
    if (key == 'weight.net') return 'Net';
    if (key == 'pieces.quantity') return 'PCS';
    if (key == 'batch.number') return 'Batch No';
    if (key == 'serial.number') return 'Sr. No';
    if (key == 'date.current') return 'Date';
    if (key == 'time.current') return 'Time';
    for (final field in fields) {
      if (_dynamicKey(field) == _normalizeBinding(key)) return field.fieldLabel;
    }
    return key.split('.').last;
  }

  String _previewText(Map<String, dynamic> element) {
    if (element['type'] == 'barcode') return '||||| BARCODE |||||';
    if (element['type'] == 'text') return '${element['text']}';
    final key = '${element['bindingKey']}';
    final value = switch (key) {
      'product.name' => 'Sample Product',
      'weight.gross' => '12.474',
      'weight.tare' => '0.800',
      'weight.net' => '11.674',
      'pieces.quantity' => '48',
      'batch.number' => 'BATCH-01',
      'serial.number' => '1',
      'date.current' => '2026-07-03',
      'time.current' => '18:30',
      _ => 'Value',
    };
    return '${element['prefix'] ?? ''}$value${element['suffix'] ?? ''}';
  }

  List<String> _lines(String text, int limit) {
    final maxChars = switch (labelSize) {
      '50x75' => 30,
      '75x75' => 28,
      '75x100' => 28,
      '100x100' => 40,
      '100x150' => 40,
      _ => 32,
    };
    final lines = <String>[];
    for (final raw in text.split('\n')) {
      final words = raw.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
      var current = '';
      for (final word in words) {
        final next = current.isEmpty ? word : '$current $word';
        if (next.length > maxChars && current.isNotEmpty) {
          lines.add(current);
          current = word;
        } else {
          current = next;
        }
        if (lines.length >= limit) return lines;
      }
      if (current.isNotEmpty) lines.add(current);
      if (lines.length >= limit) return lines;
    }
    return lines.take(limit).toList();
  }

  Map<String, dynamic> _text(
    String key,
    String text,
    double x,
    double y,
    double width,
    double height,
    int order, {
    int? font,
    String weight = '600',
    String align = 'left',
  }) => {
    'key': key,
    'type': 'text',
    'text': text,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'layerOrder': order,
    'style': {
      'fontSize': font ?? 9,
      'fontFamily': 'Arial',
      'fontWeight': weight,
      'align': align,
    },
  };

  Map<String, dynamic> _binding(
    String key,
    String bindingKey,
    double x,
    double y,
    double width,
    double height,
    int order, {
    String prefix = '',
    String suffix = '',
    int? font,
    String weight = '600',
    String align = 'left',
  }) => {
    'key': key,
    'type': 'binding_text',
    'bindingKey': bindingKey,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'layerOrder': order,
    'prefix': prefix,
    'suffix': suffix,
    'style': {
      'fontSize': font ?? 9,
      'fontFamily': 'Arial',
      'fontWeight': weight,
      'align': align,
    },
  };
}

class _PreviewElement extends StatelessWidget {
  const _PreviewElement({
    required this.element,
    required this.label,
    required this.scale,
  });

  final Map<String, dynamic> element;
  final String label;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final style = (element['style'] as Map?) ?? const {};
    if (element['type'] == 'rectangle') {
      final border = (element['border'] as Map?) ?? const {};
      return Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.black87,
            width: (((border['width'] as num?) ?? .35).toDouble() * scale)
                .clamp(1, 3),
          ),
        ),
      );
    }
    if (element['type'] == 'image') {
      final path = element['imagePath']?.toString();
      final encoded = element['imageBase64']?.toString();
      if (encoded != null && encoded.isNotEmpty) {
        return Image.memory(
          base64Decode(encoded),
          fit: BoxFit.fill,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        );
      }
      if (path != null && path.isNotEmpty) {
        return Image.file(
          File(path),
          fit: BoxFit.fill,
          errorBuilder: (_, _, _) => Container(
            color: const Color(0xFFF1F5F9),
            alignment: Alignment.center,
            child: const Text('Image unavailable'),
          ),
        );
      }
      return const SizedBox.shrink();
    }
    if (element['type'] == 'barcode') {
      return Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          border: Border.all(color: Colors.black87),
        ),
        child: Text(
          label,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
        ),
      );
    }
    return Text(
      label,
      overflow: TextOverflow.clip,
      textAlign: switch (style['align']) {
        'center' => TextAlign.center,
        'right' => TextAlign.right,
        'justify' => TextAlign.justify,
        _ => TextAlign.left,
      },
      style: TextStyle(
        fontSize: ((style['fontSize'] as num?) ?? 9).toDouble() * scale * 0.42,
        fontWeight: _weight('${style['fontWeight'] ?? '600'}'),
        color: const Color(0xFF0F172A),
      ),
    );
  }

  FontWeight _weight(String value) => switch (value) {
    '300' => FontWeight.w300,
    '400' => FontWeight.w400,
    '500' => FontWeight.w500,
    '700' => FontWeight.w700,
    '800' => FontWeight.w800,
    _ => FontWeight.w600,
  };
}
