import 'package:geolocator/geolocator.dart';

import 'firebase_service.dart';

// Raisons pour lesquelles on n'a pas pu obtenir la position.
enum LocationProblem {
  // Le GPS / la localisation est désactivé sur le téléphone.
  serviceDisabled,

  // L'utilisateur a refusé la permission (on peut la redemander).
  permissionDenied,

  // Refus définitif : seul l'écran des réglages permet de la réactiver.
  permissionDeniedForever,
}

class LocationException implements Exception {
  final LocationProblem problem;
  const LocationException(this.problem);

  String get message {
    switch (problem) {
      case LocationProblem.serviceDisabled:
        return 'La localisation est désactivée sur votre téléphone.';
      case LocationProblem.permissionDenied:
        return 'ProxServ a besoin de votre position pour trouver les '
            'professionnels proches de vous.';
      case LocationProblem.permissionDeniedForever:
        return 'La permission de localisation est bloquée. Activez-la dans '
            'les réglages de l\'application.';
    }
  }

  @override
  String toString() => 'LocationException(${problem.name})';
}

// Tout ce qui touche au GPS. Aucune dépendance à Riverpod : n'importe quel
// écran ou provider peut l'instancier.
class LocationService {
  // Vérifie le GPS et la permission (la demande si besoin), puis renvoie la
  // position actuelle. Lève une [LocationException] sinon.
  Future<Position> getCurrentPosition() async {
    await _ensurePermission();
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  // Flux de positions pour le suivi en temps réel. [distanceFilterMeters]
  // évite d'émettre (donc d'écrire dans Firestore) à chaque micro-mouvement.
  Stream<Position> watchPosition({int distanceFilterMeters = 50}) async* {
    await _ensurePermission();
    yield* Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
      ),
    );
  }

  // Pour le professionnel : lit sa position et l'écrit dans son profil
  // Firestore (réutilise FirebaseService.updateMaPosition).
  Future<Position> syncMyPosition({
    required FirebaseService firebase,
    required String uid,
  }) async {
    final position = await getCurrentPosition();
    await firebase.updateMaPosition(uid, position.latitude, position.longitude);
    return position;
  }

  Future<bool> openAppSettings() => Geolocator.openAppSettings();
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  Future<void> _ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(LocationProblem.serviceDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException(LocationProblem.permissionDenied);
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(LocationProblem.permissionDeniedForever);
    }
  }
}
