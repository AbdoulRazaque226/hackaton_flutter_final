import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/problem_classifier.dart';
import '../../data/models/enums.dart';
import '../widgets/brand_logo.dart';
import '../widgets/category_image.dart';
import 'register_screen.dart' show metierIcon;

class PublicLandingScreen extends StatefulWidget {
  const PublicLandingScreen({super.key});

  @override
  State<PublicLandingScreen> createState() => _PublicLandingScreenState();
}

class _PublicLandingScreenState extends State<PublicLandingScreen> {
  final _howItWorksKey = GlobalKey();
  final _categoriesKey = GlobalKey();
  final _aboutKey = GlobalKey();
  final _problemController = TextEditingController();

  @override
  void dispose() {
    _problemController.dispose();
    super.dispose();
  }

  void _scrollTo(GlobalKey key) {
    final target = key.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _explore({Metier? metier, String? problem}) {
    final query = <String, String>{
      if (metier != null) 'metier': metier.name,
      if (problem != null && problem.trim().isNotEmpty) 'q': problem.trim(),
    };
    context.go(
      Uri(
        path: '/explore',
        queryParameters: query.isEmpty ? null : query,
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 900;

    return Scaffold(
      drawer: isCompact ? _buildLandingDrawer(context) : null,
      appBar: AppBar(
        toolbarHeight: 76,
        titleSpacing: isCompact ? 16 : 32,
        title: const BrandLogo(height: 38),
        actions: isCompact
            ? []
            : [
                TextButton(
                  onPressed: () => _explore(),
                  child: const Text('Explorer'),
                ),
                TextButton(
                  onPressed: () => _scrollTo(_categoriesKey),
                  child: const Text('Métiers'),
                ),
                TextButton(
                  onPressed: () => _scrollTo(_aboutKey),
                  child: const Text('À propos'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Connexion'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => context.go('/register'),
                  child: const Text('S’inscrire'),
                ),
                const SizedBox(width: 24),
              ],
      ),
      body: SelectionArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHero(context, compact: isCompact),
              _buildEditorial(context, compact: isCompact, key: _aboutKey),
              _buildCategories(context, key: _categoriesKey),
              _buildSteps(context, compact: isCompact, key: _howItWorksKey),
              _buildFinalCta(context, compact: isCompact),
              _buildFooter(context, compact: isCompact),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLandingDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: BrandLogo(height: 38),
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Explorer les métiers'),
              onTap: () {
                Navigator.pop(context);
                _explore();
              },
            ),
            ListTile(
              leading: const Icon(Icons.route_outlined),
              title: const Text('Comment ça marche'),
              onTap: () {
                Navigator.pop(context);
                _scrollTo(_howItWorksKey);
              },
            ),
            ListTile(
              leading: const Icon(Icons.handyman_outlined),
              title: const Text('Métiers'),
              onTap: () {
                Navigator.pop(context);
                _scrollTo(_categoriesKey);
              },
            ),
            ListTile(
              leading: const Icon(Icons.verified_outlined),
              title: const Text('À propos'),
              onTap: () {
                Navigator.pop(context);
                _scrollTo(_aboutKey);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Connexion'),
              onTap: () {
                Navigator.pop(context);
                context.go('/login');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add_alt_1),
              title: const Text('Créer un compte'),
              onTap: () {
                Navigator.pop(context);
                context.go('/register');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, {required bool compact}) {
    final textTheme = Theme.of(context).textTheme;
    final width = MediaQuery.sizeOf(context).width;
    final titleSize = compact ? (width < 400 ? 36.0 : 42.0) : 60.0;
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const _Eyebrow(
          text: 'DES PROFESSIONNELS PRÈS DE CHEZ VOUS',
          color: Colors.white,
        ),
        const SizedBox(height: 16),
        Text(
          'Quel est votre besoin ?',
          style: textTheme.displaySmall?.copyWith(
            fontSize: titleSize,
            color: Colors.white,
            fontWeight: FontWeight.w800,
            height: 1.02,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Trouvez rapidement le bon professionnel près de chez vous.',
          style: textTheme.titleLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.94),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        _ProblemInput(
          controller: _problemController,
          onSubmit: () => _explore(
            metier: classifyProblem(_problemController.text),
            problem: _problemController.text,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: () => _explore(),
              icon: const Icon(Icons.search),
              label: const Text('Trouver un professionnel'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 52),
                padding: const EdgeInsets.symmetric(horizontal: 22),
              ),
            ),
            OutlinedButton(
              onPressed: () => context.go('/register'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.72)),
                minimumSize: const Size(0, 52),
                padding: const EdgeInsets.symmetric(horizontal: 22),
              ),
              child: const Text('S’inscrire'),
            ),
          ],
        ),
      ],
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 32,
        16,
        compact ? 16 : 32,
        compact ? 24 : 40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: ClipRRect(
            key: const ValueKey('public-home-hero-card'),
            borderRadius: BorderRadius.circular(compact ? 28 : 40),
            child: SizedBox(
              height: compact ? 670 : 620,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/hero/hero_home.jpg',
                    key: const ValueKey('public-home-hero-image'),
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                    errorBuilder: _assetErrorBuilder,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: compact
                          ? const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0x080D1020),
                                Color(0x54100D1D),
                                Color(0xE8100D1D),
                              ],
                              stops: [0.12, 0.42, 1],
                            )
                          : const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Color(0xE8100D1D),
                                Color(0xB3100D1D),
                                Color(0x26100D1D),
                              ],
                              stops: [0, 0.56, 1],
                            ),
                    ),
                  ),
                  Align(
                    alignment: compact
                        ? Alignment.bottomLeft
                        : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: compact ? 720 : 760,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(compact ? 20 : 60),
                        child: copy,
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

  Widget _buildSteps(
    BuildContext context, {
    required bool compact,
    required GlobalKey key,
  }) {
    final loc = Localizations.localeOf(context).languageCode;
    final steps = loc == 'en'
        ? const [
            (
              '01',
              'Describe your problem',
              'A few words are enough to get started.',
            ),
            ('02', 'Find a professional', 'Explore trades and profiles.'),
            ('03', 'Discuss the job', 'Message and agree on the work.'),
            ('04', 'Finish and review', 'Share your experience after the job.'),
          ]
        : const [
            (
              '01',
              'Décrivez votre besoin',
              'Quelques mots suffisent pour commencer.',
            ),
            (
              '02',
              'Trouvez un professionnel',
              'Explorez les métiers et les profils.',
            ),
            (
              '03',
              'Échangez et convenez',
              'Discutez de l’intervention avec le professionnel.',
            ),
            (
              '04',
              'Terminez et donnez votre avis',
              'Après l’intervention, partagez votre expérience.',
            ),
          ];

    return Padding(
      key: key,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 20 : 48,
        vertical: compact ? 52 : 80,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeading(
                eyebrow: 'SIMPLE ET DIRECT',
                title: 'Du premier mot à l’intervention.',
              ),
              const SizedBox(height: 32),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 1080
                      ? 4
                      : constraints.maxWidth >= 600
                      ? 2
                      : 1;
                  const spacing = 16.0;
                  final itemWidth =
                      (constraints.maxWidth - spacing * (columns - 1)) /
                      columns;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      for (final (number, title, description) in steps)
                        SizedBox(
                          width: itemWidth,
                          child: _StepCard(
                            number: number,
                            title: title,
                            description: description,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategories(BuildContext context, {required GlobalKey key}) {
    final trades = Metier.values.where((metier) => metier != Metier.autre);
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 900;
    return Container(
      key: key,
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 20 : 48,
        vertical: 48,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeading(
                eyebrow: 'LES MÉTIERS',
                title: 'Les bons gestes commencent ici.',
              ),
              const SizedBox(height: 32),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 1080
                      ? 4
                      : constraints.maxWidth >= 600
                      ? 3
                      : 2;
                  const spacing = 16.0;
                  final itemWidth =
                      (constraints.maxWidth - spacing * (columns - 1)) /
                      columns;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      for (final metier in trades)
                        SizedBox(
                          width: itemWidth,
                          child: _TradeCard(
                            metier: metier,
                            onTap: () => _explore(metier: metier),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),
              FilledButton.tonalIcon(
                onPressed: () => _explore(),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Voir tous les métiers'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditorial(
    BuildContext context, {
    required bool compact,
    required GlobalKey key,
  }) {
    return Padding(
      key: key,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 20 : 48,
        vertical: compact ? 24 : 40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            children: [
              _EditorialRow(
                image: 'assets/images/landing_client.jpg',
                eyebrow: 'UN BESOIN, UNE BONNE RENCONTRE',
                title: 'Trouvez le bon professionnel, au bon moment.',
                description:
                    'ProxServ vous aide à découvrir des professionnels de proximité et à poursuivre votre demande dans un espace dédié.',
                imageFirst: true,
                compact: compact,
              ),
              SizedBox(height: compact ? 64 : 112),
              _EditorialRow(
                image: 'assets/images/landing_need.jpg',
                eyebrow: 'PAS BESOIN DE CONNAÎTRE LE MÉTIER',
                title: 'Décrivez simplement votre problème.',
                description:
                    'Pas besoin de connaître le nom du métier. Expliquez ce qui vous arrive et ProxServ vous aide à trouver le professionnel adapté.',
                imageFirst: false,
                compact: compact,
                onAction: () => _explore(
                  metier: classifyProblem(_problemController.text),
                  problem: _problemController.text,
                ),
                actionLabel: 'Décrire mon besoin',
              ),
              SizedBox(height: compact ? 64 : 112),
              _EditorialRow(
                key: const ValueKey('landing-about-section'),
                image: 'assets/images/landing_proximity.jpg',
                eyebrow: 'À PROXIMITÉ',
                title: 'Des professionnels proches de vous.',
                description:
                    'Consultez les informations de profil et la disponibilité déclarée par les professionnels. Après connexion, envoyez une demande et poursuivez les échanges dans la messagerie liée à votre intervention.',
                imageFirst: true,
                compact: compact,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinalCta(BuildContext context, {required bool compact}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 48,
        compact ? 20 : 32,
        compact ? 16 : 48,
        compact ? 40 : 64,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 24 : 72,
              vertical: compact ? 38 : 64,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF24143D),
              borderRadius: BorderRadius.circular(compact ? 28 : 40),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Eyebrow(
                  text: 'PROXSERV, À VOS CÔTÉS',
                  color: Color(0xFFFFB16B),
                ),
                const SizedBox(height: 14),
                Text(
                  'Votre problème a besoin d’une solution.',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontSize: compact ? 32 : 48,
                    height: 1.08,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Commencez par décrire votre besoin ou parcourez les métiers.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _explore(),
                      icon: const Icon(Icons.search),
                      label: const Text('Trouver un professionnel'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandAccent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 52),
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => context.go('/register'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                        minimumSize: const Size(0, 52),
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                      ),
                      child: const Text('S’inscrire'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, {required bool compact}) {
    final brand = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BrandLogo(height: 38),
        const SizedBox(width: 10),
        Text(
          'ProxServ',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
    final links = Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        TextButton(onPressed: () => _explore(), child: const Text('Explorer')),
        TextButton(
          onPressed: () => _scrollTo(_categoriesKey),
          child: const Text('Métiers'),
        ),
        TextButton(
          onPressed: () => _scrollTo(_aboutKey),
          child: const Text('À propos'),
        ),
        TextButton(
          onPressed: () => context.go('/register'),
          child: const Text('Professionnels'),
        ),
        TextButton(
          onPressed: () => context.go('/login'),
          child: const Text('Connexion'),
        ),
        TextButton(
          onPressed: () => context.go('/register'),
          child: const Text('Inscription'),
        ),
      ],
    );
    final navigation = compact
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [brand, const SizedBox(height: 18), links],
          )
        : Row(
            children: [
              brand,
              const SizedBox(width: 24),
              Expanded(
                child: Align(alignment: Alignment.centerRight, child: links),
              ),
            ],
          );

    return Container(
      width: double.infinity,
      color: const Color(0xFFF6F3FA),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 20 : 48,
        vertical: compact ? 32 : 40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            children: [
              navigation,
              const Divider(height: 32),
              Align(
                alignment: compact
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: Text(
                  '© ProxServ',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PublicExploreScreen extends StatefulWidget {
  final Metier? initialMetier;
  final String initialQuery;

  const PublicExploreScreen({
    super.key,
    this.initialMetier,
    this.initialQuery = '',
  });

  @override
  State<PublicExploreScreen> createState() => _PublicExploreScreenState();
}

class _PublicExploreScreenState extends State<PublicExploreScreen> {
  late Metier? _selectedMetier;

  @override
  void initState() {
    super.initState();
    _selectedMetier = widget.initialMetier;
  }

  @override
  void didUpdateWidget(covariant PublicExploreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialMetier != widget.initialMetier) {
      _selectedMetier = widget.initialMetier;
    }
  }

  void _continueToLogin() {
    final query = <String, String>{
      if (_selectedMetier != null) 'metier': _selectedMetier!.name,
      if (widget.initialQuery.isNotEmpty) 'q': widget.initialQuery,
    };
    final destination = Uri(
      path: '/login',
      queryParameters: query.isEmpty ? null : query,
    );
    context.go(destination.toString());
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;
    final trades = Metier.values.where((metier) => metier != Metier.autre);
    return Scaffold(
      drawer: compact
          ? Drawer(
              child: SafeArea(
                child: ListView(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: BrandLogo(height: 38),
                    ),
                    ListTile(
                      leading: const Icon(Icons.handyman_outlined),
                      title: const Text('Parcourir les métiers'),
                      onTap: () => Navigator.pop(context),
                    ),
                    ListTile(
                      leading: const Icon(Icons.login),
                      title: const Text('Connexion'),
                      onTap: _continueToLogin,
                    ),
                  ],
                ),
              ),
            )
          : null,
      appBar: AppBar(
        title: const BrandLogo(height: 34),
        actions: [
          TextButton(
            onPressed: _continueToLogin,
            child: Text(
              compact ? 'Connexion' : 'Connexion pour voir les profils',
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: ListView(
            padding: EdgeInsets.all(compact ? 20 : 40),
            children: [
              const _Eyebrow(text: 'RECHERCHE ET DÉCOUVERTE'),
              const SizedBox(height: 8),
              Text(
                'Explorez les métiers.',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (widget.initialQuery.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Votre besoin : « ${widget.initialQuery} »',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final metier in trades)
                    ChoiceChip(
                      avatar: CategoryImage(
                        metier: metier,
                        size: 28,
                        fallbackIcon: metierIcon(metier),
                      ),
                      label: Text(metier.label),
                      selected: _selectedMetier == metier,
                      onSelected: (_) =>
                          setState(() => _selectedMetier = metier),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                padding: EdgeInsets.all(compact ? 20 : 32),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 32,
                      color: AppColors.brandPrimary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Les profils sont accessibles après connexion.',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Les catégories restent visibles sans compte. Connectez-vous pour charger et consulter les professionnels.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _continueToLogin,
                      child: const Text('Se connecter pour continuer'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProblemInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const _ProblemInput({required this.controller, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => onSubmit(),
      style: const TextStyle(color: Color(0xFF24143D)),
      decoration: InputDecoration(
        hintText: 'Ex. : une fuite sous l’évier',
        hintStyle: const TextStyle(color: Color(0xFF6B6472)),
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.85)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.brandAccent, width: 2),
        ),
        suffixIcon: IconButton(
          tooltip: 'Rechercher',
          onPressed: onSubmit,
          icon: const Icon(Icons.arrow_forward),
        ),
      ),
    );
  }
}

class _TradeCard extends StatelessWidget {
  final Metier metier;
  final VoidCallback onTap;

  const _TradeCard({required this.metier, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Explorer le métier ${metier.label}',
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final imageSize = (constraints.maxWidth - 20)
                    .clamp(96.0, 240.0)
                    .toDouble();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: CategoryImage(
                        metier: metier,
                        size: imageSize,
                        fallbackIcon: metierIcon(metier),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            metier.label,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _EditorialRow extends StatelessWidget {
  final String image;
  final String eyebrow;
  final String title;
  final String description;
  final bool imageFirst;
  final bool compact;
  final VoidCallback? onAction;
  final String? actionLabel;

  const _EditorialRow({
    super.key,
    required this.image,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.imageFirst,
    required this.compact,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Eyebrow(text: eyebrow),
        const SizedBox(height: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontSize: compact ? 32 : 44,
            height: 1.08,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.55),
        ),
        if (onAction != null) ...[
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: onAction,
            child: Text(actionLabel ?? 'Créer un compte professionnel'),
          ),
        ],
      ],
    );

    final photo = ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: AspectRatio(
        aspectRatio: compact ? 1.35 : 1.16,
        child: Image.asset(
          image,
          fit: BoxFit.cover,
          errorBuilder: _assetErrorBuilder,
        ),
      ),
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (imageFirst) ...[photo, const SizedBox(height: 24)],
          text,
          if (!imageFirst) ...[const SizedBox(height: 24), photo],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: imageFirst
          ? [
              Expanded(child: photo),
              const SizedBox(width: 48),
              Expanded(child: text),
            ]
          : [
              Expanded(child: text),
              const SizedBox(width: 48),
              Expanded(child: photo),
            ],
    );
  }
}

class _StepCard extends StatelessWidget {
  final String number;
  final String title;
  final String description;

  const _StepCard({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.brandPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(description),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String eyebrow;
  final String title;

  const _SectionHeading({required this.eyebrow, required this.title});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Eyebrow(text: eyebrow),
        const SizedBox(height: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontSize: width < 600
                ? 32
                : width < 900
                ? 38
                : 44,
            height: 1.08,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _Eyebrow extends StatelessWidget {
  final String text;
  final Color? color;

  const _Eyebrow({required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: color ?? AppColors.brandPrimary,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

Widget _assetErrorBuilder(
  BuildContext context,
  Object error,
  StackTrace? stackTrace,
) {
  FlutterError.reportError(
    FlutterErrorDetails(
      exception: error,
      stack: stackTrace,
      library: 'ProxServ landing assets',
    ),
  );
  return ColoredBox(
    color: Theme.of(context).colorScheme.errorContainer,
    child: const Center(
      child: Icon(Icons.broken_image_outlined, color: AppColors.error),
    ),
  );
}
