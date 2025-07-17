import 'package:flutter/material.dart';
import '../models/meditation_models.dart';

class MeditationStats extends StatelessWidget {
  final Meditation meditation;

  const MeditationStats({
    Key? key,
    required this.meditation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF6B4EFF).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6B4EFF).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Meditation Statistics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.star,
                  label: 'Effectiveness',
                  value:
                      '${(meditation.effectivenessScore * 5).toStringAsFixed(1)}/5.0',
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.people,
                  label: 'Popularity',
                  value: _getPopularityText(),
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.category,
                  label: 'Type',
                  value: meditation.type.replaceAll('_', ' ').toUpperCase(),
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.local_offer,
                  label: 'Tags',
                  value: '${meditation.tags.length} tags',
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF666666),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getPopularityText() {
    if (meditation.effectivenessScore >= 0.9) {
      return 'Very High';
    } else if (meditation.effectivenessScore >= 0.8) {
      return 'High';
    } else if (meditation.effectivenessScore >= 0.7) {
      return 'Good';
    } else if (meditation.effectivenessScore >= 0.6) {
      return 'Average';
    } else {
      return 'Low';
    }
  }
}
