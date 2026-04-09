import 'package:equatable/equatable.dart';

class ArticleAuthorEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;

  const ArticleAuthorEntity({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
  });

  @override
  List<Object?> get props => [id, name, email, photoUrl];
}
