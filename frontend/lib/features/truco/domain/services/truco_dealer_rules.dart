// Dealer rotation around the Truco table. The deck moves one seat per hand
// in [seatingOrder] (player ids in table order) and wraps at the end.

/// Seat after [playerId]. An unknown or missing player starts at the first
/// seat; an empty table has no seat.
String? trucoNextSeat(List<String> seatingOrder, String? playerId) {
  if (seatingOrder.isEmpty) return null;
  final index = playerId == null ? -1 : seatingOrder.indexOf(playerId);
  if (index < 0) return seatingOrder.first;
  return seatingOrder[(index + 1) % seatingOrder.length];
}

/// Seat before [playerId]. An unknown or missing player falls back to the
/// last seat (the one before the first); an empty table has no seat.
String? trucoPreviousSeat(List<String> seatingOrder, String? playerId) {
  if (seatingOrder.isEmpty) return null;
  final index = playerId == null ? -1 : seatingOrder.indexOf(playerId);
  if (index < 0) return seatingOrder.last;
  final length = seatingOrder.length;
  return seatingOrder[(index - 1 + length) % length];
}

/// The "mano" (first to play) sits right after the dealer.
String? trucoManoOf(List<String> seatingOrder, String? dealerId) =>
    trucoNextSeat(seatingOrder, dealerId);

/// [preferredId] when seated, otherwise the first seat.
String? trucoFirstDealer(List<String> seatingOrder, String? preferredId) {
  if (preferredId != null && seatingOrder.contains(preferredId)) {
    return preferredId;
  }
  return seatingOrder.isEmpty ? null : seatingOrder.first;
}
