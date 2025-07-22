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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<MeditationProvider>(context, listen: false);
      provider.loadExternalMeditations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover More Content'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              final provider =
                  Provider.of<MeditationProvider>(context, listen: false);
              await provider.refreshExternalContent();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Content refreshed!')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => _showDebugInfo(),
          ),
        ],
      ),
      body: Consumer<MeditationProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Source Filter
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Content Sources',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SourceFilterChips(
                      sources: provider.availableSources,
                      selectedSource: provider.selectedSource,
                      onSourceSelected: provider.setSource,
                    ),
                  ],
                ),
              ),

              // Error Display
              if (provider.externalError != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
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

              // Content
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
    if (provider.isLoadingExternal) {
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
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadExternalMeditations(
        source: provider.selectedSource,
      ),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: provider.externalMeditations.length,
        itemBuilder: (context, index) {
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
      ),
    );
  }

  void _showDebugInfo() async {
    final provider = Provider.of<MeditationProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Info'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Selected Source: ${provider.selectedSource}'),
              Text(
                  'External Meditations: ${provider.externalMeditations.length}'),
              Text('Is Loading: ${provider.isLoadingExternal}'),
              Text('Error: ${provider.externalError ?? 'None'}'),
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
        ],
      ),
    );
  }
}
