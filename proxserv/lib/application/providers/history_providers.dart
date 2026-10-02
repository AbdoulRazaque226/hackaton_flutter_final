import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/app_user.dart';
import '../../data/models/enums.dart';
import '../../data/models/service_request.dart';
import 'app_providers.dart';

/// Toutes les demandes de l'utilisateur connecté, triées de la plus récente à
/// la plus ancienne.
///
/// Même approche que pour le chat : filtrage par rôle côté Firestore, tri
/// côté Dart. Un `orderBy('createdAt')` combiné au `where` exigerait un index
/// composite à déployer sur la console, sans quoi la requête échoue.
final myRequestsProvider = StreamProvider<List<ServiceRequest>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value(const []);

  final field = switch (user.role) {
    UserRole.professionnel => 'professionalId',
    UserRole.client => 'clientId',
    UserRole.admin => 'clientId',
  };

  return ref
      .watch(firestoreProvider)
      .collection('requests')
      .where(field, isEqualTo: user.uid)
      .snapshots()
      .map((snapshot) {
        final requests = snapshot.docs
            .map(
              (doc) => ServiceRequest.fromMap(doc.id, {
                ...doc.data(),
                'id': doc.id,
              }),
            )
            .toList();
        requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return requests;
      });
});

/// Les deux ensembles affichés par l'onglet Historique.
///
/// - **À compléter** : la demande attend une action — en attente de
///   validation, ou déjà acceptée et pas encore finie.
/// - **Complétées** : le cycle est clos — terminée, ou refusée (plus rien à
///   faire, la carte garde son badge « Refusée » rouge pour lever l'ambiguïté).
///
/// Les statuts sont regroupés ici pour que l'onglet Client et l'onglet
/// Professionnel se comportent exactement pareil.
extension RequestHistoryBuckets on List<ServiceRequest> {
  List<ServiceRequest> get pending => where(
        (r) =>
            r.status == RequestStatus.enAttente ||
            r.status == RequestStatus.acceptee,
      ).toList();

  List<ServiceRequest> get closed => where(
        (r) =>
            r.status == RequestStatus.terminee ||
            r.status == RequestStatus.refusee,
      ).toList();
}