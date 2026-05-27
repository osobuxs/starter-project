# PRD: La Loba — Score Tracking Module

## Problem Statement

El usuario necesita anotar puntos de partidas de La Loba (juego de cartas argentino de 2 mazos) sin crear un proyecto separado. Actualmente no existe forma de trackear partidas, jugadores y scores de forma persistente dentro de la News App.

La Loba tiene reglas complejas de eliminación y retry que requieren estado sofisticado:
- Los puntos son "malos" (minimizar hasta 100)
- Cuando alguien pasa 100, puede hacer retry UNA VEZ (reinicia su puntaje al del jugador más cercano a 100)
- El juego termina cuando queda solo 1 jugador sin pasar 100
- Necesita historial persistente para futuras migraciones a Firebase

## Solution

Agregar módulo independiente **"La Loba"** dentro del News App que:
- Crea games con N jugadores
- Anotan puntos por partida (suma/resta)
- Autochequea game over y ofrece retry
- Persiste en SQLite local
- Accesible vía Drawer Menu
- Implementado con Clean Architecture (data/domain/presentation)
- State management con GameBloc

## User Stories

1. As a player, I want to create a new game with a custom name, so that I can track multiple gaming sessions

2. As a player, I want to add players to the game by entering their names one at a time, so that I can include all participants

3. As a player, I want to start a game once all players are added, so that I can begin playing partidas

4. As a player, I want to see all active players on a single screen during a partida, so that I can efficiently record scores

5. As a player, I want to enter scores for each player via a text input field, so that I can record exact points earned

6. As a player, I want to use +/- buttons to adjust scores incrementally, so that I can correct mistakes easily

7. As a player, I want to finalize a partida and move to the next one, so that I can progress through the game

8. As a player, I want to see the cumulative score for each player after each partida, so that I can track who is close to 100

9. As a system, I need to detect when a player reaches or exceeds 100 points after a partida, so that I can trigger game-over logic

10. As a player, I want to receive a retry offer when I exceed 100 points, so that I can reset my score to the closest competitor's score and continue playing

11. As a player, I want to be able to accept or reject a retry, so that I can decide whether to continue or exit the game

12. As a system, I need to track that a player has used their ONE retry per game, so that I can prevent duplicate retries

13. As a player who rejects a retry or has already used one, I want to be eliminated from the game, so that the game continues with remaining players

14. As a system, I need to continue the game with active players only after eliminations, so that eliminated players no longer score

15. As a system, I need to detect when only one player remains with score < 100, so that I can end the game

16. As a player, I want to see the final game ranking when the game ends, so that I know the results and winner (lowest score)

17. As a player, I want to view my game history, so that I can see previously completed games

18. As a player, I want to access La Loba from the app drawer menu, so that I can navigate to the feature easily

19. As a player, I want my game data to persist locally, so that I don't lose progress if I close the app

20. As a system, I need to store game data in SQLite, so that it can be migrated to Firebase in the future

21. As a player, I want to see a clear UI showing game name, current partida number, and active players, so that I understand the current game state

22. As a player, I want to see which players are still active vs eliminated, so that I understand who is still playing

23. As a player, I want to retry a game session with the same players, so that I can play multiple games consecutively

## Implementation Decisions

### Architecture

- **Pattern**: Clean Architecture (Data/Domain/Presentation layers)
- **Location**: `lib/features/la_loba/`
- **State Management**: GameBloc with events (not Cubit, for consistency with complex logic)
- **Navigation**: Drawer menu entry in main app, isolated feature navigation

### Data Layer

- **Persistence**: SQLite with `sqflite` package
- **Local Data Source**: Handles all database operations (create, read, update, delete games/players/partidas)
- **Models**: Extend domain entities with JSON serialization for DB storage
  - `GameModel` (id, name, status, createdAt, players, partidas)
  - `PlayerModel` (id, name, gameId, totalScore, hasUsedRetry, isEliminated)
  - `PartidaModel` (id, partidaNumber, gameId, scores, createdAt)
  - `ScoreModel` (id, playerId, partidaId, points)

