import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/app_localizations.dart';
import '../../data/models/professional_profile.dart';
import '../../data/services/firebase_service.dart';
import '../../data/services/location_service.dart';

/// Écran de création d'une demande d'intervention.
class RequestFormScreen extends StatefulWidget {
  final ProfessionalProfile professional;
  final FirebaseService? firebaseService;
  final LocationService locationService;
  final String? clientId;
  final String? clientName;

  RequestFormScreen({
    super.key,
    required this.professional,
    this.firebaseService,
    LocationService? locationService,
    this.clientId,
    this.clientName,
  }) : locationService = locationService ?? LocationService();

  @override
  State<RequestFormScreen> createState() => _RequestFormScreenState();
}

class _RequestFormScreenState extends State<RequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  bool _isLocating = false;
  Position? _currentPosition;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
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
        _currentPosition = pos;
      });
    } on LocationException catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locationError = 'Impossible d\'obtenir la position actuelle.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  Future<void> _submitForm() async {
    final loc = AppLocalizations.fromContext(context);
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_currentPosition == null) {
      setState(() {
        _locationError = loc.text(
          'La position GPS est indisponible. La demande ne peut pas être envoyée sans position réelle.',
          'GPS location is unavailable. The request cannot be sent without a real location.',
        );
      });
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

      final lat = _currentPosition!.latitude;
      final lon = _currentPosition!.longitude;

      await firebaseService.createRequest(
        clientId: effectiveClientId,
        clientName: effectiveClientName,
        professionalId: widget.professional.uid,
        metier: widget.professional.metier,
        description: _descriptionController.text.trim(),
        latitude: lat,
        longitude: lon,
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

                  // Position GPS
                  Row(
                    children: [
                      Icon(Icons.location_on, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isLocating
                              ? loc.text(
                                  'Récupération de votre position...',
                                  'Getting your location...',
                                )
                              : _currentPosition != null
                              ? loc.gpsRecorded
                              : (_locationError ??
                                    loc.text(
                                      'Position non disponible',
                                      'Location unavailable',
                                    )),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: loc.text(
                          'Actualiser la position',
                          'Refresh location',
                        ),
                        onPressed: _isLocating ? null : _fetchLocation,
                      ),
                    ],
                  ),

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
