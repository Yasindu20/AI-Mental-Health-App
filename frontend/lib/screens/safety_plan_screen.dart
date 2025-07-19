import 'package:flutter/material.dart';
import '../models/crisis_models.dart';
import '../services/crisis_service.dart';

class SafetyPlanScreen extends StatefulWidget {
  const SafetyPlanScreen({super.key});

  @override
  State<SafetyPlanScreen> createState() => _SafetyPlanScreenState();
}

class _SafetyPlanScreenState extends State<SafetyPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form controllers
  final List<TextEditingController> _warningSignsControllers = [
    TextEditingController()
  ];
  final List<TextEditingController> _copingStrategiesControllers = [
    TextEditingController()
  ];
  final List<Map<String, TextEditingController>> _supportContactsControllers = [
    {
      'name': TextEditingController(),
      'phone': TextEditingController(),
      'relationship': TextEditingController(),
    }
  ];
  final List<Map<String, TextEditingController>>
      _professionalContactsControllers = [
    {
      'name': TextEditingController(),
      'phone': TextEditingController(),
      'role': TextEditingController(),
    }
  ];
  final List<TextEditingController> _safeEnvironmentControllers = [
    TextEditingController()
  ];
  final List<TextEditingController> _reasonsForLivingControllers = [
    TextEditingController()
  ];

  @override
  void dispose() {
    // Dispose all controllers
    for (var controller in _warningSignsControllers) {
      controller.dispose();
    }
    for (var controller in _copingStrategiesControllers) {
      controller.dispose();
    }
    for (var contact in _supportContactsControllers) {
      for (var c in contact.values) {
        c.dispose();
      }
    }
    for (var contact in _professionalContactsControllers) {
      for (var c in contact.values) {
        c.dispose();
      }
    }
    for (var controller in _safeEnvironmentControllers) {
      controller.dispose();
    }
    for (var controller in _reasonsForLivingControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveSafetyPlan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final safetyPlan = SafetyPlan(
        warningSigns: _warningSignsControllers
            .map((c) => c.text.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        copingStrategies: _copingStrategiesControllers
            .map((c) => c.text.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        supportContacts: _supportContactsControllers
            .where((c) => c['name']!.text.isNotEmpty)
            .map((c) => {
                  'name': c['name']!.text,
                  'phone': c['phone']!.text,
                  'relationship': c['relationship']!.text,
                })
            .toList(),
        professionalContacts: _professionalContactsControllers
            .where((c) => c['name']!.text.isNotEmpty)
            .map((c) => {
                  'name': c['name']!.text,
                  'phone': c['phone']!.text,
                  'role': c['role']!.text,
                })
            .toList(),
        safeEnvironment: _safeEnvironmentControllers
            .map((c) => c.text.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        reasonsForLiving: _reasonsForLivingControllers
            .map((c) => c.text.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
      );

      await CrisisService.createSafetyPlan(safetyPlan);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Safety plan saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save safety plan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required List<TextEditingController> controllers,
    required String hint,
    required Function() onAdd,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        ...controllers.asMap().entries.map((entry) {
          final index = entry.key;
          final controller = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: hint,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                if (controllers.length > 1)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () {
                      setState(() {
                        controllers[index].dispose();
                        controllers.removeAt(index);
                      });
                    },
                    color: Colors.red,
                  ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: Text('Add ${title.split(' ').first}'),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Safety Plan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('About Safety Plans'),
                  content: const Text(
                    'A safety plan is a personalized, practical plan that includes ways to remain safe while experiencing suicidal thoughts. It helps you identify warning signs, coping strategies, and support systems.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Introduction
              Card(
                color:
                    Colors.blue.withAlpha(26), // Fixed: 0.1 opacity = 26 alpha
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.security,
                        size: 48,
                        color: Colors.blue,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your safety plan is private and confidential',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'This information will help you stay safe during difficult times',
                        style: TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Warning Signs
              _buildSection(
                title: 'Warning Signs',
                subtitle:
                    'Thoughts, moods, or behaviors that signal a crisis may be developing',
                controllers: _warningSignsControllers,
                hint: 'e.g., Feeling hopeless, isolating myself',
                onAdd: () {
                  setState(() {
                    _warningSignsControllers.add(TextEditingController());
                  });
                },
              ),

              // Coping Strategies
              _buildSection(
                title: 'Coping Strategies',
                subtitle: 'Things I can do on my own to feel better',
                controllers: _copingStrategiesControllers,
                hint: 'e.g., Take a walk, listen to music',
                onAdd: () {
                  setState(() {
                    _copingStrategiesControllers.add(TextEditingController());
                  });
                },
              ),

              // Support Contacts
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Support Contacts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'People I can reach out to for support',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._supportContactsControllers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final controllers = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: controllers['name'],
                              decoration: const InputDecoration(
                                labelText: 'Name',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: controllers['phone'],
                                    decoration: const InputDecoration(
                                      labelText: 'Phone',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.phone,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: controllers['relationship'],
                                    decoration: const InputDecoration(
                                      labelText: 'Relationship',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_supportContactsControllers.length > 1)
                              Align(
                                alignment: Alignment.centerRight,
                                child: IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () {
                                    setState(() {
                                      // Fixed: replaced forEach with for loop
                                      for (var c in controllers.values) {
                                        c.dispose();
                                      }
                                      _supportContactsControllers
                                          .removeAt(index);
                                    });
                                  },
                                  color: Colors.red,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _supportContactsControllers.add({
                          'name': TextEditingController(),
                          'phone': TextEditingController(),
                          'relationship': TextEditingController(),
                        });
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Contact'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Making Environment Safe
              _buildSection(
                title: 'Making My Environment Safe',
                subtitle: 'Ways to make my surroundings safer',
                controllers: _safeEnvironmentControllers,
                hint: 'e.g., Remove harmful objects, stay with someone',
                onAdd: () {
                  setState(() {
                    _safeEnvironmentControllers.add(TextEditingController());
                  });
                },
              ),

              // Reasons for Living
              _buildSection(
                title: 'Reasons for Living',
                subtitle:
                    'Things that are important to me and worth living for',
                controllers: _reasonsForLivingControllers,
                hint: 'e.g., My family, my goals, my pet',
                onAdd: () {
                  setState(() {
                    _reasonsForLivingControllers.add(TextEditingController());
                  });
                },
              ),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveSafetyPlan,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save Safety Plan',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
