import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/usuario.dart';
import '../services/api_service.dart';
import 'horarios_tab.dart';
import 'solicitudes_tab.dart';
import 'otp_tab.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final Usuario? usuario;

  const HomeScreen({super.key, this.usuario});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  Usuario? _usuario;

  @override
  void initState() {
    super.initState();
    _usuario = widget.usuario ?? ApiService().usuarioActual;
    if (_usuario == null) {
      _recuperarUsuario();
    }
  }

  Future<void> _recuperarUsuario() async {
    final user = await ApiService().cargarSesionGuardada();
    if (mounted && user != null) {
      setState(() => _usuario = user);
    }
  }

  String get _appBarTitle {
    switch (_currentIndex) {
      case 0:
        return 'Carga Académica';
      case 1:
        return 'Solicitudes de Aulas';
      case 2:
        return 'Apertura de Aula (OTP)';
      case 3:
        return 'Perfil y Ajustes';
      default:
        return 'AulaSync';
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      const HorariosTab(),
      const SolicitudesTab(),
      const OtpTab(),
      _buildPerfilTab(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF127A6B),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.fingerprint, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(
              _appBarTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          if (_currentIndex != 3)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Ajustes de Servidor',
              onPressed: _mostrarDialogoConfiguracionUrl,
            ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF0B2F4F).withValues(alpha: 0.12),
          elevation: 0,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month, color: Color(0xFF0B2F4F)),
              label: 'Horarios',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment, color: Color(0xFF0B2F4F)),
              label: 'Solicitudes',
            ),
            NavigationDestination(
              icon: Icon(Icons.key_outlined),
              selectedIcon: Icon(Icons.key, color: Color(0xFF0B2F4F)),
              label: 'Apertura OTP',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: Color(0xFF0B2F4F)),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB DE PERFIL Y AJUSTES ---
  Widget _buildPerfilTab() {
    final user = _usuario ?? ApiService().usuarioActual;
    final nombre = user?.nombre ?? 'Docente Universitario';
    final email = user?.email ?? 'correo@universidad.edu';
    final rol = (user?.rol ?? 'Docente').toUpperCase();
    final matricula = user?.matricula.isNotEmpty == true ? user!.matricula : 'No asignada';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          // Tarjeta de Identidad del Usuario
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor: const Color(0xFF0B2F4F),
                  child: Text(
                    nombre.isNotEmpty ? nombre.substring(0, 1).toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  nombre,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF127A6B).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF127A6B).withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        rol,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF127A6B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Text(
                        'Mat: $matricula',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tarjeta de Configuración de Red / API
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.dns_outlined, color: Color(0xFF0B2F4F), size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Conexión al Servidor API',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Endpoint base de la API REST para peticiones móviles:',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    ApiConfig.baseUrl,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0B2F4F),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _mostrarDialogoConfiguracionUrl,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Modificar URL de API'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0B2F4F),
                      side: const BorderSide(color: Color(0xFF0B2F4F)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Información del Sistema
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF0B2F4F), size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Información de la Plataforma',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Versión:', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                    Text('1.0.0 (Sesión 3)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
                Divider(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Seguridad:', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                    Text('bcrypt + Bearer Token', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
                Divider(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Apertura IoT:', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                    Text('Cerraduras OTP Dinámicas', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Botón Cerrar Sesión
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _confirmarCerrarSesion,
              icon: const Icon(Icons.logout, size: 20),
              label: const Text('Cerrar Sesión', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Diálogo interactivo para modificar la URL de la API
  void _mostrarDialogoConfiguracionUrl() {
    final ipCtrl = TextEditingController(text: ApiConfig.baseUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.settings_ethernet, color: Color(0xFF0B2F4F)),
            SizedBox(width: 8),
            Text('Ajustar URL del Servidor', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecciona o ingresa la URL de la API REST:',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 10),
            // Atajos rápidos
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ActionChip(
                  label: const Text('Emulador Android', style: TextStyle(fontSize: 11)),
                  onPressed: () => ipCtrl.text = 'http://10.0.2.2/aulasync/api',
                ),
                ActionChip(
                  label: const Text('Localhost', style: TextStyle(fontSize: 11)),
                  onPressed: () => ipCtrl.text = 'http://localhost/aulasync/api',
                ),
                ActionChip(
                  label: const Text('127.0.0.1', style: TextStyle(fontSize: 11)),
                  onPressed: () => ipCtrl.text = 'http://127.0.0.1/aulasync/api',
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ipCtrl,
              decoration: const InputDecoration(
                labelText: 'URL Base API',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUrl = ipCtrl.text.trim();
              if (newUrl.isNotEmpty) {
                ApiConfig.setBaseUrl(newUrl);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('aulasync_base_url', ApiConfig.baseUrl);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (!mounted) return;
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('URL actualizada: ${ApiConfig.baseUrl}'),
                    backgroundColor: const Color(0xFF127A6B),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B2F4F),
              foregroundColor: Colors.white,
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // Diálogo de confirmación para cerrar sesión
  void _confirmarCerrarSesion() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Cerrar Sesión?'),
        content: const Text('Se limpiará el token de seguridad local y volverás a la pantalla de acceso.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              Navigator.pop(ctx);
              await ApiService().logout();
              if (!mounted) return;
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Sí, Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}
