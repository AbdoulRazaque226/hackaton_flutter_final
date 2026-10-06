import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proxserv/presentation/widgets/star_rating.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: Center(child: child)));
}

void main() {
  /// Nombre d'étoiles pleines dessinées par [StarRating].
  ///
  /// On compte les widgets plutôt que de lire une couleur : une demi-étoile
  /// superpose une étoile pleine rognée, donc `Icons.star` est présent aussi
  /// pour une note fractionnaire. C'est `IconButton`-free ici, on inspecte donc
  /// la liste des enfants de la Row.
  int fullStars(WidgetTester tester) {
    return tester
        .widgetList<Icon>(find.byIcon(Icons.star))
        .where((icon) => icon.size != null)
        .length;
  }

  testWidgets('une note entière ne dessine que des étoiles pleines', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const StarRating(value: 3)));

    expect(fullStars(tester), 3);
    expect(find.byIcon(Icons.star_outline), findsNWidgets(2));
  });

  testWidgets('une demi-etoile est rognee et non comptee comme pleine', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const StarRating(value: 3.5)));

    // 3 étoiles remplies en propre, plus une icône pleine rognée à 50 %.
    expect(fullStars(tester), 4);
  });

  testWidgets('une note de zéro ne remplit aucune étoile', (tester) async {
    await tester.pumpWidget(_wrap(const StarRating(value: 0)));

    expect(fullStars(tester), 0);
    expect(find.byIcon(Icons.star_outline), findsNWidgets(5));
  });

  testWidgets('les valeurs hors intervalle sont ramenées', (tester) async {
    await tester.pumpWidget(_wrap(const StarRating(value: 9)));
    expect(fullStars(tester), 5);

    await tester.pumpWidget(_wrap(const StarRating(value: -3)));
    expect(fullStars(tester), 0);
  });

  testWidgets('la valeur numérique est affichee a cote des etoiles', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const StarRating(value: 4, showValue: true)));

    // Une note entiere ne doit pas afficher « 4.0 ».
    expect(find.text('4'), findsOneWidget);
    expect(find.text('4.0'), findsNothing);
  });

  testWidgets('une moyenne affiche une decimale', (tester) async {
    await tester.pumpWidget(_wrap(const StarRating(value: 4.5, showValue: true)));

    expect(find.text('4.5'), findsOneWidget);
  });

  testWidgets('le compteur d avis est au pluriel', (tester) async {
    await tester.pumpWidget(_wrap(const StarRating(value: 4, reviewCount: 1)));
    expect(find.text('1 avis'), findsOneWidget);

    await tester.pumpWidget(_wrap(const StarRating(value: 4, reviewCount: 12)));
    expect(find.text('12 avis'), findsOneWidget);
  });

  testWidgets('un état vide ne montre ni valeur ni compteur', (tester) async {
    await tester.pumpWidget(
      _wrap(const StarRating(value: 0, showValue: true, isEmpty: true)),
    );

    expect(find.text('0'), findsNothing);
    expect(find.text('0.0'), findsNothing);
  });
}