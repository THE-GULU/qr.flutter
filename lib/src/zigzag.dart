import 'dart:math';

import 'package:flutter/painting.dart';

/// reference https://www.desmos.com/calculator/mcrxahzmm0
double getZigZagAxisCoordinate(
  double triangleHeight,
  double triangleBase,
  double coordinate, {
  double shift = 0,
}) {
  return ((coordinate + shift) / triangleBase -
              ((coordinate + shift) / triangleBase).floor() -
              0.5)
          .abs() *
      triangleHeight *
      2;
}

List<Point> getZigZagPointList(
  double triangleHeight,
  double triangleBase,
  Rect rect,
  Axis axis, {
  Offset? offset,
  double? ending,
  double shift = 0,
}) {
  assert(!rect.isEmpty);
  assert(ending == null || ending <= rect.right);
  assert(!shift.isNegative);

  offset ??= rect.topLeft;

  final pointList = <Point>[];

  switch (axis) {
    case Axis.horizontal:
      ending ??= rect.bottom;
      double startX = getZigZagAxisCoordinate(
        triangleHeight,
        triangleBase,
        0,
        shift: shift,
      );
      double startY = 0;

      pointList.add(Point(startX + offset.dx, startY + offset.dy));
      startY = startY + triangleBase / 2 - shift % (triangleBase / 2);
      while (startY < rect.height) {
        double shiftX = getZigZagAxisCoordinate(
          triangleHeight,
          triangleBase,
          startY,
          shift: shift,
        );
        pointList.add(Point(shiftX + offset.dx, startY + offset.dy));
        final nextStartY = startY + triangleBase / 2;
        if (nextStartY >= rect.height) {
          double shiftX = getZigZagAxisCoordinate(
            triangleHeight,
            triangleBase,
            rect.height,
            shift: shift,
          );
          pointList.add(Point(shiftX + offset.dx, ending));
          break;
        }
        startY = nextStartY;
      }
      break;

    case Axis.vertical:
      ending ??= rect.right;
      double startX = 0;
      double startY = getZigZagAxisCoordinate(
        triangleHeight,
        triangleBase,
        0,
        shift: shift,
      );

      pointList.add(Point(startX + offset.dx, startY + offset.dy));
      startX = startX + triangleBase / 2 - shift % (triangleBase / 2);
      while (startX < rect.width) {
        double shiftY = getZigZagAxisCoordinate(
          triangleHeight,
          triangleBase,
          startX,
          shift: shift,
        );
        pointList.add(Point(startX + offset.dx, shiftY + offset.dy));
        final nextStartX = startX + triangleBase / 2;
        if (nextStartX >= rect.width) {
          double shiftY = getZigZagAxisCoordinate(
            triangleHeight,
            triangleBase,
            rect.width,
            shift: shift,
          );
          pointList.add(Point(ending, shiftY + offset.dy));
          break;
        }
        startX = nextStartX;
      }
      break;
  }

  return pointList;
}

/// [start] bottom starting point of zigzag
Path getZigZagPath(
  double triangleHeight,
  double triangleBase,
  Rect rect,
  Axis axis, {
  Offset? offset,
  double? ending,
  double shift = 0,
}) {
  assert(!rect.isEmpty);
  assert(ending == null || ending <= rect.right);
  assert(!shift.isNegative);

  final path = Path();
  final pointList = getZigZagPointList(triangleHeight, triangleBase, rect, axis,
      offset: offset, ending: ending, shift: shift);

  final topZigZagPath = Path()
    ..moveTo(pointList.first.x.toDouble(), pointList.first.y.toDouble());
  for (final point in pointList.skip(1)) {
    topZigZagPath.lineTo(point.x.toDouble(), point.y.toDouble());
  }
  path.extendWithPath(topZigZagPath, Offset.zero);

  return path.shift(offset ?? rect.topLeft);
}

Path getZigZagRectPath(
  double triangleHeight,
  double triangleBase,
  Rect rect,
  Axis axis, {
  Offset? offset,
  double? ending,
  double shift = 0,
  bool clipStart = true,
  bool clipEnd = true,
}) {
  final path = Path();

  final topPointList = getZigZagPointList(
      triangleHeight, triangleBase, rect, axis,
      shift: shift);
  final bottomPointList = getZigZagPointList(
      triangleHeight, triangleBase, rect, axis,
      shift: triangleBase / 2);
  switch (axis) {
    case Axis.horizontal:
      if (clipStart) {
        final topZigZagPath = Path()
          ..moveTo(
              topPointList.first.x.toDouble(), topPointList.first.y.toDouble());
        for (final point in topPointList.skip(1)) {
          topZigZagPath.lineTo(point.x.toDouble(), point.y.toDouble());
        }
        path.extendWithPath(topZigZagPath, Offset.zero);
      } else {
        path.moveTo(rect.left, rect.top);
        path.lineTo(rect.left, rect.bottom);
      }

      // bottom zigzag path
      if (clipEnd) {
        final reversedPointList = bottomPointList.reversed;
        final bottomZigZagPath = Path()
          ..moveTo(reversedPointList.first.x.toDouble(),
              reversedPointList.first.y.toDouble());
        for (final point in reversedPointList.skip(1)) {
          bottomZigZagPath.lineTo(point.x.toDouble(), point.y.toDouble());
        }
        path.extendWithPath(
            bottomZigZagPath, Offset(rect.width - triangleHeight, 0));
      } else {
        path.lineTo(rect.right, rect.bottom);
        path.lineTo(rect.right, rect.top);
      }
      break;

    case Axis.vertical:
      if (clipStart) {
        final topZigZagPath = Path()
          ..moveTo(
              topPointList.first.x.toDouble(), topPointList.first.y.toDouble());
        for (final point in topPointList.skip(1)) {
          topZigZagPath.lineTo(point.x.toDouble(), point.y.toDouble());
        }
        path.extendWithPath(topZigZagPath, Offset.zero);
      } else {
        path.moveTo(rect.left, rect.top);
        path.lineTo(rect.right, rect.top);
      }

      if (clipEnd) {
        final reversedPointList = bottomPointList.reversed;
        final bottomZigZagPath = Path()
          ..moveTo(reversedPointList.first.x.toDouble(),
              reversedPointList.first.y.toDouble());
        for (final point in reversedPointList.skip(1)) {
          bottomZigZagPath.lineTo(point.x.toDouble(), point.y.toDouble());
        }
        path.extendWithPath(
            bottomZigZagPath, Offset(0, rect.height - triangleHeight));
      } else {
        path.lineTo(rect.right, rect.bottom);
        path.lineTo(rect.left, rect.bottom);
      }
      break;
  }

  path.close();
  return path;
}
