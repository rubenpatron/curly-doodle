import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/aula.dart';
import '../services/api_service.dart';

class OtpTab extends StatefulWidget {
  const OtpTab({super.key});

  @override
  State<OtpTab> createState() => _OtpTabState();
}

class _OtpTabState extends State<OtpTab> with TickerProviderStateMixin {
  bool _cargandoAulas = true;
  String? _errorAulas;
  List<Aula> _aulas = [];
  Aula? _aulaSeleccionada;

  bool _generandoOtp = false;
  String? _codigoOtp;
  int _segundosTotales = 300; // 5 minutos por defecto
  int _segundosRestantes = 0;
  Timer? _timer;
  bool _codigoExpirado = false;
  bool _codigoUsado = false;

  bool _abriendoCerradura = false;
  String? _mensajeApertura;
  bool? _aperturaExitosa;

  // Modo de visualización: 'pin' o 'qr'
  int _tipoVisualizacion = 0; // 0 = PIN Numérico, 1 = Código QR IoT

  // Controladores de animación
  late AnimationController _lockController;
  late Animation<double> _lockScaleAnimation;

  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _lockController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _lockScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 0.95), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _lockController, curve: Curves.easeInOut));

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    _cargarAulas();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _lockController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _cargarAulas() async {
    setState(() {
      _cargandoAulas = true;
      _errorAulas = null;
    });

    try {
      final aulas = await ApiService().getAulas();
      if (!mounted) return;
      setState(() {
        _aulas = aulas;
        if (_aulas.isNotEmpty) {
          _aulaSeleccionada = _aulas.first;
        }
        _cargandoAulas = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorAulas = e.toString().replaceAll('Exception: ', '');
        _cargandoAulas = false;
      });
    }
  }

  void _iniciarTemporizador(int segundos) {
    _timer?.cancel();
    setState(() {
      _segundosTotales = segundos;
      _segundosRestantes = segundos;
      _codigoExpirado = false;
      _codigoUsado = false;
      _mensajeApertura = null;
      _aperturaExitosa = null;
    });
    _lockController.reset();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_segundosRestantes > 1) {
          _segundosRestantes--;
        } else {
          _segundosRestantes = 0;
          _codigoExpirado = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _generarOtp() async {
    if (_aulaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona un aula primero.')),
      );
      return;
    }

    setState(() {
      _generandoOtp = true;
      _mensajeApertura = null;
      _aperturaExitosa = null;
    });

    try {
      final data = await ApiService().solicitarOtp(_aulaSeleccionada!.id);
      if (!mounted) return;

      final codigo = data['codigo']?.toString() ?? '------';
      final vigenciaMin = data['vigencia_min'] is int
          ? data['vigencia_min'] as int
          : int.tryParse(data['vigencia_min']?.toString() ?? '5') ?? 5;

      setState(() {
        _codigoOtp = codigo;
        _generandoOtp = false;
      });

      _iniciarTemporizador(vigenciaMin * 60);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Código OTP generado para Aula ${_aulaSeleccionada!.codigo}.'),
          backgroundColor: const Color(0xFF127A6B),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _generandoOtp = false);

      final errorMsg = e.toString().replaceAll('Exception: ', '');
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lock_clock, color: Colors.amber),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Acceso Restringido',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(errorMsg),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Nota: La cerradura inteligente solo emite códigos de apertura para las aulas '
                  'asignadas a tu horario de hoy o aprobadas mediante solicitud especial.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _abrirCerradura() async {
    if (_aulaSeleccionada == null || _codigoOtp == null) return;

    if (_codigoExpirado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El código OTP ha expirado. Genera uno nuevo.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_codigoUsado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este código ya fue utilizado.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _abriendoCerradura = true);

    try {
      final res = await ApiService().abrirCerradura(
        _aulaSeleccionada!.id,
        _codigoOtp!,
      );

      if (!mounted) return;

      _timer?.cancel();
      _lockController.forward(from: 0.0);

      setState(() {
        _codigoUsado = true;
        _aperturaExitosa = true;
        _mensajeApertura = res['mensaje'] ?? '¡Acceso Concedido! Cerradura abierta exitosamente.';
        _abriendoCerradura = false;
      });

      _mostrarDialogoExito();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _aperturaExitosa = false;
        _mensajeApertura = e.toString().replaceAll('Exception: ', '');
        _abriendoCerradura = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_mensajeApertura!),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _mostrarDialogoExito() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.35),
                    blurRadius: 18,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.lock_open_rounded,
                color: Colors.white,
                size: 42,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '¡Puerta Desbloqueada!',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'La cerradura de Aula ${_aulaSeleccionada?.codigo} se ha abierto.\nEl acceso fue registrado exitosamente en la bitácora IoT de MariaDB.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Color(0xFF475569),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(ctx),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0B2F4F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'Aceptar',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatearTiempoRestante(int totalSegundos) {
    final minutos = totalSegundos ~/ 60;
    final segundos = totalSegundos % 60;
    return '${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
  }

  Widget _buildOtpDigits(String codigo) {
    final chars = codigo.padRight(6, '-').split('');

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: chars.map((ch) {
        final Color borderColor = _codigoExpirado
            ? const Color(0xFFFCA5A5)
            : _codigoUsado
                ? const Color(0xFF6EE7B7)
                : Colors.white.withValues(alpha: 0.30);
        final Color bgColor = _codigoExpirado
            ? const Color(0xFFEF4444).withValues(alpha: 0.22)
            : _codigoUsado
                ? const Color(0xFF10B981).withValues(alpha: 0.24)
                : Colors.white.withValues(alpha: 0.14);

        return Container(
          width: 46,
          height: 60,
          margin: const EdgeInsets.symmetric(horizontal: 3.5),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.3),
          ),
          alignment: Alignment.center,
          child: Text(
            ch,
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              fontFamily: 'monospace',
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQrView(String codigo, String aulaCodigo) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(180, 180),
                painter: QrMatrixPainter(
                  data: '$aulaCodigo:$codigo',
                  isExpired: _codigoExpirado,
                  isUsed: _codigoUsado,
                ),
              ),
              if (!_codigoExpirado && !_codigoUsado)
                AnimatedBuilder(
                  animation: _scanAnimation,
                  builder: (context, child) {
                    return Positioned(
                      top: _scanAnimation.value * 160 + 10,
                      left: 10,
                      right: 10,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          color: const Color(0xFF127A6B),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF127A6B).withValues(alpha: 0.8),
                              blurRadius: 6,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Escanea este código en el lector óptico del Aula $aulaCodigo',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildAnimatedLockStatus() {
    final bool isUnlocked = _codigoUsado && _aperturaExitosa == true;
    final bool isUnlocking = _abriendoCerradura;

    Color cardBg = isUnlocked
        ? const Color(0xFFECFDF5)
        : isUnlocking
            ? const Color(0xFFFEF3C7)
            : const Color(0xFFF8FAFC);

    Color borderColor = isUnlocked
        ? const Color(0xFF10B981)
        : isUnlocking
            ? const Color(0xFFF59E0B)
            : const Color(0xFFCBD5E1);

    Color iconBg = isUnlocked
        ? const Color(0xFFD1FAE5)
        : isUnlocking
            ? const Color(0xFFFDE68A)
            : const Color(0xFFE2E8F0);

    Color iconColor = isUnlocked
        ? const Color(0xFF047857)
        : isUnlocking
            ? const Color(0xFFB45309)
            : const Color(0xFF334155);

    String statusTitle = isUnlocked
        ? 'Cerradura Desbloqueada'
        : isUnlocking
            ? 'Enviando Señal IoT...'
            : 'Cerradura Asegurada';

    String statusSubtitle = isUnlocked
        ? 'Acceso concedido al Aula ${_aulaSeleccionada?.codigo ?? ""}'
        : isUnlocking
            ? 'Comunicando con nodo ESP32 / Cerradura electrónica'
            : 'Esperando validación de PIN OTP o escaneo QR';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        children: [
          ScaleTransition(
            scale: _lockScaleAnimation,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
                boxShadow: isUnlocked
                    ? [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.35),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                isUnlocked
                    ? Icons.lock_open_rounded
                    : isUnlocking
                        ? Icons.sync
                        : Icons.lock_rounded,
                color: iconColor,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isUnlocked
                            ? const Color(0xFF10B981)
                            : isUnlocking
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFF64748B),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusTitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked
                            ? const Color(0xFF065F46)
                            : isUnlocking
                                ? const Color(0xFF92400E)
                                : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  statusSubtitle,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progreso = _segundosTotales > 0
        ? _segundosRestantes / _segundosTotales
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _cargandoAulas
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF0B2F4F)),
                  SizedBox(height: 12),
                  Text('Cargando catálogo de aulas...',
                      style: TextStyle(color: Color(0xFF64748B))),
                ],
              ),
            )
          : _errorAulas != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(_errorAulas!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _cargarAulas,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0B2F4F),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                      // Componente Visual Animado de Estado de Cerradura
                      _buildAnimatedLockStatus(),
                      const SizedBox(height: 14),

                      // Selector de Aula
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Seleccionar Aula',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 10),
                              DropdownButtonFormField<Aula>(
                                initialValue: _aulaSeleccionada,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.door_sliding_outlined,
                                      color: Color(0xFF0B2F4F)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 14),
                                ),
                                isExpanded: true,
                                items: _aulas.map((a) {
                                  return DropdownMenuItem<Aula>(
                                    value: a,
                                    child: Row(
                                      children: [
                                        Text(
                                          'Aula ${a.codigo}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '(${a.edificio} · Cap: ${a.capacidad})',
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != _aulaSeleccionada) {
                                    setState(() {
                                      _aulaSeleccionada = val;
                                      _timer?.cancel();
                                      _codigoOtp = null;
                                      _codigoUsado = false;
                                      _codigoExpirado = false;
                                      _mensajeApertura = null;
                                      _lockController.reset();
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 14),

                              // Botón Generar OTP
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _generandoOtp ? null : _generarOtp,
                                  icon: _generandoOtp
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.key_rounded),
                                  label: Text(
                                    _generandoOtp
                                        ? 'Solicitando Código...'
                                        : 'Generar Código OTP',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0B2F4F),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Panel Visualizador del OTP (Digital Keycard estilo Apple Wallet)
                      if (_codigoOtp != null) ...[
                        Container(
                          padding: const EdgeInsets.all(20.0),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF071A2F),
                                Color(0xFF0B2F4F),
                                Color(0xFF0F766E),
                              ],
                              stops: [0.0, 0.55, 1.0],
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0B2F4F)
                                    .withValues(alpha: 0.28),
                                blurRadius: 28,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: Column(
                              children: [
                                // Estado de la clave
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          _codigoExpirado
                                              ? Icons.timer_off_outlined
                                              : _codigoUsado
                                                  ? Icons.check_circle_outline
                                                  : Icons.timer_outlined,
                                          size: 16,
                                          color: _codigoExpirado
                                              ? const Color(0xFFFCA5A5)
                                              : const Color(0xFF99F6E4),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _codigoExpirado
                                              ? 'CÓDIGO EXPIRADO'
                                              : _codigoUsado
                                                  ? 'CÓDIGO UTILIZADO'
                                                  : 'PIN TEMPORAL ACTIVO',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.6,
                                            color: _codigoExpirado
                                                ? const Color(0xFFFCA5A5)
                                                : const Color(0xFF99F6E4),
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Temporizador
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 11, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.16),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _codigoExpirado
                                            ? '00:00'
                                            : _formatearTiempoRestante(_segundosRestantes),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          fontFamily: 'monospace',
                                          fontFeatures: [FontFeature.tabularFigures()],
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                // Barra de Progreso
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: _codigoExpirado || _codigoUsado ? 0 : progreso,
                                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      progreso < 0.2
                                          ? const Color(0xFFF87171)
                                          : progreso < 0.5
                                              ? const Color(0xFFFBBF24)
                                              : const Color(0xFF34D399),
                                    ),
                                    minHeight: 6,
                                  ),
                                ),
                                const SizedBox(height: 18),

                                // Selector de Modo: PIN vs QR
                                SegmentedButton<int>(
                                  segments: const [
                                    ButtonSegment(
                                      value: 0,
                                      label: Text('PIN Numérico'),
                                      icon: Icon(Icons.pin_outlined),
                                    ),
                                    ButtonSegment(
                                      value: 1,
                                      label: Text('Código QR IoT'),
                                      icon: Icon(Icons.qr_code_2_rounded),
                                    ),
                                  ],
                                  selected: {_tipoVisualizacion},
                                  onSelectionChanged: (set) {
                                    setState(() => _tipoVisualizacion = set.first);
                                  },
                                  style: ButtonStyle(
                                    visualDensity: VisualDensity.compact,
                                    backgroundColor:
                                        WidgetStateProperty.resolveWith((states) {
                                      if (states.contains(WidgetState.selected)) {
                                        return Colors.white;
                                      }
                                      return Colors.white.withValues(alpha: 0.12);
                                    }),
                                    foregroundColor:
                                        WidgetStateProperty.resolveWith((states) {
                                      if (states.contains(WidgetState.selected)) {
                                        return const Color(0xFF0B2F4F);
                                      }
                                      return Colors.white;
                                    }),
                                    side: WidgetStateProperty.all(
                                      BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),

                                // Contenido según pestaña: PIN o QR
                                if (_tipoVisualizacion == 0) ...[
                                  _buildOtpDigits(_codigoOtp!),
                                  const SizedBox(height: 10),
                                  TextButton.icon(
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: _codigoOtp!));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Código copiado al portapapeles.'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.copy, size: 16),
                                    label: const Text('Copiar Código'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFFCCFBF1),
                                    ),
                                  ),
                                ] else ...[
                                  _buildQrView(_codigoOtp!, _aulaSeleccionada?.codigo ?? 'A-101'),
                                ],

                                Divider(height: 24, color: Colors.white.withValues(alpha: 0.18)),

                                // Botón para Simular Apertura con la Cerradura IoT
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: (_codigoExpirado || _codigoUsado || _abriendoCerradura)
                                        ? null
                                        : _abrirCerradura,
                                    icon: _abriendoCerradura
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Color(0xFF0B2F4F),
                                            ),
                                          )
                                        : const Icon(Icons.lock_open_rounded),
                                    label: Text(
                                      _abriendoCerradura
                                          ? 'Enviando Señal a Cerradura...'
                                          : _codigoUsado
                                              ? 'Puerta Ya Desbloqueada'
                                              : 'Simular Apertura de Cerradura IoT',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: const Color(0xFF0B2F4F),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                ),

                                // Mensaje de feedback si se abrió
                                if (_mensajeApertura != null && _aperturaExitosa == true) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFF34D399).withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_circle,
                                            color: Color(0xFF34D399), size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _mensajeApertura!,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Guía de uso rápido para el Docente
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.info_outline, size: 18, color: Color(0xFF0B2F4F)),
                                SizedBox(width: 8),
                                Text(
                                  'Instrucciones de Uso',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              '1. Selecciona el aula correspondiente a tu clase actual.\n'
                              '2. Presiona "Generar Código OTP". El sistema validará que tengas clase o una solicitud aprobada en este horario.\n'
                              '3. Introduce el PIN de 6 dígitos en el teclado digital de la cerradura o escanea el Código QR en la cámara del lector IoT.\n'
                              '4. Presiona "Simular Apertura" para verificar la integración en vivo con MariaDB y el hardware.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

/// Pintor personalizado para generar la matriz del Código QR IoT
class QrMatrixPainter extends CustomPainter {
  final String data;
  final bool isExpired;
  final bool isUsed;

  QrMatrixPainter({
    required this.data,
    required this.isExpired,
    required this.isUsed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const int gridSize = 21; // QR versión 1 estándar (21x21 módulos)
    final double cellSize = size.width / gridSize;

    final paintDark = Paint()
      ..color = isExpired
          ? Colors.red.shade700
          : isUsed
              ? Colors.grey.shade600
              : const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;

    // Generar matriz pseudo-determinista a partir del texto y código
    final matrix = _generarMatriz(data, gridSize);

    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (matrix[r][c]) {
          final rect = Rect.fromLTWH(
            c * cellSize,
            r * cellSize,
            cellSize,
            cellSize,
          );
          canvas.drawRect(rect, paintDark);
        }
      }
    }
  }

  List<List<bool>> _generarMatriz(String text, int size) {
    final m = List.generate(size, (_) => List.filled(size, false));

    // Dibujar los 3 patrones de localización estándar (Finder Patterns 7x7)
    _dibujarFinderPattern(m, 0, 0);
    _dibujarFinderPattern(m, 0, size - 7);
    _dibujarFinderPattern(m, size - 7, 0);

    // Patrón de temporización (Timing patterns en fila 6 y columna 6)
    for (int i = 7; i < size - 7; i++) {
      m[6][i] = (i % 2 == 0);
      m[i][6] = (i % 2 == 0);
    }

    // Datos basados en hash determinista del string (aula + otp)
    int seed = 0;
    for (int i = 0; i < text.length; i++) {
      seed = (seed * 31 + text.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    final rand = math.Random(seed);

    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        // No sobreescribir los finder patterns ni timing
        if (_esAreaProtegida(r, c, size)) continue;
        m[r][c] = rand.nextBool();
      }
    }

    return m;
  }

  void _dibujarFinderPattern(List<List<bool>> m, int top, int left) {
    for (int r = 0; r < 7; r++) {
      for (int c = 0; c < 7; c++) {
        // Marco exterior 7x7
        if (r == 0 || r == 6 || c == 0 || c == 6) {
          m[top + r][left + c] = true;
        }
        // Centro 3x3
        else if (r >= 2 && r <= 4 && c >= 2 && c <= 4) {
          m[top + r][left + c] = true;
        }
      }
    }
  }

  bool _esAreaProtegida(int r, int c, int size) {
    // Esquina superior izquierda
    if (r <= 7 && c <= 7) return true;
    // Esquina superior derecha
    if (r <= 7 && c >= size - 8) return true;
    // Esquina inferior izquierda
    if (r >= size - 8 && c <= 7) return true;
    // Líneas de sincronización
    if (r == 6 || c == 6) return true;
    return false;
  }

  @override
  bool shouldRepaint(covariant QrMatrixPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.isExpired != isExpired ||
        oldDelegate.isUsed != isUsed;
  }
}
