// lib/utils/theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Define the light theme
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF1E88E5),
    scaffoldBackgroundColor: const Color(0xFFF5F5F5), // Light grey background

    // Define the color scheme for light theme
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.blue,
      accentColor: Colors.blueAccent,
      backgroundColor: const Color(0xFFF5F5F5),
    ).copyWith(
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black87,
    ),

    // Define AppBar theme
    appBarTheme: const AppBarTheme(
      color: Color(0xFF1E88E5),
      elevation: 4,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),

    // Define ElevatedButton theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1E88E5), // Primary color
        foregroundColor: Colors.white, // Text color
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        elevation: 5,
      ),
    ),

    // Define TextButton theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF1E88E5), // Primary color
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    // Define IconTheme
    iconTheme: const IconThemeData(
      color: Colors.black87,
      size: 24,
    ),

    // Define BottomNavigationBar theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Color(0xFF1E88E5),
      unselectedItemColor: Colors.grey,
      elevation: 10,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
      showSelectedLabels: true,
      selectedLabelStyle: TextStyle(
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelStyle: TextStyle(
        fontWeight: FontWeight.normal,
      ),
    ),

    // Define TextTheme using Google Fonts
    textTheme: GoogleFonts.poppinsTextTheme().copyWith(
      titleLarge: const TextStyle(
        color: Colors.black87,
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: const TextStyle(
        color: Colors.black87,
        fontSize: 16,
      ),
      labelLarge: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      // Define other text styles as needed
    ),

    // Define InputDecorationTheme
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1E88E5)),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(
        color: Colors.black54,
        fontSize: 16,
      ),
      hintStyle: const TextStyle(
        color: Colors.black38,
        fontSize: 14,
      ),
    ),

    // Define CardTheme for consistent card styling
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      shadowColor: Colors.black45,
    ),

    // Define SnackBarThemeData for premium-looking snackbars
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF6A1B9A), // Deep purple for a premium look
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      behavior: SnackBarBehavior.floating,
      insetPadding: const EdgeInsets.all(16),
    ),

    // Define other theme properties as needed
    fontFamily: GoogleFonts.poppins().fontFamily,
  );

  // Define the dark theme
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF90CAF9),
    scaffoldBackgroundColor: const Color(0xFF121212), // Dark background

    // Define the color scheme for dark theme
    colorScheme: ColorScheme.fromSwatch(
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      accentColor: Colors.tealAccent,
      backgroundColor: const Color(0xFF121212),
    ).copyWith(
      surface: const Color(0xFF1F1F1F),
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: Colors.white70,
    ),

    // Define AppBar theme
    appBarTheme: const AppBarTheme(
      color: Color(0xFF1F1F1F),
      elevation: 4,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),

    // Define ElevatedButton theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF90CAF9), // Primary color
        foregroundColor: Colors.black, // Text color
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        elevation: 5,
      ),
    ),

    // Define TextButton theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF90CAF9), // Primary color
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    // Define IconTheme
    iconTheme: const IconThemeData(
      color: Colors.white70,
      size: 24,
    ),

    // Define BottomNavigationBar theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1F1F1F),
      selectedItemColor: Color.fromARGB(255, 225, 253, 10),
      unselectedItemColor: Colors.grey,
      elevation: 10,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
      showSelectedLabels: true,
      selectedLabelStyle: TextStyle(
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelStyle: TextStyle(
        fontWeight: FontWeight.normal,
      ),
    ),

    // Define TextTheme using Google Fonts
    textTheme: GoogleFonts.poppinsTextTheme().copyWith(
      titleLarge: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: const TextStyle(
        color: Colors.white70,
        fontSize: 16,
      ),
      labelLarge: const TextStyle(
        color: Colors.black,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      // Define other text styles as needed
    ),

    // Define InputDecorationTheme
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF90CAF9)),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      filled: true,
      fillColor: const Color(0xFF1F1F1F),
      labelStyle: const TextStyle(
        color: Colors.white54,
        fontSize: 16,
      ),
      hintStyle: const TextStyle(
        color: Colors.white38,
        fontSize: 14,
      ),
    ),

    // Define CardTheme for consistent card styling
    cardTheme: CardTheme(
      color: const Color(0xFF1F1F1F),
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      shadowColor: Colors.black54,
    ),

    // Define SnackBarThemeData for premium-looking snackbars in dark mode
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color.fromARGB(255, 116, 157, 245), // Deep purple for dark theme
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      behavior: SnackBarBehavior.floating,
      insetPadding: const EdgeInsets.all(16),
    ),

    // Define other theme properties as needed
    fontFamily: GoogleFonts.poppins().fontFamily,
  );
}
