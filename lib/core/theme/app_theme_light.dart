import 'package:beltech/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── iOS-style light theme ─────────────────────────────────────────────────────
//
// Design language: Apple Human Interface Guidelines
//   • systemGroupedBackground  : #F2F2F7
//   • surface (card)           : #FFFFFF
//   • separator                : #E5E5EA
//   • label (primary text)     : #0A0A0F
//   • secondaryLabel           : #515167
//   • tertiaryLabel / placeholder: #8E8EA0
//   • accent (primary)         : #2A6FE8  (brand blue)
//   • destructive              : #E03636
//   • success                  : #34C759  (iOS green)
//
// Cards use a clean white surface with a single soft shadow — no borders,
// no glass blur, no gradients on the card face.

ThemeData buildLightTheme() {
  const primary = Color(0xFF2A6FE8);
  const onPrimary = Colors.white;

  const colorScheme = ColorScheme.light(
    primary: primary,
    secondary: Color(0xFF2AAE9D),
    tertiary: Color(0xFF6D77E8),
    surface: Color(0xFFFFFFFF),
    // iOS systemGroupedBackground used for scaffold
    surfaceContainerHighest: Color(0xFFF2F2F7),
    error: Color(0xFFE03636),
    onPrimary: onPrimary,
    // ── Text ────
    onSurface: Color(0xFF0A0A0F),          // label
    onSurfaceVariant: Color(0xFF515167),   // secondaryLabel
    outline: Color(0xFFE5E5EA),            // separator
    outlineVariant: Color(0xFFEFEFF4),     // grouped cell bg
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.backgroundFor(Brightness.light),

    // ── Typography (Inter — closest to SF Pro available via Google Fonts) ──
    textTheme: GoogleFonts.interTextTheme(
      const TextTheme(
        // display / hero
        headlineLarge: TextStyle(
          color: Color(0xFF0A0A0F),
          fontWeight: FontWeight.w700,
          fontSize: 34,
          letterSpacing: 0.37,
        ),
        headlineMedium: TextStyle(
          color: Color(0xFF0A0A0F),
          fontWeight: FontWeight.w700,
          fontSize: 28,
          letterSpacing: 0.35,
        ),
        // titles
        titleLarge: TextStyle(
          color: Color(0xFF0A0A0F),
          fontWeight: FontWeight.w600,
          fontSize: 22,
          letterSpacing: 0.35,
        ),
        titleMedium: TextStyle(
          color: Color(0xFF0A0A0F),
          fontWeight: FontWeight.w600,
          fontSize: 17,
          letterSpacing: -0.4,
        ),
        titleSmall: TextStyle(
          color: Color(0xFF0A0A0F),
          fontWeight: FontWeight.w600,
          fontSize: 15,
          letterSpacing: -0.23,
        ),
        // body
        bodyLarge: TextStyle(
          color: Color(0xFF0A0A0F),
          fontWeight: FontWeight.w400,
          fontSize: 17,
          letterSpacing: -0.4,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFF515167),
          fontWeight: FontWeight.w400,
          fontSize: 15,
          letterSpacing: -0.23,
        ),
        bodySmall: TextStyle(
          color: Color(0xFF8E8EA0),
          fontWeight: FontWeight.w400,
          fontSize: 13,
          letterSpacing: -0.08,
        ),
        // label
        labelLarge: TextStyle(
          color: Color(0xFF0A0A0F),
          fontWeight: FontWeight.w600,
          fontSize: 15,
          letterSpacing: -0.23,
        ),
        labelMedium: TextStyle(
          color: Color(0xFF515167),
          fontWeight: FontWeight.w500,
          fontSize: 13,
          letterSpacing: -0.08,
        ),
        labelSmall: TextStyle(
          color: Color(0xFF8E8EA0),
          fontWeight: FontWeight.w500,
          fontSize: 11,
          letterSpacing: 0.06,
        ),
      ),
    ),

    iconTheme: const IconThemeData(color: Color(0xFF0A0A0F)),

    // ── Icon buttons — minimal iOS-style pill ─────────────────────────────
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: primary,
        backgroundColor: const Color(0xFFF2F2F7),
        minimumSize: const Size(36, 36),
        padding: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    ),

    // ── App bar — completely transparent ─────────────────────────────────
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Color(0xFF0A0A0F),
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
      ),
      iconTheme: IconThemeData(color: Color(0xFF0A0A0F)),
    ),

    // ── Snack bar ─────────────────────────────────────────────────────────
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF1C1C1E).withValues(alpha: 0.94),
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
    ),

    // ── Filled button — solid primary ────────────────────────────────────
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        textStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        elevation: 0,
      ),
    ),

    // ── Outlined button — thin border ────────────────────────────────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        backgroundColor: Colors.transparent,
        side: const BorderSide(color: Color(0xFFD1D1D6), width: 1),
        textStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.4,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),

    // ── Text button ───────────────────────────────────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        textStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.4,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    ),

    // ── Input decoration — iOS-style rounded fill ─────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFFFFFFF),
      hintStyle: const TextStyle(
        color: Color(0xFF8E8EA0),
        fontSize: 17,
        letterSpacing: -0.4,
      ),
      labelStyle: const TextStyle(
        color: Color(0xFF515167),
        fontSize: 17,
        letterSpacing: -0.4,
      ),
      prefixIconColor: const Color(0xFF8E8EA0),
      suffixIconColor: const Color(0xFF8E8EA0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD1D1D6)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD1D1D6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE03636)),
      ),
    ),

    // ── Segmented button — iOS pill switcher ──────────────────────────────
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? Colors.white
              : const Color(0xFF515167);
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? primary
              : const Color(0xFFFFFFFF);
        }),
        side: WidgetStateProperty.resolveWith((states) {
          return BorderSide(
            color: states.contains(WidgetState.selected)
                ? primary
                : const Color(0xFFD1D1D6),
          );
        }),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    ),

    // ── Popup / menu ──────────────────────────────────────────────────────
    popupMenuTheme: PopupMenuThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      textStyle: const TextStyle(
        color: Color(0xFF0A0A0F),
        fontSize: 15,
        letterSpacing: -0.23,
      ),
    ),

    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(2),
        shadowColor:
            WidgetStatePropertyAll(Colors.black.withValues(alpha: 0.1)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    ),

    // ── Switch — iOS-style ────────────────────────────────────────────────
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected)
            ? const Color(0xFF34C759) // iOS green
            : const Color(0xFFE5E5EA);
      }),
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackOutlineColor:
          const WidgetStatePropertyAll(Colors.transparent),
    ),

    // ── Chips — clean pill ────────────────────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFF2F2F7),
      selectedColor: primary.withValues(alpha: 0.12),
      side: const BorderSide(color: Colors.transparent),
      labelStyle: const TextStyle(
        color: Color(0xFF0A0A0F),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
    ),

    // ── Dialog — iOS action sheet feel ────────────────────────────────────
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: const TextStyle(
        color: Color(0xFF0A0A0F),
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
      ),
      contentTextStyle: const TextStyle(
        color: Color(0xFF515167),
        fontSize: 15,
        letterSpacing: -0.23,
      ),
    ),

    // ── Bottom sheet ──────────────────────────────────────────────────────
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      elevation: 0,
    ),

    // ── Card ──────────────────────────────────────────────────────────────
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.zero,
    ),

    // ── Divider — iOS hairline separator ─────────────────────────────────
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE5E5EA),
      thickness: 0.5,
      space: 0,
    ),

    // ── List tile ─────────────────────────────────────────────────────────
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      titleTextStyle: TextStyle(
        color: Color(0xFF0A0A0F),
        fontSize: 17,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.4,
      ),
      subtitleTextStyle: TextStyle(
        color: Color(0xFF8E8EA0),
        fontSize: 13,
        letterSpacing: -0.08,
      ),
    ),
  );
}
