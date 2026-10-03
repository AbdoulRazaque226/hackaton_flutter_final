import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proxserv/data/models/enums.dart';
import 'package:proxserv/data/models/professional_profile.dart';
import 'package:proxserv/presentation/widgets/professional_card.dart';

void main() {
  testWidgets('ProfessionalCard displays profile name and metier correctly', (
    WidgetTester tester,
  ) async {
    final testProfile = ProfessionalProfile(
      uid: 'pro_123',
      displayName: 'Kouassi Jean',
      metier: Metier.plombier,
      phone: '0102030405',
      zoneIntervention: 'Cocody, Abidjan',
      disponible: true,
      latitude: 5.35,
      longitude: -4.00,
      noteMoyenne: 4.8,
      nombreEvaluations: 12,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ProfessionalCard(profile: testProfile)),
      ),
    );

    expect(find.text('Kouassi Jean'), findsOneWidget);
    expect(find.text('Plombier'), findsOneWidget);
    expect(find.text('Disponible'), findsOneWidget);
    expect(find.text('Cocody, Abidjan'), findsOneWidget);
  });
}
