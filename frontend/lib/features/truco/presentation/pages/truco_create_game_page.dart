import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_game.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_participant.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_team.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_create_game/truco_create_game_cubit.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_create_game/truco_create_game_state.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_participant/truco_participant_bloc.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_participant/truco_participant_state.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/truco_route_names.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/widgets/truco_seating_preview.dart';

class TrucoCreateGamePage extends StatelessWidget {
  const TrucoCreateGamePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TrucoCreateGameCubit, TrucoCreateGameState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == TrucoCreateGameStatus.created &&
            state.createdGame != null) {
          Navigator.of(context).pushReplacementNamed(
            TrucoRouteNames.play,
            arguments: state.createdGame!.id,
          );
        } else if (state.status == TrucoCreateGameStatus.error &&
            state.error != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.error!)));
        }
      },
      builder: (context, state) {
        final cubit = context.read<TrucoCreateGameCubit>();
        final participantState = context.watch<TrucoParticipantBloc>().state;
        final names = participantState.namesById;

        return Scaffold(
          appBar: AppBar(title: const Text('Nueva partida de Truco')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              const _SectionTitle('Modo'),
              Wrap(
                spacing: 8,
                children: [
                  for (final mode in TrucoMode.values)
                    ChoiceChip(
                      label: Text(mode.label),
                      selected: state.mode == mode,
                      onSelected: (_) => cubit.selectMode(mode),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const _SectionTitle('Objetivo'),
              Wrap(
                spacing: 8,
                children: [
                  for (final target in trucoTargetScores)
                    ChoiceChip(
                      label: Text(
                        '$target puntos (${target ~/ 2} malas + ${target ~/ 2} buenas)',
                      ),
                      selected: state.targetScore == target,
                      onSelected: (_) => cubit.selectTarget(target),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              for (final side in TrucoTeamSide.values)
                _TeamCard(
                  key: ValueKey('team-card-${side.key}'),
                  side: side,
                  team: state.teamOf(side),
                  playersPerTeam: state.mode.playersPerTeam,
                  namesById: names,
                ),
              const SizedBox(height: 8),
              const _SectionTitle('Ubicación en la mesa'),
              TrucoSeatingPreview(
                playersPerTeam: state.mode.playersPerTeam,
                teamAPlayerIds: state.teamA.playerIds,
                teamBPlayerIds: state.teamB.playerIds,
                namesById: names,
              ),
              const SizedBox(height: 16),
              const _SectionTitle('Jugadores'),
              _PlayerPicker(
                state: state,
                participantState: participantState,
              ),
              const SizedBox(height: 24),
              if (state.validationError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    state.validationError!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
              ElevatedButton.icon(
                onPressed: state.canSubmit ? cubit.submit : null,
                icon: state.status == TrucoCreateGameStatus.submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                label: const Text('Comenzar partida'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// Team name field plus its seated members, reorderable with arrows.
class _TeamCard extends StatelessWidget {
  final TrucoTeamSide side;
  final TrucoTeam team;
  final int playersPerTeam;
  final Map<String, String> namesById;

  const _TeamCard({
    super.key,
    required this.side,
    required this.team,
    required this.playersPerTeam,
    required this.namesById,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TrucoCreateGameCubit>();
    final color = side == TrucoTeamSide.a ? trucoTeamAColor : trucoTeamBColor;
    final prefix = side == TrucoTeamSide.a ? 'A' : 'B';

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              key: ValueKey('team-name-${side.key}'),
              initialValue: team.name,
              decoration: InputDecoration(
                labelText: 'Equipo $prefix',
                prefixIcon: Icon(Icons.groups, color: color),
              ),
              onChanged: (value) => cubit.renameTeam(side, value),
            ),
            const SizedBox(height: 8),
            Text(
              'Integrantes (${team.playerIds.length}/$playersPerTeam)',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            for (var i = 0; i < team.playerIds.length; i++)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  child: Text('$prefix${i + 1}',
                      style: const TextStyle(fontSize: 11)),
                ),
                title: Text(namesById[team.playerIds[i]] ?? team.playerIds[i]),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Subir',
                      icon: const Icon(Icons.arrow_upward),
                      onPressed:
                          i == 0 ? null : () => cubit.movePlayer(side, i, i - 1),
                    ),
                    IconButton(
                      tooltip: 'Bajar',
                      icon: const Icon(Icons.arrow_downward),
                      onPressed: i == team.playerIds.length - 1
                          ? null
                          : () => cubit.movePlayer(side, i, i + 1),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Every registered player with one chip per team to seat them there.
class _PlayerPicker extends StatelessWidget {
  final TrucoCreateGameState state;
  final TrucoParticipantState participantState;

  const _PlayerPicker({required this.state, required this.participantState});

  @override
  Widget build(BuildContext context) {
    if (participantState.status == TrucoParticipantStatus.loading &&
        participantState.participants.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (participantState.participants.isEmpty) {
      return const Text(
        'No hay jugadores registrados. Agréguelos desde la pestaña Jugadores.',
        style: TextStyle(color: Colors.grey),
      );
    }

    return Column(
      children: [
        for (final player in participantState.participants)
          _PlayerRow(player: player, state: state),
      ],
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final TrucoParticipant player;
  final TrucoCreateGameState state;

  const _PlayerRow({required this.player, required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TrucoCreateGameCubit>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(player.name)),
          for (final side in TrucoTeamSide.values) ...[
            const SizedBox(width: 6),
            FilterChip(
              key: ValueKey('pick-${player.id}-${side.key}'),
              label: Text(side == TrucoTeamSide.a ? 'A' : 'B'),
              tooltip: state.teamOf(side).name,
              selected: state.teamOf(side).playerIds.contains(player.id),
              selectedColor: (side == TrucoTeamSide.a
                      ? trucoTeamAColor
                      : trucoTeamBColor)
                  .withValues(alpha: 0.25),
              onSelected: (_) => cubit.togglePlayer(side, player.id),
            ),
          ],
        ],
      ),
    );
  }
}
