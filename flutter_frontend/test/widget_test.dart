import 'package:flutter_test/flutter_test.dart';

import 'package:godavari_flutter/app.dart';
import 'package:godavari_flutter/src/state/shop_controller.dart';

void main() {
  testWidgets('app shell renders preview catalog', (tester) async {
    await tester.pumpWidget(GodavariApp(controller: ShopController.preview()));
    await tester.pumpAndSettle();

    expect(find.text('Godavari Ghaatu'), findsOneWidget);
    expect(find.text('Featured picks'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Shop'), findsOneWidget);
  });

  testWidgets('admin preview exposes store management entry point', (tester) async {
    await tester.pumpWidget(GodavariApp(controller: ShopController.preview(asAdmin: true)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();

    expect(find.text('Manage store'), findsOneWidget);
    expect(find.text('Open Admin Tools'), findsOneWidget);
  });

  testWidgets('admin preview opens control room and product studio', (tester) async {
    await tester.pumpWidget(GodavariApp(controller: ShopController.preview(asAdmin: true)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open Admin Tools'));
    await tester.pumpAndSettle();

    expect(find.text('Store Control Room'), findsOneWidget);
    expect(find.text('Open Studio'), findsWidgets);

    await tester.tap(find.text('Open Studio').first);
    await tester.pumpAndSettle();

    expect(find.text('Product Studio'), findsOneWidget);
    expect(find.text('Bundle'), findsOneWidget);
  });
}
