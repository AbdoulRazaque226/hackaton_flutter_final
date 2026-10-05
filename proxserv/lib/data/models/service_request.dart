import 'package:cloud_firestore/cloud_firestore.dart';

import 'enums.dart';

class ServiceRequest {
  final String id;
  final String clientId;
  final String clientName;
  final String professionalId;
  final Metier metier;
  final String description;
  final String country;
  final String city;
  final String neighborhood;
  final double? latitude;
  final double? longitude;
  final RequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? note; // évaluation 1-5, optionnelle, remplie après intervention
  final String? commentaire;

  const ServiceRequest({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.professionalId,
    required this.metier,
    required this.description,
    this.country = '',
    this.city = '',
    this.neighborhood = '',
    this.latitude,
    this.longitude,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.note,
    this.commentaire,
  });

  ServiceRequest copyWith({RequestStatus? status, DateTime? updatedAt}) {
    return ServiceRequest(
      id: id,
      clientId: clientId,
      clientName: clientName,
      professionalId: professionalId,
      metier: metier,
      description: description,
      country: country,
      city: city,
      neighborhood: neighborhood,
      latitude: latitude,
      longitude: longitude,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      note: note,
      commentaire: commentaire,
    );
  }

  factory ServiceRequest.fromMap(String id, Map<String, dynamic> map) {
    return ServiceRequest(
      id: id,
      clientId: map['clientId'] as String,
      clientName: map['clientName'] as String? ?? '',
      professionalId: map['professionalId'] as String,
      metier: Metier.fromName(map['metier'] as String? ?? 'autre'),
      description: map['description'] as String? ?? '',
      country: map['country'] as String? ?? '',
      city: map['city'] as String? ?? '',
      neighborhood: map['neighborhood'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      status: RequestStatus.fromName(map['status'] as String? ?? 'enAttente'),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      note: (map['note'] as num?)?.toInt(),
      commentaire: map['commentaire'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'professionalId': professionalId,
      'metier': metier.name,
      'description': description,
      'country': country,
      'city': city,
      'neighborhood': neighborhood,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'note': note,
      'commentaire': commentaire,
    };
  }
}
