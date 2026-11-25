import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../models/usuario.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/aulasync_logo.dart';
import '../widgets/aulasync_widgets.dart';
import 'horarios_tab.dart';
import 'login_screen.dart';
import 'otp_tab.dart';
import 'solicitudes_tab.dart';

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
      HorariosTab(onIrAOtp: () => setState(() => _currentIndex = 2)),
      const SolicitudesTab(),
      const OtpTab(),
      _buildPerfilTab(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const AulaSyncWordmark(fontSize: 19, darkBackground: true),
            const SizedBox(height: 1),
            Text(
              _appBarTitle,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: _mostrarDialogoConfiguracionUrl,
              borderRadius: BorderRadius.circular(AppRadii.pill),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                        radius: 3.5, backgroundColor: Color(0xFF10B981)),
                    SizedBox(width: 6),
                    Text(
                      'API Online',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.09),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: NavigationBar(
            height: 66,
            backgroundColor: Colors.transparent,
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) =>
                setState(() => _currentIndex = index),
            destinations: const [
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month_rounded,
                  color: AppColors.navy),
              label: 'Horarios',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon:
                  Icon(Icons.assignment_rounded, color: AppColors.navy),
              label: 'Solicitudes',
            ),
            NavigationDestination(
              icon: Icon(Icons.key_outlined),
              selectedIcon: Icon(Icons.key_rounded, color: AppColors.navy),
              label: 'Apertura OTP',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded, color: AppColors.navy),
              label: 'Perfil',
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildPerfilTab() {
    final user = _usuario ?? ApiService().usuarioActual;
    final nombre = user?.nombre ?? 'Docente Universitario';
    final email = user?.email ?? 'correo@universidad.edu';
    final rol = (user?.rol ?? 'Docente').toUpperCase();
    final matricula =
        user?.matricula.isNotEmpty == true ? user!.matricula : 'No asignada';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AulaSyncCard(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.teal, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.navy,
                        child: Text(
                          nombre.isNotEmpty
                              ? nombre.substring(0, 1).toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      nombre,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        StatusPill(
                          label: rol,
                          backgroundColor:
                              AppColors.teal.withValues(alpha: 0.12),
                          foregroundColor: AppColors.teal,
                          borderColor: AppColors.teal.withValues(alpha: 0.35),
                        ),
                        StatusPill(
                          label: 'Mat: $matricula',
                          backgroundColor: AppColors.surfaceSubtle,
                          foregroundColor: AppColors.textSecondary,
                          borderColor: AppColors.borderStrong,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              AulaSyncCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.dns_rounded,
                            color: AppColors.navy, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Conexión al Servidor API',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        ApiConfig.baseUrl,
                        style: AppTheme.tabularMono.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _mostrarDialogoConfiguracionUrl,
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: const Text('Modificar URL de API'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.navy,
                          side: const BorderSide(color: AppColors.navy),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              const AulaSyncCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: AppColors.navy, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Información de la Plataforma',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    _InfoRow(label: 'Versión', value: '2.0.0 (Flutter M3)'),
                    Divider(height: 18),
                    _InfoRow(label: 'Seguridad', value: 'bcrypt + Bearer Token'),
                    Divider(height: 18),
                    _InfoRow(
                        label: 'Apertura IoT',
                        value: 'Cerraduras OTP Dinámicas'),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              FilledButton.icon(
                onPressed: _confirmarCerrarSesion,
                icon: const Icon(Icons.logout_rounded, size: 19),
                label: const Text('Cerrar Sesión'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoConfiguracionUrl() {
    final urlCtrl = TextEditingController(text: ApiConfig.baseUrl);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Configurar Servidor API'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingresa la URL base de la API REST:',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(labelText: 'URL Base'),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              await ApiConfig.saveBaseUrl(urlCtrl.text);
              if (!mounted) return;
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('URL guardada: ${ApiConfig.baseUrl}'),
                  backgroundColor: AppColors.teal,
                ),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _confirmarCerrarSesion() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Deseas salir de tu cuenta actual en AulaSync?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await ApiService().logout();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Sí, salir'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
      ],
    );
  }
}
