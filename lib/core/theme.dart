import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppTheme { light, dark }

class ThemeNotifier extends ChangeNotifier {
	ThemeNotifier([this._theme = AppTheme.light]);

	AppTheme _theme;
	AppTheme get theme => _theme;

	ThemeData get themeData => _getThemeData(_theme);

	void setTheme(AppTheme t) {
		_theme = t;
		notifyListeners();
	}

	// Public mappings for UI
	static const Map<AppTheme, String> labels = {
		AppTheme.light: 'Light',
		AppTheme.dark: 'Dark',
	};

	static const Map<AppTheme, IconData> icons = {
		AppTheme.light: Icons.light_mode_rounded,
		AppTheme.dark: Icons.dark_mode_rounded,
	};

	// Light theme - Writer-friendly with warm tones
	static final ThemeData _lightTheme = ThemeData(
		useMaterial3: true,
		brightness: Brightness.light,
		// Handwriting font for titles, regular font for body
		textTheme: GoogleFonts.caveatTextTheme(ThemeData.light().textTheme).copyWith(
			// Use handwriting for display text
			displayLarge: GoogleFonts.caveat(fontSize: 57, fontWeight: FontWeight.w400),
			displayMedium: GoogleFonts.caveat(fontSize: 45, fontWeight: FontWeight.w400),
			displaySmall: GoogleFonts.caveat(fontSize: 36, fontWeight: FontWeight.w400),
			headlineLarge: GoogleFonts.caveat(fontSize: 32, fontWeight: FontWeight.w600),
			headlineMedium: GoogleFonts.caveat(fontSize: 28, fontWeight: FontWeight.w600),
			headlineSmall: GoogleFonts.caveat(fontSize: 24, fontWeight: FontWeight.w600),
			titleLarge: GoogleFonts.caveat(fontSize: 28, fontWeight: FontWeight.w700),
			titleMedium: GoogleFonts.caveat(fontSize: 24, fontWeight: FontWeight.w600),
			titleSmall: GoogleFonts.caveat(fontSize: 20, fontWeight: FontWeight.w600),
			// Use Literata for readable body text
			bodyLarge: GoogleFonts.literata(fontSize: 16, fontWeight: FontWeight.w400),
			bodyMedium: GoogleFonts.literata(fontSize: 14, fontWeight: FontWeight.w400),
			bodySmall: GoogleFonts.literata(fontSize: 12, fontWeight: FontWeight.w400),
			labelLarge: GoogleFonts.literata(fontSize: 14, fontWeight: FontWeight.w500),
			labelMedium: GoogleFonts.literata(fontSize: 12, fontWeight: FontWeight.w500),
			labelSmall: GoogleFonts.literata(fontSize: 11, fontWeight: FontWeight.w500),
		),
		colorScheme: ColorScheme.fromSeed(
			seedColor: const Color(0xFF8B5E3C), // Warm brown for writing
			brightness: Brightness.light,
		).copyWith(
			surface: const Color(0xFFFFFBF5), // Warm paper-like background
		),
		cardTheme: const CardThemeData(
			elevation: 2,
			shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
		),
		appBarTheme: AppBarTheme(
			elevation: 0,
			scrolledUnderElevation: 2,
			centerTitle: false,
			titleTextStyle: GoogleFonts.caveat(
				fontSize: 28,
				fontWeight: FontWeight.w700,
				color: const Color(0xFF5D4037),
			),
		),
		floatingActionButtonTheme: const FloatingActionButtonThemeData(
			elevation: 4,
		),
	);

	// Dark theme - Eye-friendly for night writing
	static final ThemeData _darkTheme = ThemeData(
		useMaterial3: true,
		brightness: Brightness.dark,
		textTheme: GoogleFonts.caveatTextTheme(ThemeData.dark().textTheme).copyWith(
			displayLarge: GoogleFonts.caveat(fontSize: 57, fontWeight: FontWeight.w400),
			displayMedium: GoogleFonts.caveat(fontSize: 45, fontWeight: FontWeight.w400),
			displaySmall: GoogleFonts.caveat(fontSize: 36, fontWeight: FontWeight.w400),
			headlineLarge: GoogleFonts.caveat(fontSize: 32, fontWeight: FontWeight.w600),
			headlineMedium: GoogleFonts.caveat(fontSize: 28, fontWeight: FontWeight.w600),
			headlineSmall: GoogleFonts.caveat(fontSize: 24, fontWeight: FontWeight.w600),
			titleLarge: GoogleFonts.caveat(fontSize: 28, fontWeight: FontWeight.w700),
			titleMedium: GoogleFonts.caveat(fontSize: 24, fontWeight: FontWeight.w600),
			titleSmall: GoogleFonts.caveat(fontSize: 20, fontWeight: FontWeight.w600),
			bodyLarge: GoogleFonts.literata(fontSize: 16, fontWeight: FontWeight.w400),
			bodyMedium: GoogleFonts.literata(fontSize: 14, fontWeight: FontWeight.w400),
			bodySmall: GoogleFonts.literata(fontSize: 12, fontWeight: FontWeight.w400),
			labelLarge: GoogleFonts.literata(fontSize: 14, fontWeight: FontWeight.w500),
			labelMedium: GoogleFonts.literata(fontSize: 12, fontWeight: FontWeight.w500),
			labelSmall: GoogleFonts.literata(fontSize: 11, fontWeight: FontWeight.w500),
		),
		colorScheme: ColorScheme.fromSeed(
			seedColor: const Color(0xFFD7A86E), // Warm amber for dark mode
			brightness: Brightness.dark,
		).copyWith(
			surface: const Color(0xFF1C1B1F),
		),
		cardTheme: const CardThemeData(
			elevation: 4,
			shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
		),
		appBarTheme: AppBarTheme(
			elevation: 0,
			scrolledUnderElevation: 2,
			centerTitle: false,
			titleTextStyle: GoogleFonts.caveat(
				fontSize: 28,
				fontWeight: FontWeight.w700,
				color: const Color(0xFFE8DEF8),
			),
		),
		floatingActionButtonTheme: const FloatingActionButtonThemeData(
			elevation: 4,
		),
	);

	ThemeData _getThemeData(AppTheme t) {
		switch (t) {
			case AppTheme.light:
				return _lightTheme;
			case AppTheme.dark:
				return _darkTheme;
		}
	}
  
	// helper to get icon for theme
	static IconData iconFor(AppTheme t) => icons[t]!;
}

