import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController(text: 'usuario@universidad.edu');
  final _passCtrl = TextEditingController(text: 'usuario123');
  bool _isLoading = false;
  bool _obscurePass = true;

  Future<void> _iniciarSesion() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa correo institucional y contraseña.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await ApiService().login(email, pass);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(usuario: user)),
      );
    } catch (e) {
      if (!mounted) return;
      final rawError = e.toString().replaceAll('Exception: ', '');
      final isConnectionError = rawError.contains('Failed to fetch') ||
          rawError.contains('ClientException') ||
          rawError.contains('SocketException') ||
          rawError.contains('10.0.2.2');

      final displayMsg = isConnectionError
          ? 'No se pudo conectar a ${ApiConfig.baseUrl}. Si ejecutas en Chrome/Web, usa http://localhost/aulasync/api.'
          : rawError;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(displayMsg),
          backgroundColor: const Color(0xFFDC2626),
          duration: const Duration(seconds: 5),
          action: isConnectionError
              ? SnackBarAction(
                  label: 'Configurar',
                  textColor: Colors.white,
                  onPressed: _configurarIp,
                )
              : null,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _configurarIp() {
    final ipCtrl = TextEditingController(text: ApiConfig.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.dns_rounded, color: Color(0xFF0B2F4F)),
              SizedBox(width: 10),
              Text('Servidor API REST', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selecciona o ingresa la URL de conexión según tu entorno:',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.laptop_chromebook, size: 16, color: Color(0xFF0F766E)),
                      label: const Text('Chrome / Web (localhost)', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        setDialogState(() {
                          ipCtrl.text = 'http://localhost/aulasync/api';
                        });
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.phone_android, size: 16, color: Color(0xFF0284C7)),
                      label: const Text('Emulador Android (10.0.2.2)', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        setDialogState(() {
                          ipCtrl.text = 'http://10.0.2.2/aulasync/api';
                        });
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.lan_rounded, size: 16),
                      label: const Text('127.0.0.1', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        setDialogState(() {
                          ipCtrl.text = 'http://127.0.0.1/aulasync/api';
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ipCtrl,
                  decoration: const InputDecoration(
                    labelText: 'URL Base de la API',
                    hintText: 'http://localhost/aulasync/api',
                    prefixIcon: Icon(Icons.link_rounded),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                final newUrl = ipCtrl.text.trim();
                await ApiConfig.saveBaseUrl(newUrl);
                if (ctx.mounted) Navigator.pop(ctx);
                if (!mounted) return;
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Servidor configurado en: ${ApiConfig.baseUrl}')),
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              color: Colors.white,
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Emblema Institucional Material 3
                    Center(
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0B2F4F), Color(0xFF1E4E79)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0B2F4F).withValues(alpha: 0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.fingerprint_rounded,
                          color: Color(0xFF2DD4BF),
                          size: 46,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'AulaSync Móvil',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Control de Acceso y Gestión de Aulas IoT • UTM',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Chip de Estado de Conexión al Servidor
                    Center(
                      child: InkWell(
                        onTap: _configurarIp,
                        borderRadius: BorderRadius.circular(100),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Servidor: ${ApiConfig.baseUrl}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0B2F4F),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.settings_outlined, size: 14, color: Color(0xFF64748B)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Campo de Correo
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo Institucional',
                        hintText: 'ejemplo@universidad.edu',
                        prefixIcon: Icon(Icons.alternate_email_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Campo de Contraseña
                    TextField(
                      controller: _passCtrl,
                      obscureText: _obscurePass,
                      decoration: InputDecoration(
                        labelText: 'Contraseña (Bcrypt)',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 20,
                            color: const Color(0xFF64748B),
                          ),
                          onPressed: () => setState(() => _obscurePass = !_obscurePass),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botón Principal de Acceso
                    FilledButton.icon(
                      onPressed: _isLoading ? null : _iniciarSesion,
                      icon: _isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.login_rounded, size: 20),
                      label: Text(
                        _isLoading ? 'Iniciando sesión...' : 'Iniciar Sesión',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0B2F4F),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Accesos Rápidos para Evaluación del Docente
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.touch_app_rounded, size: 14, color: Color(0xFF0F766E)),
                              SizedBox(width: 6),
                              Text(
                                'Cuentas de Demostración:',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F766E),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.school_rounded, size: 16),
                                  label: const Text('Docente', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF0F766E),
                                    side: const BorderSide(color: Color(0xFFCCFBF1), width: 1.5),
                                    backgroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () {
                                    _emailCtrl.text = 'usuario@universidad.edu';
                                    _passCtrl.text = 'usuario123';
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.admin_panel_settings_rounded, size: 16),
                                  label: const Text('Admin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF0B2F4F),
                                    side: const BorderSide(color: Color(0xFFD4E4F7), width: 1.5),
                                    backgroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () {
                                    _emailCtrl.text = 'admin@universidad.edu';
                                    _passCtrl.text = 'admin123';
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
