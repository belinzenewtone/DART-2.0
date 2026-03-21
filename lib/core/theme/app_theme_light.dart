import 'package:beltech/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData buildLightTheme() {
  const colorScheme = ColorScheme.light(
    primary: Color(0xFF2A6FE8),
    secondary: Color(0xFF2AAE9D),
    tertiary: Color(0xFF6D77E8),
    surface: Color(0xFFFFFFFF),
    error: Color(0xFFB3261E),
    onPrimary: Colors.white,
    onSurface: Color(0xFF11233F),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.backgroundFor(Brightness.light),
    textTheme: GoogleFonts.interTextTheme(
      const TextTheme(
        headlineMedium: TextStyle(
          color: Color(0xFF11233F),
          fontWeight: FontWeight.w700,
          fontSize: 32,
        ),
        titleLarge: TextStyle(
          color: Color(0xFF11233F),
          fontWeight: FontWeight.w600,
          fontSize: 26,
        ),
        titleMedium: TextStyle(
          color: Color(0xFF183056),
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
        bodyLarge: TextStyle(
          color: Color(0xFF1A335A),
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFF516584),
          fontWeight: FontWeight.w400,
          fontSize: 15,
        ),
      ),
    ),
    iconTheme: const IconThemeData(color: Color(0xFF183056)),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: const Color(0xFF183056),
        backgroundColor: const Color(0xFFF4F8FF),
        side: const BorderSide(color: Color(0xFFD1DEF0)),
        minimumSize: const Size(38, 38),
        padding: const EdgeInsets.all(9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFFF0F5FF).withValues(alpha: 0.98),
      contentTextStyle: const TextStyle(color: Color(0xFF11233F)),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        backgroundColor: const Color(0xFFF5F8FF),
        side: const BorderSide(color: Color(0xFFD1DEF0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF7FAFF),
      hintStyle: const TextStyle(color: Color(0xFF6980A0)),
      labelStyle: const TextStyle(color: Color(0xFF516584)),
      prefixIconColor: const Color(0xFF6980A0),
      suffixIconColor: const Color(0xFF6980A0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFAFC1DA),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFAFC1DA),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? Colors.white
              : const Color(0xFF516584);
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? colorScheme.primary
              : const Color(0xFFF2F7FF);
        }),
        side: WidgetStateProperty.resolveWith((states) {
          return BorderSide(
            color: states.contains(WidgetState.selected)
                ? colorScheme.primary
                : const Color(0xFFBCD0E8),
          );
        }),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: const Color(0xFFF7FAFF),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFD1DEF0)),
      ),
      textStyle: const TextStyle(color: Color(0xFF183056)),
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Color(0xFFF7FAFF)),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        side: const WidgetStatePropertyAll(
          BorderSide(color: Color(0xFFD1DEF0)),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected)
            ? colorScheme.primary.withValues(alpha: 0.36)
            : const Color(0xFFE0E9F5);
      }),
      thumbColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected)
            ? colorScheme.primary
            : const Color(0xFF7C92B1);
      }),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFF4F8FF),
      selectedColor: colorScheme.primary.withValues(alpha: 0.16),
      side: const BorderSide(color: Color(0xFFAAC0DE)),
      labelStyle: const TextStyle(color: Color(0xFF183056)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFFF3F7FF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );
}
