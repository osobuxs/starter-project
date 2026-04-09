import 'package:equatable/equatable.dart';

abstract class RemoteArticlesEvent extends Equatable {
  const RemoteArticlesEvent();

  @override
  List<Object?> get props => [];
}

class GetArticles extends RemoteArticlesEvent {
  final bool loadMore;
  final DateTime? selectedDate;
  final bool clearDateFilter;

  const GetArticles({
    this.loadMore = false,
    this.selectedDate,
    this.clearDateFilter = false,
  });

  @override
  List<Object?> get props => [loadMore, selectedDate, clearDateFilter];
}
