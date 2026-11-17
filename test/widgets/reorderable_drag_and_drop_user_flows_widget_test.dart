import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reorderable_grid_view/widgets/reorderable_builder.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helper/widget_test_helper.dart';

/// Complete drag and drop flows as a user would do them.
void main() {
  const givenItems = [0, 1, 2, 3, 4, 5];
  const givenGridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 4,
  );

  late List<int> actualItems;

  setUp(() {
    actualItems = givenItems;
  });

  /// Returns the shown position of the child of [item].
  Offset getOffset(WidgetTester tester, int item) =>
      tester.getTopLeft(find.byKey(Key('$item')).last);

  /// Drags the child of [item] to [position] and releases it.
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

  group('#GridView', () {
    Widget buildChild(int item) => ColoredBox(
          key: Key('$item'),
          color: Colors.lightBlue,
        );

    Future<void> pumpWidget(
      WidgetTester tester, {
      required Widget Function(List<Widget> children) builder,
      List<int> lockedIndices = const [],
      ScrollController? scrollController,
    }) =>
        pumpWidgetWithMaterialApp(
          tester,
          child: ReorderableBuilder<int>(
            lockedIndices: lockedIndices,
            scrollController: scrollController,
            onReorder: (reorder) => actualItems = reorder(actualItems),
            builder: builder,
            children: [for (final item in givenItems) buildChild(item)],
          ),
        );

    testWidgets(
        'GIVEN [GridView] '
        'WHEN dragging the first child below all children and releasing it '
        'THEN should move it to the last position',
        (WidgetTester tester) async {
      // given
      await pumpWidget(
        tester,
        builder: (children) => GridView(
          gridDelegate: givenGridDelegate,
          children: children,
        ),
      );

      // when
      await dragAndRelease(tester, item: 0, position: const Offset(100, 550));

      // then
      expect(actualItems, equals(const [1, 2, 3, 4, 5, 0]));
    });

    testWidgets(
        'GIVEN [GridView] with top padding and locked first index '
        'WHEN dragging the last child above all children and releasing it '
        'THEN should move it to the first unlocked position',
        (WidgetTester tester) async {
      // given
      await pumpWidget(
        tester,
        lockedIndices: const [0],
        builder: (children) => GridView(
          padding: const EdgeInsets.only(top: 100),
          gridDelegate: givenGridDelegate,
          children: children,
        ),
      );

      // when
      await dragAndRelease(tester, item: 5, position: const Offset(300, 20));

      // then
      expect(actualItems, equals(const [0, 5, 1, 2, 3, 4]));
    });

    testWidgets(
        'GIVEN horizontal [GridView] '
        'WHEN dragging the first child right of all children and releasing it '
        'THEN should move it to the last position',
        (WidgetTester tester) async {
      // given
      final givenScrollController = ScrollController();
      final givenGridViewKey = GlobalKey();
      await pumpWidget(
        tester,
        scrollController: givenScrollController,
        builder: (children) => GridView(
          key: givenGridViewKey,
          controller: givenScrollController,
          scrollDirection: Axis.horizontal,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
          ),
          children: children,
        ),
      );

      // when
      await dragAndRelease(tester, item: 0, position: const Offset(750, 100));

      // then
      expect(actualItems, equals(const [1, 2, 3, 4, 5, 0]));
    });

    testWidgets(
        'GIVEN [GridView.count] '
        'WHEN dragging the first child below all children and releasing it '
        'THEN should move it to the last position',
        (WidgetTester tester) async {
      // given
      await pumpWidget(
        tester,
        builder: (children) => GridView.count(
          crossAxisCount: 4,
          children: children,
        ),
      );

      // when
      await dragAndRelease(tester, item: 0, position: const Offset(100, 550));

      // then
      expect(actualItems, equals(const [1, 2, 3, 4, 5, 0]));
    });

    testWidgets(
        'GIVEN [GridView.extent] '
        'WHEN dragging the first child below all children and releasing it '
        'THEN should move it to the last position',
        (WidgetTester tester) async {
      // given
      await pumpWidget(
        tester,
        builder: (children) => GridView.extent(
          maxCrossAxisExtent: 200,
          children: children,
        ),
      );

      // when
      await dragAndRelease(tester, item: 0, position: const Offset(100, 550));

      // then
      expect(actualItems, equals(const [1, 2, 3, 4, 5, 0]));
    });
  });

  group('#GridView.builder', () {
    testWidgets(
        'GIVEN [ReorderableBuilder.builder] with [GridView.builder] '
        'WHEN dragging the first child below all children and releasing it '
        'THEN should move it to the last position',
        (WidgetTester tester) async {
      // given
      final givenScrollController = ScrollController();
      final givenGridViewKey = GlobalKey();
      await pumpWidgetWithMaterialApp(
        tester,
        child: ReorderableBuilder<int>.builder(
          scrollController: givenScrollController,
          itemCount: givenItems.length,
          onReorder: (reorder) => actualItems = reorder(actualItems),
          childBuilder: (itemBuilder) => GridView.builder(
            key: givenGridViewKey,
            controller: givenScrollController,
            itemCount: givenItems.length,
            gridDelegate: givenGridDelegate,
            itemBuilder: (context, index) => itemBuilder(
              ColoredBox(key: Key('$index'), color: Colors.lightBlue),
              index,
            ),
          ),
        ),
      );

      // when
      await dragAndRelease(tester, item: 0, position: const Offset(100, 550));

      // then
      expect(actualItems, equals(const [1, 2, 3, 4, 5, 0]));
    });
  });

  /// The children have widths of 60, 100, 140, 180, 60, 100 and are laid out
  /// in a 400 wide [Wrap] with spacing 8 and runSpacing 4:
  ///
  /// ```
  /// [0][ 1 ][  2  ]
  /// [   3   ][4][ 5 ]
  /// ```
  group('#Wrap', () {
    late StateSetter setItems;
    final actualUpdatedIndices = <int>[];
    var grownItem = -1;

    setUp(() {
      actualUpdatedIndices.clear();
      grownItem = -1;
      final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views;
      view.first.physicalSize = const Size(400.0, 800.0);
      view.first.devicePixelRatio = 1.0;
    });

    tearDown(() {
      final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views;
      view.first.resetPhysicalSize();
      view.first.resetDevicePixelRatio();
    });

    Future<void> pumpWidget(
      WidgetTester tester, {
      List<int> lockedIndices = const [],
      WrapAlignment alignment = WrapAlignment.start,
      TextDirection? textDirection,
    }) =>
        pumpWidgetWithMaterialApp(
          tester,
          child: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setState) {
                setItems = setState;
                return ReorderableBuilder<int>.wrap(
                  lockedIndices: lockedIndices,
                  onReorder: (reorder) =>
                      setState(() => actualItems = reorder(actualItems)),
                  onUpdatedDraggedChild: actualUpdatedIndices.add,
                  builder: (children) => Wrap(
                    alignment: alignment,
                    textDirection: textDirection,
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: children,
                  ),
                  children: [
                    for (final item in actualItems)
                      SizedBox(
                        key: Key('$item'),
                        width: 60.0 + (item % 4) * 40.0,
                        height: item == grownItem ? 80.0 : 50.0,
                        child: const ColoredBox(color: Colors.lightBlue),
                      ),
                  ],
                );
              },
            ),
          ),
        );

    /// Starts dragging the child of [item] after a long press.
    Future<TestGesture> startDrag(WidgetTester tester, int item) async {
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(Key('$item'))),
        pointer: 7,
      );
      await tester.pump(kLongPressTimeout);
      await tester.pumpAndSettle();
      return gesture;
    }

    testWidgets(
        'GIVEN [ReorderableBuilder.wrap] '
        'WHEN dragging the first child onto the fourth child '
        'THEN should exchange both and move the others to make space',
        (WidgetTester tester) async {
      // given
      await pumpWidget(tester);

      // when
      final gesture = await startDrag(tester, 0);
      await gesture.moveTo(tester.getCenter(find.byKey(const Key('3'))));
      await tester.pumpAndSettle();

      // then
      expect(getOffset(tester, 3), equals(const Offset(0, 0)));
      expect(getOffset(tester, 1), equals(const Offset(188, 0)));
      expect(getOffset(tester, 2), equals(const Offset(0, 54)));
      expect(getOffset(tester, 4), equals(const Offset(216, 54)));
      expect(getOffset(tester, 5), equals(const Offset(284, 54)));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets(
        'GIVEN [ReorderableBuilder.wrap] '
        'WHEN releasing the first child on the fourth child '
        'THEN should reorder both and show them at their new position',
        (WidgetTester tester) async {
      // given
      await pumpWidget(tester);

      // when
      await dragAndRelease(
        tester,
        item: 0,
        position: tester.getCenter(find.byKey(const Key('3'))),
      );

      // then
      expect(actualItems, equals(const [3, 1, 2, 0, 4, 5]));
      expect(getOffset(tester, 3), equals(const Offset(0, 0)));
      expect(getOffset(tester, 0), equals(const Offset(148, 54)));
    });

    testWidgets(
        'GIVEN [ReorderableBuilder.wrap] '
        'WHEN dragging the small fifth child over the wide fourth child '
        'THEN should exchange them once without trembling',
        (WidgetTester tester) async {
      // given
      await pumpWidget(tester);
      final givenWideChildCenter = tester.getCenter(find.byKey(const Key('3')));

      // when
      final gesture = await startDrag(tester, 4);
      await gesture.moveTo(givenWideChildCenter);
      await tester.pump();
      await gesture.moveTo(givenWideChildCenter + const Offset(4, 0));
      await tester.pump();
      await gesture.moveTo(givenWideChildCenter + const Offset(8, 0));
      await tester.pump();

      // then
      expect(actualUpdatedIndices, equals(const [3]));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets(
        'GIVEN [ReorderableBuilder.wrap] with locked fourth child '
        'WHEN releasing the first child on the locked child '
        'THEN should not reorder the children', (WidgetTester tester) async {
      // given
      await pumpWidget(tester, lockedIndices: const [3]);

      // when
      await dragAndRelease(
        tester,
        item: 0,
        position: tester.getCenter(find.byKey(const Key('3'))),
      );

      // then
      expect(actualItems, equals(givenItems));
    });

    testWidgets(
        'GIVEN [ReorderableBuilder.wrap] with an already reordered child '
        'WHEN reordering it a second time '
        'THEN should show all children at their new position',
        (WidgetTester tester) async {
      // given
      await pumpWidget(tester);
      await dragAndRelease(
        tester,
        item: 0,
        position: tester.getCenter(find.byKey(const Key('3'))),
      );

      // when
      await dragAndRelease(
        tester,
        item: 0,
        position: tester.getCenter(find.byKey(const Key('1'))),
      );

      // then
      expect(actualItems, equals(const [3, 0, 2, 1, 4, 5]));
      expect(getOffset(tester, 3), equals(const Offset(0, 0)));
      expect(getOffset(tester, 0), equals(const Offset(188, 0)));
      expect(getOffset(tester, 2), equals(const Offset(256, 0)));
      expect(getOffset(tester, 1), equals(const Offset(0, 54)));
      expect(getOffset(tester, 4), equals(const Offset(108, 54)));
      expect(getOffset(tester, 5), equals(const Offset(176, 54)));
    });

    testWidgets(
        'GIVEN [ReorderableBuilder.wrap] '
        'WHEN removing the first child '
        'THEN should animate the third child to its new position',
        (WidgetTester tester) async {
      // given
      await pumpWidget(tester);

      // when
      setItems(() => actualItems = const [1, 2, 3, 4, 5]);
      await tester.pump();
      // after the fade out of the removed child and before the end
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      // then: on its way from 176 to 108
      expect(getOffset(tester, 2).dx, lessThan(176));
      expect(getOffset(tester, 2).dx, greaterThan(108));

      await tester.pumpAndSettle();
      expect(getOffset(tester, 2), equals(const Offset(108, 0)));
    });

    testWidgets(
        'GIVEN [ReorderableBuilder.wrap] '
        'WHEN removing all children at once '
        'THEN should not clip the removed children while fading out',
        (WidgetTester tester) async {
      // given
      await pumpWidget(tester);
      const givenRectOfFourthChild = Rect.fromLTWH(0, 54, 180, 50);

      // when
      setItems(() => actualItems = const []);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // then
      final actualVisibleArea = tester.getRect(
        find.byType(ReorderableBuilder<int>),
      );
      expect(
        actualVisibleArea.intersect(givenRectOfFourthChild),
        equals(givenRectOfFourthChild),
      );

      await tester.pumpAndSettle();
      expect(find.byKey(const Key('3')), findsNothing);
    });

    testWidgets(
        'GIVEN [ReorderableBuilder.wrap] without children '
        'WHEN adding children while the others are still moving and '
        'dragging one onto another '
        'THEN should show all children at the right position',
        (WidgetTester tester) async {
      // given
      await pumpWidget(tester);
      setItems(() => actualItems = []);
      await tester.pumpAndSettle();

      // when: adding a child every 128 ms with real frames of 16 ms
      for (var item = 100; item <= 112; item++) {
        setItems(() => actualItems.insert(0, item));
        for (var frame = 0; frame < 8; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
      }
      await tester.pumpAndSettle();
      final gesture = await startDrag(tester, 109);
      await gesture.moveTo(tester.getCenter(find.byKey(const Key('107'))));
      await tester.pumpAndSettle();

      // then: 109 and 107 are exchanged
      expect(getOffset(tester, 112), equals(const Offset(0, 0)));
      expect(getOffset(tester, 111), equals(const Offset(68, 0)));
      expect(getOffset(tester, 110), equals(const Offset(256, 0)));
      expect(getOffset(tester, 107), equals(const Offset(0, 54)));
      expect(getOffset(tester, 108), equals(const Offset(188, 54)));
      expect(getOffset(tester, 106), equals(const Offset(0, 108)));
      expect(getOffset(tester, 105), equals(const Offset(148, 108)));
      expect(getOffset(tester, 104), equals(const Offset(256, 108)));
      expect(getOffset(tester, 103), equals(const Offset(0, 162)));
      expect(getOffset(tester, 102), equals(const Offset(188, 162)));
      expect(getOffset(tester, 101), equals(const Offset(0, 216)));
      expect(getOffset(tester, 100), equals(const Offset(108, 216)));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets(
        'GIVEN [ReorderableBuilder.wrap] '
        'WHEN dragging the first child below all children and releasing it '
        'THEN should move it to the last position',
        (WidgetTester tester) async {
      // given
      await pumpWidget(tester);

      // when
      await dragAndRelease(tester, item: 0, position: const Offset(100, 700));

      // then
      expect(actualItems, equals(const [1, 2, 3, 4, 5, 0]));
    });

    testWidgets(
        'GIVEN [ReorderableBuilder.wrap] with a centered [Wrap] '
        'WHEN dragging the first child onto the fourth child and releasing it '
        'THEN should show all children centered at their new position',
        (WidgetTester tester) async {
      // given
      await pumpWidget(tester, alignment: WrapAlignment.center);

      // when
      final gesture = await startDrag(tester, 0);
      await gesture.moveTo(tester.getCenter(find.byKey(const Key('3'))));
      await tester.pumpAndSettle();

      // then: the Wrap gets the width of its widest run (384), so the first
      // run with 288 is centered at 48
      expect(getOffset(tester, 3), equals(const Offset(48, 0)));
      expect(getOffset(tester, 1), equals(const Offset(236, 0)));
      expect(getOffset(tester, 2), equals(const Offset(0, 54)));
      expect(getOffset(tester, 4), equals(const Offset(216, 54)));
      expect(getOffset(tester, 5), equals(const Offset(284, 54)));

      // when
      await gesture.up();
      await tester.pumpAndSettle();

      // then
      expect(actualItems, equals(const [3, 1, 2, 0, 4, 5]));
      expect(getOffset(tester, 0), equals(const Offset(148, 54)));
      expect(getOffset(tester, 3), equals(const Offset(48, 0)));
      expect(getOffset(tester, 5), equals(const Offset(284, 54)));
    });

    testWidgets(
        'GIVEN [ReorderableBuilder.wrap] with a right to left [Wrap] '
        'WHEN dragging the first child onto the fourth child and releasing it '
        'THEN should show all children from the right at their new position',
        (WidgetTester tester) async {
      // given
      await pumpWidget(tester, textDirection: TextDirection.rtl);

      // when
      final gesture = await startDrag(tester, 0);
      await gesture.moveTo(tester.getCenter(find.byKey(const Key('3'))));
      await tester.pumpAndSettle();

      // then: the runs end at the right of the Wrap with a width of 384
      expect(getOffset(tester, 3), equals(const Offset(204, 0)));
      expect(getOffset(tester, 1), equals(const Offset(96, 0)));
      expect(getOffset(tester, 2), equals(const Offset(244, 54)));
      expect(getOffset(tester, 4), equals(const Offset(108, 54)));
      expect(getOffset(tester, 5), equals(const Offset(0, 54)));

      // when
      await gesture.up();
      await tester.pumpAndSettle();

      // then
      expect(actualItems, equals(const [3, 1, 2, 0, 4, 5]));
      expect(getOffset(tester, 0), equals(const Offset(176, 54)));
      expect(getOffset(tester, 3), equals(const Offset(204, 0)));
      expect(getOffset(tester, 5), equals(const Offset(0, 54)));
    });

    testWidgets(
        'GIVEN [ReorderableBuilder.wrap] and a dragged child '
        'WHEN the parent builds new children while dragging '
        'THEN should keep all children at their dragged position',
        (WidgetTester tester) async {
      // given
      await pumpWidget(tester);
      final gesture = await startDrag(tester, 0);
      await gesture.moveTo(tester.getCenter(find.byKey(const Key('3'))));
      await tester.pumpAndSettle();
      final givenOffsets = [1, 2, 3, 4, 5].map((item) {
        return getOffset(tester, item);
      }).toList();

      // when
      setItems(() {});
      await tester.pumpAndSettle();

      // then
      final actualOffsets = [1, 2, 3, 4, 5].map((item) {
        return getOffset(tester, item);
      }).toList();
      expect(actualOffsets, equals(givenOffsets));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets(
        'GIVEN [ReorderableBuilder.wrap] and a dragged child '
        'WHEN another child changes its size while dragging '
        'THEN should keep the dragged order after releasing',
        (WidgetTester tester) async {
      // given
      await pumpWidget(tester);
      final gesture = await startDrag(tester, 0);
      await gesture.moveTo(tester.getCenter(find.byKey(const Key('3'))));
      await tester.pumpAndSettle();

      // when
      setItems(() => grownItem = 5);
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();

      // then
      expect(actualItems, equals(const [3, 1, 2, 0, 4, 5]));
      expect(tester.getSize(find.byKey(const Key('5'))).height, equals(80.0));
    });
  });

  /// Children of different sizes placed in a grid of cells by
  /// [ReorderableBuilder.layoutOffsets] instead of a [Wrap].
  group('#Wrap with layoutOffsets', () {
    const givenCellSize = 100.0;
    const givenColumns = 4;

    setUp(() {
      actualItems = const [0, 1, 2, 3, 4];
      final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views;
      view.first.physicalSize = const Size(400.0, 800.0);
      view.first.devicePixelRatio = 1.0;
    });

    tearDown(() {
      final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views;
      view.first.resetPhysicalSize();
      view.first.resetDevicePixelRatio();
    });

    /// Items 0 and 1 span 2x2 cells, the others one cell.
    Size sizeOf(int item) =>
        Size.square(item < 2 ? givenCellSize * 2 : givenCellSize);

    List<Offset> layOut(List<Size> sizes) => _CellGrid.layOut(
          sizes: sizes,
          cellSize: givenCellSize,
          columns: givenColumns,
        );

    Future<void> pumpWidget(
      WidgetTester tester, {
      List<int> lockedIndices = const [],
    }) =>
        pumpWidgetWithMaterialApp(
          tester,
          child: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setState) {
                return ReorderableBuilder<int>.wrap(
                  lockedIndices: lockedIndices,
                  onReorder: (reorder) =>
                      setState(() => actualItems = reorder(actualItems)),
                  layoutOffsets: ({
                    required keys,
                    required sizes,
                    required constraints,
                  }) =>
                      layOut(sizes),
                  builder: (children) {
                    final offsets = layOut(actualItems.map(sizeOf).toList());
                    return SizedBox(
                      height: givenCellSize * 3,
                      child: Stack(
                        children: [
                          for (final (index, child) in children.indexed)
                            Positioned(
                              key: child.key,
                              left: offsets[index].dx,
                              top: offsets[index].dy,
                              child: child,
                            ),
                        ],
                      ),
                    );
                  },
                  children: [
                    for (final item in actualItems)
                      SizedBox.fromSize(
                        key: Key('$item'),
                        size: sizeOf(item),
                        child: const ColoredBox(color: Colors.lightBlue),
                      ),
                  ],
                );
              },
            ),
          ),
        );

    testWidgets(
        'GIVEN [ReorderableBuilder.wrap] with layoutOffsets '
        'WHEN pumping it '
        'THEN should show the children at the calculated offsets',
        (WidgetTester tester) async {
      // when
      await pumpWidget(tester);

      // then
      expect(getOffset(tester, 0), equals(const Offset(0, 0)));
      expect(getOffset(tester, 1), equals(const Offset(200, 0)));
      expect(getOffset(tester, 2), equals(const Offset(0, 200)));
      expect(getOffset(tester, 3), equals(const Offset(100, 200)));
      expect(getOffset(tester, 4), equals(const Offset(200, 200)));
    });

    testWidgets(
        'GIVEN [ReorderableBuilder.wrap] with layoutOffsets '
        'WHEN releasing a small child on a big child '
        'THEN should move it to the order that places it under the pointer',
        (WidgetTester tester) async {
      // given
      await pumpWidget(tester);

      // when
      await dragAndRelease(tester, item: 4, position: const Offset(250, 50));

      // then
      expect(actualItems, equals(const [0, 4, 1, 2, 3]));
      expect(getOffset(tester, 4), equals(const Offset(200, 0)));
      expect(getOffset(tester, 1), equals(const Offset(200, 100)));
      expect(getOffset(tester, 2), equals(const Offset(300, 0)));
    });

    testWidgets(
        'GIVEN [ReorderableBuilder.wrap] with layoutOffsets '
        'WHEN releasing a child where no order can place it '
        'THEN should keep the order',
        (WidgetTester tester) async {
      // given
      await pumpWidget(tester);

      // when
      await dragAndRelease(tester, item: 2, position: const Offset(350, 250));

      // then
      expect(actualItems, equals(const [0, 1, 2, 3, 4]));
      expect(getOffset(tester, 2), equals(const Offset(0, 200)));
    });

    testWidgets(
        'GIVEN [ReorderableBuilder.wrap] with layoutOffsets and a locked child '
        'WHEN releasing another child on the locked child '
        'THEN should keep the locked child at its index',
        (WidgetTester tester) async {
      // given
      await pumpWidget(tester, lockedIndices: [0]);

      // when
      await dragAndRelease(tester, item: 4, position: const Offset(50, 50));

      // then
      expect(actualItems.first, equals(0));
      expect(getOffset(tester, 0), equals(const Offset(0, 0)));
    });

    testWidgets(
        'GIVEN [ReorderableBuilder.wrap] with layoutOffsets '
        'WHEN releasing a child on a later child '
        'THEN should exchange both and keep the child between them in place',
        (WidgetTester tester) async {
      // given
      await pumpWidget(tester);

      // when
      await dragAndRelease(tester, item: 2, position: const Offset(250, 250));

      // then
      expect(actualItems, equals(const [0, 1, 4, 3, 2]));
      expect(getOffset(tester, 2), equals(const Offset(200, 200)));
      expect(getOffset(tester, 4), equals(const Offset(0, 200)));
      expect(getOffset(tester, 3), equals(const Offset(100, 200)));
      expect(getOffset(tester, 0), equals(const Offset(0, 0)));
      expect(getOffset(tester, 1), equals(const Offset(200, 0)));
    });

    testWidgets(
        'GIVEN [ReorderableBuilder.wrap] with layoutOffsets and a dragged child '
        'WHEN the pointer moves around on the child it was moved over '
        'THEN should keep the order instead of moving back and forth',
        (WidgetTester tester) async {
      // given
      await pumpWidget(tester);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('4'))),
        pointer: 7,
      );
      await tester.pump(kLongPressTimeout);
      await tester.pumpAndSettle();

      // when
      for (final position in const [
        Offset(250, 50),
        Offset(280, 120),
        Offset(220, 180),
        Offset(260, 90),
      ]) {
        await gesture.moveTo(position);
        await tester.pumpAndSettle();
      }
      await gesture.up();
      await tester.pumpAndSettle();

      // then
      expect(actualItems, equals(const [0, 4, 1, 2, 3]));
    });

    testWidgets(
        'GIVEN [ReorderableBuilder.wrap] with layoutOffsets and a dragged child '
        'WHEN the pointer stays on the dragged child '
        'THEN should not change the order', (WidgetTester tester) async {
      // given
      await pumpWidget(tester);

      // when
      await dragAndRelease(tester, item: 3, position: const Offset(160, 260));

      // then
      expect(actualItems, equals(const [0, 1, 2, 3, 4]));
    });
  });

  /// Children measured while an outer scrollable is scrolled have to be at
  /// the same position as the children measured before scrolling.
  group('#outer scrollable', () {
    late StateSetter setItems;

    setUp(() {
      actualItems = List.generate(60, (index) => index);
      final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views;
      view.first.physicalSize = const Size(400.0, 800.0);
      view.first.devicePixelRatio = 1.0;
    });

    tearDown(() {
      final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views;
      view.first.resetPhysicalSize();
      view.first.resetDevicePixelRatio();
    });

    Widget buildChild(int item) => SizedBox(
          key: Key('$item'),
          width: 60.0 + (item % 4) * 40.0,
          height: 50.0,
          child: const ColoredBox(color: Colors.lightBlue),
        );

    Future<void> pumpWidget(
      WidgetTester tester, {
      required Widget Function(List<Widget> children) builder,
      required bool isWrap,
    }) =>
        pumpWidgetWithMaterialApp(
          tester,
          child: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setState) {
                setItems = setState;
                final children = [
                  for (final item in actualItems) buildChild(item),
                ];
                void onReorder(ReorderedListFunction<int> reorder) =>
                    setState(() => actualItems = reorder(actualItems));

                return isWrap
                    ? ReorderableBuilder<int>.wrap(
                        onReorder: onReorder,
                        builder: builder,
                        children: children,
                      )
                    : ReorderableBuilder<int>(
                        onReorder: onReorder,
                        builder: builder,
                        children: children,
                      );
              },
            ),
          ),
        );

    /// Scrolls down, adds a child at the first index and drags [item] onto
    /// [targetItem] without releasing it.
    Future<TestGesture> scrollAddAndDrag(
      WidgetTester tester, {
      required int item,
      required int targetItem,
    }) async {
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      setItems(() => actualItems.insert(0, 100));
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(Key('$item'))),
        pointer: 7,
      );
      await tester.pump(kLongPressTimeout);
      await tester.pumpAndSettle();
      await gesture.moveTo(tester.getCenter(find.byKey(Key('$targetItem'))));
      await tester.pumpAndSettle();
      return gesture;
    }

    testWidgets(
        'GIVEN scrolled [ReorderableBuilder] with [GridView] in an outer '
        'scrollable and a child added while scrolled '
        'WHEN dragging a child onto another child and releasing it '
        'THEN should move it to the index of the other child',
        (WidgetTester tester) async {
      // given
      await pumpWidget(
        tester,
        isWrap: false,
        builder: (children) => GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: givenGridDelegate,
          children: children,
        ),
      );

      // when
      final gesture = await scrollAddAndDrag(tester, item: 19, targetItem: 22);
      await gesture.up();
      await tester.pumpAndSettle();

      // then
      expect(actualItems.indexOf(19), equals(23));
    });

    testWidgets(
        'GIVEN scrolled [ReorderableBuilder.wrap] in an outer scrollable '
        'WHEN removing a visible child '
        'THEN should fade it out at its last position',
        (WidgetTester tester) async {
      // given
      await pumpWidget(
        tester,
        isWrap: true,
        builder: (children) => Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: children,
        ),
      );
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      final givenOffset = tester.getTopLeft(find.byKey(const Key('30')));

      // when
      setItems(() => actualItems.remove(30));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // then
      expect(tester.getTopLeft(find.byKey(const Key('30'))), givenOffset);
    });

    testWidgets(
        'GIVEN [ReorderableBuilder] with a shrink wrapped [GridView] and full '
        'rows '
        'WHEN adding a child at the first index that needs a new row '
        'THEN should move the other children only to their next position',
        (WidgetTester tester) async {
      // given
      await pumpWidget(
        tester,
        isWrap: false,
        builder: (children) => GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: givenGridDelegate,
          children: children,
        ),
      );
      final givenOffset = getOffset(tester, 21);

      // when
      setItems(() => actualItems.insert(0, 100));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      // then: 21 moves from the second to the third column of its row
      final actualOffset = getOffset(tester, 21);
      expect(actualOffset.dy, equals(givenOffset.dy));
      expect(actualOffset.dx, greaterThan(givenOffset.dx));

      await tester.pumpAndSettle();
      expect(getOffset(tester, 21).dy, equals(givenOffset.dy));
    });
  });
}

/// Places children in a grid of square cells.
///
/// Every child takes the first free cell, row by row, where it fits.
class _CellGrid {
  static List<Offset> layOut({
    required List<Size> sizes,
    required double cellSize,
    required int columns,
  }) {
    final taken = <(int, int)>{};
    final offsets = <Offset>[];
    for (final size in sizes) {
      final width = (size.width / cellSize).round();
      final height = (size.height / cellSize).round();
      var row = 0;
      var column = 0;
      while (!_fits(taken, row, column, width, height, columns)) {
        column++;
        if (column + width > columns) {
          column = 0;
          row++;
        }
      }
      for (var y = row; y < row + height; y++) {
        for (var x = column; x < column + width; x++) {
          taken.add((x, y));
        }
      }
      offsets.add(Offset(column * cellSize, row * cellSize));
    }
    return offsets;
  }

  static bool _fits(
    Set<(int, int)> taken,
    int row,
    int column,
    int width,
    int height,
    int columns,
  ) {
    if (column + width > columns) return false;
    for (var y = row; y < row + height; y++) {
      for (var x = column; x < column + width; x++) {
        if (taken.contains((x, y))) return false;
      }
    }
    return true;
  }
}
