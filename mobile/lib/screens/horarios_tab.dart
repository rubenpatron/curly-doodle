import 'dart:async';
import 'package:flutter/material.dart';
import '../models/clase_horario.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/aulasync_widgets.dart';

class HorariosTab extends StatefulWidget {
  final void Function(int idAula)? onIrAOtp;
  final VoidCallback? onIrAPerfil;
  final String iniciales;
  final int refreshSeq;

  const HorariosTab({
    super.key,
    this.onIrAOtp,
    this.onIrAPerfil,
    this.iniciales = 'EP',
    this.refreshSeq = 0,
  });

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
  Timer? _liveTimer;

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
    _liveTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _cargarHorarios(silent: true),
    );
  }

  @override
  void didUpdateWidget(covariant HorariosTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshSeq != oldWidget.refreshSeq) {
      _cargarHorarios(silent: true);
    }
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarHorarios({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final list = await _apiService.getHorario();
      if (!mounted) return;
      setState(() {
        _horarios = list;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
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

  String get _fechaHoyTexto {
    const dias = [
      '',
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo'
    ];
    const meses = [
      '',
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    final now = DateTime.now();
    return '${dias[now.weekday]} ${now.day} de ${meses[now.month]}';
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _cargarHorarios,
      color: AppColors.navy,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildHeroIfAny()),
              SliverToBoxAdapter(child: _buildFiltros()),
              ..._buildBodySlivers(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Horarios',
                style: AppTheme.displayFont(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _fechaHoyTexto,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: widget.onIrAPerfil,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                gradient: AppColors.brandGradient,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                widget.iniciales,
                style: AppTheme.displayFont(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroIfAny() {
    if (_isLoading || _errorMessage != null) return const SizedBox.shrink();
    final claseHoy =
        _horarios.where((c) => c.diaSemana == _diaActual).firstOrNull;
    if (claseHoy == null) return const SizedBox.shrink();

    final inicio = claseHoy.horaInicio.length >= 5
        ? claseHoy.horaInicio.substring(0, 5)
        : claseHoy.horaInicio;
    final fin = claseHoy.horaFin.length >= 5
        ? claseHoy.horaFin.substring(0, 5)
        : claseHoy.horaFin;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppShadows.hero,
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
                          radius: 3, backgroundColor: AppColors.emeraldBright),
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
                    color: AppColors.tealLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              claseHoy.materia,
              style: AppTheme.displayFont(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Aula ${claseHoy.aula} · ${claseHoy.edificio}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFCCFBF1),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: widget.onIrAOtp != null
                        ? () => widget.onIrAOtp!(claseHoy.idAula)
                        : null,
                    borderRadius: BorderRadius.circular(14),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.key_rounded,
                              size: 14, color: AppColors.navy),
                          SizedBox(width: 6),
                          Text(
                            'Abrir con OTP',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltros() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppShadows.card,
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) =>
                  setState(() => _filtroBusqueda = val.trim()),
              decoration: InputDecoration(
                filled: false,
                hintText: 'Buscar materia, aula o edificio...',
                hintStyle:
                    const TextStyle(fontSize: 13, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 18, color: AppColors.textMuted),
                suffixIcon: _filtroBusqueda.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _filtroBusqueda = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _diasSemana.map((dia) {
                final isSelected = _filtroDia == dia['id'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _filtroDia = dia['id'] as int),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.navy : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isSelected
                            ? const [
                                BoxShadow(
                                  color: Color(0x330B2F4F),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ]
                            : AppShadows.card,
                      ),
                      child: Text(
                        dia['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBodySlivers() {
    if (_isLoading) {
      return const [
        SliverFillRemaining(
          child: SkeletonListPlaceholder(count: 4, itemHeight: 96),
        ),
      ];
    }

    if (_errorMessage != null) {
      return [
        SliverFillRemaining(
          child: ErrorStateView(
            message: _errorMessage!,
            onRetry: _cargarHorarios,
          ),
        ),
      ];
    }

    final lista = _horariosFiltrados;
    if (lista.isEmpty) {
      return [
        SliverFillRemaining(
          child: EmptyStateView(
            icon: Icons.calendar_today_outlined,
            title: _horarios.isEmpty
                ? 'Sin carga académica asignada'
                : 'Sin coincidencias en tu búsqueda',
            subtitle: _horarios.isEmpty
                ? 'Cuando el administrador te asigne materias y aulas, aparecerán aquí.'
                : 'Prueba cambiando el filtro de día o el término de búsqueda.',
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
        sliver: SliverList.separated(
          itemCount: lista.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, idx) => _buildClaseCard(lista[idx]),
        ),
      ),
    ];
  }

  Widget _buildClaseCard(ClaseHorario c) {
    final inicio = c.horaInicio.length >= 5
        ? c.horaInicio.substring(0, 5)
        : c.horaInicio;
    final fin =
        c.horaFin.length >= 5 ? c.horaFin.substring(0, 5) : c.horaFin;

    return AulaSyncCard(
      radius: 22,
      padding: const EdgeInsets.all(14),
      onTap: widget.onIrAOtp != null ? () => widget.onIrAOtp!(c.idAula) : null,
      child: Row(
        children: [
          Container(
            width: 68,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  inicio,
                  style: AppTheme.tabularMono.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.materia,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Aula ${c.aula} · ${c.edificio}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.teal,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              size: 20, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
