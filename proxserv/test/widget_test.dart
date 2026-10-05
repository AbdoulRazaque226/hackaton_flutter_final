import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:proxserv/core/theme/app_colors.dart';
import 'package:proxserv/core/theme/app_theme.dart';
import 'package:proxserv/data/models/enums.dart';
import 'package:proxserv/data/models/professional_profile.dart';
import 'package:proxserv/data/services/location_service.dart';
import 'package:proxserv/presentation/screens/professional_detail_screen.dart';
import 'package:proxserv/presentation/screens/request_form_screen.dart';
import 'package:proxserv/presentation/widgets/professional_card.dart';
import 'package:proxserv/presentation/widgets/request_status_style.dart';

class _TestLocationService extends LocationService {
  @override
  Future<Position> getCurrentPosition() async => Position(
    longitude: -4.0,
    latitude: 5.35,
    timestamp: DateTime(2026, 10, 4),
    accuracy: 1,
    altitude: 0,
    altitudeAccuracy: 1,
    heading: 0,
    headingAccuracy: 1,
    speed: 0,
    speedAccuracy: 0,
  );
}

class _UnavailableLocationService extends LocationService {
  @override
  Future<Position> getCurrentPosition() async {
    throw const LocationException(LocationProblem.permissionDenied);
  }
}

