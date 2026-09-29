import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/models/app_user.dart';
import '../../data/services/firebase_service.dart';
import 'client_home_screen.dart';
import 'register_screen.dart';

// Traduit une erreur Firebase en un message compréhensible par l'utilisateur.
// Partagée par login_screen et register_screen.
String authErrorMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-email':
      return 'Cette adresse e-mail n\'est pas valide.';
    case 'user-disabled':
      return 'Ce compte a été désactivé.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'E-mail ou mot de passe incorrect.';
    case 'email-already-in-use':
      return 'Un compte existe déjà avec cette adresse e-mail.';
    case 'weak-password':
      return 'Le mot de passe doit contenir au moins 6 caractères.';
    case 'too-many-requests':
      return 'Trop de tentatives. Réessayez dans quelques instants.';
    case 'network-request-failed':
      return 'Pas de connexion internet. Vérifiez votre réseau.';
    default:
      return 'Une erreur est survenue. Réessayez.';
  }
}

// Écran de connexion : e-mail + mot de passe.
class LoginScreen extends StatefulWidget {
  final FirebaseService? firebaseService;

  // Appelé une fois la connexion réussie, pour que le router puisse rediriger
  // selon le rôle (client ou professionnel). Si null, on ouvre l'accueil client.
  final void Function(AppUser user)? onSignedIn;

  const LoginScreen({super.key, this.firebaseService, this.onSignedIn});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final FirebaseService _service;
  bool _obscurePassword = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = widget.firebaseService ?? FirebaseService();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _service.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;

      final uid = _service.currentUser?.uid;
      final user = uid == null ? null : await _service.fetchAppUser(uid);
      if (!mounted) return;

      final onSignedIn = widget.onSignedIn;
      if (onSignedIn != null && user != null) {
        onSignedIn(user);
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const ClientHomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = authErrorMessage(e));
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Connexion impossible. Réessayez.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RegisterScreen(firebaseService: _service),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.home_work_outlined,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ProxServ',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Trouvez un professionnel près de chez vous',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 32),
                    if (_error != null) ...[
                      _ErrorBanner(message: _error!),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Adresse e-mail',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _loading ? null : _submit(),
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          tooltip: _obscurePassword
                              ? 'Afficher le mot de passe'
                              : 'Masquer le mot de passe',
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text('Se connecter'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _loading ? null : _goToRegister,
                      child: const Text("Pas encore de compte ? S'inscrire"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Saisissez votre adresse e-mail.';
    if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(email)) {
      return 'Cette adresse e-mail n\'est pas valide.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Saisissez votre mot de passe.';
    if (password.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères.';
    }
    return null;
  }
}

// Bandeau d'erreur utilisé par les écrans d'authentification.
class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colors.onErrorContainer, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
