import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MeditationPlayerScreen extends StatefulWidget {
  final String title;
  final String audioUrl;
  final String imageUrl;
  final String duration;

  const MeditationPlayerScreen({
    Key? key,
    required this.title,
    required this.audioUrl,
    required this.imageUrl,
    required this.duration,
  }) : super(key: key);

  @override
  State<MeditationPlayerScreen> createState() => _MeditationPlayerScreenState();
}

class _MeditationPlayerScreenState extends State<MeditationPlayerScreen>
    with TickerProviderStateMixin {
  bool _isPlaying = false;
  double _currentPosition = 0.0;
  double _totalDuration = 600.0; // 10 minutes in seconds
  late AnimationController _breathingAnimationController;
  late AnimationController _progressAnimationController;
  late Animation<double> _breathingAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _parseDuration();
  }

  void _initializeAnimations() {
    _breathingAnimationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _progressAnimationController = AnimationController(
      duration: Duration(seconds: _totalDuration.toInt()),
      vsync: this,
    );

    _breathingAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _breathingAnimationController,
      curve: Curves.easeInOut,
    ));

    _breathingAnimationController.repeat(reverse: true);
  }

  void _parseDuration() {
    String durationStr = widget.duration.replaceAll(' min', '');
    int minutes = int.tryParse(durationStr) ?? 10;
    _totalDuration = minutes * 60.0;
  }

  @override
  void dispose() {
    _breathingAnimationController.dispose();
    _progressAnimationController.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    HapticFeedback.lightImpact();
    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      _progressAnimationController.forward();
    } else {
      _progressAnimationController.stop();
    }
  }

  void _seekTo(double position) {
    setState(() {
      _currentPosition = position;
    });
    _progressAnimationController.animateTo(position / _totalDuration);
  }

  String _formatTime(double seconds) {
    int minutes = (seconds / 60).floor();
    int remainingSeconds = (seconds % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Now Playing',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () => _showOptionsMenu(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Album Art with Animation
              Expanded(
                flex: 2,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _breathingAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isPlaying ? _breathingAnimation.value : 1.0,
                        child: Container(
                          width: 280,
                          height: 280,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withValues(alpha: 0.3),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              widget.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.blue.withValues(alpha: 0.3),
                                        Colors.purple.withValues(alpha: 0.3),
                                      ],
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.self_improvement,
                                    size: 80,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Title and Info
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Guided Meditation',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Progress Bar
                    Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 16,
                            ),
                            activeTrackColor: Colors.blue,
                            inactiveTrackColor:
                                Colors.white.withValues(alpha: 0.2),
                            thumbColor: Colors.blue,
                            overlayColor: Colors.blue.withValues(alpha: 0.2),
                          ),
                          child: Slider(
                            value: _currentPosition,
                            max: _totalDuration,
                            onChanged: _seekTo,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatTime(_currentPosition),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                _formatTime(_totalDuration),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Control Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Previous/Rewind Button
                        IconButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _seekTo((_currentPosition - 30)
                                .clamp(0, _totalDuration));
                          },
                          icon: const Icon(Icons.replay_30),
                          color: Colors.white,
                          iconSize: 32,
                        ),

                        // Play/Pause Button
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: _togglePlayPause,
                            icon: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              size: 40,
                            ),
                            color: Colors.white,
                          ),
                        ),

                        // Forward Button
                        IconButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _seekTo((_currentPosition + 30)
                                .clamp(0, _totalDuration));
                          },
                          icon: const Icon(Icons.forward_30),
                          color: Colors.white,
                          iconSize: 32,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2D2D44),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Options',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.timer, color: Colors.white),
                title: const Text(
                  'Sleep Timer',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Implement sleep timer
                },
              ),
              ListTile(
                leading: const Icon(Icons.speed, color: Colors.white),
                title: const Text(
                  'Playback Speed',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Implement speed control
                },
              ),
              ListTile(
                leading: const Icon(Icons.download, color: Colors.white),
                title: const Text(
                  'Download',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Implement download
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
