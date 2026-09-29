import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/utils/distance.dart';
import '../../data/models/enums.dart';
import '../../data/models/professional_profile.dart';
import '../../data/services/firebase_service.dart';
import '../../data/services/location_service.dart';
import 'login_screen.dart';
import 'register_screen.dart';

// Accueil client : choix du métier recherché, puis liste des professionnels
// disponibles pour ce métier (les plus proches d'abord quand la position du
// client est connue).
class ClientHomeScreen extends StatefulWidget {
  final FirebaseService? firebaseService;
  final LocationService? locationService;

  // Appelé quand le client touche un professionnel (navigation vers
  // professional_detail_screen, à brancher dans le router). Si null, on
  // affiche un message d'information.
  final void Function(ProfessionalProfile pro)? onSelect;

  // Appelé après une déconnexion, pour que le router revienne à l'écran de
  // connexion. Si null, on remonte directement au premier écran.
  final void Function()? onLogout;

  const ClientHomeScreen({
    super.key,
    this.firebaseService,
    this.locationService,
    this.onSelect,
    this.onLogout,
  });

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  late final FirebaseService _service;
  late final LocationService _location;

  Metier _metier = Metier.plombier;
  Position? _position;
  String? _locationMessage;
  bool _locating = true;

  // Incrémenté par le bouton « Réessayer » : il change la clé du
  // StreamBuilder, ce qui l'oblige à se réabonner à un nouveau flux Firestore
  // (reconstruire le widget seul ne rejouerait pas l'abonnement).
  int _retry = 0;

  @override
  void initState() {
    super.initState();
    _service = widget.firebaseService ?? FirebaseService();
    _location = widget.locationService ?? LocationService();
    _locateMe();
  }

