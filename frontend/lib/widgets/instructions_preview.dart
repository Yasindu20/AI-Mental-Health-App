import 'package:flutter/material.dart';

class InstructionsPreview extends StatelessWidget {
  final List<String> instructions;
  final VoidCallback onViewAll;

  const InstructionsPreview({
    Key? key,
    required this.instructions,
    required this.onViewAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (instructions.isEmpty) return const SizedBox.shrink();

    final previewInstructions = instructions.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Instructions Preview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2D2D),
              ),
            ),
            TextButton(
              onPressed: onViewAll,
              child: const Text(
                'View All',
                style: TextStyle(
                  color: Color(0xFF6B4EFF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF6B4EFF).withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF6B4EFF).withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              ...previewInstructions.asMap().entries.map((entry) {
                final index = entry.key;
                final instruction = entry.value;
                return _buildInstructionStep(index + 1, instruction);
              }).toList(),
              if (instructions.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B4EFF).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.more_horiz,
                          size: 16,
                          color: Color(0xFF6B4EFF),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${instructions.length - 3} more steps...',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B4EFF),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionStep(int stepNumber, String instruction) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF6B4EFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                stepNumber.toString(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              instruction,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Color(0xFF666666),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
