import 'dart:async';
import 'package:flutter/material.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_game/dardos_game_state.dart';

/// Full-screen overlay banner that auto-dismisses after 2 seconds.
/// Visible only when [bannerType] != [DardosBannerType.none].
/// Calls [onDismiss] after 2 seconds.
class AutoAdvanceBanner extends StatefulWidget {
  final DardosBannerType bannerType;
  final String? bannerPayload;
  final VoidCallback onDismiss;

  const AutoAdvanceBanner({
    Key? key,
    required this.bannerType,
    this.bannerPayload,
    required this.onDismiss,
  }) : super(key: key);

  @override
  State<AutoAdvanceBanner> createState() => _AutoAdvanceBannerState();
}

class _AutoAdvanceBannerState extends State<AutoAdvanceBanner> {
  Timer? _timer;
  DardosBannerType? _activeBannerType;

  @override
  void initState() {
    super.initState();
    _startTimerIfNeeded();
  }

  @override
  void didUpdateWidget(AutoAdvanceBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bannerType != oldWidget.bannerType) {
      _timer?.cancel();
      _startTimerIfNeeded();
    }
  }

  void _startTimerIfNeeded() {
    if (widget.bannerType != DardosBannerType.none) {
      _activeBannerType = widget.bannerType;
      _timer = Timer(const Duration(milliseconds: 2000), () {
        if (mounted) {
          widget.onDismiss();
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.bannerType == DardosBannerType.none) {
      return const SizedBox.shrink();
    }

    final config = _bannerConfig(widget.bannerType, widget.bannerPayload);

    return GestureDetector(
      onTap: () {
        _timer?.cancel();
        widget.onDismiss();
      },
      child: Container(
        color: config.backgroundColor.withOpacity(0.92),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(config.icon, size: 72, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              config.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (config.subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                config.subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'Tocá para continuar',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  _BannerConfig _bannerConfig(
      DardosBannerType type, String? payload) {
    switch (type) {
      case DardosBannerType.bust:
        return _BannerConfig(
          backgroundColor: Colors.red.shade700,
          icon: Icons.cancel,
          title: 'BUST!',
          subtitle: payload != null ? 'Vuelve a $payload' : null,
        );
      case DardosBannerType.legWon:
        return _BannerConfig(
          backgroundColor: Colors.green.shade700,
          icon: Icons.emoji_events,
          title: '¡Leg ganado!',
          subtitle: payload,
        );
      case DardosBannerType.setWon:
        return _BannerConfig(
          backgroundColor: Colors.blue.shade700,
          icon: Icons.star,
          title: '¡Set ganado!',
          subtitle: payload,
        );
      case DardosBannerType.gameWon:
        return _BannerConfig(
          backgroundColor: Colors.amber.shade700,
          icon: Icons.military_tech,
          title: '¡Partida ganada!',
          subtitle: payload,
        );
      case DardosBannerType.none:
        return _BannerConfig(
          backgroundColor: Colors.transparent,
          icon: Icons.info,
          title: '',
        );
    }
  }
}

class _BannerConfig {
  final Color backgroundColor;
  final IconData icon;
  final String title;
  final String? subtitle;

  const _BannerConfig({
    required this.backgroundColor,
    required this.icon,
    required this.title,
    this.subtitle,
  });
}
