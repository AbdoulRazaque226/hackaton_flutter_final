import 'dart:math' as math;

import '../../data/models/professional_profile.dart';

// Un professionnel avec sa distance au client (en km).
// [km] est null si le professionnel n'a pas encore partagé sa position
// (à l'inscription, latitude et longitude valent 0).
typedef ProWithDistance = ({ProfessionalProfile pro, double? km});

// Distance à vol d'oiseau entre deux points GPS (formule de Haversine), en km.
double distanceKm(double lat1, double lon1, double lat2, double lon2) {
  const earthRadiusKm = 6371.0;
  final dLat = _rad(lat2 - lat1);
  final dLon = _rad(lon2 - lon1);
  final a =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(_rad(lat1)) *
          math.cos(_rad(lat2)) *
          math.pow(math.sin(dLon / 2), 2);
  return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double _rad(double deg) => deg * math.pi / 180;

// Vrai si le professionnel a une vraie position (pas le 0,0 par défaut).
bool hasPosition(ProfessionalProfile pro) =>
    !(pro.latitude == 0 && pro.longitude == 0);

// Calcule la distance de chaque professionnel au client et trie du plus
// proche au plus loin. Les professionnels sans position passent en dernier.
// Avec [onlyAvailable], seuls les professionnels disponibles sont gardés.
List<ProWithDistance> sortByProximity(
  List<ProfessionalProfile> pros, {
  required double fromLat,
  required double fromLon,
  bool onlyAvailable = false,
}) {
  final result = <ProWithDistance>[
    for (final p in pros)
      if (!onlyAvailable || p.disponible)
        (
          pro: p,
          km: hasPosition(p)
              ? distanceKm(fromLat, fromLon, p.latitude, p.longitude)
              : null,
        ),
  ];

  result.sort((a, b) {
    if (a.km == null && b.km == null) return 0;
    if (a.km == null) return 1;
    if (b.km == null) return -1;
    return a.km!.compareTo(b.km!);
  });
  return result;
}

// "650 m" sous 1 km, "2,3 km" au-delà, "Position inconnue" si null.
String formatDistance(double? km) {
  if (km == null) return 'Position inconnue';
  if (km < 1) return '${(km * 1000).round()} m';
  return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
}
