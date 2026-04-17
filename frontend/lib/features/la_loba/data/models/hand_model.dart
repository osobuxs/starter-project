import 'package:news_app_clean_architecture/features/la_loba/domain/entities/hand.dart';

class HandModel extends HandEntity {
  const HandModel({
    required int handNumber,
    required String dealerId,
    Map<String, int> scores = const {},
    required int timestamp,
  }) : super(
    handNumber: handNumber,
    dealerId: dealerId,
    scores: scores,
    timestamp: timestamp,
  );

  factory HandModel.fromFirestore(Map<String, dynamic> json, String docId) {
    return HandModel(
      handNumber: json['handNumber'] as int,
      dealerId: json['dealerId'] as String,
      scores: Map<String, int>.from(json['scores'] as Map? ?? {}),
      timestamp: json['timestamp'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'handNumber': handNumber,
      'dealerId': dealerId,
      'scores': scores,
      'timestamp': timestamp,
    };
  }

  HandEntity toEntity() => HandEntity(
    handNumber: handNumber,
    dealerId: dealerId,
    scores: scores,
    timestamp: timestamp,
  );
}
