import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_game.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_hand.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_team.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_game/truco_game_bloc.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_game/truco_game_event.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_game/truco_game_state.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_participant/truco_participant_bloc.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/widgets/truco_board.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/widgets/truco_seating_preview.dart';

/// Live board of one game. The admin enters each hand; everyone else sees
/// the board update in real time. Finished games are shown read-only (the
/// admin can still correct the finishing hand for a few minutes).
class TrucoGamePlayPage extends StatefulWidget {
  final String gameId;

  /// Clock used to decide whether the last hand is still correctable.
  final DateTime Function() now;

  const TrucoGamePlayPage({
    super.key,
    required this.gameId,
    this.now = DateTime.now,
  });

  @override
  State<TrucoGamePlayPage> createState() => _TrucoGamePlayPageState();
}

class _TrucoGamePlayPageState extends State<TrucoGamePlayPage> {
  final Map<TrucoTeamSide, TextEditingController> _controllers = {
    for (final side in TrucoTeamSide.values) side: TextEditingController(),
  };

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _syncControllers(TrucoGameState state) {
    for (final side in TrucoTeamSide.values) {
      final controller = _controllers[side]!;
      final entry = state.entryOf(side);
      if (_parse(controller.text) != entry) {
        controller.text = entry == 0 ? '' : '$entry';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TrucoGameBloc, TrucoGameState>(
      listener: (context, state) {
        if (state.status == TrucoGameBlocStatus.error && state.error != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.error!)));
        }
      },
      builder: (context, state) {
        final game = state.game;
        final participantState = context.watch<TrucoParticipantBloc>().state;
        final isAdmin = participantState.isAdmin;
        final canEditLastHand =
            isAdmin && state.editableLastHandAt(widget.now()) != null;
        _syncControllers(state);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              game == null
                  ? 'Truco'
                  : game.isFinished
                      ? 'Truco — Partida terminada'
                      : 'Truco — Mano ${game.currentHand}',
            ),
            actions: [
              if (canEditLastHand)
                IconButton(
                  tooltip: 'Corregir última mano',
                  icon: const Icon(Icons.edit),
                  onPressed: () => context
                      .read<TrucoGameBloc>()
                      .add(const StartEditLastTrucoHandEvent()),
                ),
            ],
          ),
          body: game == null
              ? state.status == TrucoGameBlocStatus.error
                  ? const Center(child: Text('No se pudo cargar la partida'))
                  : const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
                  children: [
                    if (state.isEditingHand)
                      _EditingBanner(
                        handNumber: state.editingHandNumber!,
                        onCancel: () => context
                            .read<TrucoGameBloc>()
                            .add(const CancelEditLastTrucoHandEvent()),
                      ),
                    if (game.isFinished) _WinnerBanner(game: game),
                    Text(
                      '${game.mode.label} · a ${game.targetScore} puntos',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    TrucoBoard(
                      game: game,
                      namesById: participantState.namesById,
                    ),
                    const SizedBox(height: 16),
                    if (isAdmin && !game.isFinished)
                      _HandEntry(
                        game: game,
                        state: state,
                        controllers: _controllers,
                      )
                    else if (!isAdmin)
                      const Text(
                        'Modo lectura: solo el administrador puede cargar puntos.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    const SizedBox(height: 16),
                    _HandHistory(game: game),
                  ],
                ),
        );
      },
    );
  }
}

int _parse(String text) {
  final value = text.trim();
  if (value.isEmpty || value == '-') return 0;
  return (int.tryParse(value) ?? 0)
      .clamp(TrucoGameBloc.minHandPoints, TrucoGameBloc.maxHandPoints);
}

final TextInputFormatter _pointsFormatter =
    TextInputFormatter.withFunction((oldValue, newValue) {
  final value = newValue.text;
  if (value.isEmpty || value == '-') return newValue;
  return RegExp(r'^-?\d{1,2}$').hasMatch(value) ? newValue : oldValue;
});

class _HandEntry extends StatelessWidget {
  final TrucoGame game;
  final TrucoGameState state;
  final Map<TrucoTeamSide, TextEditingController> controllers;

  const _HandEntry({
    required this.game,
    required this.state,
    required this.controllers,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TrucoGameBloc>();

    void setPoints(TrucoTeamSide side, int points) {
      bloc.add(SetTrucoHandPointsEvent(side: side, points: points));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              state.isEditingHand
                  ? 'Corregir mano ${state.editingHandNumber}'
                  : 'Puntos de la mano ${game.currentHand}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            for (final side in TrucoTeamSide.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 96,
                      child: Text(
                        game.teamOf(side).name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: side == TrucoTeamSide.a
                              ? trucoTeamAColor
                              : trucoTeamBColor,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        key: ValueKey('truco-entry-${side.key}'),
                        controller: controllers[side],
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '0',
                          isDense: true,
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(signed: true),
                        inputFormatters: [_pointsFormatter],
                        onChanged: (value) => setPoints(side, _parse(value)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _AdjustButton(
                      key: ValueKey('truco-minus-${side.key}'),
                      icon: Icons.remove,
                      onPressed: () => setPoints(side, state.entryOf(side) - 1),
                    ),
                    const SizedBox(width: 4),
                    _AdjustButton(
                      key: ValueKey('truco-plus-${side.key}'),
                      icon: Icons.add,
                      onPressed: () => setPoints(side, state.entryOf(side) + 1),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            ElevatedButton(
              onPressed: () => bloc.add(const ConfirmTrucoHandEvent()),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                state.isEditingHand ? 'Guardar corrección' : 'Confirmar',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdjustButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _AdjustButton({super.key, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
        child: Icon(icon, size: 18),
      ),
    );
  }
}

class _HandHistory extends StatelessWidget {
  final TrucoGame game;

  const _HandHistory({required this.game});

  @override
  Widget build(BuildContext context) {
    if (game.hands.isEmpty) return const SizedBox.shrink();
    final hands = game.hands.reversed.toList();

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'Manos',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          for (final hand in hands)
            ListTile(
              key: ValueKey('truco-hand-${hand.handNumber}'),
              dense: true,
              leading: Text('#${hand.handNumber}'),
              title: Text(
                '${game.teamA.name} ${_signed(hand.pointsA)} · '
                '${game.teamB.name} ${_signed(hand.pointsB)}',
              ),
              trailing: Text(
                _totalsAfter(hand, game.targetScore),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }

  String _signed(int value) => value > 0 ? '+$value' : '$value';

  String _totalsAfter(TrucoHand hand, int target) {
    final beforeA = hand.scoreABefore;
    final beforeB = hand.scoreBBefore;
    if (beforeA == null || beforeB == null) return '';
    final a = (beforeA + hand.pointsA).clamp(0, target);
    final b = (beforeB + hand.pointsB).clamp(0, target);
    return '$a – $b';
  }
}

class _WinnerBanner extends StatelessWidget {
  final TrucoGame game;

  const _WinnerBanner({required this.game});

  @override
  Widget build(BuildContext context) {
    final winner = game.winner;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: Color(0xFFF9A825)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              winner == null
                  ? 'Partida terminada'
                  : 'Ganó ${game.teamOf(winner).name} '
                      '(${game.scoreA} – ${game.scoreB})',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditingBanner extends StatelessWidget {
  final int handNumber;
  final VoidCallback onCancel;

  const _EditingBanner({required this.handNumber, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit_note),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Editando mano $handNumber',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(onPressed: onCancel, child: const Text('Cancelar')),
        ],
      ),
    );
  }
}
