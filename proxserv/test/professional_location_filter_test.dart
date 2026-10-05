import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proxserv/core/utils/distance.dart';
import 'package:proxserv/core/utils/professional_location_filter.dart';
import 'package:proxserv/data/models/app_user.dart';
import 'package:proxserv/data/models/enums.dart';
import 'package:proxserv/data/models/professional_profile.dart';
import 'package:proxserv/data/models/service_request.dart';

ProfessionalProfile _professional({
  required String uid,
  required Metier metier,
  required String country,
  required String city,
  bool available = true,
  double? latitude,
  double? longitude,
}) {
  return ProfessionalProfile(
    uid: uid,
    displayName: uid,
    phone: '',
    metier: metier,
    zoneIntervention: '',
    country: country,
    city: city,
    disponible: available,
    latitude: latitude,
    longitude: longitude,
  );
}

void main() {
  test('resolves search location by explicit GPS, manual, then profile', () {
    final gps = resolveSearchLocation(
      currentLatitude: 5.35,
      currentLongitude: -4,
      manualCountry: 'Côte d’Ivoire',
      manualCity: 'Abidjan',
      profileCountry: 'Burkina Faso',
      profileCity: 'Ouagadougou',
    );
    expect(gps?.hasGps, isTrue);

    final manual = resolveSearchLocation(
      manualCountry: 'Côte d’Ivoire',
      manualCity: 'Abidjan',
      profileCountry: 'Burkina Faso',
      profileCity: 'Ouagadougou',
    );
    expect(manual?.country, 'Côte d’Ivoire');
    expect(manual?.city, 'Abidjan');

    final usual = resolveSearchLocation(
      profileCountry: 'Burkina Faso',
      profileCity: 'Ouagadougou',
    );
    expect(usual?.country, 'Burkina Faso');
    expect(usual?.city, 'Ouagadougou');

    expect(
      resolveSearchLocation(
        manualCountry: 'Côte d’Ivoire',
        profileCountry: 'Burkina Faso',
        profileCity: 'Ouagadougou',
      ),
      isNull,
      reason: 'An incomplete explicit location must not fall back silently.',
    );
  });

  test(
    'city filters require the same city and country and honor trade/availability',
    () {
      final pros = [
        _professional(
          uid: 'Abidjan plumber',
          metier: Metier.plombier,
          country: 'Côte d’Ivoire',
          city: 'Abidjan',
          available: true,
        ),
        _professional(
          uid: 'Abidjan carpenter',
          metier: Metier.menuisier,
          country: 'Côte d’Ivoire',
          city: 'Abidjan',
        ),
        _professional(
          uid: 'Abidjan unavailable plumber',
          metier: Metier.plombier,
          country: 'Côte d’Ivoire',
          city: 'Abidjan',
          available: false,
        ),
        _professional(
          uid: 'Ouagadougou plumber',
          metier: Metier.plombier,
          country: 'Burkina Faso',
          city: 'Ouagadougou',
        ),
      ];

      final results = filterProfessionalsByLocation(
        pros,
        location: const ProfessionalSearchLocation.city(
          country: 'Cote d’Ivoire',
          city: 'Abidjan',
        ),
        metier: Metier.plombier.name,
        onlyAvailable: true,
      );

      expect(results.map((result) => result.pro.uid), ['Abidjan plumber']);
      expect(results.single.km, isNull);
    },
  );

  test('GPS results use real distances within 50km only', () {
    final pros = [
      _professional(
        uid: 'nearby',
        metier: Metier.plombier,
        country: '',
        city: '',
        latitude: 5.36,
        longitude: -4,
      ),
      _professional(
        uid: 'far',
        metier: Metier.plombier,
        country: '',
        city: '',
        latitude: 6,
        longitude: -4,
      ),
      _professional(
        uid: 'no coordinates',
        metier: Metier.plombier,
        country: '',
        city: '',
      ),
    ];

    final results = filterProfessionalsByLocation(
      pros,
      location: const ProfessionalSearchLocation.gps(
        latitude: 5.35,
        longitude: -4,
      ),
    );
    expect(results.map((result) => result.pro.uid), ['nearby']);
    expect(results.single.km, greaterThan(0));
    expect(hasPosition(pros.last), isFalse);
  });

  test('legacy models have no invented coordinates or location values', () {
    final user = AppUser.fromMap('client-1', {
      'role': 'client',
    });
    expect(user.email, isEmpty);
    expect(user.country, isEmpty);
    expect(user.city, isEmpty);

    final professional = ProfessionalProfile.fromMap('pro-1', {
      'displayName': 'Professionnel',
      'metier': 'plombier',
      'disponible': true,
    });
    expect(professional.latitude, isNull);
    expect(professional.longitude, isNull);
    expect(hasPosition(professional), isFalse);
  });

  test('invalid professional documents are excluded instead of cast', () {
    expect(
      ProfessionalProfile.tryFromMap('missing-metier', {
        'displayName': 'Profil incomplet',
        'metier': null,
      }),
      isNull,
    );
    expect(
      ProfessionalProfile.tryFromMap('unknown-metier', {
        'displayName': 'Profil invalide',
        'metier': 'unknown-trade',
      }),
      isNull,
    );
    expect(
      ProfessionalProfile.tryFromMap('valid', {
        'displayName': 'Profil valide',
        'metier': 'electricien',
        'disponible': true,
      })?.metier,
      Metier.electricien,
    );
  });

  test(
    'manual request location is stored separately without GPS coordinates',
    () {
      final request = ServiceRequest(
        id: 'request-1',
        clientId: 'client-1',
        clientName: 'Client',
        professionalId: 'pro-1',
        metier: Metier.plombier,
        description: 'Fuite d’eau',
        country: 'Côte d’Ivoire',
        city: 'Abidjan',
        neighborhood: 'Cocody',
        status: RequestStatus.enAttente,
        createdAt: DateTime(2026, 10, 5),
        updatedAt: DateTime(2026, 10, 5),
      );
      final map = request.toMap();

      expect(map['country'], 'Côte d’Ivoire');
      expect(map['city'], 'Abidjan');
      expect(map['neighborhood'], 'Cocody');
      expect(map.containsKey('latitude'), isFalse);
      expect(map.containsKey('longitude'), isFalse);

      final restored = ServiceRequest.fromMap('request-1', {
        ...map,
        'createdAt': Timestamp.fromDate(DateTime(2026, 10, 5)),
        'updatedAt': Timestamp.fromDate(DateTime(2026, 10, 5)),
      });
      expect(restored.city, 'Abidjan');
      expect(restored.latitude, isNull);
    },
  );
}
