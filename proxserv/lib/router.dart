import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proxserv/data/models/app_user.dart';
import 'application/providers/app_providers.dart';
import 'data/models/enums.dart';
import 'data/models/professional_profile.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/register_screen.dart';
import 'presentation/screens/client_home_screen.dart';
import 'presentation/screens/public_landing_screen.dart';
import 'presentation/screens/professional_dashboard_screen.dart';
import 'presentation/screens/professional_detail_screen.dart';
import 'presentation/screens/admin_dashboard_screen.dart';
import 'presentation/screens/blocked_screen.dart';
import 'presentation/screens/request_form_screen.dart';
import 'presentation/screens/map_screen.dart';
import 'presentation/screens/chat/chat_screen.dart';
import 'presentation/screens/dashboard/dashboard_shell.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/navigation/chat_route.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // IMPORTANT : on ne fait plus `ref.watch(currentUserProvider)` ici.
  // Avant, chaque émission (y compris une simple écriture de profil ou un
  // changement de préférence) recréait tout le GoRouter et ramenait
  // l'utilisateur à l'accueil.
  //
  // `ref.listen` (contrairement à `ref.watch`) ne reconstruit pas ce
  // provider : il se contente de prévenir `refreshNotifier`, qui dit à
  // go_router de ré-exécuter `redirect`. Comme `redirect` lit sa valeur
  // via ce même `currentUserProvider`, il n'y a aucun risque de lire une
  // valeur pas encore à jour (plus de flux Firebase séparé à synchroniser).
  final refreshNotifier = ValueNotifier<int>(0);
  ref.listen<AsyncValue<AppUser?>>(
    currentUserProvider,
    (_, _) => refreshNotifier.value++,
  );
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    // Redirection automatique selon l'état d'authentification et le rôle
    redirect: (context, state) {
      // `read`, pas `watch` : on veut la valeur la plus récente au moment de
      // la redirection, sans dépendre de ce provider pour reconstruire le
      // router.
      final authStateAsync = ref.read(currentUserProvider);

      // Si les données utilisateur sont encore en cours de chargement, on ne redirige pas encore
      if (authStateAsync.isLoading) return null;

      final user = authStateAsync.value;
      final isLoggingIn =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      final isPublicExplore = state.matchedLocation == '/explore';

      // Cas 1 : l'utilisateur n'est PAS connecté
      if (user == null) {
        return isLoggingIn || isPublicExplore || state.matchedLocation == '/'
            ? null
            : '/login';
      }

      // Cas 2 : le compte a été bloqué par un administrateur — priorité
      // absolue sur toute autre redirection, sauf si on est déjà sur
      // l'écran dédié (pour ne pas boucler).
      if (user.bloque) {
        return state.matchedLocation == '/blocked' ? null : '/blocked';
      }

      // Cas 3 : l'utilisateur est connecté et tente d'aller sur Login/Register,
      // vient d'ouvrir l'application à la racine '/', ou était bloqué puis
      // vient d'être débloqué (encore sur /blocked)
      if (isLoggingIn ||
          state.matchedLocation == '/' ||
          state.matchedLocation == '/blocked' ||
          isPublicExplore) {
        // Routage selon le rôle enregistré dans le document Firestore
        switch (user.role) {
          case UserRole.admin:
            return '/admin/dashboard';
          case UserRole.professionnel:
            return '/professional/dashboard';
          case UserRole.client:
            if (isPublicExplore ||
                state.uri.queryParameters.containsKey('metier') ||
                state.uri.queryParameters.containsKey('q')) {
              final query = <String, String>{
                'tab': 'explore',
                if (state.uri.queryParameters['metier'] != null)
                  'metier': state.uri.queryParameters['metier']!,
                if (state.uri.queryParameters['q'] != null)
                  'q': state.uri.queryParameters['q']!,
              };
              return Uri(
                path: '/client/home',
                queryParameters: query,
              ).toString();
            }
            return '/client/home';
        }
      }

      final location = state.matchedLocation;
      final isClientRoute =
          location.startsWith('/client/') || location == '/map';
      final isProfessionalRoute = location.startsWith('/professional/');
      final isAdminRoute = location.startsWith('/admin/');
      switch (user.role) {
        case UserRole.client:
          if (isProfessionalRoute || isAdminRoute) return '/client/home';
        case UserRole.professionnel:
          if (isClientRoute || isAdminRoute) {
            return '/professional/dashboard';
          }
        case UserRole.admin:
          if (isClientRoute || isProfessionalRoute) {
            return '/admin/dashboard';
          }
      }

      // Pas de redirection nécessaire pour les autres routes
      return null;
    },

    // Déclaration de toutes les routes de l'application
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const PublicLandingScreen(),
      ),
      GoRoute(
        path: '/explore',
        builder: (context, state) {
          final metierName = state.uri.queryParameters['metier'];
          final metier = metierName == null
              ? null
              : Metier.fromName(metierName);
          return PublicExploreScreen(
            initialMetier:
                metier == Metier.autre ? null : metier,
            initialQuery: state.uri.queryParameters['q'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/login',
        // onSignedIn/onRegistered ne naviguent pas eux-mêmes : c'est le
        // redirect ci-dessus (déclenché par currentUserProvider) qui
        // s'en charge dès que le rôle est connu — évite une double
        // navigation entre le Navigator interne et GoRouter.
        builder: (context, state) => LoginScreen(onSignedIn: (_) {}),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => RegisterScreen(onRegistered: (_) {}),
      ),
      GoRoute(path: '/blocked', builder: (context, state) => BlockedScreen()),
      // --- ESPACE CLIENT ---
      GoRoute(
        path: '/client/home',
        builder: (context, state) {
          final metierName = state.uri.queryParameters['metier'];
          final metier = metierName == null
              ? null
              : Metier.fromName(metierName);
          final initialQuery = state.uri.queryParameters['q'] ?? '';
          final initialIndex = switch (state.uri.queryParameters['tab']) {
            'requests' => 2,
            'explore' => 1,
            _ => metier != null || initialQuery.isNotEmpty ? 1 : 0,
          };
          return DashboardShell(
            home: const ClientHomeScreen(),
            initialIndex: initialIndex,
            initialExploreMetier:
                metier == Metier.autre ? null : metier,
            initialExploreQuery:
                metier == null || metier == Metier.autre ? initialQuery : '',
          );
        },
      ),
      GoRoute(
        path: '/client/explore',
        builder: (context, state) {
          final metierName = state.uri.queryParameters['metier'];
          final metier = metierName == null
              ? null
              : Metier.fromName(metierName);
          return DashboardShell(
            home: const ClientHomeScreen(),
            initialIndex: 1,
            initialExploreMetier:
                metier == Metier.autre ? null : metier,
            initialExploreQuery:
                metier == null || metier == Metier.autre
                    ? state.uri.queryParameters['q'] ?? ''
                    : '',
          );
        },
      ),
      GoRoute(
        path: '/client/professional',
        builder: (context, state) {
          final profile = state.extra;
          if (profile is! ProfessionalProfile) {
            return _professionalUnavailable(context);
          }
          return ProfessionalDetailScreen(profile: profile);
        },
      ),
      GoRoute(
        path: '/client/request-form',
        builder: (context, state) {
          final profile = state.extra;
          if (profile is! ProfessionalProfile) {
            return _professionalUnavailable(context);
          }
          return RequestFormScreen(professional: profile);
        },
      ),
      GoRoute(
        path: '/map',
        builder: (context, state) => MapScreen(
          professionals:
              (state.extra as List<ProfessionalProfile>?) ?? const [],
          onSelect: (pro) => context.push('/client/professional', extra: pro),
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      // --- ESPACE PROFESSIONNEL ---

      GoRoute(
        path: '/professional/dashboard',
        builder: (context, state) =>
            const DashboardShell(home: ProfessionalDashboardScreen()),
      ),
      // Conversation rattachée à une demande, commune aux deux rôles.
      GoRoute(
        path: chatRoutePattern,
        builder: (context, state) =>
            ChatScreen(requestId: state.pathParameters[chatRequestIdParam]!),
      ),
      // --- ESPACE ADMIN ---
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => AdminDashboardScreen(),
      ),
    ],
    // Gestion globale d'une page d'erreur 404
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page introuvable : ${state.error}')),
    ),
  );
});

/// Écran affiché quand on ouvre `/client/professional` ou `/client/request-form`
/// sans profil passé en `state.extra`.
///
/// Ces deux routes sont atteintes depuis une liste de professionnels : si le
/// document n'a pas pu être lu, on ne peut pas ouvrir la fiche ni le
/// formulaire. On propose un retour plutôt que de laisser un ecran vide.
Widget _professionalUnavailable(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text('Professionnel indisponible')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ce profil n est plus accessible.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/client/home'),
              child: const Text('Retour a l accueil'),
            ),
          ],
        ),
      ),
    ),
  );
}
