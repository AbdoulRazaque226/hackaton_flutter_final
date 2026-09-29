import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/models/app_user.dart';
import '../../data/models/professional_profile.dart';
import '../../data/models/service_request.dart';
import '../../data/models/enums.dart';
import '../../data/services/location_service.dart'; // Contient RequestStatus

// Instance Firebase de base (injectée pour faciliter d'éventuels tests)
final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);
final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

// Stream du statut d'authentification (écoute si un utilisateur est connecté ou non)
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

// Provider de l'utilisateur connecté (récupère le profil AppUser depuis Firestore)
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return Stream.value(null);

  return ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(authState.uid)
      .snapshots()
      .map(
        (snapshot) => snapshot.exists
            ? AppUser.fromMap(snapshot.id, snapshot.data()!)
            : null,
      );
});

// StateNotifier pour gérer le profil professionnel et sa disponibilité
// CORRECTION TECHNIQUE : Le deuxième type générique DOIT correspondre EXACTEMENT à ce qui est dans le super() du Notifier.
final professionalProfileProvider =
    StateNotifierProvider<
      ProfessionalNotifier,
      AsyncValue<ProfessionalProfile?>
    >((ref) {
      return ProfessionalNotifier(ref);
    });

final locationServiceProvider = Provider((ref) => LocationService());

class ProfessionalNotifier
    extends StateNotifier<AsyncValue<ProfessionalProfile?>> {
  final Ref _ref;

  ProfessionalNotifier(this._ref) : super(const AsyncLoading()) {
    _init();
  }

  // Initialise l'écoute en temps réel du profil de l'artisan connecté
  void _init() {
    _ref.listen<AsyncValue<AppUser?>>(currentUserProvider, (previous, next) {
      final user = next.value;
      if (user != null && user.role == 'professionnel') {
        _ref
            .read(firestoreProvider)
            .collection('professionals')
            .doc(user.uid)
            .snapshots()
            .listen((snapshot) {
              if (snapshot.exists) {
                state = AsyncData(
                  ProfessionalProfile.fromMap(snapshot.id, snapshot.data()!),
                );
              } else {
                state = const AsyncData(null);
              }
            }, onError: (err, stack) => state = AsyncError(err, stack));
      } else {
        state = const AsyncData(null);
      }
    }, fireImmediately: true);
  }

  // FONCTIONNALITÉ : Basculer la disponibilité (En ligne / Hors ligne)
  Future<void> toggleAvailability() async {
    final currentProfile = state.value;
    if (currentProfile == null) return;

    final newStatus = !currentProfile.disponible;

    state = AsyncData(currentProfile.copyWith(disponible: newStatus));

    try {
      Map<String, dynamic> updates = {'disponible': newStatus};

      // SI L'ARTISAN PASSE EN LIGNE : On récupère sa vraie position
      if (newStatus) {
        // Demande de permission et récupération des coordonnées
        final position = await _ref
            .read(locationServiceProvider)
            .getCurrentPosition();

        updates['latitude'] = position.latitude;
        updates['longitude'] = position.longitude;

        // Mise à jour locale 
        state = AsyncData(
          currentProfile.copyWith(
            disponible: newStatus,
            latitude: position.latitude,
            longitude: position.longitude,
          ),
        );
      }

      await _ref
          .read(firestoreProvider)
          .collection('professionals')
          .doc(currentProfile.uid)
          .update({'disponible': newStatus});
    } catch (e, stack) {
      // En cas d'erreur réseau
      state = AsyncData(currentProfile);
      state = AsyncError(e, stack);
    }
  }
}

// StreamProvider de la liste des demandes reçues par cet artisan
final professionalRequestsProvider = StreamProvider<List<ServiceRequest>>((
  ref,
) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null || user.role != 'professionnel') return Stream.value([]);

  return ref
      .watch(firestoreProvider)
      .collection('requests')
      .where('professionalId', isEqualTo: user.uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(
              (doc) =>
                  ServiceRequest.fromMap(doc.id, doc.data()..['id'] = doc.id),
            )
            .toList(),
      );
});

// Provider d'actions sur les requêtes (Accepter, Refuser, Terminer)
final requestActionsProvider = Provider((ref) {
  final firestore = ref.read(firestoreProvider);
  return RequestActions(firestore);
});

class RequestActions {
  final FirebaseFirestore _firestore;
  RequestActions(this._firestore);

  // Mettre à jour le statut d'une demande d'intervention
  Future<void> updateRequestStatus(
    String requestId,
    RequestStatus status,
  ) async {
    final statusString = status.name;

    await _firestore.collection('requests').doc(requestId).update({
      'status': statusString,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
