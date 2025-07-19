import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/meditation_provider.dart';
import '../widgets/stats_card.dart';
import '../widgets/feature_card.dart';
import '../widgets/quick_action_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final meditationProvider =
        Provider.of<MeditationProvider>(context, listen: false);

    // Check if user is authenticated
    if (!authProvider.isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    // Load meditation stats
    await meditationProvider.loadStats();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, MeditationProvider>(
      builder: (context, authProvider, meditationProvider, child) {
        // Show loading if auth is still loading
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Redirect to login if not authenticated
        if (!authProvider.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/login');
          });
          return const Scaffold(body: SizedBox());
        }

        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                await meditationProvider.loadStats();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(authProvider),
                    const SizedBox(height: 32),

                    // Stats Card
                    if (meditationProvider.stats != null)
                      StatsCard(stats: meditationProvider.stats!)
                    else
                      _buildPlaceholderStats(),
                    const SizedBox(height: 24),

                    // Main Features
                    const Text(
                      'How can I help you today?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: FeatureCard(
                            icon: Icons.chat_bubble_outline,
                            title: 'Talk to AI',
                            subtitle: 'Share your thoughts',
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6B4EFF), Color(0xFF8B6BFF)],
                            ),
                            onTap: () {
                              Provider.of<ChatProvider>(context, listen: false)
                                  .clearConversation();
                              Navigator.pushNamed(context, '/chat');
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FeatureCard(
                            icon: Icons.spa,
                            title: 'Meditations',
                            subtitle: 'Find your peace',
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                            ),
                            onTap: () {
                              Navigator.pushNamed(
                                  context, '/meditation-library');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Quick Actions
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                    const SizedBox(height: 12),

                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        QuickActionCard(
                          icon: Icons.psychology,
                          title: 'Mood Check',
                          color: Colors.orange,
                          onTap: () {
                            _showMoodCheckDialog(context);
                          },
                        ),
                        QuickActionCard(
                          icon: Icons.history,
                          title: 'My Progress',
                          color: Colors.blue,
                          onTap: () {
                            Navigator.pushNamed(context, '/profile');
                          },
                        ),
                        QuickActionCard(
                          icon: Icons.favorite,
                          title: 'Favorites',
                          color: Colors.red,
                          onTap: () {
                            Navigator.pushNamed(context, '/meditation-library');
                          },
                        ),
                        QuickActionCard(
                          icon: Icons.settings,
                          title: 'Settings',
                          color: Colors.grey,
                          onTap: () {
                            Navigator.pushNamed(context, '/settings');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Logout
                    Center(
                      child: TextButton.icon(
                        onPressed: () async {
                          await authProvider.logout();
                          if (!context.mounted) return;
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        icon: const Icon(Icons.logout, color: Colors.grey),
                        label: const Text(
                          'Logout',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B4EFF), Color(0xFF8B6BFF)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B4EFF).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Column(
        children: [
          Text(
            'Welcome to Your Journey',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Start your first meditation to see your progress here!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AuthProvider authProvider) {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6B4EFF), Color(0xFF8B6BFF)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6B4EFF).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.spa,
            size: 30,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                authProvider.user?['username'] ?? 'Friend',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2D2D),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            Navigator.pushNamed(context, '/profile');
          },
          icon: const Icon(Icons.person_outline),
          iconSize: 28,
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _showMoodCheckDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How are you feeling?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select your current mood:'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildMoodChip('😊', 'Happy', Colors.green),
                _buildMoodChip('😰', 'Anxious', Colors.orange),
                _buildMoodChip('😢', 'Sad', Colors.blue),
                _buildMoodChip('😴', 'Tired', Colors.purple),
                _buildMoodChip('😠', 'Angry', Colors.red),
                _buildMoodChip('😌', 'Calm', Colors.teal),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodChip(String emoji, String mood, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('You\'re feeling $mood. Here are some suggestions...'),
            backgroundColor: color,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(mood,
                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
