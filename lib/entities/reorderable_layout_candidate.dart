import 'package:flutter/widgets.dart';
import 'package:flutter_reorderable_grid_view/entities/reorderable_entity.dart';

/// An order of the children and the offsets they are laid out at in it.
///
/// Used to compare the orders a dragged child can move to when the positions
/// come from [ReorderableBuilder.layoutOffsets].
class ReorderableLayoutCandidate {
  /// The children in this order.
  final List<ReorderableEntity> order;

  /// The offset of every child of [order], at the same index.
  final List<Offset> offsets;

  const ReorderableLayoutCandidate({
    required this.order,
    required this.offsets,
  });

  /// Returns the offset of [entity] in this order.
  Offset offsetOf(ReorderableEntity entity) =>
      offsets[order.indexWhere((child) => child.key == entity.key)];

  /// Returns the area [entity] covers in this order.
  Rect rectOf(ReorderableEntity entity) => offsetOf(entity) & entity.size;

  /// Returns how far all children except [movedEntity] moved compared to
  /// [previous].
  double movementFrom(
    ReorderableLayoutCandidate previous, {
    required ReorderableEntity movedEntity,
  }) {
    var movement = 0.0;
    for (final (index, entity) in order.indexed) {
      if (entity.key == movedEntity.key) {
        continue;
      }
      movement += (offsets[index] - previous.offsetOf(entity)).distance;
    }
    return movement;
  }
}
