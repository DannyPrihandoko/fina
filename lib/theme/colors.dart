import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFFFDFDFD); // Premium Off-White
  static const Color cardPaleBlue = Color(0xFFF1F5FB); // Lighter blue for cards
  static const Color ctaAqua = Color(0xFF00BFA5); // Slightly darker aqua for better contrast
  static const Color textDarkBlue = Color(0xFF0D1B2A); // Darker blue for text
  static const Color textMuted = Color(0xFF62727B); // Better contrast for muted text
  static const Color borderColor = Color(0xFFE0E6ED); // Softer border
  static const Color white = Color(0xFFFFFFFF);
  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);

  // Dark Mode Palette
  static const Color darkBackground = Color(0xFF0A0E12); // Deep Obsidian
  static const Color darkCard = Color(0xFF151D26); // Dark Navy Card
  static const Color darkBorder = Color(0xFF242F3D); // Subtle Dark Border
  static const Color darkTextPrimary = Color(0xFFFDFDFD); // Off-White Text
  static const Color darkTextMuted = Color(0xFF8B9BA8); // Muted Blue-Grey

  // Semantic mappings
  static const Color primary = textDarkBlue;
  static const Color secondary = ctaAqua;
  static const Color surface = white;
  static const Color error = Color(0xFFD32F2F);

  // Premium Gradients
  static const List<Color> mainGradient = [Color(0xFF0D1B2A), Color(0xFF1B263B)];
  static const List<Color> accentGradient = [Color(0xFF00E5FF), Color(0xFF00BFA5)];
  static const List<Color> glassGradient = [Color(0x33FFFFFF), Color(0x0DFFFFFF)];
}
