import 'dart:async';

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
  final Completer<void>? completer;

  const GetArticles({
    this.loadMore = false,
    this.selectedDate,
    this.clearDateFilter = false,
    this.completer,
  });

  @override
  List<Object?> get props => [loadMore, selectedDate, clearDateFilter];
}
