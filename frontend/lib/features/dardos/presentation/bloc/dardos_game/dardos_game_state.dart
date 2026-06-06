import 'package:equatable/equatable.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/cricket_marks_state.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_game.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_throw.dart';

enum DardosGameStatus {
  initial,
  loading,
  gameCreated,
  loaded,
  throwRecorded,
  bustDetected,
  legWon,
  setWon,
  gameFinished,
  gameReopened,
  gameCancelled,
  annotatorLocked,
  error,
}

enum DardosBannerType { none, bust, legWon, setWon, gameWon }

class DardosGameState extends Equatable {
  final DardosGameStatus status;
  final DardosGameEntity? game;
  final List<DardosThrowEntity> throws;
  final Map<String, int> liveScores;
  final CricketMarksState? cricketState;
  final bool annotatorOwned;
  final DardosBannerType bannerType;
  final String? bannerPayload;
  final String? error;

  const DardosGameState({
    this.status = DardosGameStatus.initial,
    this.game,
    this.throws = const [],
    this.liveScores = const {},
    this.cricketState,
    this.annotatorOwned = false,
    this.bannerType = DardosBannerType.none,
    this.bannerPayload,
    this.error,
  });

  DardosGameState copyWith({
    DardosGameStatus? status,
    DardosGameEntity? game,
    List<DardosThrowEntity>? throws,
    Map<String, int>? liveScores,
    CricketMarksState? cricketState,
    bool? annotatorOwned,
    DardosBannerType? bannerType,
    String? bannerPayload,
    String? error,
    bool clearError = false,
    bool clearBanner = false,
  }) {
    return DardosGameState(
      status: status ?? this.status,
      game: game ?? this.game,
      throws: throws ?? this.throws,
      liveScores: liveScores ?? this.liveScores,
      cricketState: cricketState ?? this.cricketState,
      annotatorOwned: annotatorOwned ?? this.annotatorOwned,
      bannerType: clearBanner ? DardosBannerType.none : (bannerType ?? this.bannerType),
      bannerPayload: clearBanner ? null : (bannerPayload ?? this.bannerPayload),
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
        status,
        game,
        throws,
        liveScores,
        cricketState,
        annotatorOwned,
        bannerType,
        bannerPayload,
        error,
      ];
}
