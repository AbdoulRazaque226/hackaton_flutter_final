import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_providers.dart';

/// Annuaire `uid -> nom d'affichage` des professionnels.
///
/// Ni l'historique ni le chat ne peuvent afficher le nom du professionnel à
/// partir d'un `ServiceRequest`, qui ne porte que `professionalId`. Résoudre
/// chaque nom par une lecture individuelle produirait une requête par ligne ;
/// une seule lecture de la collection `professionals` suffit donc, et les
/// règles autorisent déjà la lecture de cette collection à tout utilisateur
/// connecté. Riverpod met le résultat en cache pour la durée de l'écran.
final proDirectoryProvider = FutureProvider<Map<String, String>>((ref) async {
  final snapshot = await ref
      .watch(firestoreProvider)
      .collection('professionals')
      .get();

  return {
    for (final doc in snapshot.docs)
      doc.id: (doc.data()['displayName'] as String? ?? ''),
  };
});