import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/app_localizations.dart';
import '../../data/models/app_user.dart';
import '../../data/services/firebase_service.dart';
import '../widgets/brand_logo.dart';

// Traduit une erreur Firebase en un message compréhensible par l'utilisateur.
String authErrorMessage(FirebaseAuthException e, [AppLocalizations? loc]) {
  String text(String french, String english) =>
      loc?.text(french, english) ?? french;

  switch (e.code) {
    case 'invalid-email':
      return text(
        'Cette adresse e-mail n\'est pas valide.',
        'This email address is invalid.',
      );
    case 'user-disabled':
      return text(
        'Ce compte a été désactivé.',
        'This account has been disabled.',
      );
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return text(
        'E-mail ou mot de passe incorrect.',
        'Incorrect email or password.',
      );
    case 'email-already-in-use':
      return text(
        'Un compte existe déjà avec cette adresse e-mail.',
        'An account already exists for this email.',
      );
    case 'weak-password':
      return text(
        'Le mot de passe doit contenir au moins 6 caractères.',
        'Password must be at least 6 characters.',
      );
    case 'too-many-requests':
      return text(
        'Trop de tentatives. Réessayez dans quelques instants.',
        'Too many attempts. Try again shortly.',
      );
    case 'network-request-failed':
      return text(
        'Pas de connexion internet. Vérifiez votre réseau.',
        'No internet connection. Check your network.',
      );
    default:
      return text(
        'Une erreur est survenue. Réessayez.',
        'Something went wrong. Please try again.',
      );
  }
}

/// Écran de connexion avec logo officiel ProxServ.
class LoginScreen extends StatefulWidget {
  final FirebaseService? firebaseService;
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
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(
        () =>
            _error = authErrorMessage(e, AppLocalizations.fromContext(context)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error = AppLocalizations.fromContext(context).text(
          'Connexion impossible. Réessayez.',
          'Unable to sign in. Please try again.',
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goToRegister() {
    context.go('/register');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.fromContext(context);

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
                    // LOGO OFFICIEL PROXSERV (pas d'icône générique)
                    Center(
                      child: const BrandLogo(height: 80),
                    ),
                    const SizedBox(height: 12),
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
                      loc.text(
                        'Trouvez un professionnel près de chez vous',
                        'Find a professional near you',
                      ),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
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
                      decoration: InputDecoration(
                        labelText: loc.emailLabel,
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
                        labelText: loc.passwordLabel,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          tooltip: _obscurePassword
                              ? loc.text(
                                  'Afficher le mot de passe',
                                  'Show password',
                                )
                              : loc.text(
                                  'Masquer le mot de passe',
                                  'Hide password',
                                ),
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
                                color: Colors.white,
                              ),
                            )
                          : Text(loc.loginTitle),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _loading ? null : _goToRegister,
                      child: Text(loc.noAccount),
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
    final loc = AppLocalizations.fromContext(context);
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return loc.text(
        'Saisissez votre adresse e-mail.',
        'Enter your email address.',
      );
    }
    if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(email)) {
      return loc.text(
        'Cette adresse e-mail n\'est pas valide.',
        'This email address is invalid.',
      );
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final loc = AppLocalizations.fromContext(context);
    final password = value ?? '';
    if (password.isEmpty) {
      return loc.text('Saisissez votre mot de passe.', 'Enter your password.');
    }
    if (password.length < 6) {
      return loc.text(
        'Le mot de passe doit contenir au moins 6 caractères.',
        'Password must be at least 6 characters.',
      );
    }
    return null;
  }
}

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
