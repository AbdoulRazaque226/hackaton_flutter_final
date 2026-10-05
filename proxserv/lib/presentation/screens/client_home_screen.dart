import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/problem_classifier.dart';
import '../../data/models/enums.dart';
import '../../data/services/firebase_service.dart';
import '../widgets/brand_logo.dart';
import '../widgets/category_image.dart';
import '../widgets/home_hero.dart';
import 'dashboard/dashboard_menu.dart';
import 'register_screen.dart' show metierIcon;

String clientHomeExploreUri({Metier? metier, String query = ''}) {
  final parameters = <String, String>{
    'tab': 'explore',
    if (metier != null) 'metier': metier.name,
    if (metier == null && query.trim().isNotEmpty) 'q': query.trim(),
  };
  return Uri(path: '/client/home', queryParameters: parameters).toString();
}

class ClientHomeScreen extends StatefulWidget {
  final FirebaseService? firebaseService;
  final VoidCallback? onLogout;

  const ClientHomeScreen({super.key, this.firebaseService, this.onLogout});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  FirebaseService? _service;
  final _searchController = TextEditingController();
  Metier? _selectedMetier;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
  }

  FirebaseService get _firebaseService =>
      widget.firebaseService ?? (_service ??= FirebaseService());

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateSearch(String query) {
    final suggestedMetier = classifyProblem(query);
    setState(() {
      _searchQuery = query;
      _selectedMetier = suggestedMetier;
    });
  }

  void _selectNeed(String query, Metier metier) {
    _searchController.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
    setState(() {
      _searchQuery = query;
      _selectedMetier = metier;
    });
  }

  void _selectMetier(Metier metier) {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedMetier = metier;
    });
    _navigateToExplore(metier: metier);
  }

  void _openExplore() {
    final inferredMetier = classifyProblem(_searchQuery);
    final metier = inferredMetier ?? _selectedMetier;
    _navigateToExplore(
      metier: metier,
      query: metier == null ? _searchQuery.trim() : '',
    );
  }

  void _navigateToExplore({Metier? metier, String query = ''}) {
    context.go(clientHomeExploreUri(metier: metier, query: query));
  }

  Future<void> _logout() async {
    try {
      await _firebaseService.signOut();
      if (!mounted) return;
      final onLogout = widget.onLogout;
      if (onLogout != null) {
        onLogout();
      } else {
        context.go('/login');
      }
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'ClientHomeScreen',
          context: ErrorDescription('while signing out'),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.fromContext(context).text(
              'La déconnexion a échoué. Réessayez.',
              'Sign out failed. Please try again.',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.fromContext(context);
    final compact = MediaQuery.sizeOf(context).width < 760;
    return Scaffold(
      appBar: AppBar(
        leading: dashboardMenuLeading(context),
        title: const Row(
          children: [
            BrandLogo(height: 32),
            SizedBox(width: 8),
            Text('ProxServ', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: loc.logout,
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _section(
                context,
                HomeHero(
                  searchController: _searchController,
                  onSearchChanged: _updateSearch,
                  onNeedSelected: _selectNeed,
                  onExplore: _openExplore,
                ),
                compact: compact,
                top: 16,
              ),
            ),
            SliverToBoxAdapter(
              child: _section(
                context,
                _HomeCategoryRail(
                  selected: _selectedMetier,
                  onSelected: _selectMetier,
                ),
                compact: compact,
                top: 28,
                bottom: 8,
              ),
            ),
            SliverToBoxAdapter(
              child: _section(
                context,
                HomeEditorialBand(
                  visualFirst: true,
                  icon: Icons.location_on_outlined,
                  title: loc.text(
                    'Commencez par votre besoin',
                    'Start with what you need',
                  ),
                  body: loc.text(
                    'Décrivez votre intervention ou choisissez un métier. Explore vous permet ensuite de rechercher et comparer les professionnels.',
                    'Describe the job or choose a trade. Explore lets you search and compare professionals.',
                  ),
                ),
                compact: compact,
                top: 28,
                bottom: 20,
              ),
            ),
            SliverToBoxAdapter(
              child: _section(
                context,
                HomeEditorialBand(
                  visualFirst: false,
                  icon: Icons.forum_outlined,
                  title: loc.text(
                    'Une demande, un suivi clair',
                    'One request, a clear follow-up',
                  ),
                  body: loc.text(
                    'Après avoir choisi un professionnel, envoyez votre demande et suivez son statut dans votre espace.',
                    'After choosing a professional, send your request and follow its status in your account.',
                  ),
                ),
                compact: compact,
                bottom: 24,
              ),
            ),
            SliverToBoxAdapter(
              child: _section(
                context,
                HomeFinalCta(onExplore: _openExplore),
                compact: compact,
                bottom: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(
    BuildContext context,
    Widget child, {
    required bool compact,
    double top = 0,
    double bottom = 0,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1160),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 16 : 28,
            top,
            compact ? 16 : 28,
            bottom,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _HomeCategoryRail extends StatelessWidget {
  final Metier? selected;
  final ValueChanged<Metier> onSelected;

  const _HomeCategoryRail({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.fromContext(context);
    final theme = Theme.of(context);
    final trades = Metier.values.where((metier) => metier != Metier.autre);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.text('Choisir un métier', 'Choose a trade'),
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: trades.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final metier = trades.elementAt(index);
              final isSelected = metier == selected;
              return SizedBox(
                width: 112,
                child: Material(
                  color: isSelected
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surface,
                  borderRadius: AppSpacing.borderRadiusMd,
                  child: InkWell(
                    onTap: () => onSelected(metier),
                    borderRadius: AppSpacing.borderRadiusMd,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        borderRadius: AppSpacing.borderRadiusMd,
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CategoryImage(
                            metier: metier,
                            size: 48,
                            fallbackIcon: metierIcon(metier),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            loc.metierLabel(metier),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
