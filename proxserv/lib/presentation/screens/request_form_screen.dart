import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/app_localizations.dart';
import '../../data/models/app_user.dart';
import '../../data/models/professional_profile.dart';
import '../../data/services/firebase_service.dart';
import '../../data/services/location_service.dart';
import '../navigation/chat_route.dart';

/// Écran de création d'une demande d'intervention.
class RequestFormScreen extends StatefulWidget {
  final ProfessionalProfile professional;
  final FirebaseService? firebaseService;
  final LocationService locationService;
  final AppUser? clientProfile;
  final String? clientId;
  final String? clientName;

  RequestFormScreen({
    super.key,
    required this.professional,
    this.firebaseService,
    LocationService? locationService,
    this.clientProfile,
    this.clientId,
    this.clientName,
  }) : locationService = locationService ?? LocationService();

  @override
  State<RequestFormScreen> createState() => _RequestFormScreenState();
}

enum _RequestLocationChoice { current, usual, other }

class _RequestFormScreenState extends State<RequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _neighborhoodController = TextEditingController();

  bool _isLoading = false;
  bool _isLocating = false;
  bool _locationTouched = false;
  Position? _currentPosition;
  late _RequestLocationChoice _locationChoice;
  AppUser? _clientProfile;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _clientProfile = widget.clientProfile;
    _locationChoice = _hasUsualLocation(widget.clientProfile)
        ? _RequestLocationChoice.usual
        : _RequestLocationChoice.other;
    if (widget.clientProfile == null && Firebase.apps.isNotEmpty) {
      _loadClientProfile();
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _neighborhoodController.dispose();
    super.dispose();
  }

  bool _hasUsualLocation(AppUser? user) =>
      user != null &&
      user.country.trim().isNotEmpty &&
      user.city.trim().isNotEmpty;

  Future<void> _loadClientProfile() async {
    try {
      final firebaseService = widget.firebaseService ?? FirebaseService();
      final user = firebaseService.currentUser;
      if (user == null) return;
      final profile = await firebaseService.fetchAppUser(user.uid);
      if (!mounted || profile == null) return;
      setState(() {
        _clientProfile = profile;
        if (!_locationTouched &&
            _locationChoice == _RequestLocationChoice.other &&
            _countryController.text.isEmpty &&
            _cityController.text.isEmpty &&
            _hasUsualLocation(profile)) {
          _locationChoice = _RequestLocationChoice.usual;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _locationError = AppLocalizations.fromContext(context).text(
          'Impossible de charger votre lieu habituel : $error',
          'Unable to load your usual location: $error',
        );
      });
    }
  }

  Future<void> _fetchLocation() async {
    setState(() {
      _isLocating = true;
      _locationError = null;
    });

    try {
      final pos = await widget.locationService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _locationTouched = true;
        _currentPosition = pos;
        _locationChoice = _RequestLocationChoice.current;
      });
    } on LocationException catch (e) {
      if (!mounted) return;
      final loc = AppLocalizations.fromContext(context);
      setState(() {
        _locationError = switch (e.problem) {
          LocationProblem.serviceDisabled => loc.text(
            'La localisation est désactivée.',
            'Location services are turned off.',
          ),
          LocationProblem.permissionDenied => loc.text(
            'La permission de localisation a été refusée.',
            'Location permission was denied.',
          ),
          LocationProblem.permissionDeniedForever => loc.text(
            'La permission est bloquée. Activez-la dans les réglages de l’application.',
            'Location permission is blocked. Enable it in app settings.',
          ),
        };
        _locationTouched = true;
        _locationChoice = _RequestLocationChoice.other;
      });
    } catch (error) {
      if (!mounted) return;
      final loc = AppLocalizations.fromContext(context);
      setState(() {
        _locationError = loc.text(
          'Impossible d\'obtenir la position actuelle : $error',
          'Unable to get your current location: $error',
        );
        _locationTouched = true;
        _locationChoice = _RequestLocationChoice.other;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  bool _validateRequestLocation(AppLocalizations loc) {
    switch (_locationChoice) {
      case _RequestLocationChoice.current:
        if (_currentPosition != null) return true;
        _locationError = loc.text(
          'La position actuelle n’est pas disponible. Choisissez une ville manuellement.',
          'Current location is unavailable. Choose a city manually.',
        );
        break;
      case _RequestLocationChoice.usual:
        if (_hasUsualLocation(_clientProfile)) return true;
        _locationError = loc.text(
          'Votre lieu habituel n’est pas renseigné. Choisissez une autre ville.',
          'Your usual location is not set. Choose another city.',
        );
        break;
      case _RequestLocationChoice.other:
        if (_countryController.text.trim().isNotEmpty &&
            _cityController.text.trim().isNotEmpty) {
          return true;
        }
        _locationError = loc.text(
          'Renseignez le pays et la ville de l’intervention.',
          'Enter the country and city for the service location.',
        );
        break;
    }
    return false;
  }

  Future<void> _submitForm() async {
    final loc = AppLocalizations.fromContext(context);
    if (!_formKey.currentState!.validate() ||
        !_validateRequestLocation(loc)) {
      setState(() {});
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final firebaseService = widget.firebaseService ?? FirebaseService();
      final user = firebaseService.currentUser;
      final effectiveClientId = widget.clientId ?? user?.uid;
      String effectiveClientName = widget.clientName ?? user?.displayName ?? '';

      if (effectiveClientName.isEmpty && user != null) {
        final appUser = await firebaseService.fetchAppUser(user.uid);
        if (appUser != null && appUser.displayName.isNotEmpty) {
          effectiveClientName = appUser.displayName;
        }
      }

      if (effectiveClientId == null || effectiveClientName.trim().isEmpty) {
        throw StateError(
          loc.text(
            'Le compte client est incomplet. Vérifiez votre profil avant de continuer.',
            'Client account details are incomplete. Check your profile before continuing.',
          ),
        );
      }

      final currentLocation = _locationChoice == _RequestLocationChoice.current
          ? _currentPosition
          : null;
      final selectedProfile = _locationChoice == _RequestLocationChoice.usual
          ? _clientProfile
          : null;
      final country = selectedProfile?.country ??
          (_locationChoice == _RequestLocationChoice.other
              ? _countryController.text.trim()
              : '');
      final city = selectedProfile?.city ??
          (_locationChoice == _RequestLocationChoice.other
              ? _cityController.text.trim()
              : '');
      final neighborhood = selectedProfile?.neighborhood ??
          (_locationChoice == _RequestLocationChoice.other
              ? _neighborhoodController.text.trim()
              : '');

      final requestId = await firebaseService.createRequest(
        clientId: effectiveClientId,
        clientName: effectiveClientName,
        professionalId: widget.professional.uid,
        metier: widget.professional.metier,
        description: _descriptionController.text.trim(),
        country: country,
        city: city,
        neighborhood: neighborhood,
        latitude: currentLocation?.latitude,
        longitude: currentLocation?.longitude,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loc.text(
              'Votre demande d\'intervention a été envoyée avec succès !',
              'Your service request was sent successfully.',
            ),
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Proposer le retour ou la redirection vers le suivi
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(loc.text('Demande envoyée', 'Request sent')),
          content: Text(
            loc.text(
              'Votre demande a bien été enregistrée et apparaît dans vos demandes.',
              'Your request has been saved and appears in Requests.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/client/home');
                }
              },
              child: Text(loc.text('Fermer', 'Close')),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go(chatRoutePath(requestId));
              },
              child: Text(loc.text('Envoyer un message', 'Send a message')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go('/client/home?tab=requests');
              },
              child: Text(loc.text('Voir mes demandes', 'View my requests')),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loc.text(
              'Erreur lors de l\'envoi de la demande : $e',
              'Unable to send request: $e',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.fromContext(context);
    final pro = widget.professional;

    return Scaffold(
      appBar: AppBar(title: Text(loc.requestFormTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Récapitulatif du professionnel
                  Card(
                    elevation: 1,
                    color: theme.colorScheme.surfaceContainerLow,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Icon(
                              Icons.build,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pro.displayName.isNotEmpty
                                      ? pro.displayName
                                      : loc.text(
                                          'Professionnel',
                                          'Professional',
                                        ),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${loc.text('Métier', 'Trade')}: ${loc.metierLabel(pro.metier)}',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    loc.text(
                      'Où avez-vous besoin du professionnel ?',
                      'Where do you need the professional?',
                    ),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _isLocating ? null : _fetchLocation,
                        icon: _isLocating
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.my_location),
                        label: Text(
                          loc.text(
                            'Utiliser ma position actuelle',
                            'Use my current location',
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _hasUsualLocation(_clientProfile)
                            ? () => setState(() {
                                _locationTouched = true;
                                _locationChoice = _RequestLocationChoice.usual;
                                _locationError = null;
                              })
                            : null,
                        icon: const Icon(Icons.home_outlined),
                        label: Text(
                          loc.text(
                            _hasUsualLocation(_clientProfile)
                                ? 'Lieu habituel : ${_clientProfile!.city}, ${_clientProfile!.country}'
                                : 'Lieu habituel non renseigné',
                            _hasUsualLocation(_clientProfile)
                                ? 'Usual location: ${_clientProfile!.city}, ${_clientProfile!.country}'
                                : 'Usual location not set',
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => setState(() {
                          _locationTouched = true;
                          _locationChoice = _RequestLocationChoice.other;
                          _locationError = null;
                        }),
                        icon: const Icon(Icons.public),
                        label: Text(
                          loc.text('Choisir une autre ville', 'Choose another city'),
                        ),
                      ),
                    ],
                  ),

                  if (_locationChoice == _RequestLocationChoice.current &&
                      _currentPosition != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        loc.text(
                          'Votre position GPS actuelle sera utilisée pour cette demande uniquement.',
                          'Your current GPS position will be used for this request only.',
                        ),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  if (_locationChoice == _RequestLocationChoice.usual &&
                      _hasUsualLocation(_clientProfile))
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        loc.text(
                          'Le lieu de cette demande sera ${_clientProfile!.city}, ${_clientProfile!.country}. Votre profil ne sera pas modifié.',
                          'This request will use ${_clientProfile!.city}, ${_clientProfile!.country}. Your profile will not be changed.',
                        ),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  if (_locationChoice == _RequestLocationChoice.other) ...[
                    const SizedBox(height: 10),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final country = TextFormField(
                          controller: _countryController,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: loc.text('Pays', 'Country'),
                            hintText: loc.text(
                              'Ex. Côte d’Ivoire',
                              'e.g. Côte d’Ivoire',
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (_) {
                            if (_locationError != null) {
                              setState(() => _locationError = null);
                            }
                          },
                          validator: (value) =>
                              _locationChoice == _RequestLocationChoice.other &&
                                  (value == null || value.trim().isEmpty)
                              ? loc.text('Indiquez le pays.', 'Enter a country.')
                              : null,
                        );
                        final city = TextFormField(
                          controller: _cityController,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: loc.text('Ville', 'City'),
                            hintText: loc.text('Ex. Abidjan', 'e.g. Abidjan'),
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (_) {
                            if (_locationError != null) {
                              setState(() => _locationError = null);
                            }
                          },
                          validator: (value) =>
                              _locationChoice == _RequestLocationChoice.other &&
                                  (value == null || value.trim().isEmpty)
                              ? loc.text('Indiquez la ville.', 'Enter a city.')
                              : null,
                        );
                        if (constraints.maxWidth < 520) {
                          return Column(
                            children: [
                              country,
                              const SizedBox(height: 10),
                              city,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: country),
                            const SizedBox(width: 10),
                            Expanded(child: city),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _neighborhoodController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: loc.text(
                          'Quartier / zone (facultatif)',
                          'Neighborhood / area (optional)',
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],

                  if (_locationError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        _locationError!,
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Description du besoin
                  Text(
                    loc.needDescription,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 5,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: loc.text(
                        'Décrivez brièvement votre problème ou votre besoin.',
                        'Briefly describe your problem or service need.',
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return loc.text(
                          'Veuillez saisir une description de votre besoin.',
                          'Describe the service you need.',
                        );
                      }
                      if (value.trim().length < 5) {
                        return loc.text(
                          'La description doit contenir au moins 5 caractères.',
                          'The description must contain at least 5 characters.',
                        );
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              loc.sendRequest,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
