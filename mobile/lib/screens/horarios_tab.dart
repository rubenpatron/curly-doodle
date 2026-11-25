import 'package:flutter/material.dart';
import '../models/clase_horario.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/aulasync_widgets.dart';

class HorariosTab extends StatefulWidget {
  final VoidCallback? onIrAOtp;

  const HorariosTab({super.key, this.onIrAOtp});

  @override
  State<HorariosTab> createState() => _HorariosTabState();
}

class _HorariosTabState extends State<HorariosTab> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<ClaseHorario> _horarios = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _filtroDia = 0;
  String _filtroBusqueda = '';

  final List<Map<String, dynamic>> _diasSemana = const [
    {'id': 0, 'label': 'Todos'},
    {'id': 1, 'label': 'Lun'},
    {'id': 2, 'label': 'Mar'},
    {'id': 3, 'label': 'Mié'},
    {'id': 4, 'label': 'Jue'},
    {'id': 5, 'label': 'Vie'},
    {'id': 6, 'label': 'Sáb'},
  ];

  @override
  void initState() {
    super.initState();
    _cargarHorarios();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarHorarios() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _apiService.getHorario();
      if (!mounted) return;
      setState(() {
        _horarios = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  List<ClaseHorario> get _horariosFiltrados {
    return _horarios.where((clase) {
      if (_filtroDia != 0 && clase.diaSemana != _filtroDia) return false;
      if (_filtroBusqueda.isNotEmpty) {
        final q = _filtroBusqueda.toLowerCase();
        return clase.materia.toLowerCase().contains(q) ||
            clase.materiaCodigo.toLowerCase().contains(q) ||
            clase.aula.toLowerCase().contains(q) ||
            clase.edificio.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  int get _diaActual => DateTime.now().weekday;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _cargarHorarios,
        color: AppColors.navy,
        child: Column(
          children: [
            _buildBarraFiltros(),
            Expanded(child: _buildContenido()),
          ],
        ),
      ),
    );
  }

  Widget _buildBarraFiltros() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              TextField(
                controller: _searchCtrl,
                onChanged: (val) =>
                    setState(() => _filtroBusqueda = val.trim()),
                decoration: InputDecoration(
                  hintText: 'Buscar materia, aula o edificio...',
                  hintStyle: const TextStyle(
                      fontSize: 13, color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search_rounded,
                      size: 20, color: AppColors.navy),
                  suffixIcon: _filtroBusqueda.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _filtroBusqueda = '');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    borderSide:
                        const BorderSide(color: AppColors.navy, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _diasSemana.map((dia) {
                    final isSelected = _filtroDia == dia['id'];
                    final isToday = dia['id'] == _diaActual;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        selected: isSelected,
                        showCheckmark: false,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              dia['label'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                            if (isToday && dia['id'] != 0) ...[
                              const SizedBox(width: 5),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF34D399)
                                      : AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                        backgroundColor: AppColors.background,
                        selectedColor: AppColors.navy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.navy
                                : isToday && dia['id'] != 0
                                    ? AppColors.success
                                    : AppColors.border,
                          ),
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _filtroDia = selected ? dia['id'] as int : 0;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContenido() {
    if (_isLoading) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: const SkeletonListPlaceholder(itemCount: 4, itemHeight: 102),
        ),
      );
    }

    if (_errorMessage != null) {
      return ErrorStateView(
        message: _errorMessage!,
        onRetry: _cargarHorarios,
      );
    }

    final lista = _horariosFiltrados;
    if (lista.isEmpty) {
      return EmptyStateView(
        icon: Icons.calendar_today_outlined,
        title: _horarios.isEmpty
            ? 'Sin carga académica asignada'
            : 'Sin coincidencias en tu búsqueda',
        message: _horarios.isEmpty
            ? 'Cuando el administrador te asigne materias y aulas, aparecerán aquí.'
            : 'Prueba cambiando el filtro de día o el término de búsqueda.',
      );
    }

    final claseHoy = _horarios.where((c) => c.diaSemana == _diaActual).firstOrNull;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (claseHoy != null) ...[
              _buildHeroClaseHoy(claseHoy),
              const SizedBox(height: 16),
            ],
            for (int i = 0; i < lista.length; i++) ...[
              _buildClaseCard(lista[i]),
              if (i < lista.length - 1) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeroClaseHoy(ClaseHorario c) {
    final inicio = c.horaInicio.length >= 5
        ? c.horaInicio.substring(0, 5)
        : c.horaInicio;
    final fin =
        c.horaFin.length >= 5 ? c.horaFin.substring(0, 5) : c.horaFin;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF071A2F), AppColors.navy, AppColors.teal],
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                        radius: 3.5, backgroundColor: Color(0xFF34D399)),
                    SizedBox(width: 6),
                    Text(
                      'CLASE ACTIVA HOY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$inicio – $fin',
                style: AppTheme.tabularMono.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF99F6E4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            c.materia,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Aula ${c.aula} · ${c.edificio}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFCCFBF1),
                ),
              ),
              FilledButton.icon(
                onPressed: widget.onIrAOtp,
                icon: const Icon(Icons.key_rounded, size: 15),
                label: const Text('Abrir con OTP'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.navy,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClaseCard(ClaseHorario c) {
    final esHoy = c.diaSemana == _diaActual;
    final inicio = c.horaInicio.length >= 5
        ? c.horaInicio.substring(0, 5)
        : c.horaInicio;
    final fin =
        c.horaFin.length >= 5 ? c.horaFin.substring(0, 5) : c.horaFin;

    return AulaSyncCard(
      padding: const EdgeInsets.all(14),
      backgroundColor: esHoy ? const Color(0xFFFAFFFE) : AppColors.surface,
      borderColor: esHoy ? AppColors.successBorder : AppColors.border,
      borderWidth: esHoy ? 1.4 : 1,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Bloque horario tabular a la izquierda
          Container(
            width: 72,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              color: esHoy ? AppColors.successBg : AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(
                color: esHoy ? AppColors.successBorder : AppColors.border,
              ),
            ),
            child: Column(
              children: [
                Text(
                  inicio,
                  style: AppTheme.tabularMono.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: esHoy ? AppColors.success : AppColors.navy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fin,
                  style: AppTheme.tabularMono.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Información de la clase
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusPill(
                      label: c.materiaCodigo.isNotEmpty
                          ? c.materiaCodigo
                          : c.diaNombre,
                      backgroundColor: AppColors.surfaceSubtle,
                      foregroundColor: AppColors.navy,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      c.diaNombre,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const Spacer(),
                    if (esHoy)
                      const StatusPill(
                        label: 'HOY',
                        backgroundColor: AppColors.successBg,
                        foregroundColor: AppColors.success,
                        borderColor: AppColors.successBorder,
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  c.materia,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.meeting_room_outlined,
                        size: 15, color: AppColors.teal),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Aula ${c.aula} · ${c.edificio}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.teal,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
