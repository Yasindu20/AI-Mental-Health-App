import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/crisis_models.dart';
import 'api_service.dart';

class CrisisService {
  static const String baseUrl = ApiService.baseUrl;

  // Get headers method
  static Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      // Add any authentication headers if needed
    };
  }

  // Get crisis resources
  static Future<List<CrisisResource>> getCrisisResources({
    String country = 'US',
    String? specialty,
  }) async {
    String url = '$baseUrl/crisis-resources/';
    if (specialty != null) {
      url = '$baseUrl/crisis-resources/by_specialty/?specialty=$specialty';
    } else {
      url += '?country=$country';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((r) => CrisisResource.fromJson(r)).toList();
    } else {
      throw Exception('Failed to load crisis resources');
    }
  }

  // Get emergency contacts
  static Future<List<EmergencyContact>> getEmergencyContacts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/emergency-contacts/'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((c) => EmergencyContact.fromJson(c)).toList();
    } else {
      throw Exception('Failed to load emergency contacts');
    }
  }

  // Add emergency contact
  static Future<EmergencyContact> addEmergencyContact(
    EmergencyContact contact,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/emergency-contacts/'),
      headers: _getHeaders(),
      body: jsonEncode(contact.toJson()),
    );

    if (response.statusCode == 201) {
      return EmergencyContact.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to add emergency contact');
    }
  }

  // Create safety plan
  static Future<void> createSafetyPlan(SafetyPlan plan) async {
    final response = await http.post(
      Uri.parse('$baseUrl/crisis-profile/create_safety_plan/'),
      headers: _getHeaders(),
      body: jsonEncode(plan.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to save safety plan');
    }
  }

  // Check crisis status
  static Future<Map<String, dynamic>> checkCrisisStatus() async {
    final response = await http.get(
      Uri.parse('$baseUrl/crisis-profile/check_crisis/'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to check crisis status');
    }
  }

  // Provide feedback on crisis detection
  static Future<void> provideFeedback(
    int detectionId,
    String feedback,
    bool falsePositive,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/crisis-detections/$detectionId/feedback/'),
      headers: _getHeaders(),
      body: jsonEncode({
        'feedback': feedback,
        'false_positive': falsePositive,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to submit feedback');
    }
  }
}
