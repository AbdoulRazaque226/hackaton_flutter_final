import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/app_providers.dart';
import '../../../application/providers/chat_providers.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/app_user.dart';
import '../chat/chat_list_screen.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';

class DashboardShell extends ConsumerStatefulWidget {
  final Widget home;

  const DashboardShell({super.key, required this.home});

  @override
  ConsumerState<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends ConsumerState<DashboardShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final unread = ref.watch(unreadChatCountProvider);
    final loc = AppLocalizations.of(context, ref);
    final isPro = user.role == UserRole.professionnel;
    final width = MediaQuery.of(context).size.width;

    // Définition des pages et destinations selon le rôle
    final List<Widget> pages = isPro
        ? [
            widget.home,
            const HistoryScreen(),
            const ChatListScreen(),
            const SettingsScreen(),
            const ProfileScreen(),
          ]
        : [
            widget.home,
            widget.home, // Explorer tab defaults to home view
            const HistoryScreen(),
            const ChatListScreen(),
            const ProfileScreen(),
          ];

    final destinations = isPro
        ? [
            NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined),
              selectedIcon: const Icon(Icons.dashboard),
              label: loc.dashboardTab,
            ),
            NavigationDestination(
              icon: const Icon(Icons.assignment_outlined),
              selectedIcon: const Icon(Icons.assignment),
              label: loc.requestsTab,
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
              label: loc.messagesTab,
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: loc.settingsTab,
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: loc.profileTab,
            ),
          ]
        : [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: loc.homeTab,
            ),
            NavigationDestination(
              icon: const Icon(Icons.search_outlined),
              selectedIcon: const Icon(Icons.search),
              label: loc.exploreTab,
            ),
            NavigationDestination(
              icon: const Icon(Icons.assignment_outlined),
              selectedIcon: const Icon(Icons.assignment),
              label: loc.requestsTab,
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
              label: loc.messagesTab,
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: loc.profileTab,
            ),
          ];

    final railDestinations = destinations.map((d) {
      return NavigationRailDestination(
        icon: d.icon,
        selectedIcon: d.selectedIcon,
        label: Text(d.label),
      );
    }).toList();

    final isMobile = width < 600;
    final isDesktop = width >= 840;

    if (isMobile) {
      return Scaffold(
        body: IndexedStack(
          index: _index.clamp(0, pages.length - 1),
          children: pages,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index.clamp(0, destinations.length - 1),
          onDestinationSelected: (value) => setState(() => _index = value),
          destinations: destinations,
        ),
      );
    }

    // Tablet & Desktop : NavigationRail/Sidebar (Pas de BottomNavigationBar sur grand écran)
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: isDesktop,
            selectedIndex: _index.clamp(0, railDestinations.length - 1),
            onDestinationSelected: (value) => setState(() => _index = value),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 36,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.build_circle,
                      color: AppColors.brandPrimary,
                      size: 36,
                    ),
                  ),

                  if (isDesktop) ...[
                    const SizedBox(width: 8),
                    const Text(
                      'ProxServ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            destinations: railDestinations,
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: IndexedStack(
              index: _index.clamp(0, pages.length - 1),
              children: pages,
            ),
          ),
        ],
      ),
    );
  }
}
