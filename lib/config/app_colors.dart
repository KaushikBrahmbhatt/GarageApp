import 'package:flutter/material.dart';

/// Centralized Color Palette
/// To change application colors in the future, edit the color values below.
class AppColors {
  // ── Primary Palette ────────────────────────────────────────────────────────
  static const Color primary       = Color(0xFF0B42FA); // Royal Blue
  static const Color primaryDark   = Color(0xFF002CD1); // Darker Royal Blue
  static const Color primaryLight  = Color(0xFFEEF2FF); // Soft Blue Tint
  static const Color primaryAccent = Color(0xFF2563EB); // Accent Blue

  // ── Surface & Canvas ───────────────────────────────────────────────────────
  static const Color background    = Color(0xFFF8FAFC); // Light Canvas (#F8FAFC)
  static const Color surface       = Color(0xFFFFFFFF); // Pure White Surface
  static const Color cardBorder    = Color(0xFFE2E8F0); // Subtle Border Color

  // ── Text & Typography ──────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF0F172A); // Dark Charcoal Text
  static const Color textSecondary = Color(0xFF64748B); // Slate Muted Text
  static const Color textLight     = Color(0xFF94A3B8); // Light Grey Text

  // ── Status & Accent Badges ─────────────────────────────────────────────────
  static const Color success       = Color(0xFF10B981); // Emerald Green (Completed/Done)
  static const Color successBg     = Color(0xFFD1FAE5); // Soft Green Background
  static const Color successText   = Color(0xFF047857); // Dark Green Text

  static const Color warning       = Color(0xFFF59E0B); // Amber/Yellow (In Progress/New)
  static const Color warningBg     = Color(0xFFFEF3C7); // Soft Amber Background
  static const Color warningText   = Color(0xFFD97706); // Dark Amber Text

  static const Color extraWork     = Color(0xFFF97316); // Bright Orange for Extra Work
  static const Color extraWorkBg   = Color(0xFFFFEDD5); // Soft Orange Background

  static const Color error         = Color(0xFFEF4444); // Red Error
  static const Color errorBg       = Color(0xFFFEE2E2); // Soft Red Background
}
