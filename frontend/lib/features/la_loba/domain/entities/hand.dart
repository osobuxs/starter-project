import 'package:equatable/equatable.dart';

class HandEntity extends Equatable {
  final int handNumber;
  final String dealerId; // participantId of dealer for this hand
  final Map<String, int> scores; // {participantId: points}
  final int timestamp;

  const HandEntity({
    required this.handNumber,
    required this.dealerId,
    this.scores = const {},
    required this.timestamp,
  });

  HandEntity copyWith({
    int? handNumber,
    String? dealerId,
    Map<String, int>? scores,
    int? timestamp,
  }) {
    return HandEntity(
      handNumber: handNumber ?? this.handNumber,
      dealerId: dealerId ?? this.dealerId,
      scores: scores ?? this.scores,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => [handNumber, dealerId, scores, timestamp];
}
