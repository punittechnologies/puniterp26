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
}
