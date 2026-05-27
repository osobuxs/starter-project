# Spec: Dardos Module

- **Status**: Draft
- **Date**: 2026-05-21
- **Change ID**: dardos-module
- **Owner**: Exequiel Vega

---

## Alcance del delta

Este spec describe el estado observable que DEBE ser verdadero luego de aplicar el cambio `dardos-module`. Cubre únicamente lo que cambia respecto al estado actual de `starter-project`. No repite lo que ya existe en `la_loba` salvo donde los comportamientos difieren explícitamente.

---

## R1: Gestión de participantes de dardos

### REQUIREMENT R1: Participant management (dardos-specific)

El sistema SHALL mantener una colección independiente `dardos_participants` en Firestore para jugadores de dardos, completamente separada de `participants` (la_loba). Ninguna operación de dardos SHALL escribir jamás en la colección `participants` ni en `games`.

Un `DardosParticipantEntity` SHALL tener los campos: `id`, `name`, `email` (opcional), `uid` (opcional), `totalGamesPlayed`, `totalGamesWon`, `isActive`, `deletedAt`.

Solo el admin (`lfexevega95@gmail.com`) SHALL poder crear y soft-deletear participantes. Cualquier usuario autenticado SHALL poder leer la lista. Usuarios anónimos SHALL poder leer la lista.

El soft-delete SHALL setear `isActive = false` y `deletedAt = timestamp`; el documento SHALL permanecer en Firestore.

#### SCENARIO: Admin crea participante exitosamente
**Given** el usuario autenticado es `lfexevega95@gmail.com` (admin)
**When** envía `CreateDardosParticipantEvent` con nombre no vacío
**Then** se crea un documento en `dardos_participants/{id}` con `isActive = true` y `deletedAt = null`; el BLoC emite estado con `status = success`

#### SCENARIO: No-admin intenta crear participante
**Given** el usuario autenticado NO es el email admin
**When** envía `CreateDardosParticipantEvent`
**Then** el BLoC rechaza la operación antes de llamar al repositorio; emite estado con `status = error`; Firestore NO recibe ningún write

#### SCENARIO: Admin soft-deletea participante
**Given** existe un participante con `isActive = true`
**When** admin envía `DeleteDardosParticipantEvent` con ese id
**Then** Firestore recibe un update con `{isActive: false, deletedAt: <timestamp>}`; el participante deja de aparecer en la lista activa; el documento sigue existiendo en Firestore

#### SCENARIO: Lectura pública de participantes
**Given** usuario no autenticado (anónimo)
**When** accede a la pestaña Jugadores
**Then** puede ver la lista de participantes activos; no puede crear ni eliminar

---

## R2: Creación de partida

### REQUIREMENT R2: Game creation

El sistema SHALL permitir a cualquier usuario autenticado crear una partida de dardos. Al crear una partida se SHALL especificar:
- **Nombre** (string, manual, obligatorio)
- **Modo**: `501` | `301` | `cricket`
- **Sets**: número entero ≥ 1
- **Legs**: número entero ≥ 1
- **Double-out**: boolean (aplica sólo a modos 501/301; ignorado en Cricket)
- **Participantes**: lista ordenada de ids de `dardos_participants`, mínimo 2

La partida SHALL crearse con `status = waiting`, `activeAnnotator = null`, `currentSet = 1`, `currentLeg = 1`.

El `starterOrder[]` SHALL inicializarse con el orden de participantes tal como fueron seleccionados. El starter de cada leg se determina en runtime (ver R9).

#### SCENARIO: Creación exitosa de partida 501
**Given** usuario autenticado con al menos 2 participantes seleccionados, modo `501`, sets=1, legs=3, doubleOut=true, nombre no vacío
**When** envía `CreateDardosGameEvent`
**Then** se crea documento en `dardos_games/{id}` con todos los campos correctos; `status = waiting`; `participantIds` en el orden seleccionado; BLoC navega a `game_play_page`

#### SCENARIO: Creación de partida Cricket
**Given** usuario autenticado, modo `cricket`, doubleOut=true
**When** crea la partida
**Then** el campo `doubleOut` se persiste como `false` (ignorado/forzado a false para Cricket) O se ignora en toda lógica de Cricket — el sistema SHALL no aplicar double-out en Cricket bajo ninguna circunstancia

