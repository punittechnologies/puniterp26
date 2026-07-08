import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:punit_tablet/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('renders protected tablet login', (tester) async {
    SharedPreferences.setMockInitialValues({});
    _setSurface(tester, const Size(1280, 800));

    await tester.pumpWidget(const ProviderScope(child: PunitTabletApp()));
    await tester.pumpAndSettle();

    expect(find.text('Punit ERP'), findsOneWidget);
    expect(find.text('Punit ERP App Login'), findsOneWidget);
    expect(find.text('Login & Auto-Sync'), findsOneWidget);
  });

  testWidgets('renders protected mobile portrait login', (tester) async {
    SharedPreferences.setMockInitialValues({});
    _setSurface(tester, const Size(390, 844));

    await tester.pumpWidget(const ProviderScope(child: PunitTabletApp()));
    await tester.pumpAndSettle();

    expect(find.text('Punit ERP'), findsOneWidget);
    expect(find.text('Login & Auto-Sync'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _setSurface(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
