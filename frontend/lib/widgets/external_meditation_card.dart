import 'package:flutter/material.dart';
import '../models/meditation_models.dart';

class ExternalMeditationCard extends StatelessWidget {
  final Meditation meditation;
  final VoidCallback onTap;

  const ExternalMeditationCard({
    Key? key,
    required this.meditation,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with source indicator
            Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getSourceColor(),
                    _getSourceColor().withOpacity(0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Stack(
                children: [
                  // Thumbnail or source icon
                  if (meditation.thumbnailUrl?.isNotEmpty == true)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: Image.network(
                          meditation.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildSourceIcon();
                          },
                        ),
                      ),
                    )
                  else
                    _buildSourceIcon(),

                  // Duration badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${meditation.durationMinutes}min',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Source badge
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getSourceIcon(),
                            size: 12,
                            color: _getSourceColor(),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            meditation.displaySource,
                            style: TextStyle(
                              color: _getSourceColor(),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meditation.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2D2D),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meditation.type.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getSourceColor(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (meditation.channelName?.isNotEmpty == true ||
                        meditation.artistName?.isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Text(
                        meditation.channelName ?? meditation.artistName ?? '',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF999999),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              meditation.effectivenessScore.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            if (meditation.videoUrl?.isNotEmpty == true)
                              const Icon(
                                Icons.play_circle,
                                color: Colors.red,
                                size: 16,
                              ),
                            if (meditation.audioUrl?.isNotEmpty == true ||
                                meditation.spotifyUrl?.isNotEmpty == true)
                              const Icon(
                                Icons.headphones,
                                color: Colors.green,
                                size: 16,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceIcon() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getSourceIcon(),
            size: 40,
            color: Colors.white,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              meditation.displaySource,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSourceColor() {
    switch (meditation.source) {
      case 'youtube':
        return Colors.red;
      case 'spotify':
        return Colors.green;
      case 'huggingface':
      case 'huggingface_ai':
        return Colors.orange;
      default:
        return const Color(0xFF6B4EFF);
    }
  }

  IconData _getSourceIcon() {
    switch (meditation.source) {
      case 'youtube':
        return Icons.play_circle;
      case 'spotify':
        return Icons.library_music;
      case 'huggingface':
      case 'huggingface_ai':
        return Icons.smart_toy;
      default:
        return Icons.spa;
    }
  }
}
