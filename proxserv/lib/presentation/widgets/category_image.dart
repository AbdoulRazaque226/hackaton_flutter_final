import 'package:flutter/material.dart';

import '../../data/models/enums.dart';

class CategoryImage extends StatelessWidget {
  final Metier metier;
  final double size;
  final IconData fallbackIcon;

  const CategoryImage({
    super.key,
    required this.metier,
    required this.size,
    this.fallbackIcon = Icons.handyman_outlined,
  });

  String? get _assetPath => switch (metier) {
    Metier.plombier => 'assets/images/categories/plombier.jpg',
    Metier.electricien => 'assets/images/categories/electricien.jpg',
    Metier.menuisier => 'assets/images/categories/menuisier.jpg',
    Metier.macon => 'assets/images/categories/macon.jpg',
    Metier.peintre => 'assets/images/categories/peintre.jpg',
    Metier.reparateur => 'assets/images/categories/reparateur.jpg',
    Metier.nettoyage => 'assets/images/categories/nettoyage.jpg',
    Metier.autre => null,
  };

  @override
  Widget build(BuildContext context) {
    final assetPath = _assetPath;
    final theme = Theme.of(context);
    final fallback = Icon(
      fallbackIcon,
      size: size * 0.7,
      color: theme.colorScheme.onSurfaceVariant,
    );

    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.24),
          child: ColoredBox(
            color: theme.colorScheme.surfaceContainerHighest,
            child: assetPath == null
                ? Center(child: fallback)
                : Image.asset(
                    assetPath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      FlutterError.reportError(
                        FlutterErrorDetails(
                          exception: error,
                          stack: stackTrace,
                          library: 'CategoryImage',
                          context: ErrorDescription(
                            'while loading $assetPath',
                          ),
                        ),
                      );
                      return Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: size * 0.7,
                          color: theme.colorScheme.error,
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
