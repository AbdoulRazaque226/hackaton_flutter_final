import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers/app_providers.dart';
import '../../../application/providers/chat_providers.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/enums.dart';
import '../../../data/services/firebase_service.dart';
import '../chat/chat_list_screen.dart';
import '../history/history_screen.dart';
import '../explore_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';
import '../../widgets/brand_logo.dart';
import 'dashboard_menu.dart';

/// Shell principal de navigation réactive (Mobile, Tablette, Desktop).
class DashboardShell extends ConsumerStatefulWidget {
  final Widget home;
  final int initialIndex;
  final Metier? initialExploreMetier;
  final String initialExploreQuery;

  const DashboardShell({
    super.key,
    required this.home,
    this.initialIndex = 0,
    this.initialExploreMetier,
    this.initialExploreQuery = '',
  });

  @override
  ConsumerState<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends ConsumerState<DashboardShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  @override
  void didUpdateWidget(covariant DashboardShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      _index = widget.initialIndex;
    }
  }

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

    // Pages et destinations selon le rôle (Client vs Pro)
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
            ExploreScreen(
              initialMetier: widget.initialExploreMetier,
              initialQuery: widget.initialExploreQuery,
            ),
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

    // RÈGLE DE RESPONSIVE RÉEL :
    // < 600dp : BottomNavigationBar
    // 600 - 839dp : NavigationRail (tablette)
    // >= 840dp : NavigationRail étendu / sidebar desktop
    final isMobile = width < 600;
    final isDesktop = width >= 840;

    if (isMobile) {
      return Scaffold(
        key: _scaffoldKey,
        drawer: _buildMobileDrawer(context, user, loc, isPro),
        body: DashboardMenuScope(
          onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
          child: IndexedStack(
            index: _index.clamp(0, pages.length - 1),
            children: pages,
          ),
        ),
      );
    }

    // Tablette & Desktop : PAS de BottomNavigationBar, NavigationRail / Sidebar
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
                  const BrandLogo(height: 36),
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

  Widget _buildMobileDrawer(
    BuildContext context,
    AppUser user,
    AppLocalizations loc,
    bool isPro,
  ) {
    final requestIndex = isPro ? 1 : 2;
    final messageIndex = isPro ? 2 : 3;
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Row(
                children: [
                  const BrandLogo(height: 38),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      user.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
            _drawerItem(
              context,
              icon: Icons.home_outlined,
              label: isPro ? loc.dashboardTab : loc.homeTab,
              selected: _index == 0,
              onTap: () => _selectDrawerPage(0),
            ),
            if (!isPro)
              _drawerItem(
                context,
                icon: Icons.search,
                label: loc.exploreTab,
                selected: _index == 1,
                onTap: () => _selectDrawerPage(1),
              ),
            _drawerItem(
              context,
              icon: Icons.assignment_outlined,
              label: loc.requestsTab,
              selected: _index == requestIndex,
              onTap: () => _selectDrawerPage(requestIndex),
            ),
            _drawerItem(
              context,
              icon: Icons.chat_bubble_outline,
              label: loc.messagesTab,
              selected: _index == messageIndex,
              onTap: () => _selectDrawerPage(messageIndex),
            ),
            _drawerItem(
              context,
              icon: Icons.person_outline,
              label: loc.profileTab,
              selected: _index == 4,
              onTap: () => _selectDrawerPage(4),
            ),
            _drawerItem(
              context,
              icon: Icons.settings_outlined,
              label: loc.settingsTab,
              selected: isPro && _index == 3,
              onTap: () {
                _closeDrawer();
                if (isPro) {
                  setState(() => _index = 3);
                } else {
                  context.push('/settings');
                }
              },
            ),
            const Divider(),
            _drawerItem(
              context,
              icon: Icons.logout,
              label: loc.logout,
              onTap: () => _signOut(context, loc),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      selected: selected,
      onTap: onTap,
    );
  }

  void _selectDrawerPage(int index) {
    _closeDrawer();
    setState(() => _index = index);
  }

  void _closeDrawer() => _scaffoldKey.currentState?.closeDrawer();

  Future<void> _signOut(BuildContext context, AppLocalizations loc) async {
    _closeDrawer();
    try {
      await FirebaseService().signOut();
      if (context.mounted) context.go('/login');
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'DashboardShell',
          context: ErrorDescription('while signing out from the mobile menu'),
        ),
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loc.text(
              'La déconnexion a échoué. Réessayez.',
              'Sign out failed. Please try again.',
            ),
          ),
        ),
      );
    }
  }
}
