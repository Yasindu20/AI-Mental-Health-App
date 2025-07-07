import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mental Health Companion'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, ${authProvider.user?['username'] ?? 'Friend'}!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'How are you feeling today?',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Quick actions
            const Text(
              'What would you like to do?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Action cards
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildActionCard(
                  context,
                  icon: Icons.chat,
                  title: 'Free Chat',
                  subtitle: 'Talk about anything',
                  color: Colors.blue,
                  onTap: () {
                    Provider.of<ChatProvider>(context, listen: false)
                        .setMode('unstructured');
                    Navigator.pushNamed(context, '/chat');
                  },
                ),
                _buildActionCard(
                  context,
                  icon: Icons.mood,
                  title: 'Mood Check-in',
                  subtitle: 'Track your mood',
                  color: Colors.orange,
                  onTap: () {
                    Provider.of<ChatProvider>(context, listen: false)
                        .setMode('mood_check');
                    Navigator.pushNamed(context, '/chat');
                  },
                ),
                _buildActionCard(
                  context,
                  icon: Icons.psychology,
                  title: 'CBT Exercise',
                  subtitle: 'Challenge thoughts',
                  color: Colors.purple,
                  onTap: () {
                    Provider.of<ChatProvider>(context, listen: false)
                        .setMode('cbt_exercise');
                    Navigator.pushNamed(context, '/chat');
                  },
                ),
                _buildActionCard(
                  context,
                  icon: Icons.self_improvement,
                  title: 'Mindfulness',
                  subtitle: 'Relaxation exercises',
                  color: Colors.green,
                  onTap: () {
                    Provider.of<ChatProvider>(context, listen: false)
                        .setMode('mindfulness');
                    Navigator.pushNamed(context, '/chat');
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Recent conversations
            const Text(
              'Continue Conversation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Placeholder for recent conversations
            Card(
              child: ListTile(
                leading: const Icon(Icons.history),
                title: const Text('View conversation history'),
                subtitle: const Text('Continue where you left off'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Navigate to history screen once implemented
                  // Navigator.pushNamed(context, '/history');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: color.withAlpha((0.1 * 255).round()),
                radius: 30,
                child: Icon(
                  icon,
                  color: color,
                  size: 30,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
