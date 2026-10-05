import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/utils/distance.dart';
import '../../data/models/professional_profile.dart';
import '../../data/services/location_service.dart';
import '../widgets/empty_state.dart';

// Carte des professionnels disponibles autour du client.
//
// L'écran ne va pas chercher les professionnels lui-même : on lui passe la
// liste (celle du métier choisi par le client). Il s'occupe de la position
// du client, des marqueurs et de la distance.
class MapScreen extends StatefulWidget {
  final List<ProfessionalProfile> professionals;

  // Appelé quand le client touche « Voir la fiche » (navigation vers
  // professional_detail_screen, à brancher dans le router).
  final void Function(ProfessionalProfile pro)? onSelect;

  final LocationService locationService;

  MapScreen({
    super.key,
    required this.professionals,
    this.onSelect,
    LocationService? locationService,
  }) : locationService = locationService ?? LocationService();

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Rayon affiché par zone. Fixe pour le hackathon plutôt que calculé
  // dynamiquement : une vraie estimation demanderait des données (zones
  // administratives) qu'on n'a pas, un rayon fixe reste honnête et lisible.
  static const _zoneRadiusMeters = 1500.0;

  final _mapController = MapController();
  Position? _me;
  LocationException? _problem;
  bool _loading = true;
  bool _showZones = false;

  @override
  void initState() {
    super.initState();
    _locateMe();
  }

  Future<void> _locateMe() async {
    setState(() {
      _loading = true;
      _problem = null;
    });
    try {
      final pos = await widget.locationService.getCurrentPosition();
      if (!mounted) return;
      setState(() => _me = pos);
      _mapController.move(LatLng(pos.latitude, pos.longitude), 14);
    } on LocationException catch (e) {
      if (!mounted) return;
      setState(() => _problem = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.fromContext(context);
    final me = _me;

    // Seuls les professionnels disponibles ET positionnés apparaissent.
    final visible = widget.professionals
        .where((p) => p.disponible && hasPosition(p))
        .toList();

    final center = me != null
        ? LatLng(me.latitude, me.longitude)
        : visible.isNotEmpty
        ? LatLng(visible.first.latitude!, visible.first.longitude!)
        : null;

    if (center == null) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.text('Autour de moi', 'Nearby'))),
        body: EmptyState(
          icon: Icons.location_off_outlined,
          title: loc.text('Carte indisponible', 'Map unavailable'),
          detail: loc.text(
            'Aucun professionnel disponible avec une position réelle.',
            'No available professional has a real location.',
          ),
          actionLabel: loc.viewList,
          onAction: () => context.canPop()
              ? context.pop()
              : context.go('/client/home?tab=explore'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.text('Autour de moi', 'Nearby')),
        actions: [
          IconButton(
            tooltip: loc.viewList,
            icon: const Icon(Icons.list_alt),
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go('/client/home?tab=explore'),
          ),
          IconButton(
            tooltip: _showZones
                ? loc.text('Masquer les zones couvertes', 'Hide covered zones')
                : loc.text('Voir les zones couvertes', 'Show covered zones'),
            icon: Icon(_showZones ? Icons.layers : Icons.layers_outlined),
            onPressed: () => setState(() => _showZones = !_showZones),
          ),
          IconButton(
            tooltip: 'Me localiser',
            icon: const Icon(Icons.my_location),
            onPressed: _locateMe,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_problem != null)
            _ProblemBanner(
              problem: _problem!,
              service: widget.locationService,
              onRetry: _locateMe,
            ),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(initialCenter: center, initialZoom: 13),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.proxserv.proxserv',
                ),
                if (_showZones) CircleLayer(circles: _zoneCircles(visible)),
                MarkerLayer(
                  markers: [
                    if (me != null)
                      Marker(
                        point: LatLng(me.latitude, me.longitude),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.person_pin_circle,
                          color: Colors.blue,
                          size: 40,
                        ),
                      ),
                    for (final p in visible)
                      Marker(
                        point: LatLng(p.latitude!, p.longitude!),
                        width: 44,
                        height: 44,
                        child: GestureDetector(
                          onTap: () => _showPro(p),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.green,
                            size: 44,
                          ),
                        ),
                      ),
                  ],
                ),
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('© OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Un cercle par zone déclarée (zoneIntervention), centré sur la position
  // moyenne des professionnels disponibles de cette zone. Une zone avec un
  // seul professionnel donne quand même un cercle, centré sur lui.
  List<CircleMarker> _zoneCircles(List<ProfessionalProfile> pros) {
    final byZone = <String, List<ProfessionalProfile>>{};
    for (final p in pros) {
      if (p.zoneIntervention.trim().isEmpty) continue;
      byZone.putIfAbsent(p.zoneIntervention, () => []).add(p);
    }

    final circles = <CircleMarker>[];
    for (final entry in byZone.entries) {
      final center = _centroid(entry.value);
      // Zone dont aucun membre n'a de position : aucun cercle a dessiner.
      if (center == null) continue;
      circles.add(
        CircleMarker(
          point: center,
          radius: _zoneRadiusMeters,
          useRadiusInMeter: true,
          color: Colors.green.withValues(alpha: 0.12),
          borderColor: Colors.green.withValues(alpha: 0.5),
          borderStrokeWidth: 1.5,
        ),
      );
    }
    return circles;
  }

  /// Centre geographique d'un groupe de professionnels.
  ///
  /// `latitude` et `longitude` sont nullables : un professionnel qui n'a pas
  /// partage sa position n'entre pas dans la moyenne, et une zone entierement
  /// sans position ne donne aucun cercle plutot qu'une exception.
  LatLng? _centroid(List<ProfessionalProfile> pros) {
    final lats = <double>[];
    final lons = <double>[];
    for (final p in pros) {
      final lat = p.latitude;
      final lon = p.longitude;
      if (lat == null || lon == null) continue;
      lats.add(lat);
      lons.add(lon);
    }
    if (lats.isEmpty) return null;
    return LatLng(
      lats.reduce((a, b) => a + b) / lats.length,
      lons.reduce((a, b) => a + b) / lons.length,
    );
  }

  void _showPro(ProfessionalProfile pro) {
    final me = _me;
    final km = me == null
        ? null
        : distanceKm(
            me.latitude,
            me.longitude,
            pro.latitude!,
            pro.longitude!,
          );

    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pro.displayName, style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('${pro.metier.label} · ${pro.zoneIntervention}'),
            const SizedBox(height: 4),
            Text(
              me == null
                  ? 'Activez la localisation pour voir la distance'
                  : 'À ${formatDistance(km)} de vous',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  widget.onSelect?.call(pro);
                },
                child: const Text('Voir la fiche'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProblemBanner extends StatelessWidget {
  final LocationException problem;
  final LocationService service;
  final VoidCallback onRetry;

  const _ProblemBanner({
    required this.problem,
    required this.service,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.fromContext(context);
    final needsSettings = problem.problem != LocationProblem.permissionDenied;
    return MaterialBanner(
      content: Text(problem.message),
      leading: const Icon(Icons.location_off),
      actions: [
        TextButton(
          onPressed: needsSettings
              ? () async {
                  if (problem.problem == LocationProblem.serviceDisabled) {
                    await service.openLocationSettings();
                  } else {
                    await service.openAppSettings();
                  }
                }
              : onRetry,
          child: Text(
            needsSettings
                ? loc.text('Réglages', 'Settings')
                : loc.text('Réessayer', 'Retry'),
          ),
        ),
      ],
    );
  }
}