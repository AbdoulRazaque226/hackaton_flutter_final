import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/distance.dart';
import '../../data/models/enums.dart';
import '../../data/models/professional_profile.dart';
import '../../data/services/firebase_service.dart';
import '../../data/services/location_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/professional_card.dart';
import 'register_screen.dart' show metierIcon;

class ClientHomeScreen extends ConsumerStatefulWidget {
  final FirebaseService? firebaseService;
  final LocationService? locationService;
  final void Function(ProfessionalProfile pro)? onSelect;
  final void Function()? onLogout;

  const ClientHomeScreen({
    super.key,
    this.firebaseService,
    this.locationService,
    this.onSelect,
    this.onLogout,
  });

  @override
  ConsumerState<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends ConsumerState<ClientHomeScreen> {
  late final FirebaseService _service;
  late final LocationService _location;

  Metier _metier = Metier.plombier;
  Position? _position;
  String? _locationMessage;
  bool _locating = true;
  String _searchQuery = '';

  List<ProfessionalProfile> _lastPros = const [];
  int _retry = 0;

  @override
  void initState() {
    super.initState();
    _service = widget.firebaseService ?? FirebaseService();
    _location = widget.locationService ?? LocationService();
    _locateMe();
  }

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
        _locationMessage = 'Position GPS non disponible.';
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
      context.go('/login');
    }
  }

  void _openMap() {
    context.push('/map', extra: _lastPros);
  }

  void _openProfile(ProfessionalProfile pro) {
    final onSelect = widget.onSelect;
    if (onSelect != null) {
      onSelect(pro);
    } else {
      context.push('/client/professional', extra: pro);
    }
  }

  List<ProWithDistance> _prepare(List<ProfessionalProfile> pros) {
    // Filtrage textuel si une recherche est saisie
    var filtered = pros;
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      filtered = pros.where((p) {
        final name = p.displayName.toLowerCase();
        final metier = p.metier.label.toLowerCase();
        final zone = p.zoneIntervention.toLowerCase();
        return name.contains(q) || metier.contains(q) || zone.contains(q);
      }).toList();
    }

    final position = _position;
    if (position != null) {
      return sortByProximity(
        filtered,
        fromLat: position.latitude,
        fromLon: position.longitude,
        onlyAvailable: true,
      );
    }

    final available = filtered.where((p) => p.disponible).toList()
      ..sort((a, b) => (b.noteMoyenne ?? 0).compareTo(a.noteMoyenne ?? 0));
    return [for (final p in available) (pro: p, km: null)];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context, ref);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 32,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.build_circle, color: AppColors.brandPrimary),
            ),
            const SizedBox(width: 8),
            const Text(
              'ProxServ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: loc.viewMap,
            onPressed: _lastPros.isEmpty ? null : _openMap,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: loc.logout,
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                loc.homeQuestion,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Barre de recherche textuelle de problème
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: loc.searchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            _MetierSelector(
              selected: _metier,
              onChanged: (metier) => setState(() => _metier = metier),
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
                    return EmptyState(
                      icon: Icons.cloud_off,
                      title: 'Chargement impossible',
                      detail: 'Vérifiez votre connexion internet.',
                      actionLabel: 'Réessayer',
                      onAction: () => setState(() => _retry++),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final pros = snapshot.data!;
                  final available = _prepare(pros);

                  if (!identical(_lastPros, pros)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _lastPros = pros);
                    });
                  }

                  if (available.isEmpty) {
                    return EmptyState(
                      icon: metierIcon(_metier),
                      title: loc.noProsAvailable,
                      detail: pros.isEmpty
                          ? 'Aucun ${_metier.label.toLowerCase()} n\'est encore inscrit sur ProxServ.'
                          : 'Tous les ${_metier.label.toLowerCase()}s sont indisponibles actuellement.',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: available.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _ResultHeader(
                          count: available.length,
                          metier: _metier,
                          hidden: pros.length - available.length,
                        );
                      }
                      final item = available[index - 1];
                      return ProfessionalCard(
                        profile: item.pro,
                        distanceKm: item.km,
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

class _MetierSelector extends StatelessWidget {
  final Metier selected;
  final ValueChanged<Metier> onChanged;

  const _MetierSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final metier in Metier.values) ...[
            ChoiceChip(
              label: Text(metier.label),
              avatar: Icon(metierIcon(metier), size: 18),
              selected: metier == selected,
              onSelected: (_) => onChanged(metier),
            ),
            if (metier != Metier.values.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

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
