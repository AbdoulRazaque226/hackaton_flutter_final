import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../models/app_user.dart';
import '../models/enums.dart';
import '../models/professional_profile.dart';
import '../models/service_request.dart';

/// Point d'accès unique à Firebase. Regrouper les appels ici évite de
/// disperser la logique Firestore/Auth dans les écrans.
class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // ---------- AUTH ----------

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<void> signOut() => _auth.signOut();

  /// Inscription client ou professionnel. Pour un professionnel, un profil
  /// est aussi créé dans `professionals` (métier + zone à compléter ensuite).
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
    required String phone,
    required UserRole role,
    Metier? metier,
    String? zoneIntervention,
    String country = '',
    String city = '',
    String neighborhood = '',
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    final user = AppUser(
      uid: uid,
      email: email,
      displayName: displayName,
      phone: phone,
      role: role,
    );
    await _db.collection('users').doc(uid).set(user.toMap());

    if (role == UserRole.professionnel) {
      final profile = ProfessionalProfile(
        uid: uid,
        displayName: displayName,
        phone: phone,
        metier: metier ?? Metier.autre,
        zoneIntervention: zoneIntervention ?? '',
        country: country,
        city: city,
        neighborhood: neighborhood,
        disponible: false,
      );
      await _db.collection('professionals').doc(uid).set(profile.toMap());
    }
    return user;
  }

  Future<AppUser?> fetchAppUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(uid, doc.data()!);
  }

  // ---------- PROFESSIONALS ----------

  CollectionReference<Map<String, dynamic>> get _professionals =>
      _db.collection('professionals');

  Stream<List<ProfessionalProfile>> watchProfessionalsByMetier(Metier metier) {
    return _professionals
        .where('metier', isEqualTo: metier.name)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ProfessionalProfile.tryFromMap(d.id, d.data()))
              .whereType<ProfessionalProfile>()
              .toList(),
        );
  }

  Stream<ProfessionalProfile?> watchMyProfessionalProfile(String uid) {
    return _professionals
        .doc(uid)
        .snapshots()
        .map(
          (doc) =>
              doc.exists ? ProfessionalProfile.fromMap(uid, doc.data()!) : null,
        );
  }

  Future<void> setDisponibilite(String uid, bool disponible) {
    return _professionals.doc(uid).update({'disponible': disponible});
  }

  Future<void> updateMaPosition(String uid, double lat, double lon) {
    return _professionals.doc(uid).update({'latitude': lat, 'longitude': lon});
  }

  // ---------- SERVICE REQUESTS ----------

  CollectionReference<Map<String, dynamic>> get _requests =>
      _db.collection('requests');

  Future<String> createRequest({
    required String clientId,
    required String clientName,
    required String professionalId,
    required Metier metier,
    required String description,
    required String country,
    required String city,
    String neighborhood = '',
    double? latitude,
    double? longitude,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final request = ServiceRequest(
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
      status: RequestStatus.enAttente,
      createdAt: now,
      updatedAt: now,
    );
    await _requests.doc(id).set(request.toMap());
    return id;
  }

  /// Demandes reçues par un professionnel (son tableau de bord).
  Stream<List<ServiceRequest>> watchRequestsForProfessional(
    String professionalId,
  ) {
    return _requests
        .where('professionalId', isEqualTo: professionalId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ServiceRequest.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  /// Demandes envoyées par un client (suivi de statut).
  Stream<List<ServiceRequest>> watchRequestsForClient(String clientId) {
    return _requests
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ServiceRequest.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Future<void> updateRequestStatus(String requestId, RequestStatus status) {
    return _requests.doc(requestId).update({
      'status': status.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> rateRequest(
    String requestId,
    int note,
    String? commentaire,
  ) async {
    if (note < 1 || note > 5) {
      throw ArgumentError.value(note, 'note', 'Must be between 1 and 5.');
    }

    final client = _auth.currentUser;
    if (client == null) {
      throw StateError('A signed-in client is required to submit a review.');
    }

    final requestRef = _requests.doc(requestId);
    await _db.runTransaction((transaction) async {
      final requestSnapshot = await transaction.get(requestRef);
      if (!requestSnapshot.exists) {
        throw StateError('The service request no longer exists.');
      }
      final requestData = requestSnapshot.data()!;
      if (requestData['clientId'] != client.uid) {
        throw StateError('Only the requesting client can submit a review.');
      }
      if (requestData['status'] != RequestStatus.terminee.name) {
        throw StateError('Only completed requests can be reviewed.');
      }
      if (requestData['note'] != null) {
        throw StateError('This request has already been reviewed.');
      }

      final professionalId = requestData['professionalId'] as String;
      final professionalRef = _professionals.doc(professionalId);
      final professionalSnapshot = await transaction.get(professionalRef);
      if (!professionalSnapshot.exists) {
        throw StateError('The professional profile no longer exists.');
      }

      final professionalData = professionalSnapshot.data()!;
      final reviewCount =
          (professionalData['nombreEvaluations'] as num?)?.toInt() ?? 0;
      final oldTotal =
          (professionalData['totalNotes'] as num?)?.toInt() ??
          (((professionalData['noteMoyenne'] as num?)?.toDouble() ?? 0) *
                  reviewCount)
              .round();
      final newCount = reviewCount + 1;
      final newTotal = oldTotal + note;
      final normalizedComment = commentaire?.trim();

      transaction.update(requestRef, {
        'note': note,
        'commentaire': normalizedComment == null || normalizedComment.isEmpty
            ? null
            : normalizedComment,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(professionalRef, {
        'noteMoyenne': newTotal / newCount,
        'nombreEvaluations': newCount,
        'totalNotes': newTotal,
        'lastReviewRequestId': requestId,
      });
    });
  }

  // ---------- ADMIN ----------

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  /// Tous les comptes (clients et professionnels confondus), pour
  /// l'écran d'administration.
  Stream<List<AppUser>> watchAllUsers() {
    return _users.snapshots().map(
      (snap) => snap.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList(),
    );
  }

  /// Bloque ou débloque un compte. Un compte bloqué est redirigé vers un
  /// écran dédié au prochain démarrage de l'app (voir router.dart), il ne
  /// peut plus utiliser l'application tant qu'il n'est pas débloqué.
  Future<void> setUserBlocked(String uid, bool bloque) {
    return _users.doc(uid).update({'bloque': bloque});
  }

  /// Tous les professionnels, sans filtre de métier — utilisé pour les
  /// statistiques globales de l'écran d'administration.
  Stream<List<ProfessionalProfile>> watchAllProfessionals() {
    return _professionals.snapshots().map(
      (snap) => snap.docs
          .map((d) => ProfessionalProfile.tryFromMap(d.id, d.data()))
          .whereType<ProfessionalProfile>()
          .toList(),
    );
  }

  /// Toutes les demandes, tous clients/professionnels confondus — utilisé
  /// pour les statistiques globales de l'écran d'administration.
  Stream<List<ServiceRequest>> watchAllRequests() {
    return _requests.snapshots().map(
      (snap) =>
          snap.docs.map((d) => ServiceRequest.fromMap(d.id, d.data())).toList(),
    );
  }
}
