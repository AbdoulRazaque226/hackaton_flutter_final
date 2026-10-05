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
  final String country;
  final String city;
  final String neighborhood;
  final bool disponible;
  final double? latitude;
  final double? longitude;
  final double? noteMoyenne;
  final int nombreEvaluations;
  final int totalNotes;
  final String? lastReviewRequestId;

  const ProfessionalProfile({
    required this.uid,
    required this.displayName,
    required this.phone,
    required this.metier,
    required this.zoneIntervention,
    this.country = '',
    this.city = '',
    this.neighborhood = '',
    required this.disponible,
    this.latitude,
    this.longitude,
    this.noteMoyenne,
    this.nombreEvaluations = 0,
    this.totalNotes = 0,
    this.lastReviewRequestId,
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
      country: country,
      city: city,
      neighborhood: neighborhood,
      disponible: disponible ?? this.disponible,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      noteMoyenne: noteMoyenne,
      nombreEvaluations: nombreEvaluations,
      totalNotes: totalNotes,
      lastReviewRequestId: lastReviewRequestId,
    );
  }

  factory ProfessionalProfile.fromMap(String uid, Map<String, dynamic> map) {
    final nombreEvaluations =
        (map['nombreEvaluations'] as num?)?.toInt() ?? 0;
    final noteMoyenne = (map['noteMoyenne'] as num?)?.toDouble();
    return ProfessionalProfile(
      uid: uid,
      displayName: map['displayName'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      metier: Metier.fromName(map['metier'] as String? ?? 'autre'),
      zoneIntervention: map['zoneIntervention'] as String? ?? '',
      country: map['country'] as String? ?? '',
      city: map['city'] as String? ?? '',
      neighborhood: map['neighborhood'] as String? ?? '',
      disponible: map['disponible'] as bool? ?? false,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      noteMoyenne: noteMoyenne,
      nombreEvaluations: nombreEvaluations,
      totalNotes:
          (map['totalNotes'] as num?)?.toInt() ??
          ((noteMoyenne ?? 0) * nombreEvaluations).round(),
      lastReviewRequestId: map['lastReviewRequestId'] as String?,
    );
  }

  static ProfessionalProfile? tryFromMap(
    String uid,
    Map<String, dynamic> map,
  ) {
    final metierName = map['metier'];
    if (metierName is! String ||
        !Metier.values.any((metier) => metier.name == metierName)) {
      return null;
    }
    return ProfessionalProfile.fromMap(uid, map);
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'phone': phone,
      'metier': metier.name,
      'zoneIntervention': zoneIntervention,
      'country': country,
      'city': city,
      'neighborhood': neighborhood,
      'disponible': disponible,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'noteMoyenne': noteMoyenne,
      'nombreEvaluations': nombreEvaluations,
      'totalNotes': totalNotes,
      'lastReviewRequestId': lastReviewRequestId,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }
}
