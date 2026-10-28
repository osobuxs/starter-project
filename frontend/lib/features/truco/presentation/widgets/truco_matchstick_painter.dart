import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Paints matchstick groups stacked vertically, like a paper "anotador":
/// each group of five is a square of four sticks closed by a diagonal.
///
/// Every stick gets a small rotation/offset jitter and head tint derived
/// from [seed] and its index, so the drawing looks hand-made but never
/// changes between frames.
class TrucoMatchstickPainter extends CustomPainter {
  /// Sticks per group, e.g. `[5, 5, 2]`.
  final List<int> groups;

  /// Number of square slots reserved (keeps both teams aligned).
  final int slots;
  final int seed;

  const TrucoMatchstickPainter({
    required this.groups,
    required this.slots,
    this.seed = 0,
  });

  static const double cellExtent = 52;

  static const _woodLight = Color(0xFFF1D9A8);
  static const _woodDark = Color(0xFFC79A5B);
  static const _woodEdge = Color(0xFF8D6A3A);

  /// Base head colors; each stick picks one plus a small brightness shift.
  static const _headColors = [
    Color(0xFFD32F2F),
    Color(0xFFB71C1C),
    Color(0xFFC62828),
    Color(0xFF9E1B1B),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, cellExtent) - 16;
    final left = (size.width - side) / 2;

    var stickIndex = 0;
    for (var g = 0; g < groups.length; g++) {
      final top = g * cellExtent + (cellExtent - side) / 2;
      final square = Rect.fromLTWH(left, top, side, side);
      final count = groups[g].clamp(0, 5);
      for (var s = 0; s < count; s++) {
        final segment = _segmentFor(s, square);
        _paintStick(canvas, segment.from, segment.to, stickIndex++);
      }
    }
  }

  /// Stick order: left, top, right, bottom, then the closing diagonal.
  /// The second offset is where the head goes.
  _Segment _segmentFor(int stick, Rect r) {
    switch (stick) {
      case 0:
        return _Segment(r.bottomLeft, r.topLeft);
      case 1:
        return _Segment(r.topLeft, r.topRight);
      case 2:
        return _Segment(r.topRight, r.bottomRight);
      case 3:
        return _Segment(r.bottomRight, r.bottomLeft);
      default:
        return _Segment(
            r.bottomLeft.translate(3, -3), r.topRight.translate(-3, 3));
    }
  }

  void _paintStick(Canvas canvas, Offset from, Offset to, int index) {
    final random = math.Random(seed * 7919 + index * 104729);
    final jitterAngle = (random.nextDouble() - 0.5) * 0.09; // ~±2.5°
    final jitter = Offset(
      (random.nextDouble() - 0.5) * 2.4,
      (random.nextDouble() - 0.5) * 2.4,
    );

    final start = from + jitter;
    final delta = to - from;
    final length = delta.distance;
    final angle = delta.direction + jitterAngle;
    const thickness = 4.2;
    const headLength = 8.5;
    const headWidth = 7.2;

    canvas.save();
    canvas.translate(start.dx, start.dy);
    canvas.rotate(angle);

    // Soft shadow under the whole match.
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(1.2, -thickness / 2 + 1.8, length, thickness),
        const Radius.circular(2),
      ),
      shadow,
    );

    // Wooden body with a light grain gradient across its width.
    final body =
        Rect.fromLTWH(0, -thickness / 2, length - headLength / 2, thickness);
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(1.4)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_woodLight, _woodDark],
        ).createShader(body),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(1.4)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
        ..color = _woodEdge.withValues(alpha: 0.6),
    );

    // Rounded red head with a small highlight.
    final base = _headColors[random.nextInt(_headColors.length)];
    final head = Color.lerp(base, Colors.black, random.nextDouble() * 0.18)!;
    final headRect = Rect.fromCenter(
      center: Offset(length - headLength / 2, 0),
      width: headLength,
      height: headWidth,
    );
    canvas.drawOval(
      headRect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 0.9,
          colors: [Color.lerp(head, Colors.white, 0.28)!, head],
        ).createShader(headRect),
    );
    canvas.drawOval(
      headRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6
        ..color = Colors.black.withValues(alpha: 0.35),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant TrucoMatchstickPainter oldDelegate) {
    return oldDelegate.slots != slots ||
        oldDelegate.seed != seed ||
        !_sameGroups(oldDelegate.groups, groups);
  }

  static bool _sameGroups(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class _Segment {
  final Offset from;
  final Offset to;

  const _Segment(this.from, this.to);
}
