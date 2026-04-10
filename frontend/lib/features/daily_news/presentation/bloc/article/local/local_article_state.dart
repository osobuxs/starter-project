import 'package:equatable/equatable.dart';

import '../../../../domain/entities/article.dart';

abstract class LocalArticlesState extends Equatable {
  final List<ArticleEntity>? articles;
  final String? message;

  const LocalArticlesState({this.articles, this.message});

  @override
  List<Object?> get props => [articles, message];
}

class LocalArticlesLoading extends LocalArticlesState {
  const LocalArticlesLoading();
}

class LocalArticlesDone extends LocalArticlesState {
  const LocalArticlesDone(List<ArticleEntity> articles, {String? message})
    : super(articles: articles, message: message);
}

class LocalArticlesError extends LocalArticlesState {
  const LocalArticlesError(String message, {List<ArticleEntity>? articles})
    : super(articles: articles, message: message);
}
