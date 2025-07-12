class CrisisLevel {
  static const String concern = 'concern';
  static const String warning = 'warning';
  static const String critical = 'critical';
  static const String emergency = 'emergency';
}

class CrisisResource {
  final int id;
  final String name;
  final String phoneNumber;
  final String? textNumber;
  final String? website;
  final String description;
  final bool is24_7;
  final List<String> languages;
  final List<String> specialties;

  CrisisResource({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.textNumber,
    this.website,
    required this.description,
    required this.is24_7,
    required this.languages,
    required this.specialties,
  });

  factory CrisisResource.fromJson(Map<String, dynamic> json) {
    return CrisisResource(
      id: json['id'],
      name: json['name'],
      phoneNumber: json['phone_number'],
      textNumber: json['text_number'],
      website: json['website'],
      description: json['description'],
      is24_7: json['is_24_7'],
      languages: List<String>.from(json['languages']),
      specialties: List<String>.from(json['specialties']),
    );
  }
}

class EmergencyContact {
  final int? id;
  final String name;
  final String relationship;
  final String phoneNumber;
  final String? email;
  final bool isPrimary;
  final String? notes;

  EmergencyContact({
    this.id,
    required this.name,
    required this.relationship,
    required this.phoneNumber,
    this.email,
    this.isPrimary = false,
    this.notes,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'],
      name: json['name'],
      relationship: json['relationship'],
      phoneNumber: json['phone_number'],
      email: json['email'],
      isPrimary: json['is_primary'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'relationship': relationship,
      'phone_number': phoneNumber,
      'email': email,
      'is_primary': isPrimary,
      'notes': notes,
    };
  }
}

class SafetyPlan {
  final List<String> warningSigns;
  final List<String> copingStrategies;
  final List<Map<String, String>> supportContacts;
  final List<Map<String, String>> professionalContacts;
  final List<String> safeEnvironment;
  final List<String> reasonsForLiving;

  SafetyPlan({
    required this.warningSigns,
    required this.copingStrategies,
    required this.supportContacts,
    required this.professionalContacts,
    required this.safeEnvironment,
    required this.reasonsForLiving,
  });

  Map<String, dynamic> toJson() {
    return {
      'warning_signs': warningSigns,
      'coping_strategies': copingStrategies,
      'support_contacts': supportContacts,
      'professional_contacts': professionalContacts,
      'safe_environment': safeEnvironment,
      'reasons_for_living': reasonsForLiving,
    };
  }
}
