import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/app_localizations.dart';
import '../../data/models/app_user.dart';
import '../../data/models/enums.dart';
import '../../data/services/firebase_service.dart';
import 'login_screen.dart' show authErrorMessage;

// Écran d'inscription : compte client ou professionnel.
// Pour un professionnel, le métier et la zone d'intervention sont aussi
// demandés et envoyés au FirebaseService (qui crée le profil professionnel).
class RegisterScreen extends StatefulWidget {
  final FirebaseService? firebaseService;

  // Appelé une fois le compte créé, pour que le router puisse rediriger
  // selon le rôle. Si null, on ouvre l'accueil client.
  final void Function(AppUser user)? onRegistered;

  const RegisterScreen({super.key, this.firebaseService, this.onRegistered});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _zoneController = TextEditingController();

  late final FirebaseService _service;

  UserRole _role = UserRole.client;
  Metier? _metier;
  bool _obscurePassword = true;
  bool _loading = false;
  String? _error;

  bool get _isPro => _role == UserRole.professionnel;

  @override
  void initState() {
    super.initState();
    _service = widget.firebaseService ?? FirebaseService();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _zoneController.dispose();
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
      final user = await _service.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        role: _role,
        metier: _metier,
        zoneIntervention: _isPro ? _zoneController.text.trim() : null,
      );
      if (!mounted) return;

