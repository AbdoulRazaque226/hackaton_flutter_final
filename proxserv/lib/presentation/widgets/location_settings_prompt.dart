import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../data/services/location_service.dart';

Future<void> showLocationSettingsPrompt(
  BuildContext context,
  LocationException error,
  LocationService service,
) async {
  final loc = AppLocalizations.fromContext(context);
  final openLocationSettings =
      error.problem == LocationProblem.serviceDisabled;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(loc.text('Localisation nécessaire', 'Location required')),
      content: Text(error.message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(loc.text('Annuler', 'Cancel')),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.pop(dialogContext);
            if (openLocationSettings) {
              await service.openLocationSettings();
            } else {
              await service.openAppSettings();
            }
          },
          child: Text(loc.text('Ouvrir les réglages', 'Open settings')),
        ),
      ],
    ),
  );
}
