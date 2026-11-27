import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reorderable_grid_view/widgets/reorderable_builder.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helper/widget_test_helper.dart';

void main() {
  late List<int> items;

  setUp(() {
    items = const [0, 1, 2, 3];
  });

  /// Child 0 is a tall full row, 1 and 2 share the next row, 3 is a full row.
  Size sizeOf(int item) => switch (item) {
        0 => const Size(400.0, 300.0),
        3 => const Size(400.0, 100.0),
        _ => const Size(200.0, 100.0),
      };

  Future<void> pumpWidget(
    WidgetTester tester, {
    required bool enableLeastMovingOrder,
  }) async {
    tester.view.physicalSize = const Size(400.0, 800.0);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pumpWidgetWithMaterialApp(
      tester,
      child: SingleChildScrollView(
        child: StatefulBuilder(
          builder: (context, setState) => ReorderableBuilder<int>.wrap(
            onReorder: (reorder) => setState(() => items = reorder(items)),
            enableLeastMovingOrder: enableLeastMovingOrder,
            builder: (children) => Wrap(children: children),
            children: [
              for (final item in items)
                SizedBox.fromSize(
                  key: Key('$item'),
                  size: sizeOf(item),
                  child: const ColoredBox(color: Colors.lightBlue),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> dragAndRelease(
    WidgetTester tester, {
    required int item,
    required Offset position,
  }) async {
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(Key('$item'))),
      pointer: 7,
    );
    await tester.pump(kLongPressTimeout);
    await tester.pumpAndSettle();
    await gesture.moveTo(position);
    await tester.pumpAndSettle();
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets(
      'GIVEN [ReorderableBuilder.wrap] with enableLeastMovingOrder '
      'WHEN releasing a small child on a tall child '
      'THEN should keep the other small child in its column',
      (WidgetTester tester) async {
    // given
    await pumpWidget(tester, enableLeastMovingOrder: true);

    // when
    await dragAndRelease(tester, item: 2, position: const Offset(50, 50));

    // then
    expect(items, equals(const [2, 0, 1, 3]));
  });

  testWidgets(
      'GIVEN [ReorderableBuilder.wrap] without enableLeastMovingOrder '
      'WHEN releasing a small child on a tall child '
      'THEN should exchange both children', (WidgetTester tester) async {
    // given
    await pumpWidget(tester, enableLeastMovingOrder: false);

    // when
    await dragAndRelease(tester, item: 2, position: const Offset(50, 50));

    // then
    expect(items, equals(const [2, 1, 0, 3]));
  });
}
