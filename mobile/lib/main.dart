import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/api_config.dart';
import 'models/usuario.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';
import 'widgets/aulasync_logo.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final prefs = await SharedPreferences.getInstance();
    final savedBaseUrl = prefs.getString('aulasync_base_url');
    if (savedBaseUrl != null && savedBaseUrl.trim().isNotEmpty) {
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
      theme: AppTheme.light,
      home: const AuthGate(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomeScreen(),
      },
    );
  }
}

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
    _sesionFuture = _bootstrap();
  }

  Future<Usuario?> _bootstrap() async {
    final results = await Future.wait([
      ApiService().cargarSesionGuardada(),
      Future.delayed(const Duration(milliseconds: 1900)),
    ]);
    return results[0] as Usuario?;
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

/// Pantalla 00 · Splash con halos suaves, wordmark animado y píldora de estado.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: Stack(
        children: [
          // Halos radiales ambientales
          Positioned(
            top: 170,
            right: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.teal.withValues(alpha: 0.13),
                    AppColors.teal.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 200,
            left: -70,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.navy.withValues(alpha: 0.10),
                    AppColors.navy.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AulaSyncWordmark(fontSize: 46, animate: true),
                      const SizedBox(height: 12),
                      const Text(
                        'ACCESO INTELIGENTE DE AULAS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.0,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.navy.withValues(alpha: 0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                                radius: 3, backgroundColor: AppColors.success),
                            SizedBox(width: 8),
                            Text(
                              'Sincronizando campus UTM...',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 148,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: const LinearProgressIndicator(
                            minHeight: 3,
                            backgroundColor: Color(0xFFCBD5E1),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(AppColors.teal),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Text(
                    'Universidad Tecnológica Metropolitana · 4A-IRD',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
