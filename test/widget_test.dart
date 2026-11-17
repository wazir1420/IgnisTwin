






import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ignistwin/main.dart';

void main() {
  testWidgets('fits the splash screen on a narrow phone', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const IgnisTwinApp());

    expect(find.text('IGNISTWIN', findRichText: true), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
