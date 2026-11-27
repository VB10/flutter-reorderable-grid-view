import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reorderable_grid_view/utils/definitions.dart';
import 'package:flutter_reorderable_grid_view/widgets/reorderable_builder.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helper/widget_test_helper.dart';

void main() {
  late ValueNotifier<double> height;
  late List<int> items;

  setUp(() {
    height = ValueNotifier<double>(100.0);
    items = const [0, 1, 2, 3];
  });

  tearDown(() => height.dispose());

  /// Lays out [sizes] in rows of [maxWidth] like a [Wrap] without spacing.
  List<Offset> wrapOffsets(List<Size> sizes, double maxWidth) {
    final offsets = <Offset>[];
    var x = 0.0;
    var y = 0.0;
    var runHeight = 0.0;
    for (final size in sizes) {
      if (x > 0 && x + size.width > maxWidth) {
        y += runHeight;
        x = 0;
        runHeight = 0;
      }
      offsets.add(Offset(x, y));
      x += size.width;
      runHeight = size.height > runHeight ? size.height : runHeight;
    }
    return offsets;
  }

  /// Child 0 is a full row that grows with [height], 1 and 2 share a row.
  Widget buildChild(int item) => item == 0
      ? ValueListenableBuilder<double>(
          key: Key('$item'),
          valueListenable: height,
          builder: (context, value, _) => SizedBox(
            width: 400.0,
            height: value,
            child: const ColoredBox(color: Colors.lightBlue),
          ),
        )
      : SizedBox(
          key: Key('$item'),
          width: item == 3 ? 400.0 : 200.0,
          height: 100.0,
          child: const ColoredBox(color: Colors.lightBlue),
        );

  Future<void> pumpWidget(
    WidgetTester tester, {
    ReorderableLayoutOffsets? layoutOffsets,
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
            layoutOffsets: layoutOffsets,
            builder: (children) => Wrap(children: children),
            children: [for (final item in items) buildChild(item)],
          ),
        ),
      ),
    );
  }

  /// Changes the size of child 0 again before its new size was measured.
  Future<void> changeSizeTwice(WidgetTester tester) async {
    height.value = 150.0;
    await tester.pump();
    await tester.pump();
    height.value = 220.0;
    await tester.pump();
    await tester.pumpAndSettle();
  }

  Future<TestGesture> dragOnto(
    WidgetTester tester, {
    required int item,
    required int target,
  }) async {
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(Key('$item'))),
      pointer: 7,
    );
    await tester.pump(kLongPressTimeout);
    await tester.pumpAndSettle();
    await gesture.moveTo(tester.getCenter(find.byKey(Key('$target'))));
    await tester.pumpAndSettle();
    return gesture;
  }

  testWidgets(
      'GIVEN [ReorderableBuilder.wrap] whose child changed its size twice '
      'in two following frames '
      'WHEN releasing a child on its neighbour '
      'THEN should exchange both', (WidgetTester tester) async {
    // given
    await pumpWidget(tester);
    await changeSizeTwice(tester);

    // when
    final gesture = await dragOnto(tester, item: 2, target: 1);
    await gesture.up();
    await tester.pumpAndSettle();

    // then
    expect(items, equals(const [0, 2, 1, 3]));
  });

  testWidgets(
      'GIVEN [ReorderableBuilder.wrap] whose child changed its size twice '
      'in two following frames '
      'WHEN dragging a child '
      'THEN should hide only the slot of the dragged child',
      (WidgetTester tester) async {
    // given
    await pumpWidget(tester);
    await changeSizeTwice(tester);

    // when
    final gesture = await dragOnto(tester, item: 2, target: 1);

    // then
    final hidden = tester
        .widgetList<Visibility>(find.byType(Visibility))
        .where((visibility) => !visibility.visible);
    expect(hidden, hasLength(1));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets(
      'GIVEN [ReorderableBuilder.wrap] with layoutOffsets whose child changed '
      'its size twice in two following frames '
      'WHEN dragging a child '
      'THEN should lay out the children with their real sizes',
      (WidgetTester tester) async {
    // given
    final laidOutSizes = <Size>[];
    await pumpWidget(
      tester,
      layoutOffsets: ({
        required keys,
        required sizes,
        required constraints,
      }) {
        laidOutSizes.addAll(sizes);
        return wrapOffsets(sizes, constraints.maxWidth);
      },
    );
    await changeSizeTwice(tester);

    // when
    final gesture = await dragOnto(tester, item: 2, target: 1);
    await gesture.up();
    await tester.pumpAndSettle();

    // then
    expect(laidOutSizes, isNotEmpty);
    expect(laidOutSizes, everyElement(isNot(Size.zero)));
    expect(items, equals(const [0, 2, 1, 3]));
  });
}
