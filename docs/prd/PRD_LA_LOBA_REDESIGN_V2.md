# PRD: La Loba Redesign v2

**Date**: 2026-04-17  
**Author**: Exequiel Vega  
**Status**: APPROVED  
**Project**: starter-project (News App + La Loba Module)

---

## Problem Statement

The current La Loba MVP is a linear, single-game experience with basic score tracking via SQLite. Users need:

1. **Persistent global participant management** — reusable players across multiple games with accumulated stats
2. **Multiple concurrent games** — ability to pause a game, start another, and resume the paused one
3. **Enhanced gameplay UX** — dealer rotation visibility, hand-by-hand score tracking, and dealer passing at mano derecha (clockwise)
4. **Comprehensive ranking system** — historical game lookup with multi-dimensional filtering (date, participant, winner)
5. **Admin control** — only designated admin can create/manage participants and games
6. **Cloud persistence** — all data (games, hands, participants, stats) backed by Firebase Firestore

---

## Solution

Redesign La Loba as a **multi-game, participant-centric application** with a bottom navigation bar (3 tabs: Iniciar, Usuarios, Ranking). Migrate from SQLite to Firebase Firestore. Introduce participant aggregation (global, reusable across games) with per-game state isolation.

### Key Changes

1. **Bottom Navigation UI** — 3 distinct tabs (full-screen, independently scrollable)
2. **Participant Management (Usuarios tab)** — global registry with stats, create/edit/delete (admin only)
3. **Game Management (Iniciar tab)** — create, pause, resume, and play multiple games concurrently
4. **Gameplay Redesign** — horizontal score table + two-panel layout (live table + hand history)
5. **Ranking & History (Ranking tab)** — searchable, filterable game history
6. **Firebase Backend** — Firestore collections for participants, games, and hands
7. **Admin Auth** — Firebase Auth integration; only `lfexevega95@gmail.com` can manage participants

---

## User Stories

### Tab 1: Iniciar (Game Management & Gameplay)

1. As a player, I want to create a new game so that I can start tracking scores for a session.
2. As a player, I want to select participants from a global list so that I don't have to re-enter names.
3. As a player, I want to reorder participants (drag-and-drop or up/down buttons) so that they are seated in the correct clockwise order.
4. As a player, I want to see which participant is the dealer for the current hand so that I know who deals next.
5. As a player, I want the dealer to automatically rotate after each hand so that I don't have to manually track it.
6. As a player, I want a visual notification showing the new dealer after a hand completes so that everyone knows the rotation.
7. As a player, I want a horizontal score table (one column per participant) so that I can see all scores at a glance.
8. As a player, I want to input points for each participant in each hand (integers only) so that I can track score changes.
9. As a player, I want the ability to add new participants mid-game so that latecomers can join.
10. As a player, I want newly added participants to enter with the highest current score so that the game remains balanced.
11. As a player, I want to finalize a hand (with a confirmation dialog) so that scores are locked and the next hand begins.
12. As a player, I want to see a hand history panel below the score table so that I can review past hand scores.
13. As a player, I want the hand history formatted as: "Mano 1: Juan 10 acumulado:45 / María 15 acumulado:44 / ..." so that it is concise and readable.
14. As a player, I want to see the dealer indicator on the hand history so that I know who dealt in each hand.
15. As a player, I want to pause a game and switch to another so that I can manage multiple concurrent games.
16. As a player, I want to resume a paused game and continue from where I left off so that no progress is lost.
17. As a player, I want a list of paused games (Iniciar tab) so that I can pick which game to play next.
18. As a player, I want participants who are eliminated (>100 points) to be blocked from further score input so that they cannot cheat.
19. As a player, I want eliminated participants to remain visible in the hand history so that the full game record is preserved.
20. As a player, I want to be prompted to re-engage an eliminated participant (re-ingreso) so that they can rejoin with the highest current score.
21. As a player, I want the ability to reject re-ingreso so that they stay eliminated.
22. As a player, I want to see a victory screen when all but one participant is eliminated so that the winner is clearly announced.
23. As a player, I want the victory screen to show the winner's final score and the final scores of all eliminated participants.
24. As a player, I want to expand the victory screen to see the full hand history so that I can review the entire game.
25. As a player, I want to close the victory screen and return to the Iniciar tab so that I can start a new game.

### Tab 2: Usuarios (Participant Management)

26. As a user, I want to view all registered participants and their stats (games played, games won) so that I can see the leaderboard.
27. As an admin, I want to create a new participant with a name (required) and email (optional) so that I can register players.
28. As an admin, I want to edit a participant's email (or other details) so that I can update their info.
29. As an admin, I want to delete a participant so that I can manage the roster.
30. As a user, I want to click on a participant to see their stats and game history so that I can review their record.
31. As a user, I want to see all games a participant has played in the history view so that I can review their performance.
32. As a user, I want to click on a game in the participant's history so that I can see the full game details (winner, final scores, hand history).
33. As a user (unauthenticated), I want to view the participant list in read-only mode so that I can see the leaderboard without logging in.
34. As a user, I want a search bar to find participants by name so that I can quickly locate someone.
35. As a user, I want a (+) button to add a new participant (admin only) so that the roster grows as needed.

