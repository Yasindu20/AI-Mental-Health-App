import 'package:flutter/material.dart';
import 'dart:async';

class MeditationTimer extends StatefulWidget {
  final Duration duration;
  final AnimationController? controller;
  final bool isPaused;
  final VoidCallback? onComplete;

  const MeditationTimer({
    super.key,
    required this.duration,
    this.controller,
    this.isPaused = false,
    this.onComplete,
  });

  @override
  State<MeditationTimer> createState() => _MeditationTimerState();
}

class _MeditationTimerState extends State<MeditationTimer>
    with TickerProviderStateMixin {
  late AnimationController _timerController;
  late Animation<double> _timerAnimation;
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _remaining = widget.duration;

    _timerController = widget.controller ??
        AnimationController(
          duration: widget.duration,
          vsync: this,
        );

    _timerAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _timerController,
      curve: Curves.linear,
    ));

    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (widget.controller == null) {
      _timerController.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(MeditationTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPaused != oldWidget.isPaused) {
      if (widget.isPaused) {
        _pauseTimer();
      } else {
        _resumeTimer();
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!widget.isPaused) {
        setState(() {
          if (_remaining.inSeconds > 0) {
            _remaining = Duration(seconds: _remaining.inSeconds - 1);
          } else {
            _timer?.cancel();
            widget.onComplete?.call();
          }
        });
      }
    });

    if (!widget.isPaused) {
      _timerController.forward();
    }
  }

  void _pauseTimer() {
    _timerController.stop();
  }

  void _resumeTimer() {
    _timerController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Circular Progress Indicator
          SizedBox(
            width: 120,
            height: 120,
            child: AnimatedBuilder(
              animation: _timerAnimation,
              builder: (context, child) {
                return CircularProgressIndicator(
                  value: 1.0 - _timerAnimation.value,
                  strokeWidth: 6,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Time Display
          Text(
            _formatDuration(_remaining),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'monospace',
            ),
          ),

          const SizedBox(height: 8),

          // Progress Text
          Text(
            _getProgressText(),
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }

  String _getProgressText() {
    final totalSeconds = widget.duration.inSeconds;
    final remainingSeconds = _remaining.inSeconds;
    final completedSeconds = totalSeconds - remainingSeconds;
    final percentage = ((completedSeconds / totalSeconds) * 100).round();

    if (widget.isPaused) {
      return 'Paused - $percentage% Complete';
    } else if (_remaining.inSeconds == 0) {
      return 'Meditation Complete!';
    } else {
      return '$percentage% Complete';
    }
  }
}
