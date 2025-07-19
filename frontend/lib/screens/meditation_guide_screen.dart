import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/meditation_models.dart';
import '../widgets/meditation_timer.dart';
import '../widgets/breathing_animation.dart';
import '../widgets/step_indicator.dart';

class MeditationGuideScreen extends StatefulWidget {
  final Meditation meditation;

  const MeditationGuideScreen({
    super.key,
    required this.meditation,
  });

  @override
  State<MeditationGuideScreen> createState() => _MeditationGuideScreenState();
}

class _MeditationGuideScreenState extends State<MeditationGuideScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _breathingController;
  late AnimationController _progressController;

  int _currentStep = 0;
  bool _isStarted = false;
  bool _isPaused = false;
  bool _isCompleted = false;

  int _preMoodScore = 5;
  int _postMoodScore = 5;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _breathingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _progressController = AnimationController(
      duration: Duration(minutes: widget.meditation.durationMinutes),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _breathingController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => _showExitDialog(),
        ),
        title: Text(
          widget.meditation.name,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          if (_isStarted)
            IconButton(
              icon: Icon(
                _isPaused ? Icons.play_arrow : Icons.pause,
                color: Colors.white,
              ),
              onPressed: _togglePause,
            ),
        ],
      ),
      body: !_isStarted
          ? _buildPreMeditation()
          : _isCompleted
              ? _buildPostMeditation()
              : _buildMeditationGuide(),
    );
  }

  Widget _buildPreMeditation() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.spa,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 24),
                Text(
                  'Before we begin',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'How are you feeling right now?',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 32),
                _buildMoodSlider(
                  'Current Mood',
                  _preMoodScore,
                  (value) => setState(() => _preMoodScore = value),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Preparation Tips',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...[
                        'Find a quiet, comfortable place',
                        'Sit or lie down in a relaxed position',
                        'Turn off notifications',
                        'Allow yourself to be present',
                      ].map((tip) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    tip,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _startMeditation,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B4EFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Begin Meditation',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeditationGuide() {
    return Column(
      children: [
        // Progress bar
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              StepIndicator(
                currentStep: _currentStep,
                totalSteps: widget.meditation.instructions.length,
              ),
              const SizedBox(height: 16),
              MeditationTimer(
                duration: Duration(minutes: widget.meditation.durationMinutes),
                controller: _progressController,
                isPaused: _isPaused,
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentStep = index;
              });
              HapticFeedback.lightImpact();
            },
            itemCount: widget.meditation.instructions.length,
            itemBuilder: (context, index) {
              return _buildStepContent(index);
            },
          ),
        ),

        // Navigation
        if (!_isPaused)
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  TextButton(
                    onPressed: _previousStep,
                    child: const Text(
                      'Previous',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                else
                  const SizedBox(),
                if (_currentStep < widget.meditation.instructions.length - 1)
                  ElevatedButton(
                    onPressed: _nextStep,
                    child: const Text('Next'),
                  )
                else
                  ElevatedButton(
                    onPressed: _completeMeditation,
                    child: const Text('Complete'),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStepContent(int index) {
    final instruction = widget.meditation.instructions[index];
    final isBreathingStep = instruction.toLowerCase().contains('breath');

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Step ${index + 1}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          if (isBreathingStep)
            BreathingAnimation(controller: _breathingController),
          const SizedBox(height: 32),
          Text(
            instruction,
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (isBreathingStep)
            Text(
              'Follow the breathing animation',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPostMeditation() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 80,
                  color: Colors.green,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Well done!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'You\'ve completed the meditation',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 32),
                _buildMoodSlider(
                  'How do you feel now?',
                  _postMoodScore,
                  (value) => setState(() => _postMoodScore = value),
                ),
                const SizedBox(height: 32),
                if (_postMoodScore > _preMoodScore)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Great! Your mood improved by ${_postMoodScore - _preMoodScore} points!',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B4EFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Finish',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodSlider(String title, int value, Function(int) onChanged) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF6B4EFF),
            inactiveTrackColor: Colors.white.withOpacity(0.3),
            thumbColor: const Color(0xFF6B4EFF),
            overlayColor: const Color(0xFF6B4EFF).withOpacity(0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
          ),
          child: Slider(
            value: value.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: (double newValue) {
              onChanged(newValue.round());
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '😢 Very Bad',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
            Text(
              '$value/10',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '😊 Amazing',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _startMeditation() {
    setState(() {
      _isStarted = true;
    });
    _breathingController.repeat(reverse: true);
    _progressController.forward();
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });

    if (_isPaused) {
      _breathingController.stop();
      _progressController.stop();
    } else {
      _breathingController.repeat(reverse: true);
      _progressController.forward();
    }
  }

  void _nextStep() {
    if (_currentStep < widget.meditation.instructions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeMeditation() {
    _breathingController.stop();
    _progressController.stop();
    setState(() {
      _isCompleted = true;
    });
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Meditation?'),
        content: const Text(
          'Are you sure you want to exit? Your progress will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}
