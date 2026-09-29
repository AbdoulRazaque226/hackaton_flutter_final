// Écran de test de la carte, sans Firebase et avec de faux professionnels.
// Lancer avec : flutter run -t lib/main_map_test.dart
import 'package:flutter/material.dart';

import 'package:proxserv/data/models/enums.dart';
import 'package:proxserv/data/models/professional_profile.dart';
import 'package:proxserv/presentation/screens/map_screen.dart';

void main() => runApp(const MaterialApp(home: _Demo()));

class _Demo extends StatelessWidget {
  const _Demo();

  @override
  Widget build(BuildContext context) {
    const pros = [
      ProfessionalProfile(
        uid: '1', displayName: 'Kouassi Yao', phone: '0700000001',
        metier: Metier.plombier, zoneIntervention: 'Cocody',
        disponible: true, latitude: 5.3599, longitude: -3.9989,
      ),
      ProfessionalProfile(
        uid: '2', displayName: 'Aya Traoré', phone: '0700000002',
        metier: Metier.plombier, zoneIntervention: 'Marcory',
        disponible: true, latitude: 5.3011, longitude: -3.9803,
      ),
      ProfessionalProfile(
        uid: '3', displayName: 'Indisponible Test', phone: '0700000003',
        metier: Metier.plombier, zoneIntervention: 'Yopougon',
        disponible: false, latitude: 5.3450, longitude: -4.0900,
      ),
    ];
    return MapScreen(
      professionals: pros,
      onSelect: (p) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Fiche de ${p.displayName}'))),
    );
  }
}