import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/crisis_models.dart';

class CrisisAlertDialog extends StatelessWidget {
  final String crisisLevel;
  final List<CrisisResource> resources;
  final EmergencyContact? emergencyContact;
  final bool immediateRisk;

  const CrisisAlertDialog({
    Key? key,
    required this.crisisLevel,
    required this.resources,
    this.emergencyContact,
    this.immediateRisk = false,
  }) : super(key: key);

  Color _getLevelColor() {
    switch (crisisLevel) {
      case CrisisLevel.emergency:
        return Colors.red;
      case CrisisLevel.critical:
        return Colors.orange;
      case CrisisLevel.warning:
        return Colors.amber;
      default:
        return Colors.blue;
    }
  }

  IconData _getLevelIcon() {
    switch (crisisLevel) {
      case CrisisLevel.emergency:
        return Icons.emergency;
      case CrisisLevel.critical:
        return Icons.warning;
      case CrisisLevel.warning:
        return Icons.info;
      default:
        return Icons.support_agent;
    }
  }

  String _getLevelTitle() {
    switch (crisisLevel) {
      case CrisisLevel.emergency:
        return 'Immediate Help Available';
      case CrisisLevel.critical:
        return 'You\'re Not Alone';
      case CrisisLevel.warning:
        return 'Support Is Here';
      default:
        return 'Let\'s Talk';
    }
  }

  void _callNumber(String number) async {
    final Uri telUri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(telUri)) {
      await launchUrl(telUri);
    }
  }

  void _textNumber(String number) async {
    final Uri smsUri = Uri(scheme: 'sms', path: number);
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final levelColor = _getLevelColor();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: levelColor
                    .withAlpha(26), // 0.1 opacity = 26 alpha (255 * 0.1)
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getLevelIcon(),
                    color: levelColor,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getLevelTitle(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: levelColor,
                          ),
                        ),
                        if (immediateRisk)
                          const Text(
                            'Please reach out now',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emergency services for immediate risk
                  if (immediateRisk || crisisLevel == CrisisLevel.emergency)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(26), // 0.1 opacity
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.red.withAlpha(77)), // 0.3 opacity
                      ),
                      child: Column(
                        children: [
                          const Text(
                            '🚨 If you are in immediate danger:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => _callNumber('911'),
                            icon: const Icon(Icons.emergency),
                            label: const Text('Call 911 Emergency'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Crisis resources
                  const Text(
                    'Crisis Support Lines:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...resources
                      .take(3)
                      .map((resource) => _buildResourceCard(resource)),

                  // Emergency contact
                  if (emergencyContact != null) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Your Emergency Contact:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildEmergencyContactCard(emergencyContact!),
                  ],

                  // Disclaimer
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(26), // 0.1 opacity
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Remember: These resources are here to help. Reaching out is a sign of strength, not weakness.',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Navigate to safety plan
                      Navigator.pushNamed(context, '/safety-plan');
                    },
                    child: const Text('View Safety Plan'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceCard(CrisisResource resource) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getLevelColor().withAlpha(26), // 0.1 opacity
          child: Icon(
            Icons.support_agent,
            color: _getLevelColor(),
          ),
        ),
        title: Text(
          resource.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (resource.is24_7)
              const Text(
                'Available 24/7',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                ),
              ),
            Text(
              resource.phoneNumber,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.phone, color: Colors.green),
              onPressed: () => _callNumber(resource.phoneNumber),
              tooltip: 'Call',
            ),
            if (resource.textNumber != null)
              IconButton(
                icon: const Icon(Icons.message, color: Colors.blue),
                onPressed: () => _textNumber(resource.textNumber!),
                tooltip: 'Text',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContactCard(EmergencyContact contact) {
    return Card(
      color: Colors.blue.withAlpha(26), // 0.1 opacity
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(
            Icons.person,
            color: Colors.white,
          ),
        ),
        title: Text(
          contact.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${contact.relationship} • ${contact.phoneNumber}'),
        trailing: IconButton(
          icon: const Icon(Icons.phone, color: Colors.blue),
          onPressed: () => _callNumber(contact.phoneNumber),
          tooltip: 'Call ${contact.name}',
        ),
      ),
    );
  }
}
