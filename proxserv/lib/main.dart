import 'package:firebase_core/firebase_core.dart' hide FirebaseService;
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';

import 'data/models/app_user.dart';
import 'data/services/firebase_service.dart';
import 'firebase_options.dart';
import 'presentation/screens/client_home_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/professional_dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProxServApp());
}

class ProxServApp extends StatelessWidget {
  const ProxServApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ProxServ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const AuthGate(),
    );
  }
}

/// Point d'entrée qui décide quel écran afficher : connexion si personne
/// n'est connecté, sinon le bon accueil selon le rôle (client ou
/// professionnel). C'est ici, et seulement ici, qu'on interroge le rôle —
/// chaque écran reste indépendant du reste de l'app.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _service = FirebaseService();

  // Envoie l'utilisateur vers le bon accueil une fois connecté/inscrit.
  // Utilisé à la fois par LoginScreen (onSignedIn) et RegisterScreen
  // (onRegistered) — les deux ont exactement la même signature.
  void _goHome(AppUser user) {
    final target = user.role == UserRole.professionnel
        ? ProfessionalDashboardScreen(
            professionalId: user.uid,
            firebaseService: _service,
            onLogout: () => _backToLogin(),
          )
        : ClientHomeScreen(
            firebaseService: _service,
            onLogout: () => _backToLogin(),
          );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => target),
      (route) => false,
    );
  }

  void _backToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<fb_auth.User?>(
      stream: _service.authStateChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }

        final firebaseUser = authSnapshot.data;
        if (firebaseUser == null) {
          return LoginScreen(firebaseService: _service, onSignedIn: _goHome);
        }

        // Connecté : on récupère son rôle avant de choisir l'écran.
        return FutureBuilder<AppUser?>(
          future: _service.fetchAppUser(firebaseUser.uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const _SplashScreen();
            }
            final appUser = userSnapshot.data;
            if (appUser == null) {
              // Profil introuvable (rare, ex. compte créé hors app) :
              // on ramène vers la connexion plutôt que de bloquer l'écran.
              return LoginScreen(firebaseService: _service, onSignedIn: _goHome);
            }
            return appUser.role == UserRole.professionnel
                ? ProfessionalDashboardScreen(
                    professionalId: appUser.uid,
                    firebaseService: _service,
                    onLogout: _backToLogin,
                  )
                : ClientHomeScreen(
                    firebaseService: _service,
                    onLogout: _backToLogin,
                  );
          },
        );
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}