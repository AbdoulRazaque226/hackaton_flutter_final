import '../../data/models/professional_profile.dart';
import 'distance.dart';

class ProfessionalSearchLocation {
  const ProfessionalSearchLocation.city({
    required this.country,
    required this.city,
  }) : latitude = null,
       longitude = null;

  const ProfessionalSearchLocation.gps({
    required this.latitude,
    required this.longitude,
  }) : country = null,
       city = null;

  final String? country;
  final String? city;
  final double? latitude;
  final double? longitude;

  bool get hasGps =>
      latitude != null &&
      longitude != null &&
      latitude!.isFinite &&
      longitude!.isFinite &&
      latitude! >= -90 &&
      latitude! <= 90 &&
      longitude! >= -180 &&
      longitude! <= 180;

  bool get hasCity =>
      country != null &&
      country!.trim().isNotEmpty &&
      city != null &&
      city!.trim().isNotEmpty;
}

ProfessionalSearchLocation? resolveSearchLocation({
  double? currentLatitude,
  double? currentLongitude,
  String? manualCountry,
  String? manualCity,
  String? profileCountry,
  String? profileCity,
}) {
  final current = ProfessionalSearchLocation.gps(
    latitude: currentLatitude ?? double.nan,
    longitude: currentLongitude ?? double.nan,
  );
  if (current.hasGps) return current;

  final manual = ProfessionalSearchLocation.city(
    country: manualCountry ?? '',
    city: manualCity ?? '',
  );
  if (manual.hasCity) return manual;
  if ((manualCountry?.trim().isNotEmpty ?? false) ||
      (manualCity?.trim().isNotEmpty ?? false)) {
    return null;
  }

  final usual = ProfessionalSearchLocation.city(
    country: profileCountry ?? '',
    city: profileCity ?? '',
  );
  return usual.hasCity ? usual : null;
}

List<ProWithDistance> filterProfessionalsByLocation(
  Iterable<ProfessionalProfile> professionals, {
  required ProfessionalSearchLocation location,
  String? metier,
  bool onlyAvailable = false,
  double radiusKm = 50,
}) {
  final matches = <ProWithDistance>[];

  for (final professional in professionals) {
    if (metier != null && professional.metier.name != metier) continue;
    if (onlyAvailable && !professional.disponible) continue;

    if (location.hasGps) {
      if (!hasPosition(professional)) continue;
      final km = distanceKm(
        location.latitude!,
        location.longitude!,
        professional.latitude!,
        professional.longitude!,
      );
      if (km <= radiusKm) matches.add((pro: professional, km: km));
      continue;
    }

    if (!location.hasCity) continue;
    if (_normalize(professional.country) != _normalize(location.country!)) {
      continue;
    }
    if (_normalize(professional.city) != _normalize(location.city!)) continue;
    matches.add((pro: professional, km: null));
  }

  matches.sort((a, b) {
    if (a.km == null && b.km == null) {
      return a.pro.displayName.compareTo(b.pro.displayName);
    }
    if (a.km == null) return 1;
    if (b.km == null) return -1;
    return a.km!.compareTo(b.km!);
  });
  return matches;
}

String _normalize(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll(RegExp('[àáâäãå]'), 'a')
    .replaceAll(RegExp('[èéêë]'), 'e')
    .replaceAll(RegExp('[ìíîï]'), 'i')
    .replaceAll(RegExp('[òóôöõ]'), 'o')
    .replaceAll(RegExp('[ùúûü]'), 'u')
    .replaceAll('ç', 'c')
    .replaceAll(RegExp(r'\s+'), ' ');
