String _safePrefix(String value, [int length = 4]) {
  if (value.isEmpty) return '----';
  final end = value.length < length ? value.length : length;
  return value.substring(0, end).toUpperCase();
}

String resolveParticipantName(
  String participantId,
  Map<String, String> participantNames,
) {
  final resolved = participantNames[participantId]?.trim();
  if (resolved != null && resolved.isNotEmpty) {
    return resolved;
  }

  return _safePrefix(participantId);
}

String shortParticipantLabel(
  String participantId,
  Map<String, String> participantNames,
) {
  final resolvedName = resolveParticipantName(participantId, participantNames);
  return _safePrefix(resolvedName, 4);
}