#### SCENARIO: Menos de 2 participantes seleccionados
**Given** usuario autenticado
**When** intenta crear partida con 1 o 0 participantes
**Then** el BLoC rechaza la operación; emite estado `error` con mensaje descriptivo; Firestore no recibe write

#### SCENARIO: Nombre vacío
**Given** usuario autenticado, participantes válidos
**When** intenta crear partida con nombre vacío o solo espacios
**Then** el BLoC rechaza; emite estado `error`; Firestore no recibe write

---

## R3: Reorden de jugadores y roster lock

### REQUIREMENT R3: Player reordering and roster lock

El sistema SHALL permitir reordenar la lista de participantes de una partida únicamente mientras `status = waiting` (ningún tiro registrado). Una vez que se registra el primer tiro, el roster SHALL quedar bloqueado permanentemente.

El roster lock SHALL ser verificado en el BLoC: si `status != waiting`, cualquier evento de reorden SHALL ser ignorado.

#### SCENARIO: Reorden antes del primer tiro
**Given** partida con `status = waiting`, ningún throw registrado
**When** usuario reordena la lista de jugadores
**Then** el campo `participantIds` en el documento del game se actualiza con el nuevo orden; `starterOrder` se recalcula según el nuevo orden

#### SCENARIO: Intento de reorden con tiros ya registrados
**Given** partida con al menos 1 throw en la subcolección `throws`
**When** el BLoC recibe un evento de reorden
**Then** el evento es ignorado; el estado permanece sin cambios; Firestore no recibe write

---

## R4: Cancelación de partidas

### REQUIREMENT R4: Game cancellation (admin only)

Solo el admin SHALL poder cancelar una partida. Una partida cancelada SHALL:
- Cambiar `status` a `cancelled`
- **Conservar** todos sus throws en la subcolección (para analítica)
- **Excluirse** del cómputo de ranking (W/L, MPR, avg, etc.)
- Ser visible en historial con estado `cancelled` pero marcada visualmente como tal

Un usuario no-admin que intente cancelar SHALL ver el intento rechazado por el BLoC antes de llegar a Firestore.

#### SCENARIO: Admin cancela partida en curso
**Given** partida con `status = in_progress` con throws registrados
**When** admin envía `CancelDardosGameEvent`
**Then** Firestore recibe update `{status: 'cancelled'}`; los throws en la subcolección permanecen intactos; la partida no aparece en el ranking

#### SCENARIO: No-admin intenta cancelar
**Given** usuario autenticado sin privilegios admin
**When** envía `CancelDardosGameEvent`
**Then** BLoC rechaza; emite estado `error`; Firestore no recibe write

#### SCENARIO: Partida cancelada excluida del ranking
**Given** partida con `status = cancelled` con throws de jugadores
**When** se computa el ranking de cualquier modo
**Then** los throws y resultados de esa partida NO contribuyen a ninguna métrica de ranking

---

## R5: Soft-lock de anotador

### REQUIREMENT R5: Annotator soft-lock

El sistema SHALL implementar un mecanismo de exclusión mutua de escritura mediante el campo `activeAnnotator` en el documento del game. Solo el dispositivo/usuario que posea el lock SHALL poder registrar tiros.

La toma del lock SHALL ejecutarse mediante una transacción Firestore con condición: `activeAnnotator == null || activeAnnotator == myDeviceId`. Si la condición falla, el intento se rechaza.

El lock SHALL liberarse cuando:
- El anotador cierra la pantalla de juego
- La partida finaliza (status = finished)
- Admin fuerza la liberación manualmente (v1: sin UI especial — admin puede hacerlo vía admin panel externo)

El cliente sin lock SHALL ver la pantalla en modo read-only con un banner: `"<nombre> está anotando. Tocá para tomar el control"`. Al tocar, se intenta la transacción de toma de lock.

#### SCENARIO: Primer dispositivo toma el lock
**Given** partida con `activeAnnotator = null`
**When** dispositivo A ejecuta la transacción de toma de lock
**Then** `activeAnnotator` se setea al id del dispositivo A; dispositivo A entra en modo anotación

#### SCENARIO: Segundo dispositivo intenta tomar lock ocupado
**Given** partida con `activeAnnotator = "deviceA"`
**When** dispositivo B intenta tomar el lock
**Then** la transacción Firestore falla (precondición no cumplida); dispositivo B permanece en modo read-only con banner visible

