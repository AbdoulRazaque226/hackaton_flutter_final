import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/enums.dart';

class RequestStatusStyle {
  const RequestStatusStyle._();

  static Color foreground(RequestStatus status) => switch (status) {
    RequestStatus.enAttente => AppColors.warning,
    RequestStatus.acceptee || RequestStatus.enCours => AppColors.info,
    RequestStatus.terminee => AppColors.success,
    RequestStatus.refusee => AppColors.error,
    RequestStatus.annulee => const Color(0xFF64748B),
    RequestStatus.sansReponse => const Color(0xFF94A3B8),
  };

  static Color background(RequestStatus status, Brightness brightness) {
    if (status == RequestStatus.annulee ||
        status == RequestStatus.sansReponse) {
      return brightness == Brightness.dark
          ? AppColors.surfaceMutedDark
          : AppColors.surfaceMutedLight;
    }

    return switch (status) {
      RequestStatus.enAttente => AppColors.warningContainer,
      RequestStatus.acceptee ||
      RequestStatus.enCours => AppColors.infoContainer,
      RequestStatus.terminee => AppColors.successContainer,
      RequestStatus.refusee => AppColors.errorContainer,
      RequestStatus.annulee ||
      RequestStatus.sansReponse => AppColors.surfaceMutedLight,
    };
  }

  static IconData icon(RequestStatus status) => switch (status) {
    RequestStatus.enAttente => Icons.hourglass_empty,
    RequestStatus.acceptee => Icons.check_circle_outline,
    RequestStatus.enCours => Icons.sync,
    RequestStatus.terminee => Icons.task_alt,
    RequestStatus.refusee => Icons.cancel_outlined,
    RequestStatus.annulee => Icons.do_not_disturb,
    RequestStatus.sansReponse => Icons.help_outline,
  };
}
