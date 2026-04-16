import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/navigation/route_names.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/game_bloc.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/game_event.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/game_state.dart';

class CreateGamePage extends StatefulWidget {
  const CreateGamePage({super.key});

  @override
  State<CreateGamePage> createState() => _CreateGamePageState();
}

class _CreateGamePageState extends State<CreateGamePage> {
  final _gameNameController = TextEditingController();
  final _playerNameController = TextEditingController();
  bool _gameCreated = false;

  @override
  void dispose() {
    _gameNameController.dispose();
    _playerNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _gameCreated ? 'Agregar jugadores' : 'Nuevo juego',
          style: const TextStyle(color: Colors.black),
        ),
      ),
      body: BlocConsumer<GameBloc, GameState>(
        listener: (context, state) {
          if (state.status == GameBlocStatus.gameCreated && !_gameCreated) {
            setState(() => _gameCreated = true);
          }
          if (state.status == GameBlocStatus.error && state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
          }
        },
        builder: (context, state) {
          if (!_gameCreated) {
            return _buildCreateGameForm(context);
          }
          return _buildAddPlayersForm(context, state);
        },
      ),
    );
  }

  Widget _buildCreateGameForm(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Nombre del juego',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _gameNameController,
            decoration: const InputDecoration(
              hintText: 'Ej: Viernes de Loba',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _createGame(context),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _createGame(context),
            child: const Text('Crear juego'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPlayersForm(BuildContext context, GameState state) {
    final players = state.game?.players ?? [];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _playerNameController,
                  decoration: const InputDecoration(
                    hintText: 'Nombre del jugador',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addPlayer(context, state),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _addPlayer(context, state),
                child: const Text('Agregar'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (players.isNotEmpty) ...[
            Text(
              'Jugadores (${players.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: players.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text('${index + 1}'),
                    ),
                    title: Text(players[index].name),
                  );
                },
              ),
            ),
          ] else
            const Expanded(
              child: Center(
                child: Text(
                  'Agregá al menos 2 jugadores para empezar',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          if (players.length >= 2)
            ElevatedButton(
              onPressed: () {
                context.read<GameBloc>().add(
                  StartGameEvent(state.game!.id!),
                );
                Navigator.of(context).pushReplacementNamed(
                  AppRouteNames.laLobaPlay,
                  arguments: state.game!.id,
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Empezar juego',
                style: TextStyle(fontSize: 16),
              ),
            ),
        ],
      ),
    );
  }

  void _createGame(BuildContext context) {
    final name = _gameNameController.text.trim();
    if (name.isNotEmpty) {
      context.read<GameBloc>().add(CreateGameEvent(name));
    }
  }

  void _addPlayer(BuildContext context, GameState state) {
    final name = _playerNameController.text.trim();
    if (name.isNotEmpty && state.game != null) {
      context.read<GameBloc>().add(
        AddPlayerEvent(
          gameId: state.game!.id!,
          playerName: name,
        ),
      );
      _playerNameController.clear();
    }
  }
}
