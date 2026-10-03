import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/app_providers.dart';
import '../../../application/providers/settings_providers.dart';
import '../../../data/models/app_user.dart';

/// Onglet « Paramètres » du dashboard.
///
/// Tout ce qui est proposé ici agit réellement :
/// - la disponibilité du professionnel passe par le provider existant ;
/// - les préférences sont persistées dans le document de l'utilisateur ;
/// - la déconnexion passe par Firebase Auth.
///
/// La suppression de compte n'est volontairement pas proposée : les règles
/// Firestore interdisent aujourd'hui toute suppression (`allow delete: if
/// false`), l'option serait inopérante.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final prefs = ref.watch(userPreferencesProvider).value ??
        const <String, dynamic>{};

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isPro = user.role == UserRole.professionnel;
    final profile = ref.watch(professionalProfileProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const _SectionTitle('Compte'),
          ListTile(
            leading: const Icon(Icons.alternate_email),
            title: const Text('Adresse e-mail'),
            subtitle: Text(user.email),
            enabled: false,
          ),
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('Rôle'),
            subtitle: Text(_roleLabel(user.role)),
            enabled: false,
          ),

          // La disponibilité n'existe que pour un professionnel.
          if (isPro) ...[
            const _SectionTitle('Disponibilité'),
            SwitchListTile(
              secondary: Icon(
                (profile?.disponible ?? false)
                    ? Icons.check_circle
                    : Icons.do_not_disturb_on,
                color: (profile?.disponible ?? false)
                    ? Colors.green
                    : Colors.red,
              ),
              title: Text(
                (profile?.disponible ?? false)
                    ? 'Vous êtes en ligne'
                    : 'Vous êtes hors ligne',
              ),
              subtitle: Text(
                (profile?.disponible ?? false)
                    ? 'Les clients voient votre fiche comme disponible.'
                    : 'Votre fiche n\'est pas proposée aux clients.',
              ),
              value: profile?.disponible ?? false,
              onChanged: profile == null
                  ? null
                  : (_) => ref
                      .read(professionalProfileProvider.notifier)
                      .toggleAvailability(),
            ),
          ],

          const _SectionTitle('Notifications'),
          SwitchListTile(
            secondary: const Icon(Icons.work_outline),
            title: const Text('Demandes'),
            subtitle: const Text('Suivi des demandes d\'intervention'),
            value: preference(prefs, 'notifDemandes'),
            onChanged: (value) =>
                setPreference(ref, user.uid, 'notifDemandes', value),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.chat_bubble_outline),
            title: const Text('Messages'),
            subtitle: const Text('Nouveaux messages dans une conversation'),
            value: preference(prefs, 'notifMessages'),
            onChanged: (value) =>
                setPreference(ref, user.uid, 'notifMessages', value),
          ),

          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () => ref.read(firebaseAuthProvider).signOut(),
              icon: const Icon(Icons.logout),
              label: const Text('Se déconnecter'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _roleLabel(UserRole role) => switch (role) {
      UserRole.client => 'Client',
      UserRole.professionnel => 'Professionnel',
      UserRole.admin => 'Administrateur',
    };