import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/app_providers.dart';
import '../../../application/providers/chat_providers.dart';
import '../chat/chat_list_screen.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';

/// Coquille commune aux espaces Client et Professionnel.
///
/// Les deux rôles partagent le même plan de navigation : seuls les *contenus*
/// changent (le Home est fourni par l'appelant, l'historique et le chat lisent
/// le rôle de l'utilisateur). Écrire cet écran une seule fois évite d'entretenir
/// deux coquilles qui divergeraient.
///
/// Le `Scaffold` parent n'a volontairement pas d'`AppBar` : chaque onglet
/// possède le sien, comme sur les écrans existants.
class DashboardShell extends ConsumerStatefulWidget {
  /// Onglet « Accueil » — `ClientHomeScreen` ou `ProfessionalDashboardScreen`.
  final Widget home;

  const DashboardShell({super.key, required this.home});

  @override
  ConsumerState<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends ConsumerState<DashboardShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    // Sert surtout de garde : le routeur renvoie vers /login tant que ce
    // provider n'est pas résolu.
    final user = ref.watch(currentUserProvider).value;
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final unread = ref.watch(unreadChatCountProvider);

    return Scaffold(
      // IndexedStack : chaque onglet reste monté, donc la position de scroll,
      // le métier sélectionné sur l'accueil et l'état de l'historique
      // survivent aux changements d'onglet.
      body: IndexedStack(
        index: _index,
        children: [
          widget.home,
          const ChatListScreen(),
          const HistoryScreen(),
          const SettingsScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.chat_bubble_outline),
            ),
            selectedIcon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.chat_bubble),
            ),
            label: 'Chat',
          ),
          const NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Historique',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Paramètres',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}