void main() {
  testWidgets('button theme has finite minimum widths inside rows', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        home: Scaffold(
          body: Wrap(
            children: [
              ElevatedButton(onPressed: () {}, child: const Text('Elevated')),
              FilledButton(onPressed: () {}, child: const Text('Filled')),
              OutlinedButton(onPressed: () {}, child: const Text('Outlined')),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    for (final button in [
      find.byType(ElevatedButton),
      find.byType(FilledButton),
      find.byType(OutlinedButton),
    ]) {
      expect(tester.getSize(button).width.isFinite, isTrue);
      expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
    }

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  test('RequestStatusStyle uses the exact semantic color for every status', () {
    final expected = <RequestStatus, Color>{
      RequestStatus.enAttente: AppColors.warning,
      RequestStatus.acceptee: AppColors.info,
      RequestStatus.enCours: AppColors.info,
      RequestStatus.terminee: AppColors.success,
      RequestStatus.refusee: AppColors.error,
      RequestStatus.annulee: const Color(0xFF64748B),
      RequestStatus.sansReponse: const Color(0xFF94A3B8),
    };
    final expectedBackground = <RequestStatus, Color>{
      RequestStatus.enAttente: AppColors.warningContainer,
      RequestStatus.acceptee: AppColors.infoContainer,
      RequestStatus.enCours: AppColors.infoContainer,
      RequestStatus.terminee: AppColors.successContainer,
      RequestStatus.refusee: AppColors.errorContainer,
      RequestStatus.annulee: AppColors.surfaceMutedLight,
      RequestStatus.sansReponse: AppColors.surfaceMutedLight,
    };

    for (final entry in expected.entries) {
      expect(RequestStatusStyle.foreground(entry.key), entry.value);
      expect(RequestStatusStyle.icon(entry.key), isA<IconData>());
      expect(
        RequestStatusStyle.background(entry.key, Brightness.light),
        expectedBackground[entry.key],
      );
    }
  });

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
    expect(find.text('Plumber'), findsOneWidget);
    expect(find.text('Available'), findsOneWidget);
    expect(find.text('Cocody, Abidjan'), findsOneWidget);
    expect(find.text('4,8'), findsNothing);
    expect(find.text('(12 reviews)'), findsNothing);
    expect(find.text('Aucun avis'), findsNothing);
  });

  testWidgets('ProfessionalCard uses dark theme surfaces without exceptions', (
    WidgetTester tester,
  ) async {
    final profile = ProfessionalProfile(
      uid: 'pro_dark',
      displayName: 'Kouassi Jean',
      metier: Metier.plombier,
      phone: '0102030405',
      zoneIntervention: 'Cocody, Abidjan',
      disponible: true,
      latitude: 5.35,
      longitude: -4.0,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme(),
        home: Scaffold(
          body: ListView(
            children: [ProfessionalCard(profile: profile, onTap: () {})],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Kouassi Jean'), findsOneWidget);
    expect(find.text('Available'), findsOneWidget);
    expect(find.text('New (0 reviews)'), findsNothing);
    expect(find.text('No reviews yet'), findsNothing);
  });

  testWidgets(
    'ProfessionalCard CTA lays out at mobile, tablet and desktop widths',
    (WidgetTester tester) async {
      final testProfile = ProfessionalProfile(
        uid: 'pro_responsive',
        displayName: 'Kouassi Jean',
        metier: Metier.plombier,
        phone: '0102030405',
        zoneIntervention: 'Cocody, Abidjan',
        disponible: true,
        latitude: 5.35,
        longitude: -4.00,
      );
      var openedProfile = false;

      for (final width in [360.0, 768.0, 1280.0]) {
        tester.view
          ..physicalSize = Size(width, 900)
          ..devicePixelRatio = 1;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme(),
            home: Scaffold(
              body: ListView(
                children: [
                  ProfessionalCard(
                    profile: testProfile,
                    onTap: () => openedProfile = true,
                  ),
                ],
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull, reason: 'width: $width');
        final button = find.widgetWithText(OutlinedButton, 'View profile');
        expect(button, findsOneWidget, reason: 'width: $width');
        final buttonSize = tester.getSize(button);
        expect(buttonSize.width.isFinite, isTrue, reason: 'width: $width');
        expect(
          buttonSize.height,
          greaterThanOrEqualTo(48),
          reason: 'width: $width',
        );
        expect(
          buttonSize.width,
          lessThanOrEqualTo(width),
          reason: 'width: $width',
        );

        await tester.tap(button);
        expect(openedProfile, isTrue, reason: 'width: $width');
        openedProfile = false;
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );

  testWidgets('RequestForm fits mobile, tablet and desktop widths', (
    WidgetTester tester,
  ) async {
    final professional = ProfessionalProfile(
      uid: 'pro_form',
      displayName: 'Kouassi Jean',
      metier: Metier.plombier,
      phone: '0102030405',
      zoneIntervention: 'Cocody, Abidjan',
      disponible: true,
      latitude: 5.35,
      longitude: -4.0,
    );

    for (final width in [360.0, 768.0, 1280.0]) {
      tester.view
        ..physicalSize = Size(width, 900)
        ..devicePixelRatio = 1;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: RequestFormScreen(
            professional: professional,
            locationService: _TestLocationService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'width: $width');
      expect(find.text('Intervention Request'), findsOneWidget);
      expect(find.text('Send Request'), findsOneWidget);
    }

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('ProfessionalDetail fits mobile, tablet and desktop widths', (
    WidgetTester tester,
  ) async {
    final professional = ProfessionalProfile(
      uid: 'pro_detail',
      displayName: 'Kouassi Jean',
      metier: Metier.plombier,
      phone: '0102030405',
      zoneIntervention: 'Cocody, Abidjan',
      disponible: true,
      latitude: 5.35,
      longitude: -4.0,
    );

    for (final width in [360.0, 390.0, 768.0, 1024.0, 1280.0]) {
      tester.view
        ..physicalSize = Size(width, 900)
        ..devicePixelRatio = 1;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: ProfessionalDetailScreen(profile: professional),
        ),
      );

      expect(tester.takeException(), isNull, reason: 'width: $width');
      expect(find.text('Kouassi Jean'), findsOneWidget);
      await tester.ensureVisible(find.text('Request Intervention'));
      expect(find.text('Request Intervention'), findsOneWidget);
    }

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets(
    'professional call action follows phone number, not availability',
    (tester) async {
      final professional = ProfessionalProfile(
        uid: 'pro_unavailable',
        displayName: 'Kouassi Jean',
        metier: Metier.plombier,
        phone: '0102030405',
        zoneIntervention: 'Cocody, Abidjan',
        disponible: false,
        latitude: 5.35,
        longitude: -4.0,
      );

      await tester.pumpWidget(
        MaterialApp(home: ProfessionalDetailScreen(profile: professional)),
      );
      final callButton = tester.widget<OutlinedButton>(
        find.byKey(const ValueKey('professional-call-button')),
      );
      expect(callButton.onPressed, isNotNull);

      final profileWithoutPhone = ProfessionalProfile(
        uid: 'pro_without_phone',
        displayName: 'Kouassi Jean',
        metier: Metier.plombier,
        phone: '',
        zoneIntervention: 'Cocody, Abidjan',
        disponible: true,
        latitude: 5.35,
        longitude: -4.0,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ProfessionalDetailScreen(profile: profileWithoutPhone),
        ),
      );
      final disabledCallButton = tester.widget<OutlinedButton>(
        find.byKey(const ValueKey('professional-call-button')),
      );
      expect(disabledCallButton.onPressed, isNull);
    },
  );

  testWidgets('RequestForm falls back to manual location when GPS is refused', (
    WidgetTester tester,
  ) async {
    final professional = ProfessionalProfile(
      uid: 'pro_no_gps',
      displayName: 'Kouassi Jean',
      metier: Metier.plombier,
      phone: '0102030405',
      zoneIntervention: 'Cocody, Abidjan',
      disponible: true,
      latitude: 5.35,
      longitude: -4.0,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RequestFormScreen(
          professional: professional,
          locationService: _UnavailableLocationService(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use my current location'));
    await tester.pumpAndSettle();

    expect(find.text('Location permission was denied.'), findsOneWidget);
    expect(find.text('Country'), findsOneWidget);
    expect(find.text('City'), findsOneWidget);
  });
}