#### SCENARIO: Segundo dispositivo toma lock con toma explícita
**Given** partida con `activeAnnotator = "deviceA"`, usuario B toca el banner "Tomar control"
**When** dispositivo B ejecuta la transacción de take-over
**Then** `activeAnnotator` se actualiza a `"deviceB"` en una sola transacción atómica; dispositivo A pasa a modo read-only; dispositivo B entra en modo anotación

#### SCENARIO: Liberación de lock al cerrar pantalla
**Given** dispositivo A posee el lock (`activeAnnotator = "deviceA"`)
**When** dispositivo A navega fuera de `game_play_page`
**Then** Firestore recibe update `{activeAnnotator: null}`

#### SCENARIO: Espectador anónimo
**Given** usuario no autenticado accede a una partida en curso
**Then** puede ver el estado del juego en tiempo real (Firestore onSnapshot); no puede registrar tiros; no puede tomar el lock

---

## R6: Anotación de tiro (501/301)

### REQUIREMENT R6: Throw annotation — 501/301 modes

El sistema SHALL permitir al anotador registrar hasta 3 dardos por turno. Cada dardo SHALL persistirse como un documento individual en `dardos_games/{id}/throws/{throwId}` con los campos estructurados: `number` (1–20, 25 para bull ext, 50 para bull int), `multiplier` (1|2|3 — para bull: 1=single/25pts, 2=double/50pts), `points` (calculado), `playerId`, `turnNumber`, `dartIndex` (0|1|2), `set`, `leg`, `timestamp`, `isBust`.

La puntuación de un turno en 501/301 SHALL restar la suma de los 3 dardos del puntaje actual del jugador.

#### SCENARIO: Turno normal sin bust
**Given** jugador con 200 puntos restantes, turno con dardos [T20=60, S20=20, S5=5] = 85 pts
**When** se registran los 3 dardos
**Then** 3 documentos en `throws`; el puntaje del jugador baja de 200 a 115; se avanza al siguiente jugador

#### SCENARIO: Bust por pasarse
**Given** jugador con 32 puntos, dardos [S20, S15, ...] — primer dardo 20, quedan 12; segundo dardo 15, queda -3
**When** el segundo dardo produce score < 0
**Then** el tiro que produce bust se persiste con `isBust = true`; el puntaje del jugador NO cambia (vuelve a 32); el turno termina inmediatamente; se avanza al siguiente jugador

#### SCENARIO: Bust por quedar en exactamente 1 punto
**Given** jugador con 3 puntos, doubleOut = true, lanza S2
**When** el tiro deja al jugador con 1 punto
**Then** isBust = true; puntaje vuelve al inicio del turno (3 puntos); turno termina

#### SCENARIO: Bust por llegar a 0 sin doble (double-out ON)
**Given** jugador con 20 puntos, doubleOut = true, lanza S20
**When** el tiro lleva el score a 0 pero el dardo no es doble (multiplier ≠ 2 y no es bull interior)
**Then** isBust = true; puntaje vuelve al inicio del turno; turno termina

#### SCENARIO: Cierre válido con doble (double-out ON)
**Given** jugador con 40 puntos, doubleOut = true, lanza D20 (doble 20 = 40 puntos)
**When** el tiro lleva el score a exactamente 0 y el dardo es doble (multiplier = 2)
**Then** isBust = false; score = 0; el jugador gana el leg; se avanza a resolver winner (R9)

#### SCENARIO: Cierre válido sin doble requerido (double-out OFF)
**Given** jugador con 20 puntos, doubleOut = false, lanza S20
**When** el tiro lleva el score a exactamente 0
**Then** isBust = false; score = 0; el jugador gana el leg; se avanza a R9

#### SCENARIO: Cierre con bull interior como doble (double-out ON)
**Given** jugador con 50 puntos, doubleOut = true
**When** lanza bull interior (number=50, multiplier=2, points=50)
**Then** isBust = false; score = 0; cierre válido con doble; jugador gana el leg

#### SCENARIO: El jugador no lanza los 3 dardos por bust
**Given** jugador recibe bust en el segundo dardo
**Then** el tercer dardo NO se registra; el turno termina con 2 throws; la detección de bust es correcta

---

## R7: Anotación de tiro (Cricket)

### REQUIREMENT R7: Throw annotation — Cricket mode

En Cricket, el tablero SÓLO contiene los objetivos: 15, 16, 17, 18, 19, 20 y bull. Un tiro a cualquier otro número vale 0 marcas y 0 puntos.

