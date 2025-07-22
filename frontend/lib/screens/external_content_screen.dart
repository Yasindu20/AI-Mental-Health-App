import 'package:flutter/material.dart';
import 'package:frontend/widgets/external_meditation_card.dart';
import 'package:provider/provider.dart';
import '../providers/meditation_provider.dart';
import '../widgets/source_filter_chips.dart';

class ExternalContentScreen extends StatefulWidget {
  const ExternalContentScreen({Key? key}) : super(key: key);

  @override
  State<ExternalContentScreen> createState() => _ExternalContentScreenState();
}

class _ExternalContentScreenState extends State<ExternalContentScreen> {
  late ScrollController _scrollController;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<MeditationProvider>(context, listen: false);
      provider.loadExternalMeditations();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreContent();
    }
  }

  Future<void> _loadMoreContent() async {
    if (_isLoadingMore) return;

    final provider = Provider.of<MeditationProvider>(context, listen: false);

    if (!provider.hasMoreExternalContent || provider.isLoadingMoreExternal) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    await provider.loadMoreExternalMeditations();

    if (mounted) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _refreshContent() async {
    final provider = Provider.of<MeditationProvider>(context, listen: false);
    await provider.refreshExternalContent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover More Content'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshContent,
            tooltip: 'Refresh Content',
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => _showDebugInfo(),
            tooltip: 'Debug Info',
          ),
        ],
      ),
      body: Consumer<MeditationProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Source Filter Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Content Sources',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${provider.externalMeditations.length} items',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SourceFilterChips(
                      sources: provider.availableSources,
                      selectedSource: provider.selectedSource,
                      onSourceSelected: (source) {
                        provider.setSource(source);
                        _scrollController.animateTo(
                          0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Error Display
              if (provider.externalError != null)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.externalError!,
                          style: const TextStyle(color: Colors.orange),
                        ),
                      ),
                      TextButton(
                        onPressed: provider.clearExternalError,
                        child: const Text('Dismiss'),
                      ),
                    ],
                  ),
                ),

              // Content Area
              Expanded(
                child: _buildContent(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(MeditationProvider provider) {
    // Initial loading state
    if (provider.isLoadingExternal && provider.externalMeditations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading external content...'),
            SizedBox(height: 8),
            Text(
              'This may take a moment',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (provider.externalMeditations.isEmpty &&
        provider.externalError == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No external content found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different source or check your connection',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.loadExternalMeditations(
                source: provider.selectedSource,
                refresh: true,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Content grid with infinite scroll
    return RefreshIndicator(
      onRefresh: _refreshContent,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final meditation = provider.externalMeditations[index];
                  return ExternalMeditationCard(
                    meditation: meditation,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/meditation-detail',
                        arguments: {'meditation': meditation},
                      );
                    },
                  );
                },
                childCount: provider.externalMeditations.length,
              ),
            ),
          ),

          // Loading more indicator
          if (provider.isLoadingMoreExternal)
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text(
                        'Loading more content...',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // End of content indicator
          if (!provider.hasMoreExternalContent &&
              provider.externalMeditations.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.done_all,
                        color: Colors.grey[400],
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You\'ve reached the end!',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Total: ${provider.externalMeditations.length} meditations',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () {
                          _scrollController.animateTo(
                            0,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: const Text('Back to Top'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 16),
          ),
        ],
      ),
    );
  }

  void _showDebugInfo() async {
    final provider = Provider.of<MeditationProvider>(context, listen: false);
    final debugInfo = provider.getDebugInfo(); // FIXED: Using public method

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Info'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Selected Source: ${debugInfo['selectedSource']}'),
              Text(
                  'External Meditations: ${provider.externalMeditations.length}'),
              Text('Current Page: ${provider.currentExternalPage}'),
              Text('Has More Content: ${provider.hasMoreExternalContent}'),
              Text('Is Loading: ${provider.isLoadingExternal}'),
              Text('Is Loading More: ${provider.isLoadingMoreExternal}'),
              Text('Error: ${debugInfo['externalError'] ?? 'None'}'),
              const SizedBox(height: 16),
              const Text('Pagination Status:'),
              ...provider.availableSources.map((source) {
                final meditations =
                    debugInfo['externalMeditations'][source] ?? 0;
                final page = debugInfo['currentPages'][source] ?? 1;
                final hasMore = debugInfo['hasMoreContent'][source] ?? false;
                return Text(
                    '$source: $meditations items, page $page, hasMore: $hasMore');
              }),
              const SizedBox(height: 16),
              const Text('Sample meditation:'),
              if (provider.externalMeditations.isNotEmpty)
                Text(
                  'ID: ${provider.externalMeditations.first.id}\n'
                  'Name: ${provider.externalMeditations.first.name}\n'
                  'Source: ${provider.externalMeditations.first.source}\n'
                  'Type: ${provider.externalMeditations.first.type}',
                  style: const TextStyle(fontSize: 12),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              provider.resetExternalContent();
              provider.loadExternalMeditations(source: provider.selectedSource);
              Navigator.pop(context);
            },
            child: const Text('Reset & Reload'),
          ),
        ],
      ),
    );
  }
}
