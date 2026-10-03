import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proxserv/data/models/app_user.dart';
import 'application/providers/app_providers.dart';
import 'data/models/professional_profile.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/register_screen.dart';
import 'presentation/screens/client_home_screen.dart';
import 'presentation/screens/professional_dashboard_screen.dart';
import 'presentation/screens/professional_detail_screen.dart';
import 'presentation/screens/admin_dashboard_screen.dart';
import 'presentation/screens/blocked_screen.dart';
import 'presentation/screens/request_form_screen.dart';
import 'presentation/screens/map_screen.dart';
import 'presentation/screens/chat/chat_screen.dart';
import 'presentation/screens/dashboard/dashboard_shell.dart';
import 'presentation/navigation/chat_route.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // On écoute le statut de l'utilisateur pour forcer une réévaluation des routes s'il change
  final authStateAsync = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/',
    // Redirection automatique selon l'état d'authentification et le rôle
    redirect: (context, state) {
      // Si les données utilisateur sont encore en cours de chargement, on ne redirige pas encore
      if (authStateAsync.isLoading) return null;

      final user = authStateAsync.value;
      final isLoggingIn =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      // Cas 1 : l'utilisateur n'est PAS connecté
      if (user == null) {
        // S'il n'est pas sur une page d'authentification, on le renvoie vers le Login
        return isLoggingIn ? null : '/login';
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
          state.matchedLocation == '/blocked') {
        // Routage selon le rôle enregistré dans le document Firestore
        switch (user.role) {
          case UserRole.admin:
            return '/admin/dashboard';
          case UserRole.professionnel:
            return '/professional/dashboard';
          case UserRole.client:
            return '/client/home';
        }
      }

      // Pas de redirection nécessaire pour les autres routes
      return null;
    },

    // Déclaration de toutes les routes de l'application
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(
        path: '/login',
        // onSignedIn/onRegistered ne naviguent pas eux-mêmes : c'est le
        // redirect ci-dessus (déclenché par currentUserProvider) qui
        // s'en charge dès que le rôle est connu — évite une double
        // navigation entre le Navigator interne et GoRouter.
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(path: '/blocked', builder: (context, state) => BlockedScreen()),
      // --- ESPACE CLIENT ---
      GoRoute(
        path: '/client/home',
        builder: (context, state) => DashboardShell(
          // Ici on branche vraiment la fiche professionnel : au clic sur
          // un professionnel, on pousse la route dédiée en lui passant le
          // profil sélectionné.
          home: ClientHomeScreen(
            onSelect: (pro) => context.push('/client/professional', extra: pro),
          ),
        ),
      ),
      GoRoute(
        path: '/client/professional',
        builder: (context, state) => ProfessionalDetailScreen(
          profile: state.extra as ProfessionalProfile,
        ),
      ),
      GoRoute(
        path: '/client/request-form',
        builder: (context, state) =>
            RequestFormScreen(professional: state.extra as ProfessionalProfile),
      ),
      GoRoute(
        path: '/map',
        builder: (context, state) => MapScreen(
          professionals:
              (state.extra as List<ProfessionalProfile>?) ?? const [],
          onSelect: (pro) => context.push('/client/professional', extra: pro),
        ),
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