**Marcas**:
- `number=15-20`, `multiplier=1` → 1 marca en ese número
- `number=15-20`, `multiplier=2` → 2 marcas en ese número
- `number=15-20`, `multiplier=3` → 3 marcas en ese número
- Bull exterior (`number=25`, `multiplier=1`) → 1 marca en bull
- Bull interior (`number=50`, `multiplier=2`) → 2 marcas en bull
- Cualquier otro número → 0 marcas, 0 puntos

Un número queda **cerrado** cuando el jugador acumula ≥ 3 marcas.

**Puntos cruzados**: tras cerrar un número, cada marca adicional sobre ese mismo número (sobrante de cierre + tiros futuros) SHALL generar puntos igual al valor del número × cantidad de marcas excedentes, PERO SÓLO SI al menos un oponente aún no ha cerrado ese número.

Si TODOS los jugadores han cerrado un número, no se generan puntos (el número queda "dead").

La condición de victoria en un leg de Cricket: el jugador que cierra TODOS sus objetivos (15-20 + bull) Y tiene igual o más puntos que todos sus oponentes.

#### SCENARIO: Turno con triple sobre número abierto
**Given** jugador A tiene 0 marcas en el 19, lanza T19 (triple 19)
**When** se registra el tiro
**Then** jugador A tiene 3 marcas en 19 → cerrado; 0 puntos generados (marca exacta de cierre); el tiro se persiste con marks computados

#### SCENARIO: Cierre con marca sobrante y oponente sin cerrar
**Given** jugador A tiene 2 marcas en 17; jugador B tiene 0 marcas en 17 (no cerrado)
**When** jugador A lanza D17 (doble 17 = 2 marcas)
**Then** 1 marca cierra el 17 (llega a 3); 1 marca sobrante × 17 pts = 17 puntos para jugador A; el tiro se persiste

#### SCENARIO: Cierre con marca sobrante y todos cerraron
**Given** jugador A tiene 2 marcas en 17; jugador B ya cerró el 17
**When** jugador A lanza D17
**Then** 1 marca cierra el 17; el 17 está "dead" (todos lo cerraron); 0 puntos generados

#### SCENARIO: Puntos cruzados en número ya cerrado
**Given** jugador A ya cerró el 20; jugador B tiene 1 marca en el 20 (no cerrado)
**When** jugador A lanza T20
**Then** jugador A genera 60 puntos (3 × 20); el tiro se persiste

#### SCENARIO: No genera puntos cuando todos cerraron
**Given** jugador A cerró 20; jugador B cerró 20
**When** jugador A lanza T20
**Then** 0 puntos generados (número dead); el tiro se persiste con points = 0

#### SCENARIO: Bull en Cricket — exterior vs interior
**Given** jugador A tiene 0 marcas en bull
**When** lanza bull exterior (25 pts físicamente)
**Then** jugador A suma 1 marca en bull; si bull extrajuego aún no cerrado por nadie, 0 puntos (aún no cerrado)

**Given** jugador A tiene 2 marcas en bull
**When** lanza bull interior (50 pts físicamente)
**Then** jugador A suma 2 marcas → bull cerrado (acumula 4 marcas, necesitaba 3 — 1 sobrante); si algún oponente no cerró bull, genera 25 puntos por la marca sobrante (bull vale 25 por marca)

#### SCENARIO: Ganador de leg en Cricket
**Given** jugador A cerró 15, 16, 17, 18, 19, 20 y bull; jugador B tiene puntaje 45 pts; jugador A tiene 80 pts
**When** jugador A cierra el último objetivo abierto
**Then** se evalúa condición: A tiene todos cerrados y A.pts (80) >= B.pts (45) → A gana el leg

#### SCENARIO: Cerró todo pero oponente tiene más puntos
**Given** jugador A cerró todos los objetivos; jugador B tiene más puntos que A
**When** se evalúa condición de victoria
**Then** A NO gana el leg aún; el juego continúa; A debe generar puntos hasta igualar o superar a B

---

## R8: Auto-avance de turno

### REQUIREMENT R8: Turn auto-advance

El sistema SHALL avanzar automáticamente al siguiente jugador cuando:
1. El jugador actual completa 3 dardos en su turno (sin bust)
2. Se produce un bust (turno termina inmediatamente al detectar el bust, aunque queden dardos)

El orden de turnos SHALL seguir el orden de `participantIds` de forma cíclica dentro de cada leg. El starter del leg N es `participantIds[N mod count]` (0-indexed).

