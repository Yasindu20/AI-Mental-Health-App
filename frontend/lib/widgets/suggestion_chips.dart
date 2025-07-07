import 'package:flutter/material.dart';

class SuggestionChips extends StatelessWidget {
  final List<String> suggestions;
  final Function(String) onSelected;

  const SuggestionChips({
    Key? key,
    required this.suggestions,
    required this.onSelected,
  }) : super(key: key);

  String _getSuggestionText(String suggestion) {
    final suggestionTexts = {
      'gentle_walk': 'Take a gentle walk',
      'call_friend': 'Call a friend',
      'gratitude_journal': 'Write in gratitude journal',
      'favorite_music': 'Listen to favorite music',
      'breathing_exercise': 'Try breathing exercise',
      'progressive_relaxation': 'Progressive muscle relaxation',
      'worry_time': 'Schedule worry time',
      'grounding': 'Grounding exercise',
      'physical_exercise': 'Physical exercise',
      'journal_feelings': 'Journal your feelings',
      'count_to_ten': 'Count to ten slowly',
      'take_break': 'Take a break',
      'share_joy': 'Share your joy',
      'gratitude_practice': 'Practice gratitude',
      'plan_activity': 'Plan a fun activity',
      'help_others': 'Help someone else',
      'mood_check': 'Check your mood',
      'mindfulness': 'Mindfulness exercise',
      'daily_planning': 'Plan your day',
      'self_care': 'Self-care activity',
    };

    return suggestionTexts[suggestion] ?? suggestion;
  }

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox();

    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(_getSuggestionText(suggestion)),
              onPressed: () => onSelected(suggestion),
              backgroundColor: Colors.blue[50],
              labelStyle: TextStyle(color: Colors.blue[700]),
            ),
          );
        },
      ),
    );
  }
}
