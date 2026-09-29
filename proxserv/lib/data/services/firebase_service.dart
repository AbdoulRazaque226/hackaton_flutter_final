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
        disponible: false,
        latitude: 0,
        longitude: 0,
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
        .map((snap) => snap.docs
            .map((d) => ProfessionalProfile.fromMap(d.id, d.data()))
            .toList());
  }

  Stream<ProfessionalProfile?> watchMyProfessionalProfile(String uid) {
    return _professionals.doc(uid).snapshots().map(
        (doc) => doc.exists ? ProfessionalProfile.fromMap(uid, doc.data()!) : null);
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

  Future<void> createRequest({
    required String clientId,
    required String clientName,
    required String professionalId,
    required Metier metier,
    required String description,
    required double latitude,
    required double longitude,
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
      latitude: latitude,
      longitude: longitude,
      status: RequestStatus.enAttente,
      createdAt: now,
      updatedAt: now,
    );
    await _requests.doc(id).set(request.toMap());
  }

  /// Demandes reçues par un professionnel (son tableau de bord).
  Stream<List<ServiceRequest>> watchRequestsForProfessional(String professionalId) {
    return _requests
        .where('professionalId', isEqualTo: professionalId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ServiceRequest.fromMap(d.id, d.data())).toList());
  }

  /// Demandes envoyées par un client (suivi de statut).
  Stream<List<ServiceRequest>> watchRequestsForClient(String clientId) {
    return _requests
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ServiceRequest.fromMap(d.id, d.data())).toList());
  }

  Future<void> updateRequestStatus(String requestId, RequestStatus status) {
    return _requests.doc(requestId).update({
      'status': status.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> rateRequest(String requestId, int note, String? commentaire) {
    return _requests.doc(requestId).update({
      'note': note,
      'commentaire': commentaire,
    });
  }
}
