import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:punit_tablet/features/weighing/presentation/searchable_selection_field.dart';

void main() {
  testWidgets('search control is visible and filters selectable values', (
    tester,
  ) async {
    String? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchableSelectionField<String>(
            label: 'Product',
            hint: 'Select product',
            value: null,
            options: const ['Aluminium Extrusion', 'Copper Wire'],
            optionLabel: (value) => value,
            onChanged: (value) => selected = value,
          ),
        ),
      ),
    );

    expect(find.text('Tap here to search and select'), findsOneWidget);
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);

    await tester.tap(find.text('Select product'));
    await tester.pumpAndSettle();

    expect(find.text('Search Product'), findsOneWidget);
    expect(find.text('Type to search'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('searchable-selection-query')),
      'copper',
    );
    await tester.pump();

    expect(find.text('Aluminium Extrusion'), findsNothing);
    expect(find.text('Copper Wire'), findsOneWidget);

    await tester.tap(find.text('Copper Wire'));
    await tester.pumpAndSettle();

    expect(selected, 'Copper Wire');
  });

  testWidgets('selected value stays readable with enlarged Android text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1280);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.8)),
          child: child!,
        ),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: SearchableSelectionField<String>(
              label: 'Product detail with a long field name',
              hint: 'Select product detail',
              value: 'A long selected product detail value',
              options: const ['A long selected product detail value'],
              optionLabel: (value) => value,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Product detail with a long field name'), findsOneWidget);
    expect(find.text('A long selected product detail value'), findsOneWidget);
    expect(find.text('Tap here to search and select'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
