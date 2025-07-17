import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/screens/meditation_detail_screen.dart';
import '../models/meditation_models.dart';

class MeditationRecommendationCard extends StatelessWidget {
  final Map<String, dynamic> meditation;
  final VoidCallback? onFavoriteToggle;

  const MeditationRecommendationCard({
    Key? key,
    required this.meditation,
    this.onFavoriteToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      width: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withValues(alpha: 0.1),
            Colors.purple.withValues(alpha: 0.1),
            Colors.indigo.withValues(alpha: 0.1),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToDetail(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with favorite button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        meditation['category'] ?? 'Meditation',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        onFavoriteToggle?.call();
                      },
                      icon: Icon(
                        meditation['isFavorite'] == true
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: meditation['isFavorite'] == true
                            ? Colors.red
                            : Colors.white.withValues(alpha: 0.6),
                        size: 24,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Meditation Image
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(
                        meditation['imageUrl'] ??
                            'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=500',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Play button overlay
                        Center(
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.black87,
                              size: 28,
                            ),
                          ),
                        ),
                        // Duration badge
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              meditation['duration'] ?? '10 min',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Title
                Text(
                  meditation['title'] ?? 'Untitled Meditation',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 6),

                // Description
                Text(
                  meditation['description'] ?? 'A peaceful meditation session.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // Rating and difficulty
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${meditation['rating'] ?? 4.5}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(meditation['difficulty']),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        meditation['difficulty'] ?? 'Beginner',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(String? difficulty) {
    switch (difficulty?.toLowerCase()) {
      case 'beginner':
        return Colors.green.withValues(alpha: 0.7);
      case 'intermediate':
        return Colors.orange.withValues(alpha: 0.7);
      case 'advanced':
        return Colors.red.withValues(alpha: 0.7);
      default:
        return Colors.blue.withValues(alpha: 0.7);
    }
  }

  void _navigateToDetail(BuildContext context) {
    HapticFeedback.lightImpact();

    // Create a Meditation object from the map data
    final meditationObj = Meditation(
      id: int.tryParse(meditation['id']?.toString() ?? '0') ?? 0,
      name: meditation['title'] ?? 'Untitled Meditation',
      type: meditation['category'] ?? 'mindfulness',
      level: meditation['difficulty'] ?? 'Beginner',
      durationMinutes: _parseDuration(meditation['duration']),
      description:
          meditation['description'] ?? 'A peaceful meditation session.',
      instructions: meditation['instructions'] != null
          ? List<String>.from(meditation['instructions'])
          : [
              'Begin by finding a comfortable position',
              'Close your eyes and breathe naturally'
            ],
      benefits: meditation['benefits'] != null
          ? List<String>.from(meditation['benefits'])
          : ['Reduces stress', 'Improves focus'],
      targetStates: meditation['targetStates'] != null
          ? List<String>.from(meditation['targetStates'])
          : ['relaxation'],
      audioUrl: meditation['audioUrl'],
      videoUrl: meditation['videoUrl'],
      tags: meditation['tags'] != null
          ? List<String>.from(meditation['tags'])
          : [],
      effectivenessScore: meditation['rating']?.toDouble() ?? 4.5,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MeditationDetailScreen(
          meditation: meditationObj,
        ),
      ),
    );
  }

  int _parseDuration(String? duration) {
    if (duration == null) return 10;

    // Extract number from strings like "10 min", "15 minutes", etc.
    final regex = RegExp(r'(\d+)');
    final match = regex.firstMatch(duration);
    return int.tryParse(match?.group(1) ?? '10') ?? 10;
  }
}
