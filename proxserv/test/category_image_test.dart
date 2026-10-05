import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proxserv/data/models/enums.dart';
import 'package:proxserv/presentation/widgets/category_image.dart';

void main() {
  const assetPaths = {
    Metier.plombier: 'assets/images/categories/plombier.jpg',
    Metier.electricien: 'assets/images/categories/electricien.jpg',
    Metier.menuisier: 'assets/images/categories/menuisier.jpg',
    Metier.macon: 'assets/images/categories/macon.jpg',
    Metier.peintre: 'assets/images/categories/peintre.jpg',
    Metier.reparateur: 'assets/images/categories/reparateur.jpg',
    Metier.nettoyage: 'assets/images/categories/nettoyage.jpg',
  };

  testWidgets('each supported trade uses its category image', (tester) async {
    for (final entry in assetPaths.entries) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryImage(metier: entry.key, size: 32),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final image = tester.widget<Image>(find.byType(Image));
      expect((image.image as AssetImage).assetName, entry.value);
      expect(tester.takeException(), isNull, reason: entry.value);
    }
  });

  testWidgets('unsupported trade shows a visible fallback', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: CategoryImage(metier: Metier.autre, size: 32)),
      ),
    );

    expect(find.byIcon(Icons.handyman_outlined), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
