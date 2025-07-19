import 'package:flutter/material.dart';

class BreathingAnimation extends StatefulWidget {
  final AnimationController controller;
  final Color color;
  final double size;

  const BreathingAnimation({
    super.key,
    required this.controller,
    this.color = Colors.blue,
    this.size = 120,
  });

  @override
  State<BreathingAnimation> createState() => _BreathingAnimationState();
}

class _BreathingAnimationState extends State<BreathingAnimation> {
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: widget.controller,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: widget.controller,
      curve: Curves.easeInOut,
    ));

    _colorAnimation = ColorTween(
      begin: widget.color.withOpacity(0.3),
      end: widget.color.withOpacity(0.8),
    ).animate(CurvedAnimation(
      parent: widget.controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer Ring
              Container(
                width: widget.size * 1.5,
                height: widget.size * 1.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _colorAnimation.value!.withOpacity(0.3),
                    width: 2,
                  ),
                ),
              ),

              // Animated Circle
              Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _colorAnimation.value!
                            .withOpacity(_opacityAnimation.value * 0.8),
                        _colorAnimation.value!
                            .withOpacity(_opacityAnimation.value * 0.4),
                        _colorAnimation.value!
                            .withOpacity(_opacityAnimation.value * 0.1),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _colorAnimation.value!
                            .withOpacity(_opacityAnimation.value * 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
              ),

              // Inner Circle
              Container(
                width: widget.size * 0.4,
                height: widget.size * 0.4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(_opacityAnimation.value),
                ),
              ),

              // Breathing Text
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: widget.size * 0.8),
                  Text(
                    _getBreathingText(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(_opacityAnimation.value),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getBreathingInstruction(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white
                          .withOpacity(_opacityAnimation.value * 0.7),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  String _getBreathingText() {
    if (widget.controller.status == AnimationStatus.forward) {
      return 'Breathe In';
    } else if (widget.controller.status == AnimationStatus.reverse) {
      return 'Breathe Out';
    } else {
      return 'Breathe';
    }
  }

  String _getBreathingInstruction() {
    if (widget.controller.status == AnimationStatus.forward) {
      return 'Inhale slowly and deeply';
    } else if (widget.controller.status == AnimationStatus.reverse) {
      return 'Exhale gently and completely';
    } else {
      return 'Follow the circle\'s rhythm';
    }
  }
}
