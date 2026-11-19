import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/api_config.dart';
import 'models/usuario.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Restaurar URL base persistida si existe
  try {
    final prefs = await SharedPreferences.getInstance();
    final savedBaseUrl = prefs.getString('aulasync_base_url');
    if (savedBaseUrl != null && savedBaseUrl.trim().isNotEmpty) {
      // En Web (Chrome), 10.0.2.2 es inaccesible; autocorregir a localhost
      if (kIsWeb && savedBaseUrl.contains('10.0.2.2')) {
        await ApiConfig.saveBaseUrl('http://localhost/aulasync/api');
      } else {
        ApiConfig.setBaseUrl(savedBaseUrl.trim());
      }
    } else {
      ApiConfig.setBaseUrl(ApiConfig.defaultBaseUrl);
    }
  } catch (_) {
    ApiConfig.setBaseUrl(ApiConfig.defaultBaseUrl);
  }

  runApp(const AulaSyncApp());
}

class AulaSyncApp extends StatelessWidget {
  const AulaSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AulaSync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B2F4F),
          primary: const Color(0xFF0B2F4F),
          onPrimary: Colors.white,
          primaryContainer: const Color(0xFFD4E4F7),
          onPrimaryContainer: const Color(0xFF001D36),
          secondary: const Color(0xFF0F766E),
          onSecondary: Colors.white,
          secondaryContainer: const Color(0xFFCCFBF1),
          onSecondaryContainer: const Color(0xFF00201B),
          tertiary: const Color(0xFF0284C7),
          surface: const Color(0xFFF8FAFC),
          onSurface: const Color(0xFF0F172A),
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: const Color(0xFFF1F5F9),
          surfaceContainer: const Color(0xFFE2E8F0),
          outline: const Color(0xFFCBD5E1),
          outlineVariant: const Color(0xFFE2E8F0),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B2F4F),
          foregroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 2,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.2,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          elevation: 3,
          height: 70,
          indicatorColor: const Color(0xFF0B2F4F).withValues(alpha: 0.12),
          indicatorShape: const StadiumBorder(),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0B2F4F),
                letterSpacing: 0.2,
              );
            }
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            );
          }),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0B2F4F),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0B2F4F),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF0B2F4F), width: 1.8),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      home: const AuthGate(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

/// Verifica el estado de la sesión almacenada en el dispositivo
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<Usuario?> _sesionFuture;

  @override
  void initState() {
    super.initState();
    _sesionFuture = ApiService().cargarSesionGuardada();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Usuario?>(
      future: _sesionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }

        if (snapshot.hasData && snapshot.data != null) {
          return HomeScreen(usuario: snapshot.data);
        }

        return const LoginScreen();
      },
    );
  }
}

/// Pantalla de bienvenida / carga inicial de AulaSync
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B2F4F),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF127A6B), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.fingerprint,
                size: 54,
                color: Color(0xFF127A6B),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'AulaSync',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Control de Acceso y Gestión de Aulas IoT',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF127A6B)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