  // Position du client, uniquement pour trier les professionnels par
  // proximité. En cas d'échec, la liste s'affiche quand même, sans distance.
  Future<void> _locateMe() async {
    setState(() {
      _locating = true;
      _locationMessage = null;
    });
    try {
      final position = await _location.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _position = position;
        _locating = false;
      });
    } on LocationException catch (e) {
      if (!mounted) return;
      setState(() {
        _position = null;
        _locating = false;
        _locationMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _position = null;
        _locating = false;
        _locationMessage = 'Position indisponible.';
      });
    }
  }

  Future<void> _logout() async {
    final onLogout = widget.onLogout;
    await _service.signOut();
    if (!mounted) return;
    if (onLogout != null) {
      onLogout();
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _openProfile(ProfessionalProfile pro) {
    final onSelect = widget.onSelect;
    if (onSelect != null) {
      onSelect(pro);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fiche de ${pro.displayName} — à brancher au router.'),
      ),
    );
  }

  // Filtre les professionnels disponibles et les trie du plus proche au plus
  // loin. Sans position du client, on trie par note décroissante.
  List<ProWithDistance> _prepare(List<ProfessionalProfile> pros) {
    final position = _position;
    if (position != null) {
      return sortByProximity(
        pros,
        fromLat: position.latitude,
        fromLon: position.longitude,
        onlyAvailable: true,
      );
    }

    final available = pros.where((p) => p.disponible).toList()
      ..sort((a, b) => (b.noteMoyenne ?? 0).compareTo(a.noteMoyenne ?? 0));
    return [for (final p in available) (pro: p, km: null)];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ProxServ'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'De quel service avez-vous besoin ?',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _MetierSelector(
                    selected: _metier,
                    onChanged: (metier) => setState(() => _metier = metier),
                  ),
                ],
              ),
            ),
            if (_locationMessage != null)
              _LocationNotice(
                message: _locationMessage!,
                onRetry: _locating ? null : _locateMe,
              ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<ProfessionalProfile>>(
                key: ValueKey('${_metier.name}-$_retry'),
                stream: _service.watchProfessionalsByMetier(_metier),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _Message(
                      icon: Icons.cloud_off,
                      title: 'Chargement impossible',
                      detail: 'Vérifiez votre connexion internet.',
                      onRetry: () => setState(() => _retry++),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final pros = snapshot.data!;
                  final available = _prepare(pros);

                  if (available.isEmpty) {
                    return _Message(
                      icon: metierIcon(_metier),
                      title: 'Aucun professionnel disponible',
                      detail: pros.isEmpty
                          ? 'Aucun ${_metier.label.toLowerCase()} n\'est encore '
                                'inscrit sur ProxServ.'
                          : 'Les ${_metier.label.toLowerCase()}s sont tous '
                                'indisponibles pour le moment. Réessayez plus tard.',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: available.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _ResultHeader(
                          count: available.length,
                          metier: _metier,
                          hidden: pros.length - available.length,
                        );
                      }
                      final item = available[index - 1];
                      return _ProfessionalCard(
                        entry: item,
                        onTap: () => _openProfile(item.pro),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Sélecteur du métier recherché.
class _MetierSelector extends StatelessWidget {
  final Metier selected;
  final ValueChanged<Metier> onChanged;

  const _MetierSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final metier in Metier.values)
          ChoiceChip(
            label: Text(metier.label),
            avatar: Icon(metierIcon(metier), size: 18),
            selected: metier == selected,
            onSelected: (_) => onChanged(metier),
          ),
      ],
    );
  }
}

// « X professionnels disponibles » (+ les indisponibles masqués).
class _ResultHeader extends StatelessWidget {
  final int count;
  final Metier metier;
  final int hidden;

  const _ResultHeader({
    required this.count,
    required this.metier,
    required this.hidden,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$count ${count > 1 ? 'professionnels' : 'professionnel'} '
              '${metier.label.toLowerCase()}${count > 1 ? 's' : ''} '
              '${count > 1 ? 'disponibles' : 'disponible'}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (hidden > 0)
            Text(
              '$hidden indisponible${hidden > 1 ? 's' : ''}',
              style: theme.textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}

// Carte d'un professionnel disponible : nom, métier, zone, note, distance.
class _ProfessionalCard extends StatelessWidget {
  final ProWithDistance entry;
  final VoidCallback onTap;

  const _ProfessionalCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final pro = entry.pro;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: colors.primaryContainer,
                    child: Icon(
                      metierIcon(pro.metier),
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pro.displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          pro.metier.label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.primary,
                          ),
                        ),
                        if (pro.zoneIntervention.isNotEmpty)
                          Text(
                            pro.zoneIntervention,
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.secondaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 8, color: colors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Disponible',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.star, size: 18, color: colors.tertiary),
                  const SizedBox(width: 4),
                  Text(_noteLabel(pro), style: theme.textTheme.bodySmall),
                  const Spacer(),
                  Icon(
                    Icons.near_me_outlined,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    formatDistance(entry.km),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// "4,5 (3)" s'il y a des avis, sinon "Pas encore d'avis" : un professionnel
// sans évaluation n'est pas pénalisé.
String _noteLabel(ProfessionalProfile pro) {
  final note = pro.noteMoyenne;
  if (note == null || pro.nombreEvaluations <= 0) return 'Pas encore d\'avis';
  final value = note.toStringAsFixed(1).replaceAll('.', ',');
  return '$value (${pro.nombreEvaluations})';
}

// Bandeau discret quand la position n'a pas pu être récupérée : la liste
// reste utilisable, seule la distance est absente.
class _LocationNotice extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _LocationNotice({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          Icon(
            Icons.location_off_outlined,
            size: 16,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              child: const Text('Réessayer'),
            ),
        ],
      ),
    );
  }
}

// État vide / erreur / chargement.
class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? detail;
  final VoidCallback? onRetry;

  const _Message({
    required this.icon,
    required this.title,
    this.detail,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (detail != null) ...[
              const SizedBox(height: 6),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
