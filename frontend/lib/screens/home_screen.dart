import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic> _stats = {
    'total_sessions': 0,
    'total_minutes': 0,
    'current_streak': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    // TODO: Load actual stats from API
    // For now, using placeholder values
    setState(() {
      _stats = {
        'total_sessions': 12,
        'total_minutes': 156,
        'current_streak': 5,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6B4EFF), Color(0xFF8B6BFF)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6B4EFF).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.spa,
                    size: 60,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 32),

                // Welcome text
                Text(
                  'Welcome back, ${authProvider.user?['username'] ?? 'Friend'}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2D2D),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Your meditation companion is here',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),

                const SizedBox(height: 48),

                // Start Chat Button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6B4EFF), Color(0xFF8B6BFF)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6B4EFF).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      // Clear any previous conversation
                      Provider.of<ChatProvider>(context, listen: false)
                          .clearConversation();
                      Navigator.pushNamed(context, '/chat');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Start Conversation',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Quick Stats Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            icon: Icons.self_improvement,
                            label: 'Sessions',
                            value: _stats['total_sessions'].toString(),
                            color: const Color(0xFF6B4EFF),
                          ),
                          _buildStatItem(
                            icon: Icons.timer,
                            label: 'Minutes',
                            value: _stats['total_minutes'].toString(),
                            color: const Color(0xFF4CAF50),
                          ),
                          _buildStatItem(
                            icon: Icons.calendar_today,
                            label: 'Streak',
                            value: _stats['current_streak'].toString(),
                            color: const Color(0xFFFF9800),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Quick Actions
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickAction(
                        icon: Icons.history,
                        label: 'History',
                        onTap: () {
                          // TODO: Navigate to history
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('History coming soon!'),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickAction(
                        icon: Icons.settings,
                        label: 'Settings',
                        onTap: () {
                          // TODO: Navigate to settings
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Settings coming soon!'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Logout button
                TextButton.icon(
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
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

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: const Color(0xFF6B4EFF),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
