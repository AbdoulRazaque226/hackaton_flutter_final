import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_localizations.dart';
import 'app_providers.dart';

/// Préférences d'affichage (Thème, Langue, Notifications) de l'utilisateur,
/// stockées dans son document `users/{uid}` sous le champ `preferences`.
final userPreferencesProvider = StreamProvider<Map<String, dynamic>>((ref) {
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

/// Provider du Thème actif (Light, Dark, System) dérivé des préférences
final themeModeProvider = Provider<ThemeMode>((ref) {
  final prefs = ref.watch(userPreferencesProvider).value ?? const {};
  final themeStr = prefs['theme'] as String? ?? 'system';
  switch (themeStr) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
});

/// Synchronisation de la langue avec la préférence utilisateur
final syncedLanguageProvider = Provider<AppLanguage>((ref) {
  final prefs = ref.watch(userPreferencesProvider).value ?? const {};
  final langStr = prefs['language'] as String? ?? 'fr';
  return langStr == 'en' ? AppLanguage.en : AppLanguage.fr;
});

/// Écriture d'une préférence booléenne ou chaîne
Future<void> setPreference(
  WidgetRef ref,
  String uid,
  String key,
  dynamic value,
) async {
  await ref.read(firestoreProvider).collection('users').doc(uid).set({
    'preferences': {key: value},
  }, SetOptions(merge: true));
}

/// Lecture d'une préférence avec valeur par défaut
bool preference(
  Map<String, dynamic> prefs,
  String key, {
  bool fallback = true,
}) {
  return prefs[key] as bool? ?? fallback;
}
