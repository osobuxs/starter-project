import 'package:flutter/material.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/cricket_marks_state.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/widgets/multiplier_modal.dart';

const _cricketTargets = ['20', '19', '18', '17', '16', '15', 'bull'];

/// Cricket scoring board widget.
/// Shows a table where each row is a player and each column is a target number.
/// Marks are displayed as: empty / | (1) / X (2) / ⊗ (3 = closed).
///
/// [playerIds] ordered list of player IDs.
/// [playerNames] map of id → display name.
/// [cricketState] current marks and points.
/// [currentPlayerId] ID of the player whose turn it is.
/// [enabled] whether input buttons are active.
/// [onThrow] called with (cricketTarget, multiplier) where cricketTarget is
///           e.g. "20", "bull". Use "0" for a miss (non-cricket number).
class CricketBoard extends StatelessWidget {
  final List<String> playerIds;
  final Map<String, String> playerNames;
  final CricketMarksState cricketState;
  final String currentPlayerId;
  final bool enabled;
  final void Function(String target, int multiplier) onThrow;

  const CricketBoard({
    Key? key,
    required this.playerIds,
    required this.playerNames,
    required this.cricketState,
    required this.currentPlayerId,
    this.enabled = true,
    required this.onThrow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header row: player names
        _buildHeaderRow(context),
        // Target rows
        ..._cricketTargets.map((target) => _buildTargetRow(context, target)),
        // Action buttons row
        if (enabled) _buildActionButtons(context),
      ],
    );
  }

  Widget _buildHeaderRow(BuildContext context) {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      children: [
        TableRow(
          decoration:
              BoxDecoration(color: Colors.indigo.shade50),
          children: [
            const _HeaderCell(text: 'Objetivo'),
            ...playerIds.map((id) => _HeaderCell(
                  text: playerNames[id] ?? id,
                  highlight: id == currentPlayerId,
                )),
            const _HeaderCell(text: 'Pts'),
          ],
        ),
      ],
    );
  }

  Widget _buildTargetRow(BuildContext context, String target) {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      children: [
        TableRow(
          children: [
            _TargetLabelCell(target: target),
            ...playerIds.map((id) {
              final marks =
                  cricketState.marksByPlayer[id]?[target] ?? 0;
              return _MarksCell(marks: marks);
            }),
            // Points column (sum of all points for all players — show by player)
            _PointsCell(
              points: cricketState.pointsByPlayer.values.fold(
                0,
                (sum, p) => sum + p,
              ),
              playerIds: playerIds,
              pointsByPlayer: cricketState.pointsByPlayer,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          // Buttons for each cricket target
          ..._cricketTargets.map((target) {
            final displayLabel =
                target == 'bull' ? 'Bull' : target;
            return ElevatedButton(
              onPressed: () {
                final number =
                    target == 'bull' ? 25 : int.parse(target);
                showMultiplierModal(
                  context: context,
                  number: number,
                  onSelected: (n, mult) {
                    onThrow(target, mult);
                  },
                );
              },
              child: Text(displayLabel),
            );
          }),
          // Miss button (non-cricket number)
          ElevatedButton(
            onPressed: () => onThrow('0', 1),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade600,
            ),
            child: const Text(
              '<15 / Miss',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final bool highlight;

  const _HeaderCell({
    Key? key,
    required this.text,
    this.highlight = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: highlight ? Colors.indigo : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _TargetLabelCell extends StatelessWidget {
  final String target;

  const _TargetLabelCell({Key? key, required this.target}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Text(
          target == 'bull' ? 'Bull' : target,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _MarksCell extends StatelessWidget {
  final int marks;

  const _MarksCell({Key? key, required this.marks}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String display;
    if (marks == 0) {
      display = '';
    } else if (marks == 1) {
      display = '/';
    } else if (marks == 2) {
      display = 'X';
    } else {
      display = '⊗'; // closed
    }

    return TableCell(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Text(
          display,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: marks >= 3 ? Colors.green.shade700 : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _PointsCell extends StatelessWidget {
  final int points;
  final List<String> playerIds;
  final Map<String, int> pointsByPlayer;

  const _PointsCell({
    Key? key,
    required this.points,
    required this.playerIds,
    required this.pointsByPlayer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final text = playerIds
        .map((id) => '${pointsByPlayer[id] ?? 0}')
        .join(' / ');
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
