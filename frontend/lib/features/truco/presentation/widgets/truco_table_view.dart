import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_team.dart';

const trucoTeamAColor = Color(0xFF1565C0);
const trucoTeamBColor = Color(0xFFC62828);
const _dealerColor = Color(0xFFFFB300);

Color trucoTeamColor(TrucoTeamSide side) =>
    side == TrucoTeamSide.a ? trucoTeamAColor : trucoTeamBColor;

/// One seat around the table. [playerId] is null for an empty seat, which
/// shows its placeholder label (A1, B2, ...).
class TrucoTableSeat {
  final String? playerId;
  final String label;
  final TrucoTeamSide side;
  final bool isDealer;
  final bool isMano;

  const TrucoTableSeat({
    required this.label,
    required this.side,
    this.playerId,
    this.isDealer = false,
    this.isMano = false,
  });
}

/// Top view of the table with the seats in play order, the first one at the
/// bottom and the rest clockwise. The dealer is marked with "Reparte" and a
/// deck icon; the player after the dealer is marked as "Mano".
///
/// Shared by the create page (seating preview) and the play page.
class TrucoTableView extends StatelessWidget {
  final List<TrucoTableSeat> seats;

  const TrucoTableView({super.key, required this.seats});

  static const _seatWidth = 88.0;
  static const _seatHeight = 50.0;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      key: const ValueKey('truco-table'),
      aspectRatio: 1.6,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final center = Offset(width / 2, height / 2);
          final radiusX = math.max(0.0, width / 2 - _seatWidth / 2);
          final radiusY = math.max(0.0, height / 2 - _seatHeight / 2);

          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _TablePainter()),
              ),
              for (var i = 0; i < seats.length; i++)
                _positioned(
                  seats[i],
                  index: i,
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

  Widget _positioned(
    TrucoTableSeat seat, {
    required int index,
    required Offset center,
    required double radiusX,
    required double radiusY,
  }) {
    final angle = math.pi / 2 + 2 * math.pi * index / seats.length;
    final x = center.dx + radiusX * math.cos(angle);
    final y = center.dy + radiusY * math.sin(angle);

    return Positioned(
      key: ValueKey(
        seat.playerId == null
            ? 'truco-seat-empty-$index'
            : 'truco-seat-${seat.playerId}',
      ),
      left: x - _seatWidth / 2,
      top: y - _seatHeight / 2,
      width: _seatWidth,
      height: _seatHeight,
      child: _SeatChip(seat: seat),
    );
  }
}

class _SeatChip extends StatelessWidget {
  final TrucoTableSeat seat;

  const _SeatChip({required this.seat});

  @override
  Widget build(BuildContext context) {
    final color = trucoTeamColor(seat.side);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 28,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            border: seat.isDealer
                ? Border.all(color: _dealerColor, width: 2.5)
                : null,
            boxShadow: const [
              BoxShadow(
                  color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
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
        if (seat.isDealer)
          const _Badge(
            icon: Icons.style,
            text: 'Reparte',
            background: _dealerColor,
            foreground: Colors.black87,
          )
        else if (seat.isMano)
          const _Badge(
            text: 'Mano',
            background: Colors.white,
            foreground: Colors.black87,
          ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData? icon;
  final String text;
  final Color background;
  final Color foreground;

  const _Badge({
    required this.text,
    required this.background,
    required this.foreground,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      // Scales down instead of overflowing on narrow seats or large fonts.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 11, color: foreground),
              const SizedBox(width: 2),
            ],
            Text(
              text,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
