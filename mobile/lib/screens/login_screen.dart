import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/aulasync_logo.dart';
import '../widgets/aulasync_widgets.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscurePass = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _rellenarDemo(String email, String password) {
    setState(() {
      _emailCtrl.text = email;
      _passCtrl.text = password;
      _errorMessage = null;
    });
  }

  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final usuario = await ApiService().login(
        _emailCtrl.text.trim(),
        _passCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen(usuario: usuario)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _mostrarDialogoUrl() {
    final urlCtrl = TextEditingController(text: ApiConfig.baseUrl);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Servidor API REST'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingresa la URL base donde corre el backend PHP:',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                labelText: 'URL Base',
                hintText: 'http://localhost/aulasync/api',
              ),
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
                  content: Text('API actualizada: ${ApiConfig.baseUrl}'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF071A2F), AppColors.navy, AppColors.teal],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  const SizedBox(height: 34),
                  const AulaSyncWordmark(
                    fontSize: 38,
                    darkBackground: true,
                    animate: true,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Llave Digital Universitaria · UTM',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFFCBD5E1),
                    ),
                  ),
                  const SizedBox(height: 34),

                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 30,
                            offset: const Offset(0, -8),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Bienvenido',
                                    style: AppTheme.displayFont(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: _mostrarDialogoUrl,
                                    borderRadius:
                                        BorderRadius.circular(AppRadii.pill),
                                    child: const StatusPill(
                                      label: 'API Online',
                                      showDot: true,
                                      backgroundColor: AppColors.successBg,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Ingresa con tus credenciales institucionales para acceder a tus aulas.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMuted,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 20),

                              if (_errorMessage != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.errorBg,
                                    borderRadius:
                                        BorderRadius.circular(AppRadii.md),
                                    border:
                                        Border.all(color: AppColors.errorBorder),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline_rounded,
                                          size: 18, color: AppColors.error),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.error,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Correo Institucional',
                                  hintText: 'usuario@universidad.edu',
                                  prefixIcon: Icon(Icons.mail_outline_rounded),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Ingresa tu correo institucional';
                                  }
                                  if (!v.contains('@')) {
                                    return 'Ingresa un correo válido';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              TextFormField(
                                controller: _passCtrl,
                                obscureText: _obscurePass,
                                decoration: InputDecoration(
                                  labelText: 'Contraseña',
                                  prefixIcon:
                                      const Icon(Icons.lock_outline_rounded),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePass
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                    onPressed: () => setState(
                                        () => _obscurePass = !_obscurePass),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Ingresa tu contraseña';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  ActionChip(
                                    avatar: const Icon(Icons.school_outlined,
                                        size: 15, color: AppColors.navy),
                                    label: const Text('Demo Docente',
                                        style: TextStyle(fontSize: 12)),
                                    backgroundColor: const Color(0xFFEEF2F7),
                                    side: const BorderSide(
                                        color: AppColors.border),
                                    onPressed: () => _rellenarDemo(
                                        'usuario@universidad.edu',
                                        'usuario123'),
                                  ),
                                  ActionChip(
                                    avatar: const Icon(
                                        Icons.admin_panel_settings_outlined,
                                        size: 15,
                                        color: AppColors.teal),
                                    label: const Text('Demo Admin',
                                        style: TextStyle(fontSize: 12)),
                                    backgroundColor: const Color(0xFFEEF2F7),
                                    side: const BorderSide(
                                        color: AppColors.border),
                                    onPressed: () => _rellenarDemo(
                                        'admin@universidad.edu', 'admin123'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),

                              AulaSyncGradientButton(
                                label: 'Iniciar Sesión',
                                loading: _isLoading,
                                onPressed: _iniciarSesion,
                              ),
                              const SizedBox(height: 14),

                              Center(
                                child: TextButton.icon(
                                  onPressed: _mostrarDialogoUrl,
                                  icon: const Icon(
                                      Icons.settings_ethernet_rounded,
                                      size: 15),
                                  label: Text(
                                    ApiConfig.baseUrl,
                                    style: AppTheme.tabularMono.copyWith(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