Luego de un bust o turno completo, el sistema SHALL mostrar un cartel visual por 2 segundos antes de avanzar. El cartel SHALL mostrar: bust (mensaje de bust), o fin de turno (puntaje conseguido).

#### SCENARIO: Auto-avance tras 3 dardos sin bust
**Given** jugador A completó 3 dardos sin bust ni victoria
**When** se registra el tercer dardo
**Then** el turno pasa automáticamente al siguiente jugador en el orden cíclico; se muestra cartel 2s

#### SCENARIO: Auto-avance inmediato por bust
**Given** jugador A recibe bust en el segundo dardo
**When** se registra el dardo de bust
**Then** turno pasa inmediatamente al siguiente jugador sin esperar el tercer dardo; se muestra cartel 2s con "Bust"

---

## R9: Resolución de winner de leg/set/game y rotación de starter

### REQUIREMENT R9: Leg/set/game winner and starter rotation

El sistema SHALL implementar una state machine de 2 niveles (leg → set → game).

**Leg winner**: El jugador que llega a 0 puntos (con/sin doble según config) en 501/301, o cumple condición Cricket (R7), gana el leg. Se persiste en el documento del game: `legWinners[legIndex] = playerId`.

**Set winner**: El jugador que gane la mayoría de legs configurados dentro de un set gana el set. Se persiste `setWinners[setIndex] = playerId`.

**Game winner**: El jugador que gane la mayoría de sets gana el game. Se setea `winnerId` y `status = finished`.

**Rotación del starter**: El starter del leg `L` (0-indexed globalmente a través de todos los legs de todos los sets) SHALL ser `participantIds[L mod participantIds.length]`.

Al finalizar un leg o set, el sistema SHALL mostrar un cartel 2s antes de avanzar.

#### SCENARIO: Jugador gana un leg en 501
**Given** partida 501, legs=3, sets=1; jugador A baja su puntaje a 0 con tiro válido
**When** se registra el tiro ganador
**Then** `legWinners[currentLegIndex] = playerA.id`; se evalúa si hay ganador de set; si no, empieza nuevo leg con starter rotado; se muestra cartel "Leg ganado por A" 2s

#### SCENARIO: Jugador gana el set
**Given** partida 501, legs=3, sets=1; jugador A gana 2 de 3 legs
**When** jugador A gana el segundo leg
**Then** `setWinners[0] = playerA.id`; se evalúa si hay ganador de game; si sets=1, playerA gana el game

#### SCENARIO: Jugador gana el game
**Given** partida con sets=3; jugador A gana 2 de 3 sets
**When** jugador A gana el segundo set
**Then** `winnerId = playerA.id`; `status = finished`; se dispara R15 (métricas de cierre); se navega a `game_finished_page`; `activeAnnotator` se libera (seteado a null)

#### SCENARIO: Rotación de starter entre legs
**Given** partida con 3 jugadores [A, B, C]; leg 0 → starter A; leg 1 → starter B; leg 2 → starter C; leg 3 → starter A
**When** se inicia cada nuevo leg
**Then** el primer turno del leg corresponde al jugador en posición `L mod 3`

---

## R10: Undo del último tiro (sin restricción)

### REQUIREMENT R10: Unrestricted undo

El sistema SHALL permitir deshacer el último tiro registrado en cualquier momento durante la partida, sin restricción de turno, leg o set. El undo SHALL funcionar aunque el tiro a deshacer sea el último de un turno completado, el que ganó un leg, o el que ganó un set.

**Mecanismo (event-sourced replay)**:
1. Se obtiene el throw más reciente de la subcolección `throws` (ordenado por `set`, `leg`, `turnNumber`, `dartIndex` desc)
2. Se borra ese documento de Firestore
3. El estado del game (puntajes, marcas, currentLeg, currentSet, starterOrder, legWinners, setWinners, winnerId) se recomputa replayando todos los throws restantes desde cero, en orden ascendente

El undo SHALL ser encadenable (se puede hacer undo múltiples veces hasta llegar al estado inicial sin throws).

Si no hay throws, el evento de undo SHALL ser ignorado.

#### SCENARIO: Undo dentro del mismo turno
**Given** jugador A tiene 2 dardos lanzados en el turno actual (darts 0 y 1)
**When** se dispara `UndoLastThrowEvent`
**Then** el documento del dart 1 se borra de Firestore; el estado del turno retrocede a 1 dardo lanzado; el puntaje se recalcula por replay

