import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/app_localizations.dart';
import '../../data/models/enums.dart';
import '../../data/models/professional_profile.dart';
import '../../data/services/firebase_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/professional_card.dart';
import 'register_screen.dart' show metierIcon;

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchController = TextEditingController();
  late final FirebaseService? _service;
  Metier? _metier;
  bool _availableOnly = false;
  List<ProfessionalProfile> _visibleProfessionals = const [];

  @override
  void initState() {
    super.initState();
    _service = Firebase.apps.isEmpty ? null : FirebaseService();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ProfessionalProfile> _filter(
    List<ProfessionalProfile> professionals,
    AppLocalizations loc,
  ) {
    final query = _searchController.text.trim().toLowerCase();
    return professionals.where((professional) {
      if (_availableOnly && !professional.disponible) return false;
      if (_metier != null && professional.metier != _metier) return false;
      if (query.isEmpty) return true;
      return professional.displayName.toLowerCase().contains(query) ||
          loc.metierLabel(professional.metier).toLowerCase().contains(query) ||
          professional.zoneIntervention.toLowerCase().contains(query);
    }).toList()..sort((a, b) {
      if (a.disponible != b.disponible) return a.disponible ? -1 : 1;
      return a.displayName.compareTo(b.displayName);
    });
  }

  void _openProfessional(ProfessionalProfile professional) {
    context.push('/client/professional', extra: professional);
  }

  void _openMap() {
    context.push('/map', extra: _visibleProfessionals);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.fromContext(context);
    final service = _service;

    if (service == null || service.currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.exploreTab)),
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
        title: Text(loc.exploreTab),
        actions: [
          IconButton(
            tooltip: loc.viewMap,
            onPressed: _visibleProfessionals.isEmpty ? null : _openMap,
            icon: const Icon(Icons.map_outlined),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
          SizedBox(
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
                    avatar: Icon(metierIcon(metier), size: 18),
                    label: Text(loc.metierLabel(metier)),
                    selected: _metier == metier,
                    onSelected: (_) => setState(() => _metier = metier),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: Text(
                    loc.text('Disponible maintenant', 'Available now'),
                  ),
                  selected: _availableOnly,
                  onSelected: (value) => setState(() => _availableOnly = value),
                ),
                if (_metier != null || _searchController.text.isNotEmpty)
                  ActionChip(
                    label: Text(
                      loc.text('Effacer les filtres', 'Clear filters'),
                    ),
                    onPressed: () => setState(() {
                      _metier = null;
                      _searchController.clear();
                    }),
                  ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ProfessionalProfile>>(
              stream: service.watchAllProfessionals(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return EmptyState(
                    icon: Icons.cloud_off,
                    title: loc.text('Chargement impossible', 'Unable to load'),
                    detail: loc.text(
                      'Vérifiez votre connexion internet.',
                      'Check your internet connection.',
                    ),
                    actionLabel: loc.text('Réessayer', 'Retry'),
                    onAction: () => setState(() {}),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final professionals = _filter(snapshot.data!, loc);
                if (!listEquals(_visibleProfessionals, professionals)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() => _visibleProfessionals = professionals);
                    }
                  });
                }
                if (professionals.isEmpty) {
                  return EmptyState(
                    icon: Icons.search_off,
                    title: loc.text('Aucun résultat', 'No results'),
                    detail: loc.text(
                      'Modifiez votre recherche ou vos filtres.',
                      'Adjust your search or filters.',
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: professionals.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => ProfessionalCard(
                    profile: professionals[index],
                    onTap: () => _openProfessional(professionals[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
