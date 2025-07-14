import 'package:flutter/material.dart';

class MeditationSuggestionCard extends StatelessWidget {
  final List<String> techniques;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;

  const MeditationSuggestionCard({
    Key? key,
    required this.techniques,
    required this.onAccept,
    required this.onDismiss,
  }) : super(key: key);

  String _getTechniqueName(String technique) {
    final names = {
      'breathing': 'Breathing Exercise',
      'body_scan': 'Body Scan',
      'mindfulness': 'Mindfulness Practice',
      'visualization': 'Visualization',
      'loving_kindness': 'Loving-Kindness Meditation',
      'grounding': '5-4-3-2-1 Grounding',
      'progressive_relaxation': 'Progressive Muscle Relaxation',
    };
    return names[technique] ?? technique;
  }

  IconData _getTechniqueIcon(String technique) {
    final icons = {
      'breathing': Icons.air,
      'body_scan': Icons.accessibility_new,
      'mindfulness': Icons.psychology,
      'visualization': Icons.landscape,
      'loving_kindness': Icons.favorite,
      'grounding': Icons.foundation,
      'progressive_relaxation': Icons.self_improvement,
    };
    return icons[technique] ?? Icons.spa;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6B4EFF).withOpacity(0.1),
            const Color(0xFF8B6BFF).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6B4EFF).withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.spa,
                  color: const Color(0xFF6B4EFF),
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Meditation Suggestion',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B4EFF),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onDismiss,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: techniques.map((technique) {
                return Chip(
                  avatar: Icon(
                    _getTechniqueIcon(technique),
                    size: 18,
                    color: const Color(0xFF6B4EFF),
                  ),
                  label: Text(_getTechniqueName(technique)),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: const Color(0xFF6B4EFF).withOpacity(0.3),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAccept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B4EFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Start Meditation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