#### SCENARIO: Undo cruzando turno
**Given** jugador B está en su turno; el último tiro registrado es el 3er dardo del turno anterior de jugador A
**When** se dispara `UndoLastThrowEvent`
**Then** el 3er dardo de A se borra; el turno vuelve a ser de jugador A (con 2 dardos ya lanzados); el puntaje de A se recalcula

#### SCENARIO: Undo cruzando leg
**Given** jugador A acaba de ganar el leg 1; el sistema muestra leg 2 como activo
**When** se dispara `UndoLastThrowEvent`
**Then** el tiro ganador del leg 1 se borra; `legWinners` se re-evalúa (leg 1 ya no tiene ganador); `currentLeg` vuelve a 1; el puntaje de A se recalcula por replay completo

#### SCENARIO: Undo cruzando set
**Given** jugador A acaba de ganar el set 1; el sistema muestra set 2 como activo
**When** se dispara `UndoLastThrowEvent`
**Then** el tiro ganador del último leg del set se borra; `setWinners[0]` se limpia; `currentSet` vuelve a 1; el puntaje se recalcula por replay completo

#### SCENARIO: Undo sin throws
**Given** partida recién creada, sin ningún throw en la subcolección
**When** se dispara `UndoLastThrowEvent`
**Then** el evento es ignorado; el estado no cambia; Firestore no recibe operaciones

#### SCENARIO: Undo encadenado hasta el estado inicial
**Given** partida con N throws registrados
**When** se ejecutan N veces `UndoLastThrowEvent`
**Then** al final no quedan throws; el estado del game vuelve al estado inicial (puntajes = 501/301 o marcas vacías, leg=1, set=1, sin ganadores de leg/set); no hay errores

---

## R11: Vista en tiempo real para espectadores

### REQUIREMENT R11: Live view — read-only spectators

El sistema SHALL proveer una vista en tiempo real del estado de la partida para usuarios no-anotadores y usuarios anónimos. La UI SHALL reflejar cambios de Firestore (onSnapshot) sin requerir refresh manual.

La vista read-only SHALL mostrar: puntajes actuales por jugador, dardos del turno en curso, leg/set actuales, quién está anotando (banner `annotator_lock_banner`).

#### SCENARIO: Espectador anónimo ve partida en tiempo real
**Given** usuario anónimo navega a una partida en curso
**Then** puede ver el estado actualizado en tiempo real; no ve controles de anotación; el banner "X está anotando" es visible pero el botón "Tomar control" está deshabilitado o ausente

#### SCENARIO: Usuario autenticado sin lock ve partida
**Given** usuario autenticado que no posee el lock
**When** ve la pantalla de juego
**Then** puede ver el estado completo; el banner muestra "X está anotando. Tocá para tomar el control" con botón activo

---

## R12: Detección de Cricket — cierre de número multi-jugador

### REQUIREMENT R12: Cricket multi-player state

En partidas de Cricket con más de 2 jugadores, la condición "número dead" SHALL evaluarse contra TODOS los jugadores: el número es dead sólo cuando TODOS los jugadores (sin excepción) han cerrado ese número.

La función que calcula puntos cruzados SHALL recibir el estado de marcas de todos los jugadores y evaluar si queda al menos un jugador sin cerrar ese número.

El ganador de un leg en modo Cricket SHALL ser el primer jugador que: (a) cierre todos los objetivos Y (b) tenga puntaje ≥ al puntaje de TODOS sus oponentes.

#### SCENARIO: 3 jugadores, número dead cuando todos cerraron
**Given** partida de Cricket con 3 jugadores A, B, C; A cerró el 18; B cerró el 18; C tiene 2 marcas en el 18
**When** C lanza S18
**Then** C cierra el 18; el número 18 es ahora dead (todos cerraron); 0 puntos generados para C aunque tenga marcas sobrantes del tiro

#### SCENARIO: 3 jugadores, puntos cruzados con uno sin cerrar
**Given** A cerró el 18; B cerró el 18; C NO cerró el 18
**When** A lanza T18
**Then** A genera 54 puntos (3 × 18) porque C aún no cerró

---

## R13: Persistencia de métricas al finalizar partida

### REQUIREMENT R13: Game completion metrics

Al finalizar una partida (`status = finished`), el sistema SHALL computar y persistir las métricas del juego en el documento de la partida bajo el campo `metrics`. Las métricas son per-jugador y se persisten como un mapa.

