import 'package:flutter/material.dart';

/// Design System ProxServ - Palette Officielle (Mission 2A Gelée)
class AppColors {
  AppColors._();

  // -- COULEURS DE MARQUE PROXSERV (VIOLET & ORANGE) --
  static const Color brandPrimary = Color(0xFF6D28D9); // Violet officiel
  static const Color brandPrimaryDark = Color(0xFF5B21B6); // Violet sombre
  static const Color brandPrimaryLight = Color(0xFFDDD6FE); // Violet clair

  static const Color brandAccent = Color(0xFFF97316); // Orange d'accent
  static const Color brandAccentDark = Color(0xFFC2410C); // Orange sombre
  static const Color brandAccentLight = Color(0xFFFFEDD5); // Orange clair

  // -- COULEURS SÉMANTIQUES (INDÉPENDANTES DE LA MARQUE) --
  // Succès / Disponible / Terminée
  static const Color success = Color(0xFF16A34A);
  static const Color successContainer = Color(0xFFDCFCE7);

  // Warning / Attention / En attente
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xFFFEF3C7);

  // Error / Refusé / Annulé / Danger / Bloqué
  static const Color error = Color(0xFFDC2626);
  static const Color errorContainer = Color(0xFFFEE2E2);

  // Info / En cours (Correction sémantique : Bleu, pas Violet) / GPS
  static const Color info = Color(0xFF2563EB);
  static const Color infoContainer = Color(0xFFDBEAFE);

  // -- COULEURS NEUTRES (MODE CLAIR / LIGHT MODE) --
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceMutedLight = Color(0xFFF1F5F9);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color borderLight = Color(0xFFE2E8F0);

  // -- COULEURS NEUTRES (MODE SOMBRE / DARK MODE) --
  static const Color bgDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color surfaceMutedDark = Color(0xFF334155);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color borderDark = Color(0xFF334155);
}
