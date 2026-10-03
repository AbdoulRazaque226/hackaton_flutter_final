import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/professional_profile.dart';
import '../../data/services/firebase_service.dart';
import '../../data/services/location_service.dart';

/// Écran de création d'une demande d'intervention.
class RequestFormScreen extends StatefulWidget {
  final ProfessionalProfile professional;
  final FirebaseService firebaseService;
  final LocationService locationService;
  final String? clientId;
  final String? clientName;

  RequestFormScreen({
    super.key,
    required this.professional,
    FirebaseService? firebaseService,
    LocationService? locationService,
    this.clientId,
    this.clientName,
  }) : firebaseService = firebaseService ?? FirebaseService(),
       locationService = locationService ?? LocationService();

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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = widget.firebaseService.currentUser;
      final effectiveClientId =
          widget.clientId ?? user?.uid ?? 'client_inconnu';
      String effectiveClientName = widget.clientName ?? user?.displayName ?? '';

      if (effectiveClientName.isEmpty && user != null) {
        final appUser = await widget.firebaseService.fetchAppUser(user.uid);
        if (appUser != null && appUser.displayName.isNotEmpty) {
          effectiveClientName = appUser.displayName;
        }
      }

      if (effectiveClientName.isEmpty) {
        effectiveClientName = 'Client ProxServ';
      }

      final lat = _currentPosition?.latitude ?? widget.professional.latitude;
      final lon = _currentPosition?.longitude ?? widget.professional.longitude;

      await widget.firebaseService.createRequest(
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
        const SnackBar(
          content: Text(
            'Votre demande d\'intervention a été envoyée avec succès !',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Proposer le retour ou la redirection vers le suivi
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Demande envoyée'),
          content: const Text(
            'Votre demande a bien été enregistrée. Le professionnel en sera notifié.',
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
              child: const Text('Fermer'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go('/client/home');
              },
              child: const Text('Voir mes demandes'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'envoi de la demande : $e'),
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
    final pro = widget.professional;

    return Scaffold(
      appBar: AppBar(title: const Text('Demande d\'intervention')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
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
                                  : 'Professionnel',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Métier : ${pro.metier.label}',
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
                          ? 'Récupération de votre position...'
                          : _currentPosition != null
                          ? 'Position GPS enregistrée'
                          : (_locationError ?? 'Position non disponible'),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Actualiser la position',
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
                'Description de votre besoin',
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
                  hintText:
                      'Décrivez brièvement votre problème ou votre besoin (ex: fuite d\'eau sous le lavabo, panne électrique dans le salon...)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez saisir une description de votre besoin.';
                  }
                  if (value.trim().length < 5) {
                    return 'La description doit contenir au moins 5 caractères.';
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
                      : const Text(
                          'Envoyer la demande',
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
    );
  }
}
