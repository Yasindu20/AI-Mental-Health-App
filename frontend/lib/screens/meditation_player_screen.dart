// frontend/lib/screens/meditation_player_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../models/meditation_models.dart';
import '../services/meditation_service.dart';

class MeditationPlayerScreen extends StatefulWidget {
  final Meditation meditation;
  final String? personalizedScript;
  final int sessionId;

  const MeditationPlayerScreen({
    Key? key,
    required this.meditation,
    this.personalizedScript,
    required this.sessionId,
  }) : super(key: key);

  @override
  State<MeditationPlayerScreen> createState() => _MeditationPlayerScreenState();
}

class _MeditationPlayerScreenState extends State<MeditationPlayerScreen>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  int _secondsElapsed = 0;
  bool _isPlaying = false;
  bool _isCompleted = false;
  late AnimationController _breathingController;
  double _completionPercentage = 0;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    _startMeditation();
  }

  @override
  void dispose() {
    _timer.cancel();
    _breathingController.dispose();
    super.dispose();
  }

  void _startMeditation() {
    setState(() => _isPlaying = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
        _completionPercentage =
            (_secondsElapsed / (widget.meditation.durationMinutes * 60)) * 100;

        if (_completionPercentage >= 100) {
          _completionPercentage = 100;
          _isCompleted = true;
          _isPlaying = false;
          timer.cancel();
          _showCompletionDialog();
        }
      });
    });
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _secondsElapsed++;
            _completionPercentage =
                (_secondsElapsed / (widget.meditation.durationMinutes * 60)) *
                    100;
          });
        });
      } else {
        _timer.cancel();
      }
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CompletionDialog(
        sessionId: widget.sessionId,
        onComplete: () => Navigator.of(context).popUntil(
          ModalRoute.withName('/home'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _secondsElapsed ~/ 60;
    final seconds = _secondsElapsed % 60;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.meditation.name),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Breathing animation
              if (widget.meditation.type == 'breathing')
                _buildBreathingAnimation(),

              const SizedBox(height: 48),

              // Timer
              Text(
                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              // Progress bar
              LinearProgressIndicator(
                value: _completionPercentage / 100,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF6B4EFF),
                ),
              ),

              const SizedBox(height: 48),

              // Instructions or script
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    widget.personalizedScript ??
                        widget.meditation.instructions.join('\n\n'),
                    style: const TextStyle(
                      fontSize: 18,
                      height: 1.6,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Control buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Skip backward
                  IconButton(
                    icon: const Icon(Icons.replay_10, size: 32),
                    color: Colors.white54,
                    onPressed: () {
                      setState(() {
                        _secondsElapsed =
                            (_secondsElapsed - 10).clamp(0, 99999);
                      });
                    },
                  ),
                  const SizedBox(width: 24),

                  // Play/Pause
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6B4EFF), Color(0xFF8B6BFF)],
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 48,
                      ),
                      color: Colors.white,
                      padding: const EdgeInsets.all(16),
                      onPressed: _togglePlayPause,
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Skip forward
                  IconButton(
                    icon: const Icon(Icons.forward_10, size: 32),
                    color: Colors.white54,
                    onPressed: () {
                      setState(() {
                        _secondsElapsed += 10;
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // End session button
              TextButton(
                onPressed: () {
                  _timer.cancel();
                  _showCompletionDialog();
                },
                child: const Text(
                  'End Session',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreathingAnimation() {
    return AnimatedBuilder(
      animation: _breathingController,
      builder: (context, child) {
        final scale = 1 + (_breathingController.value * 0.3);
        return Container(
          width: 150 * scale,
          height: 150 * scale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFF6B4EFF).withOpacity(0.3),
                const Color(0xFF6B4EFF).withOpacity(0.1),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Center(
            child: Text(
              _breathingController.value < 0.5 ? 'Inhale' : 'Exhale',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CompletionDialog extends StatefulWidget {
  final int sessionId;
  final VoidCallback onComplete;

  const _CompletionDialog({
    Key? key,
    required this.sessionId,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<_CompletionDialog> createState() => _CompletionDialogState();
}

class _CompletionDialogState extends State<_CompletionDialog> {
  int _moodScore = 5;
  bool? _helpful;
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _completeSession() async {
    setState(() => _isLoading = true);

    try {
      final result = await MeditationService.completeSession(
        sessionId: widget.sessionId,
        moodScore: _moodScore,
        completionPercentage: 100,
        helpful: _helpful,
        notes: _notesController.text,
      );

      // Show results
      if (mounted) {
        final improvement = result['session_stats']['mood_improvement'] ?? 0;
        final message = improvement > 0
            ? 'Great job! Your mood improved by $improvement points!'
            : 'Well done on completing your session!';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );

        widget.onComplete();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            const Text(
              'Session Complete!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Mood rating
            const Text(
              'How do you feel now?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(10, (index) {
                final score = index + 1;
                return GestureDetector(
                  onTap: () => setState(() => _moodScore = score),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: score <= _moodScore
                          ? const Color(0xFF6B4EFF)
                          : Colors.grey[300],
                    ),
                    child: Center(
                      child: Text(
                        score.toString(),
                        style: TextStyle(
                          color: score <= _moodScore
                              ? Colors.white
                              : Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 24),

            // Helpful toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Was this helpful?'),
                const SizedBox(width: 16),
                ToggleButtons(
                  borderRadius: BorderRadius.circular(8),
                  selectedColor: Colors.white,
                  fillColor: const Color(0xFF6B4EFF),
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Yes'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('No'),
                    ),
                  ],
                  isSelected: [_helpful == true, _helpful == false],
                  onPressed: (index) {
                    setState(() => _helpful = index == 0);
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Notes
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'How was your experience?',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _completeSession,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Complete'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
