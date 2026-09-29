import 'package:cloud_firestore/cloud_firestore.dart';

import 'enums.dart';

/// Profil professionnel, lié 1-1 à un AppUser (même uid) dont le rôle
/// est UserRole.professionnel. Stocké dans la collection `professionals`.
class ProfessionalProfile {
  final String uid;
  final String displayName;
  final String phone;
  final Metier metier;
  final String zoneIntervention;
  final bool disponible;
  final double latitude;
  final double longitude;
  final double? noteMoyenne;
  final int nombreEvaluations;

  const ProfessionalProfile({
    required this.uid,
    required this.displayName,
    required this.phone,
    required this.metier,
    required this.zoneIntervention,
    required this.disponible,
    required this.latitude,
    required this.longitude,
    this.noteMoyenne,
    this.nombreEvaluations = 0,
  });

  ProfessionalProfile copyWith({
    bool? disponible,
    double? latitude,
    double? longitude,
  }) {
    return ProfessionalProfile(
      uid: uid,
      displayName: displayName,
      phone: phone,
      metier: metier,
      zoneIntervention: zoneIntervention,
      disponible: disponible ?? this.disponible,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      noteMoyenne: noteMoyenne,
      nombreEvaluations: nombreEvaluations,
    );
  }

  factory ProfessionalProfile.fromMap(String uid, Map<String, dynamic> map) {
    return ProfessionalProfile(
      uid: uid,
      displayName: map['displayName'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      metier: Metier.fromName(map['metier'] as String? ?? 'autre'),
      zoneIntervention: map['zoneIntervention'] as String? ?? '',
      disponible: map['disponible'] as bool? ?? false,
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      noteMoyenne: (map['noteMoyenne'] as num?)?.toDouble(),
      nombreEvaluations: (map['nombreEvaluations'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'phone': phone,
      'metier': metier.name,
      'zoneIntervention': zoneIntervention,
      'disponible': disponible,
      'latitude': latitude,
      'longitude': longitude,
      'noteMoyenne': noteMoyenne,
      'nombreEvaluations': nombreEvaluations,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }
}
