import 'package:equatable/equatable.dart';

class ArticlePaginationCursor extends Equatable {
  final DateTime createdAt;
  final String firestoreId;

  const ArticlePaginationCursor({
    required this.createdAt,
    required this.firestoreId,
  });

  @override
  List<Object?> get props => [createdAt, firestoreId];
}
