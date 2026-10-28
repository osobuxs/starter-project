import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/navigation/route_names.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/hand.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/services/board_history.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/game_bloc.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/game_event.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/game_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/multi_game_bloc.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/multi_game_event.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/participant_bloc.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/participant_event.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/participant_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/utils/participant_display.dart';

class GamePlayPage extends StatefulWidget {
  final String gameId;

  const GamePlayPage({super.key, required this.gameId});

  @override
  State<GamePlayPage> createState() => _GamePlayPageState();
}

class _GamePlayPageState extends State<GamePlayPage> {
  static const int _scoreMin = -999;
  static const int _scoreMax = 999;
  static const Color _eliminationCellColor = Color(0xFFD32F2F);
  static const Color _rejoinCellColor = Color(0xFFFF9800);

  final Map<String, TextEditingController> _scoreControllers = {};

  @override
  void initState() {
    super.initState();
    final participantBloc = context.read<ParticipantBloc>();
    if (participantBloc.state.participants.isEmpty) {
      participantBloc.add(const FetchAllParticipantsEvent());
    }
  }

  @override
  void dispose() {
    for (final controller in _scoreControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _syncControllers(List<String> participantIds, Map<String, int> scores) {
    for (final participantId in participantIds) {
      final controller = _scoreControllers.putIfAbsent(
        participantId,
        () => TextEditingController(),
      );
      final score = scores[participantId];
      final desired = score == null ? '' : score.toString();
      if (controller.text != desired) {
        controller.text = desired;
      }
    }

    final obsolete = _scoreControllers.keys
        .where((id) => !participantIds.contains(id))
        .toList();
    for (final id in obsolete) {
      _scoreControllers.remove(id)?.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GameBloc, GameState>(
      listener: (context, state) async {
        if (state.status == GameBlocStatus.retryRequired &&
            state.currentRetryParticipantId != null &&
            state.game != null) {
          final isAdmin = context.read<ParticipantBloc>().state.isAdmin;
          if (!isAdmin) return;
          await _showRetryDecisionDialog(
            context,
            participantId: state.currentRetryParticipantId!,
            gameState: state,
          );
        }

        if (state.status == GameBlocStatus.gameFinished) {
          if (!mounted) return;
          context.read<MultiGameBloc>().add(const LoadGamesEvent());
          context
              .read<ParticipantBloc>()
              .add(const FetchAllParticipantsEvent());
          Navigator.of(context).pushReplacementNamed(
            AppRouteNames.laLobaFinished,
            arguments: widget.gameId,
          );
        }

        if (state.status == GameBlocStatus.error && state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!)),
          );
        }

        if (state.status == GameBlocStatus.handFinished) {
          for (final controller in _scoreControllers.values) {
            controller.clear();
          }
        }
      },
      builder: (context, state) {
        final game = state.game;
        final isAdmin = context.select<ParticipantBloc, bool>(
          (bloc) => bloc.state.isAdmin,
        );
        final canEditLastHand = isAdmin &&
            state.editableLastHandAt(DateTime.now()) != null &&
            state.status != GameBlocStatus.retryRequired;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              '${game?.name ?? "La Loba"} — Mano ${game?.currentHand ?? 0}',
              style: const TextStyle(color: Colors.black),
            ),
            actions: [
              if (canEditLastHand)
                TextButton.icon(
                  icon: const Icon(Icons.edit, color: Colors.black),
                  label: const Text(
                    'Corregir última mano',
                    style: TextStyle(color: Colors.black),
                  ),
                  onPressed: () => context
                      .read<GameBloc>()
                      .add(const StartEditLastHandEvent()),
                ),
            ],
          ),
          body: state.status == GameBlocStatus.loading
              ? const Center(child: CircularProgressIndicator())
              : game == null
                  ? const Center(child: Text('No hay juego cargado'))
                  : BlocBuilder<ParticipantBloc, ParticipantState>(
                      builder: (context, participantState) {
                        final isReadOnly = game.status == 'finished' ||
                            !participantState.isAdmin;
                        final participantNames = {
                          for (final participant
                              in participantState.participants)
                            participant.id: participant.name,
                        };

                        final participantIds = game.participantIds;
                        _syncControllers(
                          participantIds,
                          state.currentHandScores,
                        );

                        final totals = {
                          for (final participantId in participantIds)
                            participantId: _extractTotalScore(
                              game.participantStates[participantId],
                            ),
                        };

                        final activeIds = participantIds
                            .where(
                                (id) => _isActive(game.participantStates[id]))
                            .toList();
                        final boardHistory = buildBoardHistory(game);

                        return Column(
                          children: [
                            if (state.isEditingHand)
                              _EditingHandBanner(
                                handNumber: state.editingHandNumber!,
                                onCancel: () => context
                                    .read<GameBloc>()
                                    .add(const CancelEditLastHandEvent()),
                              ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                              child: Row(
                                children: [
                                  Text(
                                    'Participantes: ${participantIds.length}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Dealer: ${shortParticipantLabel(game.currentDealerId, participantNames)}',
                                    style: TextStyle(
                                      color: Colors.indigo.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: SingleChildScrollView(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Scoreboard',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: double.infinity,
                                      child: Card(
                                        child: LayoutBuilder(
                                          builder: (context, constraints) {
                                            return SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: ConstrainedBox(
                                                constraints: BoxConstraints(
                                                  minWidth:
                                                      constraints.maxWidth,
                                                ),
                                                child: DataTable(
                                                  horizontalMargin: 6,
                                                  columnSpacing: 10,
                                                  columns: [
                                                    const DataColumn(
                                                        label: Text('Mano')),
                                                    ...participantIds.map(
                                                      (participantId) =>
                                                          DataColumn(
                                                        label: Text(
                                                          shortParticipantLabel(
                                                            participantId,
                                                            participantNames,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                  rows: [
                                                    DataRow(
                                                      cells: [
                                                        const DataCell(
                                                          Text(
                                                            'Total',
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                        ...participantIds.map(
                                                          (participantId) =>
                                                              DataCell(
                                                            Row(
                                                              children: [
                                                                Text(
                                                                  '${totals[participantId] ?? 0}',
                                                                  style:
                                                                      const TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                                if (!_isActive(
                                                                  game.participantStates[
                                                                      participantId],
                                                                )) ...[
                                                                  const SizedBox(
                                                                      width: 4),
                                                                  const Icon(
                                                                    Icons.block,
                                                                    size: 14,
                                                                    color: Colors
                                                                        .red,
                                                                  ),
                                                                ],
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    ...game.hands.map(
                                                      (hand) => DataRow(
                                                        cells: [
                                                          DataCell(
                                                            Text(
                                                                'R${hand.handNumber}'),
                                                          ),
                                                          ...participantIds.map(
                                                            (participantId) =>
                                                                DataCell(
                                                              _buildHandScoreCell(
                                                                boardHistory,
                                                                hand,
                                                                participantId,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    if (participantState.isAdmin) ...[
                                      Row(
                                        children: [
                                          const Expanded(
                                            child: Text(
                                              'Cargar ronda actual',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          TextButton.icon(
                                            onPressed: isReadOnly ||
                                                    state.isEditingHand
                                                ? null
                                                : () =>
                                                    _showAddParticipantDialog(
                                                      context,
                                                      participantState:
                                                          participantState,
                                                      gameParticipantIds:
                                                          participantIds,
                                                    ),
                                            icon: const Icon(Icons.person_add),
                                            label: const Text('Agregar'),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      ...participantIds.map((participantId) {
                                        final shortLabel =
                                            shortParticipantLabel(
                                          participantId,
                                          participantNames,
                                        );
                                        final isActive = _isActive(
                                          game.participantStates[participantId],
                                        );
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 8.0),
                                          child: Row(
                                            children: [
                                              SizedBox(
                                                width: 64,
                                                child: Text(
                                                  shortLabel,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    color: isActive
                                                        ? Colors.black
                                                        : Colors.grey,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: TextField(
                                                  controller: _scoreControllers[
                                                      participantId],
                                                  enabled:
                                                      isActive && !isReadOnly,
                                                  decoration: InputDecoration(
                                                    border:
                                                        const OutlineInputBorder(),
                                                    hintText: isActive
                                                        ? 'Puntos mano'
                                                        : 'Eliminado',
                                                  ),
                                                  keyboardType:
                                                      const TextInputType
                                                          .numberWithOptions(
                                                    signed: true,
                                                  ),
                                                  inputFormatters: [
                                                    _scoreInputFormatter,
                                                  ],
                                                  onChanged: (value) {
                                                    final score =
                                                        _parseScoreInput(value);
                                                    context
                                                        .read<GameBloc>()
                                                        .add(
                                                          RecordScoreEvent(
                                                            participantId:
                                                                participantId,
                                                            points: score,
                                                          ),
                                                        );
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              _ScoreAdjustButton(
                                                icon: Icons.remove,
                                                enabled:
                                                    isActive && !isReadOnly,
                                                onPressed: () =>
                                                    _adjustParticipantScore(
                                                  participantId: participantId,
                                                  delta: -1,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              _ScoreAdjustButton(
                                                icon: Icons.add,
                                                enabled:
                                                    isActive && !isReadOnly,
                                                onPressed: () =>
                                                    _adjustParticipantScore(
                                                  participantId: participantId,
                                                  delta: 1,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: activeIds.isEmpty ||
                                                  isReadOnly
                                              ? null
                                              : () => _confirmAndFinishRound(
                                                    context,
                                                  ),
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                          ),
                                          child: Text(
                                            state.isEditingHand
                                                ? 'Guardar corrección'
                                                : 'Confirmar ronda',
                                            style:
                                                const TextStyle(fontSize: 16),
                                          ),
                                        ),
                                      ),
                                    ] else
                                      const Padding(
                                        padding: EdgeInsets.only(top: 4),
                                        child: Text(
                                          'Modo lectura: no tenés permisos para cargar puntajes.',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
        );
      },
    );
  }

  Future<void> _showRetryDecisionDialog(
    BuildContext context, {
    required String participantId,
    required GameState gameState,
  }) async {
    final game = gameState.game;
    if (game == null) return;

    final participantBloc = context.read<ParticipantBloc>();
    final participant = participantBloc.state.participants
        .where((p) => p.id == participantId)
        .firstOrNull;
    final participantName = participant?.name ?? participantId;
    final reentryBaseScore = gameState.retryReentryBaseScore;
    final reentryBaseText =
        reentryBaseScore != null ? ' (base: $reentryBaseScore)' : '';

    final decision = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Superó 100 puntos'),
          content: Text(
            '$participantName superó los 100 puntos. ¿Reingresa a la partida$reentryBaseText?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('No reingresa'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Reingresa'),
            ),
          ],
        );
      },
    );

    if (!mounted || decision == null) return;
    context.read<GameBloc>().add(
          ResolveRetryDecisionEvent(
            participantId: participantId,
            rejoin: decision,
          ),
        );
  }

  Future<void> _confirmAndFinishRound(BuildContext context) async {
    final editingHand = context.read<GameBloc>().state.editingHandNumber;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            editingHand == null ? 'Confirmar ronda' : 'Corregir mano',
          ),
          content: Text(
            editingHand == null
                ? '¿Confirmás los puntajes de esta ronda?'
                : '¿Guardás los puntajes corregidos de la mano $editingHand? '
                    'Se recalculan totales, eliminaciones, dealer y ganador.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Sí'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirm != true) return;
    context.read<GameBloc>().add(FinishPartidaEvent(widget.gameId));
  }

  Future<void> _showAddParticipantDialog(
    BuildContext context, {
    required ParticipantState participantState,
    required List<String> gameParticipantIds,
  }) async {
    final available = participantState.participants
        .where((participant) => !gameParticipantIds.contains(participant.id))
        .toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No hay participantes disponibles para agregar')),
      );
      return;
    }

    final participantNames = {
      for (final participant in participantState.participants)
        participant.id: participant.name,
    };
    final positionOptions = <_InsertPositionOption>[
      const _InsertPositionOption(index: 0, label: 'Al inicio'),
      ...gameParticipantIds.asMap().entries.map(
            (entry) => _InsertPositionOption(
              index: entry.key + 1,
              label:
                  'Después de ${shortParticipantLabel(entry.value, participantNames)}',
            ),
          ),
    ];

    String? selectedId = available.first.id;
    int? selectedInsertIndex = gameParticipantIds.length;

    final chosen = await showDialog<_AddParticipantSelection>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Agregar participante'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedId,
                    decoration: const InputDecoration(
                      labelText: 'Participante',
                    ),
                    items: available
                        .map(
                          (participant) => DropdownMenuItem<String>(
                            value: participant.id,
                            child: Text(participant.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: selectedInsertIndex,
                    decoration: const InputDecoration(
                      labelText: 'Posición',
                    ),
                    items: positionOptions
                        .map(
                          (option) => DropdownMenuItem<int>(
                            value: option.index,
                            child: Text(option.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedInsertIndex = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: selectedId == null
                      ? null
                      : () => Navigator.of(dialogContext).pop(
                            _AddParticipantSelection(
                              participantId: selectedId!,
                              insertIndex: selectedInsertIndex,
                            ),
                          ),
                  child: const Text('Agregar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || chosen == null) return;

    context.read<GameBloc>().add(
          AddPlayerEvent(
            gameId: widget.gameId,
            participantId: chosen.participantId,
            insertIndex: chosen.insertIndex,
          ),
        );
  }

  void _adjustParticipantScore({
    required String participantId,
    required int delta,
  }) {
    final controller = _scoreControllers[participantId];
    if (controller == null) return;

    final current = _parseScoreInput(controller.text);
    final next = _clampScore(current + delta);
    final nextText = next.toString();

    if (controller.text != nextText) {
      controller.text = nextText;
    }

    context.read<GameBloc>().add(
          RecordScoreEvent(participantId: participantId, points: next),
        );
  }

  int _extractTotalScore(dynamic participantState) {
    if (participantState is! Map<String, dynamic>) return 0;
    final score = participantState['score'];
    if (score is int) return score;
    return 0;
  }

  bool _isActive(dynamic participantState) {
    if (participantState is! Map<String, dynamic>) return false;
    return participantState['status'] == 'active';
  }

  int _parseScoreInput(String value) {
    final sanitized = value.trim();
    if (sanitized.isEmpty || sanitized == '-') {
      return 0;
    }

    return _clampScore(int.tryParse(sanitized) ?? 0);
  }

  int _clampScore(int value) {
    if (value > _scoreMax) return _scoreMax;
    if (value < _scoreMin) return _scoreMin;
    return value;
  }

  Widget _buildHandScoreCell(
    BoardHistory boardHistory,
    HandEntity hand,
    String participantId,
  ) {
    // A mid-game join shows its entry score in the hand before it started
    // playing (legacy games stored it inside that hand's scores).
    final joinScore =
        boardHistory.joinScoresByHand[hand.handNumber]?[participantId];
    final scoreText = '${hand.scores[participantId] ?? joinScore ?? 0}';

    final rejoinScore =
        boardHistory.rejoinScoresByHand[hand.handNumber]?[participantId];
    if (rejoinScore != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            scoreText,
            style: const TextStyle(
              color: _rejoinCellColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '($rejoinScore)',
            key: ValueKey('rejoin-score-${hand.handNumber}-$participantId'),
            style: const TextStyle(
              color: _rejoinCellColor,
              fontSize: 10,
            ),
          ),
        ],
      );
    }

    final eliminationHand =
        boardHistory.eliminationHandByParticipant[participantId];
    if (eliminationHand == hand.handNumber) {
      return Text(
        scoreText,
        style: const TextStyle(
          color: _eliminationCellColor,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return Text(scoreText);
  }

  static final TextInputFormatter _scoreInputFormatter =
      TextInputFormatter.withFunction((oldValue, newValue) {
    final value = newValue.text;
    if (value.isEmpty) return newValue;
    if (value == '-') return newValue;

    final isValid = RegExp(r'^-?\d{1,3}$').hasMatch(value);
    return isValid ? newValue : oldValue;
  });
}

class _ScoreAdjustButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  const _ScoreAdjustButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}

class _AddParticipantSelection {
  final String participantId;
  final int? insertIndex;

  const _AddParticipantSelection({
    required this.participantId,
    required this.insertIndex,
  });
}

class _InsertPositionOption {
  final int index;
  final String label;

  const _InsertPositionOption({required this.index, required this.label});
}

class _EditingHandBanner extends StatelessWidget {
  final int handNumber;
  final VoidCallback onCancel;

  const _EditingHandBanner({
    required this.handNumber,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.amber.shade100,
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      child: Row(
        children: [
          const Icon(Icons.edit_note, color: Colors.black87),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Editando mano $handNumber',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: onCancel,
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
}