**Métricas para 501/301**:
- `avgThreeDart`: promedio de puntos por turno de 3 dardos (excluye turnos de bust)
- `bestTurn`: mejor turno de 3 dardos
- `count180s`: cantidad de turnos con 180 puntos (T20+T20+T20)
- `count140plus`: cantidad de turnos ≥ 140 puntos
- `checkoutPct`: porcentaje de turnos en los que el jugador tenía oportunidad de cierre (score ≤ 170) y lo logró

**Métricas para Cricket**:
- `mpr`: marks per round (total marcas / total rondas jugadas)
- `closings`: cantidad de números cerrados por el jugador

Las métricas SHALL computarse del event log (subcolección `throws`) — nunca de contadores pre-calculados.

Adicionalmente, al finalizar la partida, el sistema SHALL actualizar los stats de los participantes en `dardos_participants`:
- `totalGamesPlayed += 1` para todos los participantes
- `totalGamesWon += 1` solo para el ganador (`winnerId`)

Las partidas con `status = cancelled` NO disparan esta actualización.

#### SCENARIO: Métricas de 501 al finalizar
**Given** partida 501 finalizada con throws registrados
**When** el game alcanza `status = finished`
**Then** el campo `metrics` en el documento del game contiene un mapa con `{playerId: {avgThreeDart, bestTurn, count180s, count140plus, checkoutPct}}`; los valores son computados correctamente desde el event log

#### SCENARIO: Stats de participante actualizadas
**Given** partida finalizada con ganador = jugador A
**When** se procesa la finalización
**Then** `dardos_participants/{A.id}` recibe update `{totalGamesWon: increment(1), totalGamesPlayed: increment(1)}`; todos los demás participantes reciben `{totalGamesPlayed: increment(1)}`

#### SCENARIO: Partida cancelada no actualiza stats
**Given** partida con `status = cancelled`
**When** se revisa el estado de los participantes
**Then** `totalGamesPlayed` y `totalGamesWon` de los participantes involucrados NO fueron modificados por esa partida

---

## R14: Ranking por modo

### REQUIREMENT R14: Rankings per game mode

La pantalla de ranking SHALL tener sub-tabs: **301 | 501 | Cricket**.

Cada sub-tab SHALL mostrar los jugadores ordenados por métricas relevantes al modo:
- **501/301**: ordenados por `checkoutPct` desc (primario), `avgThreeDart` desc (secundario), `count180s` desc (terciario)
- **Cricket**: ordenados por `mpr` desc (primario), `closings` desc (secundario)

El ranking SHALL considerar SÓLO partidas con `status = finished` (no `cancelled`, no `waiting`, no `in_progress`).

Los jugadores sin partidas en un modo SHALL aparecer al final o no aparecer (sin datos).

#### SCENARIO: Jugador con múltiples partidas 501
**Given** jugador A tiene 3 partidas 501 finalizadas con diferentes checkoutPct
**When** se carga el ranking de 501
**Then** las métricas mostradas son agregados de TODAS sus partidas finalizadas de 501 (avg de avg, sum de 180s, etc.) — o la métrica de su mejor/última partida según la decisión de diseño — los datos mostrados son consistentes con el event log

#### SCENARIO: Ranking excluye partidas canceladas
**Given** jugador A tiene 1 partida 501 finalizada y 1 partida 501 cancelada
**When** se carga el ranking
**Then** sólo la partida finalizada contribuye a las métricas; la cancelada no suma en ninguna métrica

---

## R15: Navegación global y módulo wrapper

### REQUIREMENT R15: Global navigation and module wrapper

El sistema SHALL incluir:
- Una entrada en el drawer global de `AppSectionScaffold` con label `'Dardos'` e ícono `Icons.sports_score`, que navega a la ruta `AppRouteNames.dardos`
- Una pantalla wrapper `DardosWrapper` con `BottomNavigationBar` de 3 tabs: **Iniciar** (tab 0) / **Jugadores** (tab 1) / **Ranking** (tab 2)
- Rutas registradas en `routes.dart`: `dardos`, `dardosCreate`, `dardosPlay`, `dardosFinished`, `dardosParticipantDetail`
- `registerDardosDependencies(sl)` invocado desde `injection_container.dart`

#### SCENARIO: Acceso desde drawer global
**Given** cualquier pantalla del app que muestre el drawer
**When** usuario toca la entrada "Dardos"
**Then** navega a `DardosWrapper` con tab 0 (Iniciar) activo

