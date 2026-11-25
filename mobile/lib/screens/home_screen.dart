import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../models/usuario.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
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

  String _iniciales(String nombre) {
    final parts = nombre.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'US';
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = _usuario ?? ApiService().usuarioActual;
    final List<Widget> tabs = [
      HorariosTab(
        iniciales: _iniciales(user?.nombre ?? 'Docente'),
        onIrAOtp: () => setState(() => _currentIndex = 2),
      ),
      const SolicitudesTab(),
      const OtpTab(),
      _buildPerfilTab(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _currentIndex,
          children: tabs,
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: AppShadows.card,
          ),
          clipBehavior: Clip.antiAlias,
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              indicatorColor: AppColors.background,
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                final selected = states.contains(WidgetState.selected);
                return TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.navy : AppColors.textMuted,
                );
              }),
            ),
            child: NavigationBar(
              height: 66,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) =>
                  setState(() => _currentIndex = index),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined,
                      color: AppColors.textMuted),
                  selectedIcon: Icon(Icons.calendar_month_rounded,
                      color: AppColors.navy),
                  label: 'Horarios',
                ),
                NavigationDestination(
                  icon: Icon(Icons.assignment_outlined,
                      color: AppColors.textMuted),
                  selectedIcon:
                      Icon(Icons.assignment_rounded, color: AppColors.navy),
                  label: 'Solicitudes',
                ),
                NavigationDestination(
                  icon: Icon(Icons.key_outlined, color: AppColors.textMuted),
                  selectedIcon: Icon(Icons.key_rounded, color: AppColors.navy),
                  label: 'Apertura OTP',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded,
                      color: AppColors.textMuted),
                  selectedIcon:
                      Icon(Icons.person_rounded, color: AppColors.navy),
                  label: 'Perfil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPerfilTab() {
    final user = _usuario ?? ApiService().usuarioActual;
    final nombre = user?.nombre ?? 'Docente Universitario';
    final rol = (user?.rol ?? 'Docente').toUpperCase();
    final matricula =
        user?.matricula.isNotEmpty == true ? user!.matricula : 'No asignada';
    final iniciales = _iniciales(nombre);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Text(
                  'Perfil',
                  style: AppTheme.displayFont(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Tarjeta identidad estilo Figma 06
              AulaSyncCard(
                radius: 24,
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: const BoxDecoration(
                        gradient: AppColors.brandGradient,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        iniciales,
                        style: AppTheme.displayFont(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombre,
                            style: AppTheme.displayFont(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$rol · Mat. $matricula',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.teal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tarjeta agrupada de ajustes estilo Figma 06
              AulaSyncCard(
                radius: 24,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(
                  children: [
                    _SettingsRow(
                      icon: Icons.dns_rounded,
                      iconColor: AppColors.info,
                      iconBg: AppColors.infoBg,
                      title: 'Servidor API REST',
                      subtitle: ApiConfig.baseUrl,
                      onTap: _mostrarDialogoConfiguracionUrl,
                    ),
                    const Divider(height: 1, color: AppColors.background),
                    const _SettingsRow(
                      icon: Icons.verified_user_outlined,
                      iconColor: AppColors.success,
                      iconBg: AppColors.successBg,
                      title: 'Seguridad y Sesión',
                      subtitle: 'bcrypt + Bearer Token',
                    ),
                    const Divider(height: 1, color: AppColors.background),
                    const _SettingsRow(
                      icon: Icons.lock_clock_outlined,
                      iconColor: AppColors.warningDark,
                      iconBg: AppColors.warningBg,
                      title: 'Protocolo Cerraduras',
                      subtitle: 'OTP Dinámico 6 dígitos',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Botón suave Cerrar Sesión estilo Figma 06
              Material(
                color: AppColors.errorBg,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: _confirmarCerrarSesion,
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded,
                            size: 18, color: AppColors.error),
                        SizedBox(width: 8),
                        Text(
                          'Cerrar Sesión',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
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

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
