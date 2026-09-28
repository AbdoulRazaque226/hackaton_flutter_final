import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Importations de vos applications / providers
import 'application/providers/app_providers.dart';

// Importations des écrans créés par vos camarades (Esther, Moutala) et vous-même
// import 'presentation/screens/login_screen.dart';
// import 'presentation/screens/register_screen.dart';
// import 'presentation/screens/client_home_screen.dart';
// import 'presentation/screens/professional_dashboard_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // On écoute le statut de l'utilisateur pour forcer une réévaluation des routes s'il change
  final authStateAsync = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/',
    //Redirection automatique selon l'état d'authentification et le rôle
    redirect: (context, state) {
      // Si les données utilisateur sont encore en cours de chargement, on ne redirige pas encore
      if (authStateAsync.isLoading) return null;

      final user = authStateAsync.value;
      final isLoggingIn =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      //Cas 1: L'utilisateur n'est PAS connecté
      if (user == null) {
        // S'il n'est pas sur une page d'authentification, on le renvoie vers le Login
        return isLoggingIn ? null : '/login';
      }

      //Cas 2 : L'utilisateur est connecté et tente d'aller sur Login/Register
      if (isLoggingIn) {
        // Routage selon le rôle enregistré dans le document Firestore
        return user.role == 'professionnel'
            ? '/professional/dashboard'
            : '/client/home';
      }

      //Cas3 : L'utilisateur ouvre l'application à la racine '/'
      if (state.matchedLocation == '/') {
        return user.role == 'professionnel'
            ? '/professional/dashboard'
            : '/client/home';
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
      // GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      // GoRoute(
      //   path: '/register',
      //   builder: (context, state) => const RegisterScreen(),
      // ),
      // // --- ESPACE CLIENT ---
      // GoRoute(
      //   path: '/client/home',
      //   builder: (context, state) => const ClientHomeScreen(),
      // ),
      // // --- ESPACE PROFESSIONNEL---
      // GoRoute(
      //   path: '/professional/dashboard',
      //   builder: (context, state) => const ProfessionalDashboardScreen(),
      // ),
    ],
    //Gestion globale d'une page d'erreur 404
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page introuvable : ${state.error}')),
    ),
  );
});
