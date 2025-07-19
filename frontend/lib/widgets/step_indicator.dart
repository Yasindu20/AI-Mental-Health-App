import 'package:flutter/material.dart';

class StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final Color activeColor;
  final Color inactiveColor;
  final double dotSize;
  final double spacing;

  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.activeColor = const Color(0xFF6B4EFF),
    this.inactiveColor = Colors.grey,
    this.dotSize = 12,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Progress Text
        Text(
          'Step ${currentStep + 1} of $totalSteps',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(width: 16),

        // Progress Dots
        Row(
          children: List.generate(totalSteps, (index) {
            return Container(
              margin:
                  EdgeInsets.only(right: index < totalSteps - 1 ? spacing : 0),
              child: _buildDot(index),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDot(int index) {
    final isActive = index <= currentStep;
    final isCurrent = index == currentStep;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isCurrent ? dotSize * 2 : dotSize,
      height: dotSize,
      decoration: BoxDecoration(
        color: isActive ? activeColor : inactiveColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(dotSize / 2),
        border: isCurrent
            ? Border.all(
                color: Colors.white,
                width: 2,
              )
            : null,
      ),
    );
  }
}

// Alternative Linear Progress Version
class LinearStepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final Color activeColor;
  final Color inactiveColor;
  final double height;

  const LinearStepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.activeColor = const Color(0xFF6B4EFF),
    this.inactiveColor = Colors.grey,
    this.height = 4,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (currentStep + 1) / totalSteps;

    return Column(
      children: [
        // Progress Text
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Step ${currentStep + 1}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            Text(
              '$totalSteps Steps Total',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Progress Bar
        Container(
          height: height,
          decoration: BoxDecoration(
            color: inactiveColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),

        // Percentage
        Text(
          '${(progress * 100).round()}% Complete',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
