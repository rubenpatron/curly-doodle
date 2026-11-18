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
        const SnackBar(content: Text('Por favor ingresa correo y contraseña.')),
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
          ? 'No se pudo conectar a ${ApiConfig.baseUrl}. Si ejecutas en Chrome/Web, usa http://localhost/aulasync/api (toca el selector arriba).'
          : rawError;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(displayMsg),
          backgroundColor: Colors.red.shade700,
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
          title: const Row(
            children: [
              Icon(Icons.dns_rounded, color: Color(0xFF0B2F4F)),
              SizedBox(width: 8),
              Text('Servidor API REST'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selecciona o ingresa la URL de conexión según tu entorno:',
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.laptop_chromebook, size: 16),
                      label: const Text('Chrome / Web (localhost)', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        setDialogState(() {
                          ipCtrl.text = 'http://localhost/aulasync/api';
                        });
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.phone_android, size: 16),
                      label: const Text('Emulador Android (10.0.2.2)', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        setDialogState(() {
                          ipCtrl.text = 'http://10.0.2.2/aulasync/api';
                        });
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.network_check, size: 16),
                      label: const Text('127.0.0.1', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        setDialogState(() {
                          ipCtrl.text = 'http://127.0.0.1/aulasync/api';
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: ipCtrl,
                  decoration: const InputDecoration(
                    labelText: 'URL Base de la API',
                    hintText: 'http://localhost/aulasync/api',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link),
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
            ElevatedButton(
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFF0F172A)),
            tooltip: 'Ajustar IP del Servidor',
            onPressed: _configurarIp,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo e Icono
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B2F4F),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0B2F4F).withValues(alpha: 0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.fingerprint,
                    color: Color(0xFF127A6B),
                    size: 44,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'AulaSync Móvil',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Text(
                'Gestión y Control de Acceso IoT',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),

              // Chip interactivo del servidor actual
              Center(
                child: ActionChip(
                  avatar: const Icon(Icons.dns_rounded, size: 14, color: Color(0xFF0B2F4F)),
                  label: Text(
                    'Servidor: ${ApiConfig.baseUrl}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0B2F4F)),
                  ),
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.grey.shade300),
                  onPressed: _configurarIp,
                ),
              ),
              const SizedBox(height: 24),

              // Campo Correo
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Correo Institucional',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // Campo Contraseña
              TextField(
                controller: _passCtrl,
                obscureText: _obscurePass,
                decoration: InputDecoration(
                  labelText: 'Contraseña (bcrypt)',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // Botón Iniciar Sesión
              ElevatedButton(
                onPressed: _isLoading ? null : _iniciarSesion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B2F4F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Iniciar Sesión', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 28),

              // Accesos Rápidos para Evaluación
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Accesos Rápidos de Prueba:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.admin_panel_settings, size: 16),
                            label: const Text('Admin', style: TextStyle(fontSize: 13)),
                            onPressed: () {
                              _emailCtrl.text = 'admin@universidad.edu';
                              _passCtrl.text = 'admin123';
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.school, size: 16),
                            label: const Text('Docente', style: TextStyle(fontSize: 13)),
                            onPressed: () {
                              _emailCtrl.text = 'usuario@universidad.edu';
                              _passCtrl.text = 'usuario123';
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
    );
  }
}
