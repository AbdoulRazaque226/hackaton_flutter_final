import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_providers.dart';

/// Préférences d'affichage et de notification de l'utilisateur, stockées
/// dans son document `users/{uid}` sous le champ `preferences`.
///
/// Elles sont persistées et relues en temps réel. Le branchement effectif des
/// notifications push relève du module de notifications porté par un autre
/// membre : ces interrupteurs enregistrent l'intention, pas l'envoi.
final userPreferencesProvider =
    StreamProvider<Map<String, dynamic>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value(const <String, dynamic>{});

  return ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map(
        (snapshot) =>
            (snapshot.data()?['preferences'] as Map<String, dynamic>?) ??
            const <String, dynamic>{},
      );
});

/// Écriture d'une préférence.
Future<void> setPreference(
  WidgetRef ref,
  String uid,
  String key,
  bool value,
) async {
  await ref.read(firestoreProvider).collection('users').doc(uid).set(
        {'preferences': {key: value}},
        SetOptions(merge: true),
      );
}

/// Lecture d'une préférence, avec une valeur par défaut quand elle n'a jamais
/// été enregistrée.
bool preference(Map<String, dynamic> prefs, String key, {bool fallback = true}) {
  return prefs[key] as bool? ?? fallback;
}