- **Repository Implementation**: `GameRepositoryImpl` handles datasource operations and error mapping

### Domain Layer

- **Entities**: Pure Dart objects, no dependencies
  - `Game`: id, name, players, partidas, status, createdAt
  - `Player`: id, name, gameId, totalScore, hasUsedRetry, isEliminated
  - `Partida`: id, partidaNumber, gameId, scores, createdAt
  - `Score`: id, playerId, partidaId, points

- **Repository Interface**: Abstract `GameRepository` with methods for all operations

- **Use Cases**: Single responsibility, each encapsulates one business operation
  - `CreateGameUseCase(name)` → Game
  - `AddPlayerUseCase(gameId, playerName)` → Player
  - `RecordScoreUseCase(gameId, partidaNumber, playerId, points)` → void
  - `FinishPartidaUseCase(gameId, partidaNumber)` → List<Player> (updated scores)
  - `CheckGameOverUseCase(gameId)` → {gameOver: bool, eliminatedPlayer: Player?, retryCandidate: Player?}
  - `DoRetryUseCase(gameId, playerId)` → Player (score reset)
  - `RejectRetryUseCase(gameId, playerId)` → void (eliminates player)
  - `FetchGameUseCase(gameId)` → Game
  - `FetchGameHistoryUseCase()` → List<Game>

### Presentation Layer

- **GameBloc**: Event-driven state management
  - Events: CreateGame, AddPlayer, RecordScore, FinishPartida, CheckGameOver, DoRetry, RejectRetry, FetchGame, FetchHistory
  - States: Initial, Loading, GameCreated, GamePlaying, PartidaFinished, RetryOffered, GameOver, Error
  - Handles navigation and business logic orchestration

- **Screens**:
  - `CreateGameScreen`: Input game name, add players (list + input field + "agregar" button)
  - `GamePlayScreen`: All players with scores, input + +/- buttons per player, "finalizar partida" button
  - `GameFinishedScreen`: Final ranking, "volver" or "nueva game" button

- **Widgets**:
  - `PlayerScoreCard`: Displays player name, score, input + buttons
  - `RetryDialog`: Popup offering retry with accept/reject buttons
  - `GameOverDialog`: Final results summary
  - `GameHistoryList`: List of past games with view option

### Database Schema

**games** table
```
id (INTEGER PRIMARY KEY)
name (TEXT NOT NULL)
status (TEXT) -- "playing" | "finished"
createdAt (INTEGER) -- unix timestamp
```

**players** table
```
id (INTEGER PRIMARY KEY)
gameId (INTEGER FOREIGN KEY)
name (TEXT NOT NULL)
totalScore (INTEGER DEFAULT 0)
hasUsedRetry (INTEGER DEFAULT 0) -- 0 | 1
isEliminated (INTEGER DEFAULT 0) -- 0 | 1
```

**partidas** table
```
id (INTEGER PRIMARY KEY)
gameId (INTEGER FOREIGN KEY)
partidaNumber (INTEGER NOT NULL)
createdAt (INTEGER)
```

**scores** table
```
id (INTEGER PRIMARY KEY)
playerId (INTEGER FOREIGN KEY)
partidaId (INTEGER FOREIGN KEY)
points (INTEGER NOT NULL)
```

### UI/UX Flow

1. **Drawer Menu** → "La Loba" option
2. **Create Game Screen** → Input game name → Button "crear"
3. **Add Players Screen** → Input field + "agregar" button (repeatable) → "empezar" button
4. **Game Play Screen** (loop per partida)
   - Shows: Game name, Partida N, list of active players
   - Per player: current score + input field + +/- buttons
   - "finalizar partida" button
