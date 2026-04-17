class RoundScoresUpdateResult {
  final Map<String, dynamic> updatedStates;
  final List<String> overLimitParticipantIds;

  const RoundScoresUpdateResult({
    required this.updatedStates,
    required this.overLimitParticipantIds,
  });
}

Map<String, int> buildRoundScoresForActivePlayers({
  required List<String> participantIds,
  required Map<String, dynamic> participantStates,
  required Map<String, int> enteredScores,
}) {
  final scores = <String, int>{};

  for (final participantId in participantIds) {
    final state = participantStates[participantId];
    if (!_isActiveState(state)) {
      continue;
    }

    scores[participantId] = enteredScores[participantId] ?? 0;
  }

  return scores;
}

RoundScoresUpdateResult applyRoundScoresAndFindOverLimit({
  required Map<String, dynamic> participantStates,
  required Map<String, int> roundScores,
}) {
  final updatedStates = {
    for (final entry in participantStates.entries)
      entry.key: _copyParticipantState(entry.value),
  };

  final overLimitIds = <String>[];

  for (final entry in roundScores.entries) {
    final participantId = entry.key;
    final state = updatedStates[participantId];
    if (!_isActiveState(state)) {
      continue;
    }

    final points = entry.value;
    final current = _readScore(state);
    final updatedScore = current + points;
    _writeScore(state, updatedScore);

    if (updatedScore > 100) {
      overLimitIds.add(participantId);
    }
  }

  return RoundScoresUpdateResult(
    updatedStates: updatedStates,
    overLimitParticipantIds: overLimitIds,
  );
}

Map<String, dynamic> applyRetryDecision({
  required Map<String, dynamic> participantStates,
  required String participantId,
  required bool rejoin,
  int? rejoinScoreOverride,
}) {
  final updatedStates = {
    for (final entry in participantStates.entries)
      entry.key: _copyParticipantState(entry.value),
  };

  final targetState = updatedStates[participantId];
  if (targetState is! Map<String, dynamic>) {
    return updatedStates;
  }

  if (rejoin) {
    final rejoinScore = rejoinScoreOverride ??
        _highestActiveScore(
          updatedStates,
          excludeParticipantId: participantId,
        );
    targetState['score'] = rejoinScore;
    targetState['status'] = 'active';
  } else {
    targetState['status'] = 'eliminated';
  }

  return updatedStates;
}

String? determineAutomaticWinner(Map<String, dynamic> participantStates) {
  String? candidate;
  var activeUnderLimitCount = 0;

  for (final entry in participantStates.entries) {
    final state = entry.value;
    if (!_isActiveState(state)) {
      continue;
    }

    final score = _readScore(state);
    if (score <= 100) {
      activeUnderLimitCount += 1;
      candidate = entry.key;
    }
  }

  if (activeUnderLimitCount == 1) {
    return candidate;
  }

  return null;
}

int countActiveParticipantsAtOrUnderLimit(
  Map<String, dynamic> participantStates,
) {
  var count = 0;

  for (final state in participantStates.values) {
    if (!_isActiveState(state)) {
      continue;
    }

    if (_readScore(state) <= 100) {
      count += 1;
    }
  }

  return count;
}

bool _isActiveState(dynamic rawState) {
  if (rawState is! Map<String, dynamic>) {
    return false;
  }

  return rawState['status'] == 'active';
}

Map<String, dynamic> _copyParticipantState(dynamic rawState) {
  if (rawState is Map<String, dynamic>) {
    return Map<String, dynamic>.from(rawState);
  }

  return <String, dynamic>{'score': 0, 'status': 'active'};
}

int _readScore(dynamic rawState) {
  if (rawState is! Map<String, dynamic>) {
    return 0;
  }

  final score = rawState['score'];
  return score is int ? score : 0;
}

void _writeScore(dynamic rawState, int score) {
  if (rawState is! Map<String, dynamic>) {
    return;
  }

  rawState['score'] = score;
}

int _highestActiveScore(
  Map<String, dynamic> participantStates, {
  String? excludeParticipantId,
}) {
  var highest = 0;

  for (final entry in participantStates.entries) {
    if (excludeParticipantId != null && entry.key == excludeParticipantId) {
      continue;
    }

    final state = entry.value;
    if (!_isActiveState(state)) {
      continue;
    }

    final score = _readScore(state);
    if (score > highest) {
      highest = score;
    }
  }

  return highest;
}