      final onRegistered = widget.onRegistered;
      if (onRegistered != null) {
        onRegistered(user);
      }
    } on FirebaseAuthException catch (e, st) {
      // Le code exact apparaît dans la console : c'est lui qui explique le 400.
      debugPrint('signUp FirebaseAuthException: ${e.code} | ${e.message}');
      debugPrintStack(stackTrace: st, maxFrames: 5);
      if (!mounted) return;
      setState(() => _error = _signUpErrorMessage(e));
    } catch (e, st) {
      // Erreur non-Auth (ex. échec d'écriture du profil dans Firestore).
      debugPrint('signUp erreur inattendue: $e');
      debugPrintStack(stackTrace: st, maxFrames: 5);
      if (!mounted) return;
      setState(() {
        _error = kDebugMode
            ? 'Inscription impossible : $e'
            : 'Inscription impossible. Réessayez.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Messages précis pour les erreurs d'inscription ; sinon on retombe sur
  // le message générique partagé (authErrorMessage).
  String _signUpErrorMessage(FirebaseAuthException e) {
    final loc = AppLocalizations.fromContext(context);
    final raw = '${e.code} ${e.message ?? ''}'.toUpperCase();
    // En développement, on ajoute le code brut pour diagnostiquer vite.
    final suffix = kDebugMode ? ' [${e.code}]' : '';

    if (raw.contains('RECAPTCHA')) {
      return '${loc.text('Vérification de sécurité échouée (reCAPTCHA). Réessayez ou contactez le support.', 'Security verification failed (reCAPTCHA). Try again or contact support.')}$suffix';
    }
    if (raw.contains('OPERATION_NOT_ALLOWED') ||
        raw.contains('OPERATION-NOT-ALLOWED')) {
      return '${loc.text('L\'inscription par e-mail n\'est pas activée sur le serveur.', 'Email registration is not enabled on the server.')}$suffix';
    }
    if (raw.contains('CONFIGURATION_NOT_FOUND') ||
        raw.contains('API_KEY') ||
        raw.contains('API KEY')) {
      return '${loc.text('Configuration Firebase invalide. Contactez le support.', 'Invalid Firebase configuration. Contact support.')}$suffix';
    }
    if (raw.contains('NETWORK')) {
      return '${loc.text('Problème de connexion. Vérifiez votre réseau.', 'Connection problem. Check your network.')}$suffix';
    }
    return '${authErrorMessage(e, loc)}$suffix';
  }

  void _selectRole(UserRole role) {
    setState(() {
      _role = role;
      // Le métier n'a de sens que pour un professionnel.
      if (role == UserRole.client) _metier = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.fromContext(context);

    return Scaffold(
      appBar: AppBar(title: Text(loc.registerTitle)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 64,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                    Text(
                      loc.text('Rejoignez ProxServ', 'Join ProxServ'),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loc.text(
                        'Remplissez le formulaire pour créer votre compte.',
                        'Complete the form to create your account.',
                      ),
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    if (_error != null) ...[
                      _RegisterErrorBanner(message: _error!),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      loc.text('Je suis', 'I am a'),
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<UserRole>(
                      segments: [
                        ButtonSegment(
                          value: UserRole.client,
                          icon: Icon(Icons.person_outline),
                          label: Text(loc.iAmClient),
                        ),
                        ButtonSegment(
                          value: UserRole.professionnel,
                          icon: Icon(Icons.handyman_outlined),
                          label: Text(loc.iAmPro),
                        ),
                      ],
                      selected: {_role},
                      onSelectionChanged: (selection) =>
                          _selectRole(selection.first),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: loc.fullNameLabel,
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (value) => (value?.trim().isEmpty ?? true)
                          ? loc.text(
                              'Saisissez votre nom complet.',
                              'Enter your full name.',
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9+\s().-]'),
                        ),
                      ],
                      decoration: InputDecoration(
                        labelText: loc.phoneLabel,
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: _validatePhone,
                    ),
                    const SizedBox(height: 16),
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
                      textInputAction: TextInputAction.next,
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmController,
                      obscureText: _obscurePassword,
                      // Pour un professionnel, d'autres champs suivent.
                      textInputAction: _isPro
                          ? TextInputAction.next
                          : TextInputAction.done,
                      onFieldSubmitted: (_) {
                        if (!_isPro && !_loading) _submit();
                      },
                      decoration: InputDecoration(
                        labelText: loc.confirmPasswordLabel,
                        prefixIcon: Icon(Icons.lock_reset_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return loc.text(
                            'Confirmez votre mot de passe.',
                            'Confirm your password.',
                          );
                        }
                        if (value != _passwordController.text) {
                          return loc.text(
                            'Les deux mots de passe ne correspondent pas.',
                            'The passwords do not match.',
                          );
                        }
                        return null;
                      },
                    ),
                    if (_isPro) ...[
                      const SizedBox(height: 24),
                      DropdownButtonFormField<Metier>(
                        // `value` fonctionne sur toutes les versions de Flutter
                        // (initialValue n'existe que sur les plus récentes).
                        initialValue: _metier,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: loc.text('Métier', 'Trade'),
                          prefixIcon: Icon(Icons.handyman_outlined),
                        ),
                        items: [
                          for (final metier in Metier.values)
                            DropdownMenuItem<Metier>(
                              value: metier,
                              child: Row(
                                children: [
                                  Icon(metierIcon(metier), size: 20),
                                  const SizedBox(width: 12),
                                  Text(loc.metierLabel(metier)),
                                ],
                              ),
                            ),
                        ],
                        onChanged: (value) => setState(() => _metier = value),
                        validator: (value) {
                          if (!_isPro) return null;
                          return value == null
                              ? loc.text(
                                  'Choisissez votre métier.',
                                  'Choose your trade.',
                                )
                              : null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _zoneController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) {
                          if (!_loading) _submit();
                        },
                        decoration: InputDecoration(
                          labelText: loc.text(
                            'Zone d\'intervention',
                            'Service area',
                          ),
                          hintText: loc.text(
                            'Ex. Cocody, Abidjan',
                            'e.g. Cocody, Abidjan',
                          ),
                          prefixIcon: Icon(Icons.map_outlined),
                        ),
                        validator: (value) {
                          if (!_isPro) return null;
                          return (value?.trim().isEmpty ?? true)
                              ? loc.text(
                                  'Indiquez votre zone d\'intervention.',
                                  'Enter your service area.',
                                )
                              : null;
                        },
                      ),
                    ],
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
                          : Text(loc.registerTitle),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _loading ? null : () => context.go('/login'),
                      child: Text(loc.hasAccount),
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
      return loc.text('Saisissez un mot de passe.', 'Enter a password.');
    }
    if (password.length < 6) {
      return loc.text(
        'Le mot de passe doit contenir au moins 6 caractères.',
        'Password must be at least 6 characters.',
      );
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final loc = AppLocalizations.fromContext(context);
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) {
      return loc.text(
        'Saisissez votre numéro de téléphone.',
        'Enter your phone number.',
      );
    }
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 8) {
      return loc.text(
        'Ce numéro semble incomplet.',
        'This number seems incomplete.',
      );
    }
    return null;
  }
}

// Bandeau d'erreur de l'écran d'inscription.
class _RegisterErrorBanner extends StatelessWidget {
  final String message;

  const _RegisterErrorBanner({required this.message});

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

// Icône représentative d'un métier. Partagée avec client_home_screen, qui
// affiche elle aussi la liste des professionnels par métier.
IconData metierIcon(Metier metier) {
  switch (metier) {
    case Metier.plombier:
      return Icons.plumbing;
    case Metier.electricien:
      return Icons.bolt;
    case Metier.macon:
      return Icons.foundation;
    case Metier.menuisier:
      return Icons.carpenter;
    case Metier.peintre:
      return Icons.format_paint;
    case Metier.reparateur:
      return Icons.build_outlined;
    case Metier.nettoyage:
      return Icons.cleaning_services;
    case Metier.autre:
      return Icons.handyman_outlined;
  }
}
