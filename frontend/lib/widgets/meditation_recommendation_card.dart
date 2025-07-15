// frontend/lib/widgets/meditation_recommendation_card.dart
import 'package:flutter/material.dart';
import '../models/meditation_models.dart';
import '../screens/meditation_detail_screen.dart';

class MeditationRecommendationCard extends StatelessWidget {
  final List<MeditationRecommendation> recommendations;
  final MentalStateAnalysis? analysis;
  final VoidCallback onDismiss;

  const MeditationRecommendationCard({
    Key? key,
    required this.recommendations,
    this.analysis,
    required this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6B4EFF).withOpacity(0.05),
            const Color(0xFF8B6BFF).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF6B4EFF).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B4EFF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Color(0xFF6B4EFF),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Personalized Recommendations',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (analysis != null)
                        Text(
                          'Based on ${_formatConcern(analysis!.primaryConcern)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onDismiss,
                  color: Colors.grey,
                ),
              ],
            ),
          ),

          // Mental state summary
          if (analysis != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Stress',
                    analysis!.stressLevel,
                    Colors.orange,
                  ),
                  _buildStatItem(
                    'Anxiety',
                    analysis!.anxietyLevel,
                    Colors.purple,
                  ),
                  _buildStatItem(
                    'Mood',
                    10 - analysis!.depressionLevel,
                    Colors.blue,
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Recommendations list
          ...recommendations.take(3).map((rec) => _buildRecommendationItem(
                context,
                rec,
              )),

          // View all button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  // Navigate to full recommendations
                  Navigator.pushNamed(context, '/recommendations');
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF6B4EFF)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('View All Recommendations'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, double value, Color color) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                value: value / 10,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeWidth: 6,
              ),
            ),
            Text(
              value.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationItem(
    BuildContext context,
    MeditationRecommendation rec,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MeditationDetailScreen(
                meditation: rec.meditation,
                recommendation: rec,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            children: [
              // Type icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getTypeColor(rec.meditation.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getTypeIcon(rec.meditation.type),
                  color: _getTypeColor(rec.meditation.type),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rec.meditation.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rec.reason,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.timer,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${rec.meditation.durationMinutes} min',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.signal_cellular_4_bar,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatLevel(rec.meditation.level),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Match score
              Column(
                children: [
                  Text(
                    '${(rec.relevanceScore * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(rec.relevanceScore),
                    ),
                  ),
                  Text(
                    'Match',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatConcern(String concern) {
    return concern.replaceAll('_', ' ');
  }

  String _formatLevel(String level) {
    return level[0].toUpperCase() + level.substring(1);
  }

  Color _getTypeColor(String type) {
    final colors = {
      'breathing': Colors.blue,
      'mindfulness': Colors.purple,
      'body_scan': Colors.orange,
      'loving_kindness': Colors.pink,
      'visualization': Colors.teal,
      'movement': Colors.green,
    };
    return colors[type] ?? Colors.grey;
  }

  IconData _getTypeIcon(String type) {
    final icons = {
      'breathing': Icons.air,
      'mindfulness': Icons.psychology,
      'body_scan': Icons.accessibility_new,
      'loving_kindness': Icons.favorite,
      'visualization': Icons.landscape,
      'movement': Icons.directions_walk,
    };
    return icons[type] ?? Icons.self_improvement;
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }
}
