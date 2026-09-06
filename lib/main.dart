import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const AsistenciaApp());
}

class AsistenciaApp extends StatelessWidget {
  const AsistenciaApp({super.key});

  // Tema oscuro (original)
  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0D1B2A),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF0066FF),
        secondary: Color(0xFF00FFCC),
        surface: Color(0xFF0A1428),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0A1428),
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF0A1428),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[800]!),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[900],
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0066FF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // Tema claro neumórfico (basado en el HTML compartido)
  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFE0E5EC),
      colorScheme: ColorScheme.light(
        primary: const Color(0xFF7B9ACC),
        secondary: const Color(0xFFA1A6B4),
        surface: const Color(0xFFE0E5EC),
        background: const Color(0xFFE0E5EC),
      ),
      // Colores personalizados para el estilo neumórfico
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32.0,
          fontWeight: FontWeight.w700,
          color: Color(0xFF3B3B3B),
        ),
        displayMedium: TextStyle(
          fontSize: 24.0,
          fontWeight: FontWeight.w600,
          color: Color(0xFF3B3B3B),
        ),
        bodyLarge: TextStyle(
          fontSize: 16.0,
          color: Color(0xFF3B3B3B),
        ),
      ),
      // Shadow colors for neumorphic effect
      shadowColor: const Color(0xFFA3B1C6),
      dividerColor: const Color(0xFFC1C7D0),
      // Card theme with neumorphic styling
      cardTheme: CardThemeData(
        color: const Color(0xFFE0E5EC),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFC1C7D0), width: 1),
        ),
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        hintStyle: const TextStyle(color: Color(0xFF8592A8)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7B9ACC),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      // AppBar theme for light mode
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFE0E5EC),
        foregroundColor: const Color(0xFF3B3B3B),
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Color(0xFF3B3B3B),
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asistencia QR',
      debugShowCheckedModeBanner: false,
      // Usar Theme.switch para permitir modo claro/oscuro
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      // Mantener la vista en modo oscuro por defecto, pero permitir cambio
      themeMode: ThemeMode.dark,
      home: const HomeScreen(),
    );
  }
}