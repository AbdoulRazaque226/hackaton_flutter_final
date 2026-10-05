import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers/app_providers.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/distance.dart';
import '../../core/utils/professional_location_filter.dart';
import '../../data/models/app_user.dart';
import '../../data/models/enums.dart';
import '../../data/models/professional_profile.dart';
import '../../data/services/firebase_service.dart';
import '../../data/services/location_service.dart';
import '../widgets/category_image.dart';
import '../widgets/empty_state.dart';
import '../widgets/professional_card.dart';
import 'dashboard/dashboard_menu.dart';
import 'register_screen.dart' show metierIcon;

class ExploreScreen extends ConsumerStatefulWidget {
  final Metier? initialMetier;
  final String initialQuery;

  const ExploreScreen({super.key, this.initialMetier, this.initialQuery = ''});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  late final TextEditingController _searchController;
  late final TextEditingController _countryController;
  late final TextEditingController _cityController;
  late final FirebaseService? _service;
  late Stream<List<ProfessionalProfile>> _professionalsStream;
  Metier? _metier;
  bool _availableOnly = false;
  bool _isLocating = false;
  Position? _gpsPosition;
  String? _locationError;
  List<ProWithDistance> _visibleProfessionals = const [];

  @override
  void initState() {
    super.initState();
    _metier = widget.initialMetier;
    _availableOnly = widget.initialMetier != null;
    _searchController = TextEditingController(text: widget.initialQuery);
    _countryController = TextEditingController();
    _cityController = TextEditingController();
    _countryController.addListener(_manualLocationChanged);
    _cityController.addListener(_manualLocationChanged);
    if (Firebase.apps.isEmpty) {
      _service = null;
      _professionalsStream = const Stream.empty();
    } else {
      final service = FirebaseService();
      _service = service;
      _professionalsStream = service.watchAllProfessionals();
    }
  }

  @override
  void didUpdateWidget(covariant ExploreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialMetier != widget.initialMetier) {
      _metier = widget.initialMetier;
      _availableOnly = widget.initialMetier != null;
    }
    if (oldWidget.initialQuery != widget.initialQuery) {
      _searchController.value = TextEditingValue(
        text: widget.initialQuery,
        selection: TextSelection.collapsed(offset: widget.initialQuery.length),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _countryController
      ..removeListener(_manualLocationChanged)
      ..dispose();
    _cityController
      ..removeListener(_manualLocationChanged)
      ..dispose();
    super.dispose();
  }

  void _manualLocationChanged() {
    if (_gpsPosition != null || _locationError != null) {
      setState(() {
        _gpsPosition = null;
        _locationError = null;
      });
    } else {
      setState(() {});
    }
  }

  ProfessionalSearchLocation? _searchLocation(AppUser? user) {
    final position = _gpsPosition;
    return resolveSearchLocation(
      currentLatitude: position?.latitude,
      currentLongitude: position?.longitude,
      manualCountry: _countryController.text.trim(),
      manualCity: _cityController.text.trim(),
      profileCountry: user?.country,
      profileCity: user?.city,
    );
  }

  List<ProWithDistance> _filter(
    List<ProfessionalProfile> professionals,
    AppLocalizations loc,
    AppUser? user,
  ) {
    final query = _searchController.text.trim().toLowerCase();
    final location = _searchLocation(user);
    if (location == null) return const [];

    final matches = filterProfessionalsByLocation(
      professionals,
      location: location,
      metier: _metier?.name,
      onlyAvailable: _availableOnly,
    );
    final filtered = matches.where((match) {
      final professional = match.pro;
      if (query.isEmpty) return true;
      return professional.displayName.toLowerCase().contains(query) ||
          loc.metierLabel(professional.metier).toLowerCase().contains(query) ||
          professional.zoneIntervention.toLowerCase().contains(query) ||
          professional.neighborhood.toLowerCase().contains(query) ||
          professional.city.toLowerCase().contains(query) ||
          professional.country.toLowerCase().contains(query);
    }).toList();
    if (!location.hasGps) {
      filtered.sort((a, b) {
        if (a.pro.disponible != b.pro.disponible) {
          return a.pro.disponible ? -1 : 1;
        }
        return a.pro.displayName.compareTo(b.pro.displayName);
      });
    }
    return filtered;
  }

  bool get _hasActiveFilters =>
      _availableOnly ||
      _metier != null ||
      _searchController.text.isNotEmpty ||
      _gpsPosition != null ||
      _countryController.text.isNotEmpty ||
      _cityController.text.isNotEmpty;

  void _clearFilters() {
    _countryController.clear();
    _cityController.clear();
    _searchController.clear();
    setState(() {
      _metier = null;
      _availableOnly = false;
      _gpsPosition = null;
    });
  }

  void _retryLoading() {
    final service = _service;
    if (service == null) return;
    setState(() {
      _visibleProfessionals = const [];
      _professionalsStream = service.watchAllProfessionals();
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLocating = true;
      _locationError = null;
    });
    try {
      final position = await LocationService().getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _gpsPosition = position;
      });
    } on LocationException catch (error) {
      if (!mounted) return;
      setState(() => _locationError = error.message);
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _locationError = AppLocalizations.fromContext(context).text(
          'Impossible d’obtenir la position actuelle : $error',
          'Unable to get your current location: $error',
        ),
      );
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _openProfessional(ProfessionalProfile professional) {
    context.push('/client/professional', extra: professional);
  }