### Tab 3: Ranking (Game History & Filtering)

36. As a user, I want to see a list of all completed games sorted by date (most recent first) so that I can browse the history.
37. As a user, I want to filter games by date range so that I can find games from a specific period.
38. As a user, I want to filter games by participant so that I can see all games a specific player participated in.
39. As a user, I want to filter games by winner so that I can see all games won by a specific player.
40. As a user, I want to combine multiple filters (date + participant + winner) so that I can narrow results efficiently.
41. As a user, I want to click on a game in the ranking so that I can see the full game details.
42. As a user, I want the game detail view to show the winner, final scores, and an expandible section for hand-by-hand history.
43. As a user, I want to see the hand history with the dealer indicator for each hand so that I can review the game progression.

### Authentication & Admin

44. As a user, I want to access the app without logging in so that I can view participants, games, and rankings freely.
45. As a user, I want to log in with Firebase Auth using my email so that I unlock admin features.
46. As an admin (lfexevega95@gmail.com), I want create/edit/delete buttons to appear when I log in so that I have full control.
47. As a non-admin user, I want create/edit/delete buttons to be hidden so that I cannot accidentally modify data.
48. As an admin, I want to create a game so that I can initialize a new game session.
49. As a non-admin user, I want to view in-progress and paused games so that I can follow along.

### Data Persistence & Statistics

50. As a player, I want all game data (games, hands, scores) to persist in Firebase so that no data is lost.
51. As a participant, I want my stats (total games played, total games won) to update automatically so that my leaderboard position is accurate.
52. As a participant, I want to see my stats in the Usuarios tab so that I can track my performance.
53. As a player, I want to see which participant won a game in the victory screen so that credit is given.
54. As a player, I want the winner's stats to increment (games won) when a game finishes so that their leaderboard reflects the win.

---

## Implementation Decisions

### Architecture & Data Model

- **Participant Entity (new)**: Global, non-game-specific entity with fields: `id`, `name`, `email`, `totalGamesPlayed`, `totalGamesWon`, `uid` (Firebase Auth).
- **Game Entity (refactored)**: Now uses `participantIds[]` (references) instead of embedded `PlayerEntity` objects. Adds fields: `currentDealerId`, `currentHand`, `participantStates{participantId: {score, status}}`, `winnerId`, `date`.
- **Hand Entity (renamed from PartidaEntity)**: `handNumber`, `dealerId`, `scores{participantId: points}`, `timestamp`.
- **Participant Status States**: `active` (can score), `eliminated` (>100 points, blocked), `reinstarted` (re-joined after elimination).
- **Firestore Collection Structure (Hybrid)**:
  ```
  /participants/{participantId}
    - name, email, totalGamesPlayed, totalGamesWon, uid
  /games/{gameId}
    - name, date, status (playing/paused/finished), winnerId, participantIds[], currentDealerId, currentHand
    - participantStates{participantId: {score, status}}
    /hands/{handNumber}
      - dealerId, scores{participantId: points}, timestamp
  ```

### UI & Navigation

- **Bottom Navigation**: 3 tabs (Iniciar, Usuarios, Ranking) using `IndexedStack` for persistent state management. Each tab is a full-screen, independently scrollable view.
- **Game Pause/Resume**: Paused games stored in a list; selecting one resumes from last state without losing progress.
- **Score Table Layout**: Horizontal table (one column per participant, max 6 participants) for ease of data entry.
- **Hand History Panel**: Two-panel layout (top: live table, bottom: scrollable hand history). Format: compact inline (Mano N: P1 pts acc / P2 pts acc / ...).
- **Dealer Rotation**: Auto-rotate after hand confirmation; toast notification with dealer name.
- **Eliminated Participants**: Blocked from input in current hand; remain visible in history as read-only rows.

### Gameplay Logic

- **Re-ingreso Flow**: Unified "Add Participant" button works for both new mid-game adds and re-entries. System detects if participant already exists in game (for re-ingreso) or is new.
- **Highest Score Rule**: New/re-joining participants enter with the highest current score in the game.
- **Game Over Condition**: Game ends when all but one participant are eliminated (>100 points). Winner is the last active participant.
- **Victory Screen**: Shows winner + final scores of all participants (ordered: winner first, then others). Expandible section for full hand history.

### Firebase & Persistence

- **Backend**: Firestore (not SQLite). All collections replicate to client via realtime listeners.
- **Authentication**: Firebase Auth (email/password). Only `lfexevega95@gmail.com` can create/manage participants.
- **Security Rules**: Firestore rules enforce write permissions (admin only for `/participants` collection). Read access is public (no auth required for views).
- **Stats Aggregation**: Participant stats (`totalGamesPlayed`, `totalGamesWon`) updated via Cloud Functions or client-side batch writes on game finish.

### Admin Features

- **Role Detection**: App checks `currentUser.email` on startup. If `lfexevega95@gmail.com`, show create/edit/delete buttons.
- **Participant CRUD** (admin only):
  - Create: Modal with name (required) + email (optional) inputs.
  - Edit: Modal to update email or other details.
  - Delete: Confirmation dialog (prevents accidental deletes).