#### SCENARIO: Navegación entre tabs
**Given** usuario está en `DardosWrapper`
**When** toca los tabs del bottom nav
**Then** el `IndexedStack` muestra la pantalla correcta sin reconstruir las otras tabs

---

## R16: Reglas Firestore para dardos

### REQUIREMENT R16: Firestore security rules

El sistema SHALL agregar reglas Firestore para las colecciones de dardos que permitan:
- `read: true` (público) en `dardos_participants` y `dardos_games` (incluida la subcolección `throws`)
- `create` y `update: isSignedIn()` en las mismas
- `delete: false` en todas las colecciones de dardos

Las reglas NO SHALL interferir con las reglas existentes de `la_loba`.

#### SCENARIO: Lectura pública de throws
**Given** usuario anónimo
**When** ejecuta un query a `dardos_games/{id}/throws`
**Then** la operación es permitida por las reglas (read = true)

#### SCENARIO: Write no autenticado rechazado
**Given** usuario no autenticado
**When** intenta crear un documento en `dardos_games`
**Then** la operación es rechazada por las reglas Firestore (isSignedIn() = false)

---

## R17: Tests unitarios de servicios de dominio

### REQUIREMENT R17: Domain service unit tests (strict TDD)

Los tres servicios de dominio SHALL tener cobertura de tests unitarios > 90%:
- `dardos_score_rules_test.dart`: cubre todos los casos de bust, double-out, countdown correcto
- `dardos_cricket_rules_test.dart`: cubre marks computation, puntos cruzados, condición de dead, condición de victoria
- `dardos_leg_rules_test.dart`: cubre `isLegOver`, `isSetOver`, `isGameOver`, `nextStarter` con rotación correcta

Los servicios son funciones puras sin dependencias de Firestore ni BLoC. Los tests son unitarios puros (sin mocks de Firestore).

#### SCENARIO: Test de bust en score_rules
**Given** test unitario de `dardos_score_rules.dart`
**When** se llama a `isBust(remainingScore: 1, dart: Dart(number:1, multiplier:1))`
**Then** retorna `true` (quedar en 0 con single cuando doubleOut=true es bust)

#### SCENARIO: Test de rotación de starter
**Given** `participantIds = [A, B, C]`, `legIndex = 4` (0-indexed)
**When** se llama a `nextStarter(participantIds, legIndex: 4)`
**Then** retorna `participantIds[4 mod 3] = participantIds[1] = B`

---

## R18: Colecciones dardos NO cruzan a la_loba

### REQUIREMENT R18: Isolation from la_loba collections

Ningún repositorio, datasource ni BLoC de dardos SHALL referenciar las rutas Firestore `participants` ni `games` (las de la_loba). Toda referencia de dardos SHALL usar exclusivamente `dardos_participants` y `dardos_games`.

#### SCENARIO: Isolation test
**Given** todos los archivos bajo `frontend/lib/features/dardos/`
**When** se busca cualquier referencia a la colección `'participants'` o `'games'` (sin prefijo `dardos_`)
**Then** no se encuentra ninguna referencia en el código de dardos (salvo comentarios documentales)

---

## Campos estructurados de un DardosThrowEntity

Cada documento en `dardos_games/{id}/throws/{throwId}` SHALL contener:

```
{
  id: String,
  gameId: String,
  playerId: String,
  set: int,
  leg: int,
  turnNumber: int,
  dartIndex: int,        // 0, 1 o 2
  number: int,           // 1-20, 25 (bull ext), 50 (bull int)
  multiplier: int,       // 1, 2, o 3
  points: int,           // calculado: number * multiplier
  isBust: bool,
  timestamp: Timestamp
}
```

Los campos calculados de estado del game (puntaje actual, marcas Cricket, leg/set actual) SHALL ser recomputados en cliente a partir del event log, NO persistidos como contadores en el document del throw.

---

## Restricciones y no-objetivos (v1)

Los siguientes comportamientos están explícitamente OUT del scope de este spec:
- Modo Cut Throat Cricket
- Master Out / Double In
- Reconocimiento por voz
- Cache local offline / SQLite
- Dashboard de analítica avanzada (gráficos de tendencia, heatmaps)
- Importación/exportación de partidas
- Heartbeat automático de lock (v2)
- Liberación forzada de lock por admin desde la UI (v1: sólo vía Firestore externo)
