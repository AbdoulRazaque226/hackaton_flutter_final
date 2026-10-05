import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/enums.dart';

class HomeHero extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final void Function(String query, Metier metier) onNeedSelected;
  final VoidCallback onExplore;

  const HomeHero({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onNeedSelected,
    required this.onExplore,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.fromContext(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                color: colors.secondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              loc.text('RAPIDE · HONNÊTE · LOCAL', 'FAST · HONEST · LOCAL'),
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          loc.homeQuestion,
          style: theme.textTheme.displayLarge?.copyWith(
            fontSize: compactFontSize(context),
            height: 1.04,
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          loc.text(
            'Décrivez simplement votre besoin et trouvez un professionnel près de chez vous.',
            'Describe what you need and find a professional in your area.',
          ),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.92),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: loc.searchHint,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: loc.text('Effacer', 'Clear'),
                    onPressed: () {
                      searchController.clear();
                      onSearchChanged('');
                    },
                    icon: const Icon(Icons.close),
                  ),
            filled: true,
            fillColor: colors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            _NeedExample(
              label: loc.text('Fuite d’eau', 'Water leak'),
              onPressed: () => onNeedSelected(
                loc.text('Fuite d’eau', 'Water leak'),
                Metier.plombier,
              ),
            ),
            _NeedExample(
              label: loc.text('Panne électrique', 'Power outage'),
              onPressed: () => onNeedSelected(
                loc.text('Panne électrique', 'Power outage'),
                Metier.electricien,
              ),
            ),
            _NeedExample(
              label: loc.text('Réparation meuble', 'Furniture repair'),
              onPressed: () => onNeedSelected(
                loc.text('Réparation meuble', 'Furniture repair'),
                Metier.menuisier,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: onExplore,
            icon: const Icon(Icons.arrow_forward),
            label: Text(
              loc.text('Explorer les professionnels', 'Explore professionals'),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, AppSpacing.touchTarget),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            ),
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        return ClipRRect(
          key: const ValueKey('home-hero-card'),
          borderRadius: AppSpacing.borderRadiusLg,
          child: SizedBox(
            width: double.infinity,
            height: compact ? 680 : 560,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/hero/hero_home.jpg',
                  key: const ValueKey('home-hero-image'),
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                  errorBuilder: (context, error, stackTrace) {
                    FlutterError.reportError(
                      FlutterErrorDetails(
                        exception: error,
                        stack: stackTrace,
                        library: 'HomeHero',
                        context: ErrorDescription(
                          'while loading assets/images/hero/hero_home.jpg',
                        ),
                      ),
                    );
                    return ColoredBox(
                      color: colors.errorContainer,
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 56,
                        color: colors.error,
                      ),
                    );
                  },
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: compact
                        ? const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x080D1020),
                              Color(0x60100D1D),
                              Color(0xE8100D1D),
                            ],
                            stops: [0.08, 0.42, 1],
                          )
                        : const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Color(0xE8100D1D),
                              Color(0xB3100D1D),
                              Color(0x26100D1D),
                            ],
                            stops: [0, 0.58, 1],
                          ),
                  ),
                ),
                Align(
                  alignment: compact
                      ? Alignment.bottomLeft
                      : Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: compact ? 680 : 720,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(
                        compact ? AppSpacing.lg : AppSpacing.xxl,
                      ),
                      child: content,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  double compactFontSize(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 400) return 38;
    if (width < 720) return 42;
    return 56;
  }
}

class _NeedExample extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _NeedExample({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: const Icon(Icons.arrow_outward, size: 14),
      label: Text(label),
      onPressed: onPressed,
      backgroundColor: Theme.of(context).colorScheme.surface,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
    );
  }
}

class HomeFinalCta extends StatelessWidget {
  final VoidCallback onExplore;

  const HomeFinalCta({super.key, required this.onExplore});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.fromContext(context);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: AppSpacing.borderRadiusLg,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final text = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.text('Besoin d’un professionnel ?', 'Need a professional?'),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                loc.text(
                  'Parcourez les profils disponibles près de chez vous.',
                  'Explore available profiles in your area.',
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          );
          final button = FilledButton.icon(
            onPressed: onExplore,
            icon: const Icon(Icons.search),
            label: Text(
              loc.text('Trouver un professionnel', 'Find a professional'),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, AppSpacing.touchTarget),
            ),
          );
          return compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    text,
                    const SizedBox(height: AppSpacing.lg),
                    button,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: text),
                    const SizedBox(width: AppSpacing.lg),
                    button,
                  ],
                );
        },
      ),
    );
  }
}

class HomeEditorialBand extends StatelessWidget {
  final bool visualFirst;
  final IconData icon;
  final String title;
  final String body;

  const HomeEditorialBand({
    super.key,
    required this.visualFirst,
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(body, style: theme.textTheme.bodyLarge),
      ],
    );
    final visual = Container(
      width: 148,
      height: 112,
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Icon(icon, size: 42, color: colors.onSecondaryContainer),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: AppSpacing.borderRadiusLg,
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    copy,
                    const SizedBox(height: AppSpacing.lg),
                    Align(
                      alignment: visualFirst
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: visual,
                    ),
                  ],
                )
              : Row(
                  children: visualFirst
                      ? [
                          visual,
                          const SizedBox(width: AppSpacing.xxl),
                          Expanded(child: copy),
                        ]
                      : [
                          Expanded(child: copy),
                          const SizedBox(width: AppSpacing.xxl),
                          visual,
                        ],
                ),
        );
      },
    );
  }
}
