import 'package:flutter/material.dart';
import '../models/meditation_models.dart';

class ExternalMeditationCard extends StatefulWidget {
  final Meditation meditation;
  final VoidCallback onTap;

  const ExternalMeditationCard({
    Key? key,
    required this.meditation,
    required this.onTap,
  }) : super(key: key);

  @override
  State<ExternalMeditationCard> createState() => _ExternalMeditationCardState();
}

class _ExternalMeditationCardState extends State<ExternalMeditationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
  }

  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTap: widget.onTap,
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            child: Container(
              key: ValueKey(
                  widget.meditation.id), // Important for efficient rendering
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(_isPressed ? 0.15 : 0.1),
                    blurRadius: _isPressed ? 15 : 10,
                    offset: Offset(0, _isPressed ? 8 : 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with source indicator
                  Expanded(
                    flex: 3,
                    child: Container(
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
                          if (widget.meditation.thumbnailUrl?.isNotEmpty ==
                              true)
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                                child: Image.network(
                                  widget.meditation.thumbnailUrl!,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return _buildSourceIcon();
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildSourceIcon();
                                  },
                                ),
                              ),
                            )
                          else
                            _buildSourceIcon(),

                          // Gradient overlay for better text readability
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.3),
                                  ],
                                ),
                              ),
                            ),
                          ),

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
                                '${widget.meditation.durationMinutes}min',
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
                                    _getSourceIconData(),
                                    size: 12,
                                    color: _getSourceColor(),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.meditation.displaySource,
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

                          // Play button overlay
                          Center(
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.play_arrow,
                                color: _getSourceColor(),
                                size: 28,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Content
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.meditation.name,
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
                            widget.meditation.type
                                .replaceAll('_', ' ')
                                .toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              color: _getSourceColor(),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (widget.meditation.channelName?.isNotEmpty ==
                                  true ||
                              widget.meditation.artistName?.isNotEmpty ==
                                  true) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.meditation.channelName ??
                                  widget.meditation.artistName ??
                                  '',
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
                              // Rating
                              Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.meditation.effectivenessScore
                                        .toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF666666),
                                    ),
                                  ),
                                ],
                              ),
                              // Media type indicators
                              Row(
                                children: [
                                  if (widget.meditation.videoUrl?.isNotEmpty ==
                                      true)
                                    const Icon(
                                      Icons.play_circle,
                                      color: Colors.red,
                                      size: 16,
                                    ),
                                  if (widget.meditation.audioUrl?.isNotEmpty ==
                                          true ||
                                      widget.meditation.spotifyUrl
                                              ?.isNotEmpty ==
                                          true) ...[
                                    if (widget
                                            .meditation.videoUrl?.isNotEmpty ==
                                        true)
                                      const SizedBox(width: 4),
                                    const Icon(
                                      Icons.headphones,
                                      color: Colors.green,
                                      size: 16,
                                    ),
                                  ],
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
          ),
        );
      },
    );
  }

  Widget _buildSourceIcon() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getSourceIconData(),
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
              widget.meditation.displaySource,
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
    switch (widget.meditation.source) {
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

  IconData _getSourceIconData() {
    switch (widget.meditation.source) {
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