5. **After Partida** → Check scores
   - If anyone ≥ 100: Show popup "¿Retry?" (accept/reject)
   - If retry rejected or already used: Eliminate player
   - If only 1 player <100: Game Over
   - Else: Continue to next Partida
6. **Game Over Screen** → Ranking (by totalScore ascending), "volver" / "nueva game"

### Event Flow & State Transitions

```
Initial
  → CreateGame event
    → Loading
    → GameCreated (ready to add players)
  → AddPlayer event (repeated)
    → GameCreated (updated player list)
  → Start Game
    → GamePlaying (Partida 1, all players active)
  → RecordScore event (per player)
    → GamePlaying (updated scores)
  → FinishPartida event
    → Loading
    → CheckGameOver event (automatic)
      → If game over && someone ≥100
        → RetryOffered state (show dialog)
          → DoRetry event
            → GamePlaying (Partida N+1, player score reset)
          → RejectRetry event
            → GamePlaying (Partida N+1, player eliminated)
      → If only 1 player <100
        → GameOver state (show ranking)
```

### Error Handling

- Invalid game state (e.g., no players)
- Database failures (catch and emit Error state)
- Score validation (non-negative integers)
- Retry logic already used (prevent double retry)

## Testing Decisions

### What Makes a Good Test

- **Test external behavior**, not implementation details
- Each test should validate a complete business operation
- Mocks should be at the layer boundary (repository mocks in bloc tests, datasource mocks in repo tests)
- Test edge cases: empty games, single player, multiple eliminations, retry logic

### Modules to Test

1. **Domain Layer** (most important — pure business logic)
   - `CheckGameOverUseCase`: ✅ Test all end-game scenarios (game over, retry offered, continue)
   - `DoRetryUseCase`: ✅ Test score reset logic, one-retry limit
   - `RecordScoreUseCase`: ✅ Test score accumulation
   - All other use cases with business logic

2. **Data Layer** (integration tests)
   - `LocalDataSource`: ✅ Test SQLite CRUD (create game, add players, record scores, retrieve)
   - `GameRepositoryImpl`: ✅ Test repository contract (error mapping, data transformation)

3. **Presentation Layer** (bloc tests)
   - `GameBloc`: ✅ Test state transitions, event handling, error states
   - Screens/Widgets: Manual testing (UI testing is expensive, focus on logic)

### Prior Art

Follow the existing project's BLoC testing patterns from `test/features/*/presentation/bloc/` directory. Use `bloc_test` package for event/state assertions.

## Out of Scope

- **Firebase Integration**: Will be done in Phase 2 after local MVP is validated
- **Multiplayer Sync**: No real-time collaboration, single-device for now
- **Card Logic**: No simulation of actual cards, only score tracking
- **UI Animations**: Basic UI, no fancy animations in MVP
- **Advanced Analytics**: No deep game statistics in Phase 1
- **Game Export/Share**: Will consider for Phase 2
- **Dark Mode Support**: Not required for MVP
- **Accessibility Improvements**: Standard Flutter accessibility, no special features

## Further Notes

### Migration Path to Firebase

Once MVP is stable:
1. Add Firebase Firestore collection for games/players
2. Extend `LocalDataSource` to sync with Firestore
3. Implement conflict resolution (last-write-wins or custom)
4. Add offline-first sync logic

### Testing Strategy

- Start with domain layer (use cases) — critical business logic
- Then data layer (repository + datasource) — persistence correctness
- Finally bloc tests — state orchestration
- UI manual testing only (heavy widget testing is not cost-effective)

### Future Enhancements (Post-MVP)

- Player statistics (win rate, average score)
- Favorite players list (for faster game creation)
- Game statistics per session
- Undo/revert last partida
- Custom retry rules
- Tournament mode (multiple games, standings)

---

**Status**: Ready for SDD Phase 1 (Exploration complete via grill-me)
**Next**: Execute SDD workflow → proposal → specs → design → tasks → implementation
