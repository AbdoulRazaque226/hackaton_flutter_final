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
  final _mapController = MapController();
  Position? _me;
  LocationException? _problem;
  bool _loading = true;

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
