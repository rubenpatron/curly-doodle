import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/aula.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/aulasync_widgets.dart';

class OtpTab extends StatefulWidget {
  const OtpTab({super.key});

  @override
  State<OtpTab> createState() => _OtpTabState();
}

class _OtpTabState extends State<OtpTab> {
  bool _cargandoAulas = true;
  String? _errorAulas;
  List<Aula> _aulas = [];
  Aula? _aulaSeleccionada;

  bool _generandoOtp = false;
  String? _codigoOtp;
  int _segundosTotales = 300;
  int _segundosRestantes = 0;
  Timer? _timer;
  bool _codigoExpirado = false;
  bool _codigoUsado = false;

  bool _abriendoCerradura = false;
  int _tipoVisualizacion = 0; // 0 = PIN, 1 = QR

  @override
  void initState() {
    super.initState();
    _cargarAulas();
  }

  @override
  void dispose() {
    _timer?.cancel();
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
    });

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
    if (_aulaSeleccionada == null) return;
    setState(() => _generandoOtp = true);

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
          content: Text('OTP generado para ${_aulaSeleccionada!.codigo}.'),
          backgroundColor: AppColors.teal,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _generandoOtp = false);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Acceso Restringido'),
          content: Text(e.toString().replaceAll('Exception: ', '')),
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
    if (_codigoExpirado || _codigoUsado) return;

    setState(() => _abriendoCerradura = true);
    try {
      await ApiService().abrirCerradura(_aulaSeleccionada!.id, _codigoOtp!);
      if (!mounted) return;
      _timer?.cancel();
      setState(() {
        _codigoUsado = true;
        _abriendoCerradura = false;
      });
      _mostrarDialogoExito();
    } catch (e) {
      if (!mounted) return;
      setState(() => _abriendoCerradura = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _mostrarDialogoExito() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_open_rounded,
                  color: Colors.white, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              '¡Puerta Desbloqueada!',
              style: AppTheme.displayFont(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'La cerradura de Aula ${_aulaSeleccionada?.codigo} se abrió y el acceso quedó registrado.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  String get _tiempoFormateado {
    final m = (_segundosRestantes ~/ 60).toString().padLeft(2, '0');
    final s = (_segundosRestantes % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Llave IoT',
                      style: AppTheme.displayFont(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const StatusPill(
                      label: 'ESP32 Online',
                      showDot: true,
                      color: AppColors.success,
                      backgroundColor: AppColors.successBg,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (_cargandoAulas)
                const SizedBox(
                  height: 220,
                  child: SkeletonListPlaceholder(count: 2, itemHeight: 88),
                )
              else if (_errorAulas != null)
                ErrorStateView(message: _errorAulas!, onRetry: _cargarAulas)
              else ...[
                _buildAulaSelector(),
                const SizedBox(height: 16),
                _buildKeycard(),
                const SizedBox(height: 16),
                _buildCtaButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAulaSelector() {
    final aula = _aulaSeleccionada;
    return AulaSyncCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: _aulas.length > 1 ? _mostrarSelectorAula : null,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.meeting_room_outlined,
                size: 18, color: AppColors.navy),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  aula != null ? 'Aula ${aula.codigo}' : 'Sin aulas',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  aula != null
                      ? '${aula.edificio} · Cap. ${aula.capacidad} alumnos'
                      : 'No hay aulas disponibles',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.keyboard_arrow_down_rounded,
              size: 20, color: AppColors.textMuted),
        ],
      ),
    );
  }

  void _mostrarSelectorAula() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        children: _aulas
            .map((a) => ListTile(
                  leading: const Icon(Icons.meeting_room_outlined,
                      color: AppColors.navy),
                  title: Text('Aula ${a.codigo}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${a.edificio} · Cap. ${a.capacidad}'),
                  trailing: a.id == _aulaSeleccionada?.id
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.teal)
                      : null,
                  onTap: () {
                    setState(() {
                      _aulaSeleccionada = a;
                      _codigoOtp = null;
                      _timer?.cancel();
                    });
                    Navigator.pop(ctx);
                  },
                ))
            .toList(),
      ),
    );
  }

  Widget _buildKeycard() {
    final activo = _codigoOtp != null && !_codigoExpirado && !_codigoUsado;
    final digits = (_codigoOtp ?? '------').padRight(6, '-').split('');
    final progress = activo && _segundosTotales > 0
        ? (_segundosRestantes / _segundosTotales).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppShadows.hero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                activo
                    ? 'PIN TEMPORAL ACTIVO'
                    : _codigoUsado
                        ? 'PUERTA DESBLOQUEADA'
                        : 'CERRADURA ASEGURADA',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.tealLight,
                  letterSpacing: 0.6,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  activo ? _tiempoFormateado : '--:--',
                  style: AppTheme.tabularMono.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          if (_tipoVisualizacion == 0 || !activo)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                6,
                (i) => Container(
                  width: 44,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.30),
                      width: 1.2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    digits[i],
                    style: AppTheme.displayFont(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            )
          else
            Center(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: CustomPaint(
                  size: const Size(156, 156),
                  painter: QrMatrixPainter(
                    data: '${_aulaSeleccionada?.codigo ?? ''}:$_codigoOtp',
                    isExpired: _codigoExpirado,
                    isUsed: _codigoUsado,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.emeraldBright),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: activo
                    ? () {
                        Clipboard.setData(ClipboardData(text: _codigoOtp!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('PIN copiado')),
                        );
                      }
                    : null,
                child: Text(
                  activo ? 'PIN Numérico · Copiar' : 'Solicita un PIN para abrir',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFCBD5E1),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(
                    () => _tipoVisualizacion = _tipoVisualizacion == 0 ? 1 : 0),
                child: Text(
                  _tipoVisualizacion == 0 ? 'Ver QR →' : 'Ver PIN →',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.tealSoft,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCtaButton() {
    final activo = _codigoOtp != null && !_codigoExpirado && !_codigoUsado;
    return AulaSyncGradientButton(
      label: activo ? 'Desbloquear Cerradura IoT' : 'Generar Código OTP',
      icon: activo ? Icons.lock_open_rounded : Icons.key_rounded,
      loading: _generandoOtp || _abriendoCerradura,
      onPressed: activo ? _abrirCerradura : _generarOtp,
    );
  }
}

/// CustomPainter para renderizar un código QR matricial determinista sin dependencias externas.
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
    const int gridSize = 21;
    final cellSize = size.width / gridSize;
    final matrix = _generarMatriz(data, gridSize);

    final paintDark = Paint()
      ..color = isExpired || isUsed
          ? const Color(0xFF94A3B8)
          : const Color(0xFF0B2F4F)
      ..style = PaintingStyle.fill;

    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (matrix[r][c]) {
          canvas.drawRect(
            Rect.fromLTWH(c * cellSize, r * cellSize, cellSize, cellSize),
            paintDark,
          );
        }
      }
    }
  }

  List<List<bool>> _generarMatriz(String text, int size) {
    final m = List.generate(size, (_) => List.filled(size, false));
    _dibujarFinderPattern(m, 0, 0);
    _dibujarFinderPattern(m, 0, size - 7);
    _dibujarFinderPattern(m, size - 7, 0);

    for (int i = 7; i < size - 7; i++) {
      m[6][i] = (i % 2 == 0);
      m[i][6] = (i % 2 == 0);
    }

    int seed = 0;
    for (int i = 0; i < text.length; i++) {
      seed = (seed * 31 + text.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    final rand = math.Random(seed);

    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (_esAreaProtegida(r, c, size)) continue;
        m[r][c] = rand.nextBool();
      }
    }
    return m;
  }

  void _dibujarFinderPattern(List<List<bool>> m, int top, int left) {
    for (int r = 0; r < 7; r++) {
      for (int c = 0; c < 7; c++) {
        if (r == 0 || r == 6 || c == 0 || c == 6 || (r >= 2 && r <= 4 && c >= 2 && c <= 4)) {
          m[top + r][left + c] = true;
        }
      }
    }
  }

  bool _esAreaProtegida(int r, int c, int size) {
    if (r <= 7 && c <= 7) return true;
    if (r <= 7 && c >= size - 8) return true;
    if (r >= size - 8 && c <= 7) return true;
    if (r == 6 || c == 6) return true;
    return false;
  }

  @override
  bool shouldRepaint(covariant QrMatrixPainter oldDelegate) =>
      oldDelegate.data != data ||
      oldDelegate.isExpired != isExpired ||
      oldDelegate.isUsed != isUsed;
}
