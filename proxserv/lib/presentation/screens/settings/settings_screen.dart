import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/app_providers.dart';
import '../../../application/providers/settings_providers.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/app_user.dart';
import '../dashboard/dashboard_menu.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final prefs =
        ref.watch(userPreferencesProvider).value ?? const <String, dynamic>{};
    final loc = AppLocalizations.of(context, ref);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isPro = user.role == UserRole.professionnel;
    final profile = ref.watch(professionalProfileProvider).value;
    final currentTheme = prefs['theme'] as String? ?? 'system';
    final currentLang =
        prefs['language'] as String? ?? (loc.isFr ? 'fr' : 'en');

    return Scaffold(
      appBar: AppBar(
        leading: dashboardMenuLeading(context),
        title: Text(loc.settingsTab),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _SectionTitle(loc.text('Compte', 'Account')),
          ListTile(
            leading: const Icon(Icons.alternate_email),
            title: Text(loc.emailLabel),
            subtitle: Text(user.email),
            enabled: false,
          ),
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: Text(loc.text('Rôle', 'Role')),
            subtitle: Text(loc.roleLabel(user.role)),
            enabled: false,
          ),

          // Apparence (Clair / Sombre / Système)
          _SectionTitle(loc.appearance),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(loc.appearance),
            subtitle: Text(
              currentTheme == 'light'
                  ? loc.lightTheme
                  : currentTheme == 'dark'
                  ? loc.darkTheme
                  : loc.systemTheme,
            ),
            trailing: DropdownButton<String>(
              value: currentTheme,
              underline: const SizedBox.shrink(),
              items: [
                DropdownMenuItem(value: 'system', child: Text(loc.systemTheme)),
                DropdownMenuItem(value: 'light', child: Text(loc.lightTheme)),
                DropdownMenuItem(value: 'dark', child: Text(loc.darkTheme)),
              ],
              onChanged: (val) {
                if (val != null) {
                  setPreference(ref, user.uid, 'theme', val);
                }
              },
            ),
          ),

          // Langue (Français / English)
          _SectionTitle(loc.languageSection),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: Text(loc.languageSection),
            subtitle: Text(currentLang == 'en' ? loc.english : loc.french),
            trailing: DropdownButton<String>(
              value: currentLang,
              underline: const SizedBox.shrink(),
              items: [
                DropdownMenuItem(value: 'fr', child: Text(loc.french)),
                DropdownMenuItem(value: 'en', child: Text(loc.english)),
              ],
              onChanged: (val) {
                if (val != null) {
                  setPreference(ref, user.uid, 'language', val);
                  ref
                      .read(appLanguageNotifierProvider.notifier)
                      .setLanguage(
                        val == 'en' ? AppLanguage.en : AppLanguage.fr,
                      );
                }
              },
            ),
          ),

          if (isPro) ...[
            _SectionTitle(loc.text('Disponibilité', 'Availability')),
            SwitchListTile(
              secondary: Icon(
                (profile?.disponible ?? false)
                    ? Icons.check_circle
                    : Icons.do_not_disturb_on,
                color: (profile?.disponible ?? false)
                    ? AppColors.success
                    : AppColors.error,
              ),
              title: Text(
                (profile?.disponible ?? false)
                    ? loc.text('Vous êtes en ligne', 'You are online')
                    : loc.text('Vous êtes hors ligne', 'You are offline'),
              ),
              subtitle: Text(
                (profile?.disponible ?? false)
                    ? loc.text(
                        'Les clients voient votre fiche comme disponible.',
                        'Clients see your profile as available.',
                      )
                    : loc.text(
                        'Votre fiche n\'est pas proposée aux clients.',
                        'Your profile is not shown to clients.',
                      ),
              ),
              value: profile?.disponible ?? false,
              onChanged: profile == null
                  ? null
                  : (_) => ref
                        .read(professionalProfileProvider.notifier)
                        .toggleAvailability(),
            ),
          ],

          _SectionTitle(loc.text('Notifications', 'Notifications')),
          SwitchListTile(
            secondary: const Icon(Icons.work_outline),
            title: Text(loc.requestsTab),
            subtitle: Text(
              loc.text(
                'Suivi des demandes d\'intervention',
                'Service request updates',
              ),
            ),
            value: preference(prefs, 'notifDemandes'),
            onChanged: (value) =>
                setPreference(ref, user.uid, 'notifDemandes', value),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.chat_bubble_outline),
            title: Text(loc.messagesTab),
            subtitle: Text(
              loc.text(
                'Nouveaux messages dans une conversation',
                'New messages in a conversation',
              ),
            ),
            value: preference(prefs, 'notifMessages'),
            onChanged: (value) =>
                setPreference(ref, user.uid, 'notifMessages', value),
          ),

          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () => ref.read(firebaseAuthProvider).signOut(),
              icon: const Icon(Icons.logout),
              label: Text(loc.logout),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
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
          color: AppColors.brandPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
