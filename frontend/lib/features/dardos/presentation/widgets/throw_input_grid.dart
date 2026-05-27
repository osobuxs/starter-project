import 'package:flutter/material.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/widgets/multiplier_modal.dart';

/// Fixed 6×4 grid of dart numbers for 501/301 scoring.
/// Fills the available space — no scroll.
///   20 19 18 17
///   16 15 14 13
///   12 11 10  9
///    8  7  6  5
///    4  3  2  1
///   25 50  0
class ThrowInputGrid extends StatelessWidget {
  final void Function(int number, int multiplier) onThrow;
  final bool enabled;

  const ThrowInputGrid({
    Key? key,
    required this.onThrow,
    this.enabled = true,
  }) : super(key: key);

  static const _numbers = [
    20, 19, 18, 17,
    16, 15, 14, 13,
    12, 11, 10, 9,
    8, 7, 6, 5,
    4, 3, 2, 1,
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Column(
        children: [
          // Number rows 20→1 (5 rows of 4)
          for (var row = 0; row < 5; row++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: List.generate(4, (col) {
                    final index = row * 4 + col;
                    final number = _numbers[index];
                    final isRed = (index % 2 == 0);
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: _NumberTile(
                          label: '$number',
                          color: isRed
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                          enabled: enabled,
                          onTap: () {
                            showMultiplierModal(
                              context: context,
                              number: number,
                              onSelected: onThrow,
                            );
                          },
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          // Bull / 50 / 0 row
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _NumberTile(
                        label: '25',
                        color: Colors.green.shade800,
                        enabled: enabled,
                        onTap: () => onThrow(25, 1),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _NumberTile(
                        label: '50',
                        color: Colors.red.shade800,
                        enabled: enabled,
                        onTap: () => onThrow(25, 2),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _NumberTile(
                        label: '0',
                        color: Colors.black87,
                        enabled: enabled,
                        onTap: () => onThrow(0, 1),
                      ),
                    ),
                  ),
                  const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberTile extends StatelessWidget {
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _NumberTile({
    Key? key,
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? color : Colors.grey.shade400,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: enabled ? onTap : null,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
