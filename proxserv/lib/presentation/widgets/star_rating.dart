import 'package:flutter/material.dart';

/// Affichage d'une note sous forme d'étoiles, sur 5.
///
/// La note moyenne est un décimal : les demi-étoiles sont rendues en
/// superposant une étoile pleine rognée sur une étoile vide. Sans cela, une
/// moyenne de 4,5 afficherait 4 étoiles pleines et laisserait croire à une
/// note de 4.
class StarRating extends StatelessWidget {
  /// Valeur affichée. Peut être fractionnaire (moyenne) ou entière (note d'un
  /// avis). Les valeurs hors de 0..5 sont ramenées dans l'intervalle.
  final double value;

  /// Taille de chaque étoile.
  final double size;

  /// Nombre d'étoiles à dessiner.
  final int starCount;

  /// Affiche la valeur numérique à côté des étoiles (`4,5`).
  final bool showValue;

  /// Affiche le nombre d'évaluations sous les étoiles.
  final int? reviewCount;

  /// Indique qu'aucune évaluation n'a encore été donnée : dessine des
  /// étoiles vides sans valeur ni compteur.
  final bool isEmpty;

  final Color? color;
  final TextStyle? valueStyle;
  final TextStyle? captionStyle;

  const StarRating({
    super.key,
    required this.value,
    this.size = 18,
    this.starCount = 5,
    this.showValue = false,
    this.reviewCount,
    this.isEmpty = false,
    this.color,
    this.valueStyle,
    this.captionStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final starColor = color ?? theme.colorScheme.tertiary;
    final clamped = value.isNaN ? 0.0 : value.clamp(0.0, starCount.toDouble());

    final stars = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= starCount; i++)
          Padding(
            padding: EdgeInsets.only(right: i == starCount ? 0 : 1),
            child: _Star(
              fill: (clamped - (i - 1)).clamp(0.0, 1.0),
              size: size,
              color: starColor,
            ),
          ),
      ],
    );

    if (isEmpty) return stars;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            stars,
            if (showValue) ...[
              const SizedBox(width: 8),
              Text(
                // Une note entière n'a pas de décimale à afficher.
                clamped == clamped.roundToDouble()
                    ? clamped.toStringAsFixed(0)
                    : clamped.toStringAsFixed(1),
                style: valueStyle ?? theme.textTheme.titleMedium,
              ),
            ],
          ],
        ),
        if (reviewCount != null) ...[
          const SizedBox(height: 2),
          Text(
            reviewCount == 1
                ? '1 avis'
                : '$reviewCount avis',
            style: captionStyle ?? theme.textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

/// Une étoile : fond vide, puis remplissage rogné à la proportion demandée.
class _Star extends StatelessWidget {
  final double fill;
  final double size;
  final Color color;

  const _Star({required this.fill, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    final outline = Icon(Icons.star_outline, size: size, color: color);

    if (fill >= 1) {
      return Icon(Icons.star, size: size, color: color);
    }
    if (fill <= 0) return outline;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          outline,
          ClipRect(
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: fill,
              child: Icon(Icons.star, size: size, color: color),
            ),
          ),
        ],
      ),
    );
  }
}