- **Game Creation** (admin only): Only admin can initiate a new game. Non-admins can view and play existing games.

### BLoC State Management

- **MultiGameBloc** (new): Manages list of games (active, paused, finished). Events: `CreateGame`, `StartGame`, `PauseGame`, `ResumeGame`, `FinishGame`, `AddParticipant`, `AddHandScore`, `FinalizeHand`, `PromptReinicio`.
- **ParticipantBloc** (new): Manages participant CRUD and listing. Events: `FetchParticipants`, `CreateParticipant`, `UpdateParticipant`, `DeleteParticipant`.
- **GameBloc** (refactored): Now scoped to a single game instance (the one being played). Receives participant data from MultiGameBloc.
- **BottomNavBloc** (new): Manages tab navigation state and tab-specific data (e.g., which game is selected in Iniciar tab).

---

## Testing Decisions

### What Makes a Good Test

- **Test external behavior, not implementation**: Tests verify that a use case produces the correct output given an input, without caring how it's done internally.
- **One assertion per test** (when possible): Easier to debug and understand failures.
- **Arrange-Act-Assert pattern**: Set up state, perform action, verify result.
- **Mock external dependencies**: Firebase calls, repositories, and data sources are mocked in unit tests. Integration tests use an emulator or test database.

### Modules to Test

1. **Participant Use Cases** (new):
   - `CreateParticipantUseCase` — validates name, email (optional), creates participant.
   - `UpdateParticipantUseCase` — updates email, checks for duplicates.
   - `DeleteParticipantUseCase` — removes participant (admin only).
   - `FetchParticipantsUseCase` — retrieves all participants sorted by stats.

2. **Game Use Cases** (refactored):
   - `CreateGameUseCase` — validates name, initializes game with participantIds[].
   - `StartGameUseCase` — transitions game from "created" to "playing".
   - `PauseGameUseCase` — saves state, transitions to "paused".
   - `ResumeGameUseCase` — loads state, transitions back to "playing".
   - `FinishGameUseCase` — determines winner, updates participant stats.
   - `FetchGamesUseCase` — retrieves active, paused, or finished games.

3. **Hand Use Cases** (new/refactored):
   - `AddHandScoreUseCase` — records points for all participants in a hand.
   - `FinalizeHandUseCase` — locks hand, rotates dealer, checks for eliminations.
   - `PromptReinicioUseCase` — handles re-ingreso logic.

4. **Game Repository** (refactored):
   - Abstract interface with methods for CRUD and multi-game operations.
   - Verify Firestore calls (mocked in unit tests).

5. **Firestore Data Source** (new):
   - Unit tests with mocked Firestore client.
   - Integration tests with emulator (optional, later).

### Prior Art

- Existing MVP tests in `test/features/la_loba/` use BLoC testing patterns (`blocTest`).
- Follow the same conventions: `given` / `when` / `then` comments, `expect()` matchers.
- Use `mockito` for mocking repositories and data sources.

---

## Out of Scope

- **Social features** — sharing games, chat, invitations (not included in v2).
- **Advanced analytics** — win rate graphs, hand-by-hand replay animations (future).
- **Mobile notifications** — push notifications for turn order or game updates (future).
- **Offline mode** — app requires Firebase connectivity (offline queueing not in v2).
- **Multiple device sync** — real-time multiplayer on different devices (not in v2; single-device multi-game only).
- **Export/Import** — CSV exports, backups (future).
- **Undo/Redo** — reverting hand scores after finalization (future; can manually edit in Firestore for now).

---

## Further Notes

### Migration Path from MVP

The current MVP (SQLite-based) will be **incrementally refactored** into v2:

1. **Phase 1**: Migrate entities (Game, Player → Game, Participant) and repository to Firebase.
2. **Phase 2**: Implement MultiGameBloc, BottomNavBloc, and new tabs (Usuarios, Ranking).
3. **Phase 3**: Refactor gameplay UX (horizontal table, two panels, dealer rotation).
4. **Phase 4**: Add admin auth and CRUD for participants.
5. **Phase 5**: Polish, testing, and release.

### Backward Compatibility

Existing games in SQLite will **not** be migrated automatically. New games will use Firebase exclusively. If users have in-progress SQLite games, they will appear in a "legacy" section (read-only) or be discarded upon first launch.

### Firebase Setup

- Firestore database: standard configuration (no sharding needed for single device).
- Firebase Auth: email/password provider only.
- Security Rules: enforce admin-only writes to `/participants`. Public read access for all other collections.
- Cloud Functions: optional, can auto-update participant stats on game finish (or do client-side for simplicity in v2).

### Performance Considerations

- **Real-time listeners**: Games and hands use Firestore listeners for live updates. Paused games unsubscribe from listeners to reduce battery drain.
- **Lazy loading**: Ranking tab loads games in batches (pagination) to avoid loading entire history on first load.
- **Indexing**: Firestore composite indexes on (date, status) and (winnerId, date) for efficient filtering.

---

**Status**: Ready for SDD Planning & Implementation
