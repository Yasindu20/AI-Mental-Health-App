import 'package:flutter/material.dart';
import '../models/meditation_models.dart';
import '../widgets/benefits_list.dart';
import '../widgets/instructions_preview.dart';
import '../widgets/meditation_stats.dart';

class MeditationDetailScreen extends StatefulWidget {
  final Meditation meditation;

  const MeditationDetailScreen({
    super.key,
    required this.meditation,
  });

  @override
  State<MeditationDetailScreen> createState() => _MeditationDetailScreenState();
}

class _MeditationDetailScreenState extends State<MeditationDetailScreen> {
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF6B4EFF),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.meditation.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 2,
                      color: Colors.black26,
                    ),
                  ],
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF6B4EFF),
                      Color(0xFF8B6BFF),
                    ],
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background pattern
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.1,
                        child: Image.asset(
                          'assets/images/meditation_pattern.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // Meditation icon
                    const Center(
                      child: Icon(
                        Icons.spa,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _isFavorite = !_isFavorite;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _isFavorite
                            ? 'Added to favorites'
                            : 'Removed from favorites',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Info Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoChip(
                        Icons.access_time,
                        '${widget.meditation.durationMinutes} min',
                        Colors.blue,
                      ),
                      _buildInfoChip(
                        Icons.signal_cellular_alt,
                        widget.meditation.level,
                        Colors.green,
                      ),
                      _buildInfoChip(
                        Icons.category,
                        widget.meditation.type,
                        Colors.orange,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Meditation Stats
                  MeditationStats(meditation: widget.meditation),

                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'About This Meditation',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.meditation.description,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Color(0xFF666666),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Benefits
                  BenefitsList(benefits: widget.meditation.benefits),

                  const SizedBox(height: 24),

                  // Instructions Preview
                  InstructionsPreview(
                    instructions: widget.meditation.instructions,
                    onViewAll: () {
                      Navigator.pushNamed(
                        context,
                        '/meditation-guide',
                        arguments: {'meditation': widget.meditation},
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Target States
                  if (widget.meditation.targetStates.isNotEmpty) ...[
                    const Text(
                      'Helps With',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.meditation.targetStates.map((state) {
                        return Chip(
                          label: Text(
                            state.replaceAll('_', ' ').toUpperCase(),
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor:
                              const Color(0xFF6B4EFF).withOpacity(0.1),
                          labelStyle: const TextStyle(color: Color(0xFF6B4EFF)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Start Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/meditation-guide',
                          arguments: {'meditation': widget.meditation},
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B4EFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow, size: 28),
                          SizedBox(width: 12),
                          Text(
                            'Start Meditation',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
