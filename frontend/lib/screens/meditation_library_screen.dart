import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/meditation_card.dart';
import 'meditation_detail_screen.dart';

class MeditationLibraryScreen extends StatefulWidget {
  const MeditationLibraryScreen({Key? key}) : super(key: key);

  @override
  State<MeditationLibraryScreen> createState() =>
      _MeditationLibraryScreenState();
}

class _MeditationLibraryScreenState extends State<MeditationLibraryScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  String _searchQuery = '';
  bool _isLoading = false;

  // Sample meditation data
  final List<Map<String, dynamic>> _allMeditations = [
    {
      'id': '1',
      'title': 'Morning Mindfulness',
      'category': 'Mindfulness',
      'duration': '10 min',
      'difficulty': 'Beginner',
      'description':
          'Start your day with intention and awareness through this gentle morning meditation.',
      'audioUrl': 'https://example.com/morning_mindfulness.mp3',
      'imageUrl':
          'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=500',
      'rating': 4.8,
      'isFavorite': false,
    },
    {
      'id': '2',
      'title': 'Deep Sleep Meditation',
      'category': 'Sleep',
      'duration': '20 min',
      'difficulty': 'Intermediate',
      'description':
          'Drift into peaceful sleep with this calming bedtime meditation.',
      'audioUrl': 'https://example.com/deep_sleep.mp3',
      'imageUrl':
          'https://images.unsplash.com/photo-1445116572660-236099ec97a0?w=500',
      'rating': 4.9,
      'isFavorite': true,
    },
    {
      'id': '3',
      'title': 'Anxiety Relief',
      'category': 'Stress Relief',
      'duration': '15 min',
      'difficulty': 'Beginner',
      'description':
          'Find calm and peace with this anxiety-reducing meditation practice.',
      'audioUrl': 'https://example.com/anxiety_relief.mp3',
      'imageUrl':
          'https://images.unsplash.com/photo-1499209974431-9dddcece7f88?w=500',
      'rating': 4.7,
      'isFavorite': false,
    },
  ];

  List<Map<String, dynamic>> _filteredMeditations = [];
  List<String> _categories = [
    'All',
    'Mindfulness',
    'Sleep',
    'Stress Relief',
    'Focus'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _filteredMeditations = _allMeditations;
    _loadMeditations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMeditations() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _filteredMeditations = _allMeditations;
    });
  }

  void _filterMeditations() {
    setState(() {
      String selectedCategory = _categories[_tabController.index];

      _filteredMeditations = _allMeditations.where((meditation) {
        bool matchesSearch = meditation['title']
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            meditation['description']
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());

        bool matchesCategory = selectedCategory == 'All' ||
            meditation['category'] == selectedCategory;

        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _navigateToMeditationDetail(Map<String, dynamic> meditation) {
    HapticFeedback.lightImpact();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MeditationDetailScreen(
          title: meditation['title'],
          description: meditation['description'],
          duration: meditation['duration'],
          audioUrl: meditation['audioUrl'],
          imageUrl: meditation['imageUrl'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Meditation Library',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () {
              _showFilterBottomSheet();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search meditations...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _searchQuery = '';
                          _filterMeditations();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _filterMeditations();
              },
            ),
          ),

          // Category Tabs
          TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: Colors.blue,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
            onTap: (index) {
              _filterMeditations();
            },
            tabs: _categories.map((category) => Tab(text: category)).toList(),
          ),

          const SizedBox(height: 16),

          // Meditation Grid
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  )
                : _filteredMeditations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No meditations found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your search or filters',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _filteredMeditations.length,
                          itemBuilder: (context, index) {
                            final meditation = _filteredMeditations[index];
                            return MeditationCard(
                              meditation: meditation,
                              onTap: () =>
                                  _navigateToMeditationDetail(meditation),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2D2D44),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Meditations',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              // Add filter options here
              const Text(
                'Coming soon: Duration, Difficulty, and Rating filters',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
