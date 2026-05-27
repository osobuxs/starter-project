import 'package:flutter/material.dart';

/// Banner showing current Set/Leg progress AND the running leg tally
/// per player within the current set.
///
/// Example: "Set 1/3 · Leg 2/5    Oso 2 - 0 Coman"
class LegSetIndicator extends StatelessWidget {
  final int currentSet;
  final int totalSets;
  final int currentLeg;
  final int totalLegs;
  final List<String>? playerIds;
  final Map<String, String>? playerNames;
  // legWinners[set][leg] = winnerId or null
  final List<List<String?>>? legWinners;
  // setWinners[set] = winnerId or null
  final List<String?>? setWinners;
  final String? mode; // '501' | '301' | 'cricket'
  final bool? doubleOut;

  const LegSetIndicator({
    Key? key,
    required this.currentSet,
    required this.totalSets,
    required this.currentLeg,
    required this.totalLegs,
    this.playerIds,
    this.playerNames,
    this.legWinners,
    this.setWinners,
    this.mode,
    this.doubleOut,
  }) : super(key: key);

  String _buildLabel() {
    final setLabel = currentSet >= totalSets
        ? 'Set ${currentSet + 1} (extra)'
        : 'Set ${currentSet + 1}/$totalSets';
    final legLabel = currentLeg >= totalLegs
        ? 'Leg ${currentLeg + 1} (extra)'
        : 'Leg ${currentLeg + 1}/$totalLegs';
    return '$setLabel  ·  $legLabel';
  }

  Map<String, int> _legsWonInCurrentSet() {
    final counts = <String, int>{
      for (final p in playerIds ?? const <String>[]) p: 0,
    };
    if (legWinners == null || currentSet >= legWinners!.length) return counts;
    for (final w in legWinners![currentSet]) {
      if (w == null) continue;
      counts[w] = (counts[w] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, int> _setsWonByPlayer() {
    final counts = <String, int>{
      for (final p in playerIds ?? const <String>[]) p: 0,
    };
    if (setWinners == null) return counts;
    for (final w in setWinners!) {
      if (w == null) continue;
      counts[w] = (counts[w] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final legsWon = _legsWonInCurrentSet();
    final setsWon = _setsWonByPlayer();
    final ids = playerIds ?? const <String>[];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: Colors.indigo.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _buildLabel(),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: (currentSet >= totalSets || currentLeg >= totalLegs)
                      ? Colors.deepOrange.shade800
                      : Colors.indigo.shade900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (mode != null) ...[
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${mode!.toUpperCase()}'
                    '${mode != 'cricket' && doubleOut == true ? ' · Double-out' : ''}'
                    '${mode != 'cricket' && doubleOut == false ? ' · Sin double-out' : ''}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.indigo.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (ids.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ids.map((pid) {
                final name = playerNames?[pid] ?? pid;
                final legs = legsWon[pid] ?? 0;
                final sets = setsWon[pid] ?? 0;
                return Expanded(
                  child: Column(
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(color: Colors.black87),
                          children: [
                            TextSpan(
                              text: 'L:$legs',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.indigo.shade800,
                              ),
                            ),
                            const TextSpan(
                              text: '  ',
                              style: TextStyle(fontSize: 12),
                            ),
                            TextSpan(
                              text: 'S:$sets',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.deepOrange.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
