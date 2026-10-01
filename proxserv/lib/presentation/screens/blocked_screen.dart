import 'package:flutter/material.dart';

import '../../data/services/firebase_service.dart';
import 'login_screen.dart';

/// Affiché à la place de l'accueil habituel quand le compte connecté a
/// bloque == true (voir router.dart). Empêche l'accès au reste de l'app
/// sans avoir à dupliquer la vérification dans chaque écran.
class BlockedScreen extends StatelessWidget {
  final FirebaseService firebaseService;
  final void Function()? onLogout;

  BlockedScreen({super.key, FirebaseService? firebaseService, this.onLogout})
      : firebaseService = firebaseService ?? FirebaseService();

  Future<void> _logout(BuildContext context) async {
    await firebaseService.signOut();
    if (onLogout != null) {
      onLogout!();
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.block, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Compte bloqué',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  "Votre compte a été suspendu par un administrateur. "
                  "Contactez le support de ProxServ si vous pensez qu'il "
                  "s'agit d'une erreur.",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Se déconnecter'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