  void _openMap() {
    context.push(
      '/map',
      extra: _visibleProfessionals.map((result) => result.pro).toList(),
    );
  }

  Widget _locationSelector(
    AppLocalizations loc,
    AppUser? user,
    ProfessionalSearchLocation? activeLocation,
  ) {
    final theme = Theme.of(context);
    final hasProfileLocation =
        user != null &&
        user.country.trim().isNotEmpty &&
        user.city.trim().isNotEmpty;
    final isUsingGps = _gpsPosition != null;
    final manualSelected =
        !isUsingGps &&
        _countryController.text.trim().isNotEmpty &&
        _cityController.text.trim().isNotEmpty;
    final usingProfile =
        activeLocation != null && !isUsingGps && !manualSelected;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1160),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.text(
                      'Où recherchez-vous ?',
                      'Where are you searching?',
                    ),
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _isLocating ? null : _useCurrentLocation,
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
                      if (hasProfileLocation)
                        TextButton.icon(
                          onPressed: () {
                            _countryController.clear();
                            _cityController.clear();
                            setState(() {
                              _gpsPosition = null;
                            });
                          },
                          icon: const Icon(Icons.home_outlined),
                          label: Text(
                            loc.text(
                              'Utiliser mon lieu habituel',
                              'Use my usual location',
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final country = TextField(
                        controller: _countryController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: loc.text('Pays', 'Country'),
                          hintText: loc.text(
                            'Ex. Côte d’Ivoire',
                            'e.g. Côte d’Ivoire',
                          ),
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      );
                      final city = TextField(
                        controller: _cityController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: loc.text('Ville', 'City'),
                          hintText: loc.text('Ex. Abidjan', 'e.g. Abidjan'),
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      );
                      if (constraints.maxWidth < 520) {
                        return Column(
                          children: [
                            country,
                            const SizedBox(height: AppSpacing.sm),
                            city,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: country),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(child: city),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    isUsingGps
                        ? loc.text(
                            'Recherche GPS dans un rayon de 50 km.',
                            'GPS search within 50 km.',
                          )
                        : manualSelected
                        ? loc.text(
                            'Recherche dans ${_cityController.text.trim()}, ${_countryController.text.trim()}.',
                            'Searching in ${_cityController.text.trim()}, ${_countryController.text.trim()}.',
                          )
                        : usingProfile
                        ? loc.text(
                            'Lieu habituel : ${user?.city ?? ''}, ${user?.country ?? ''}.',
                            'Usual location: ${user?.city ?? ''}, ${user?.country ?? ''}.',
                          )
                        : loc.text(
                            'Choisissez une ville ou renseignez votre lieu habituel dans Profil.',
                            'Choose a city or add your usual location under Profile.',
                          ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (_locationError != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _locationError!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _resultsTitle(AppLocalizations loc) {
    final metier = _metier;
    if (metier == null) {
      return _availableOnly
          ? loc.text('Professionnels disponibles', 'Available professionals')
          : loc.text(
              'Professionnels dans votre zone',
              'Professionals in your area',
            );
    }
    final label = switch (metier) {
      Metier.plombier => loc.text('Plombiers', 'Plumbers'),
      Metier.electricien => loc.text('Électriciens', 'Electricians'),
      Metier.macon => loc.text('Maçons', 'Masons'),
      Metier.menuisier => loc.text('Menuisiers', 'Carpenters'),
      Metier.peintre => loc.text('Peintres', 'Painters'),
      Metier.reparateur => loc.text('Réparateurs', 'Repair professionals'),
      Metier.nettoyage => loc.text('Nettoyage', 'Cleaning'),
      Metier.autre => loc.text('Professionnels', 'Professionals'),
    };
    return _availableOnly
        ? metier == Metier.nettoyage
              ? loc.text(
                  'Professionnels du nettoyage disponibles',
                  'Available cleaning professionals',
                )
              : loc.text('$label disponibles', '$label available')
        : loc.text('$label dans votre zone', '$label in your area');
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.fromContext(context);
    final service = _service;
    final client = ref.watch(currentUserProvider).value;
    final activeLocation = _searchLocation(client);

    if (service == null || service.currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          leading: dashboardMenuLeading(context),
          title: Text(loc.exploreTab),
        ),
        body: EmptyState(
          icon: Icons.search,
          title: loc.exploreTab,
          detail: loc.text(
            'Connectez-vous pour explorer les professionnels.',
            'Sign in to explore professionals.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: dashboardMenuLeading(context),
        title: Text(loc.exploreTab),
        actions: [
          IconButton(
            tooltip: loc.viewMap,
            onPressed: _visibleProfessionals.isEmpty ? null : _openMap,
            icon: const Icon(Icons.map_outlined),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1160),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: AppSpacing.borderRadiusLg,
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.14),
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 580;
                        final title = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 3,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  loc.text('ANNUAIRE LOCAL', 'LOCAL DIRECTORY'),
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              loc.text(
                                'Explorez les professionnels',
                                'Explore professionals',
                              ),
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              loc.text(
                                'Filtrez par métier, disponibilité ou zone.',
                                'Filter by service, availability, or area.',
                              ),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                  ),
                            ),
                          ],
                        );
                        final illustration = Container(
                          width: compact ? 52 : 76,
                          height: compact ? 52 : 76,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.secondaryContainer,
                            borderRadius: AppSpacing.borderRadiusMd,
                          ),
                          child: Icon(
                            Icons.manage_search,
                            size: compact ? 28 : 38,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSecondaryContainer,
                          ),
                        );
                        return compact
                            ? title
                            : Row(
                                children: [
                                  Expanded(child: title),
                                  const SizedBox(width: AppSpacing.lg),
                                  illustration,
                                ],
                              );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _locationSelector(loc, client, activeLocation),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1160),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Card(
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: loc.text(
                            'Métier, professionnel ou quartier',
                            'Trade, professional or neighborhood',
                          ),
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: loc.text('Effacer', 'Clear'),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.clear),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  ChoiceChip(
                    label: Text(loc.text('Tous les métiers', 'All trades')),
                    selected: _metier == null,
                    onSelected: (_) => setState(() => _metier = null),
                  ),
                  for (final metier in Metier.values) ...[
                    const SizedBox(width: 8),
                    ChoiceChip(
                      avatar: CategoryImage(
                        metier: metier,
                        size: 24,
                        fallbackIcon: metierIcon(metier),
                      ),
                      label: Text(loc.metierLabel(metier)),
                      selected: _metier == metier,
                      onSelected: (_) => setState(() => _metier = metier),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: Text(
                      loc.text('Disponible maintenant', 'Available now'),
                    ),
                    selected: _availableOnly,
                    onSelected: (value) =>
                        setState(() => _availableOnly = value),
                  ),
                  if (_hasActiveFilters)
                    ActionChip(
                      label: Text(
                        loc.text('Effacer les filtres', 'Clear filters'),
                      ),
                      onPressed: _clearFilters,
                    ),
                ],
              ),
            ),
          ),
          StreamBuilder<List<ProfessionalProfile>>(
            stream: _professionalsStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.cloud_off,
                    title: loc.text('Chargement impossible', 'Unable to load'),
                    detail: loc.text(
                      'Vérifiez votre connexion internet.',
                      'Check your internet connection.',
                    ),
                    actionLabel: loc.text('Réessayer', 'Retry'),
                    onAction: _retryLoading,
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final professionals = _filter(snapshot.data!, loc, client);
              if (!listEquals(_visibleProfessionals, professionals)) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() => _visibleProfessionals = professionals);
                  }
                });
              }
              if (professionals.isEmpty) {
                return SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.search_off,
                    title: loc.text('Aucun résultat', 'No results'),
                    detail: activeLocation == null
                        ? loc.text(
                            'Choisissez un pays et une ville, ou renseignez votre lieu habituel dans votre profil.',
                            'Choose a country and city, or add your usual location to your profile.',
                          )
                        : loc.text(
                            'Aucun professionnel ne correspond au métier, à la zone et aux filtres sélectionnés.',
                            'No professional matches the selected trade, location, and filters.',
                          ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _resultsTitle(loc),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            Text(
                              '${professionals.length}',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                            ),
                          ],
                        ),
                      );
                    }
                    final result = professionals[index - 1];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ProfessionalCard(
                        profile: result.pro,
                        distanceKm: result.km,
                        onTap: () => _openProfessional(result.pro),
                      ),
                    );
                  }, childCount: professionals.length + 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
