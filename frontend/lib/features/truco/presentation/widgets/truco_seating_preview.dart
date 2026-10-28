import 'dart:math' as math;

import 'package:flutter/material.dart';

const trucoTeamAColor = Color(0xFF1565C0);
const trucoTeamBColor = Color(0xFFC62828);

/// Top view of the table with the seats in play order: A1, B1, A2, B2, ...
/// Empty seats show their placeholder (A1, B2, ...).
class TrucoSeatingPreview extends StatelessWidget {
  final int playersPerTeam;
  final List<String> teamAPlayerIds;
  final List<String> teamBPlayerIds;
  final Map<String, String> namesById;

  const TrucoSeatingPreview({
    super.key,
    required this.playersPerTeam,
    required this.teamAPlayerIds,
    required this.teamBPlayerIds,
    required this.namesById,
  });

  @override
  Widget build(BuildContext context) {
    final seats = <_Seat>[];
    for (var i = 0; i < playersPerTeam; i++) {
      seats.add(_Seat(
        isTeamA: true,
        label: _labelFor(teamAPlayerIds, i, 'A${i + 1}'),
      ));
      seats.add(_Seat(
        isTeamA: false,
        label: _labelFor(teamBPlayerIds, i, 'B${i + 1}'),
      ));
    }

    return AspectRatio(
      aspectRatio: 1.6,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final center = Offset(width / 2, height / 2);
          final radiusX = width / 2 - 44;
          final radiusY = height / 2 - 22;

          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _TablePainter()),
              ),
              for (var i = 0; i < seats.length; i++)
                _positionedSeat(
                  seats[i],
                  index: i,
                  count: seats.length,
                  center: center,
                  radiusX: radiusX,
                  radiusY: radiusY,
                ),
            ],
          );
        },
      ),
    );
  }

  String _labelFor(List<String> ids, int index, String placeholder) {
    if (index >= ids.length) return placeholder;
    return namesById[ids[index]] ?? placeholder;
  }

  Widget _positionedSeat(
    _Seat seat, {
    required int index,
    required int count,
    required Offset center,
    required double radiusX,
    required double radiusY,
  }) {
    // First seat at the bottom, then clockwise around the table.
    final angle = math.pi / 2 + 2 * math.pi * index / count;
    final x = center.dx + radiusX * math.cos(angle);
    final y = center.dy + radiusY * math.sin(angle);
    const seatWidth = 84.0;
    const seatHeight = 30.0;
    final color = seat.isTeamA ? trucoTeamAColor : trucoTeamBColor;

    return Positioned(
      left: x - seatWidth / 2,
      top: y - seatHeight / 2,
      width: seatWidth,
      height: seatHeight,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Text(
          seat.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _Seat {
  final bool isTeamA;
  final String label;

  const _Seat({required this.isTeamA, required this.label});
}

/// Green felt oval with a wooden rim.
class _TablePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      size.width * 0.16,
      size.height * 0.18,
      size.width * 0.68,
      size.height * 0.64,
    );
    canvas.drawOval(
      rect.shift(const Offset(0, 4)),
      Paint()
        ..color = Colors.black26
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawOval(rect, Paint()..color = const Color(0xFF6D4C41));
    canvas.drawOval(
      rect.deflate(8),
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
