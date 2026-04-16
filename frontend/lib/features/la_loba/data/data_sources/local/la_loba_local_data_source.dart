import 'package:news_app_clean_architecture/features/la_loba/data/models/game_model.dart';
import 'package:news_app_clean_architecture/features/la_loba/data/models/partida_model.dart';
import 'package:news_app_clean_architecture/features/la_loba/data/models/player_model.dart';
import 'package:news_app_clean_architecture/features/la_loba/data/models/score_model.dart';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

abstract class LaLobaLocalDataSource {
  Future<void> initDb();
  Future<GameModel> createGame(String name);
  Future<PlayerModel> addPlayer(int gameId, String name);
  Future<GameModel> getGame(int gameId);
  Future<List<GameModel>> getGameHistory();
  Future<List<PlayerModel>> getActivePlayers(int gameId);
  Future<List<PlayerModel>> getAllPlayers(int gameId);
  Future<PartidaModel> createPartida(int gameId, int partidaNumber);
  Future<void> recordScore(int playerId, int partidaId, int points);
  Future<void> updatePlayerScore(int playerId, int newTotalScore);
  Future<void> updatePlayerRetry(int playerId);
  Future<void> eliminatePlayer(int playerId);
  Future<void> updateGameStatus(int gameId, String status);
  Future<bool> playerNameExists(int gameId, String name);
}

class LaLobaLocalDataSourceImpl implements LaLobaLocalDataSource {
  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = '${dir.path}${Platform.pathSeparator}la_loba.db';
    return openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS games (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'created',
            createdAt INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS players (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            gameId INTEGER NOT NULL,
            name TEXT NOT NULL,
            totalScore INTEGER NOT NULL DEFAULT 0,
            hasUsedRetry INTEGER NOT NULL DEFAULT 0,
            isEliminated INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (gameId) REFERENCES games(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS partidas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            gameId INTEGER NOT NULL,
            partidaNumber INTEGER NOT NULL,
            createdAt INTEGER NOT NULL,
            FOREIGN KEY (gameId) REFERENCES games(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS scores (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            playerId INTEGER NOT NULL,
            partidaId INTEGER NOT NULL,
            points INTEGER NOT NULL,
            FOREIGN KEY (playerId) REFERENCES players(id),
            FOREIGN KEY (partidaId) REFERENCES partidas(id)
          )
        ''');
      },
    );
  }

  @override
  Future<void> initDb() async {
    await database;
  }

  @override
  Future<GameModel> createGame(String name) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = await db.insert('games', {
      'name': name,
      'status': 'created',
      'createdAt': now,
    });
    return GameModel(id: id, name: name, status: 'created', createdAt: now);
  }

  @override
  Future<PlayerModel> addPlayer(int gameId, String name) async {
    final db = await database;
    final id = await db.insert('players', {
      'gameId': gameId,
      'name': name,
      'totalScore': 0,
      'hasUsedRetry': 0,
      'isEliminated': 0,
    });
    return PlayerModel(id: id, name: name, gameId: gameId);
  }

  @override
  Future<GameModel> getGame(int gameId) async {
    final db = await database;
    final gameMaps = await db.query(
      'games',
      where: 'id = ?',
      whereArgs: [gameId],
    );
    if (gameMaps.isEmpty) throw Exception('Game not found');

    final players = await getAllPlayers(gameId);
    final partidas = await _getPartidas(gameId);

    return GameModel.fromMap(
      gameMaps.first,
      players: players,
      partidas: partidas,
    );
  }

  @override
  Future<List<GameModel>> getGameHistory() async {
    final db = await database;
    final gameMaps = await db.query('games', orderBy: 'createdAt DESC');

    final games = <GameModel>[];
    for (final map in gameMaps) {
      final gameId = map['id'] as int;
      final players = await getAllPlayers(gameId);
      games.add(GameModel.fromMap(map, players: players));
    }
    return games;
  }

  @override
  Future<List<PlayerModel>> getActivePlayers(int gameId) async {
    final db = await database;
    final maps = await db.query(
      'players',
      where: 'gameId = ? AND isEliminated = 0',
      whereArgs: [gameId],
    );
    return maps.map((m) => PlayerModel.fromMap(m)).toList();
  }

  @override
  Future<List<PlayerModel>> getAllPlayers(int gameId) async {
    final db = await database;
    final maps = await db.query(
      'players',
      where: 'gameId = ?',
      whereArgs: [gameId],
    );
    return maps.map((m) => PlayerModel.fromMap(m)).toList();
  }

  @override
  Future<PartidaModel> createPartida(int gameId, int partidaNumber) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = await db.insert('partidas', {
      'gameId': gameId,
      'partidaNumber': partidaNumber,
      'createdAt': now,
    });
    return PartidaModel(
      id: id,
      partidaNumber: partidaNumber,
      gameId: gameId,
      createdAt: now,
    );
  }

  @override
  Future<void> recordScore(int playerId, int partidaId, int points) async {
    final db = await database;
    await db.insert('scores', {
      'playerId': playerId,
      'partidaId': partidaId,
      'points': points,
    });
  }

  @override
  Future<void> updatePlayerScore(int playerId, int newTotalScore) async {
    final db = await database;
    await db.update(
      'players',
      {'totalScore': newTotalScore},
      where: 'id = ?',
      whereArgs: [playerId],
    );
  }

  @override
  Future<void> updatePlayerRetry(int playerId) async {
    final db = await database;
    await db.update(
      'players',
      {'hasUsedRetry': 1},
      where: 'id = ?',
      whereArgs: [playerId],
    );
  }

  @override
  Future<void> eliminatePlayer(int playerId) async {
    final db = await database;
    await db.update(
      'players',
      {'isEliminated': 1},
      where: 'id = ?',
      whereArgs: [playerId],
    );
  }

  @override
  Future<void> updateGameStatus(int gameId, String status) async {
    final db = await database;
    await db.update(
      'games',
      {'status': status},
      where: 'id = ?',
      whereArgs: [gameId],
    );
  }

  @override
  Future<bool> playerNameExists(int gameId, String name) async {
    final db = await database;
    final result = await db.query(
      'players',
      where: 'gameId = ? AND name = ?',
      whereArgs: [gameId, name],
    );
    return result.isNotEmpty;
  }

  Future<List<PartidaModel>> _getPartidas(int gameId) async {
    final db = await database;
    final partidaMaps = await db.query(
      'partidas',
      where: 'gameId = ?',
      whereArgs: [gameId],
      orderBy: 'partidaNumber ASC',
    );

    final partidas = <PartidaModel>[];
    for (final map in partidaMaps) {
      final partidaId = map['id'] as int;
      final scoreMaps = await db.query(
        'scores',
        where: 'partidaId = ?',
        whereArgs: [partidaId],
      );
      final scores = scoreMaps.map((s) => ScoreModel.fromMap(s)).toList();
      partidas.add(PartidaModel.fromMap(map, scores: scores));
    }
    return partidas;
  }
}
