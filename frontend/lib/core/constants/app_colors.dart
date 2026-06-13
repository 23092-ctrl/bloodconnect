import 'package:flutter/material.dart';

class AppColors {
  // ── Brand rouge sang — utilisé UNIQUEMENT pour les éléments liés au sang ──
  static const primary = Color(0xFFC62828);       // Rouge sang (bouton Donate, badges)
  static const primaryDark = Color(0xFF8E0000);
  static const primaryLight = Color(0xFFFF5F52);

  // ── Couleur secondaire (actions positives, confirm) ──────────────────────
  static const secondary = Color(0xFF1565C0);      // Bleu
  static const secondaryLight = Color(0xFF5E92F3);

  // ── Statuts inventaire ───────────────────────────────────────────────────
  static const criticalRed = Color(0xFFC62828);
  static const lowOrange = Color(0xFFE65100);
  static const normalGreen = Color(0xFF2E7D32);

  // ── Surfaces light ───────────────────────────────────────────────────────
  static const background = Color(0xFFF5F7FA);
  static const surface = Color(0xFFFFFFFF);
  static const cardLight = Color(0xFFFFFFFF);

  // ── Surfaces dark ────────────────────────────────────────────────────────
  static const backgroundDark = Color(0xFF121212);
  static const surfaceDark = Color(0xFF1E1E1E);
  static const cardDark = Color(0xFF2A2A2A);

  // ── Texte ────────────────────────────────────────────────────────────────
  static const onPrimary = Color(0xFFFFFFFF);
  static const onBackground = Color(0xFF1A1A1A);
  static const onSurface = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF6B7280);
  static const divider = Color(0xFFE5E7EB);

  // ── Divers ───────────────────────────────────────────────────────────────
  static const error = Color(0xFFB00020);

  // ── Couleurs par groupe sanguin ──────────────────────────────────────────
  static const bloodTypes = {
    'A+': Color(0xFFE53935),
    'A-': Color(0xFFEF9A9A),
    'B+': Color(0xFF1E88E5),
    'B-': Color(0xFF90CAF9),
    'AB+': Color(0xFF8E24AA),
    'AB-': Color(0xFFCE93D8),
    'O+': Color(0xFF43A047),
    'O-': Color(0xFFA5D6A7),
  };
}
