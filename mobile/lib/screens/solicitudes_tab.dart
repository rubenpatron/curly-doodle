import 'package:flutter/material.dart';
import '../models/solicitud.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/aulasync_widgets.dart';
import 'nueva_solicitud_screen.dart';

class SolicitudesTab extends StatefulWidget {
  const SolicitudesTab({super.key});

  @override
  State<SolicitudesTab> createState() => _SolicitudesTabState();
}

class _SolicitudesTabState extends State<SolicitudesTab> {
  bool _cargando = true;
  String? _error;
  List<Solicitud> _solicitudes = [];
  String _filtroEstado = 'todas';

  @override
  void initState() {
    super.initState();
    _cargarSolicitudes();
  }

  Future<void> _cargarSolicitudes() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final list = await ApiService().getSolicitudes();
      if (!mounted) return;
      setState(() {
        _solicitudes = list;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _cargando = false;
      });
    }
  }

  Future<void> _abrirNuevaSolicitud() async {
    final creada = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const NuevaSolicitudScreen(),
      ),
    );

    if (creada == true) {
      _cargarSolicitudes();
    }
  }

  List<Solicitud> get _solicitudesFiltradas {
    if (_filtroEstado == 'todas') return _solicitudes;
    return _solicitudes
        .where((s) => s.estado.toLowerCase() == _filtroEstado.toLowerCase())
        .toList();
  }

  int _countEstado(String estado) =>
      _solicitudes.where((s) => s.estado.toLowerCase() == estado).length;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _cargarSolicitudes,
      color: AppColors.navy,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildKpiRow()),
              ..._buildBodySlivers(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Solicitudes',
            style: AppTheme.displayFont(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.6,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppShadows.cta,
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: _abrirNuevaSolicitud,
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 16, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'Nueva',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
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
    );
  }

  Widget _buildKpiRow() {
    final total = _solicitudes.length;
    final pendientes = _countEstado('pendiente');
    final aprobadas = _countEstado('aprobada');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: _KpiCard(
              value: '$total',
              label: 'Total',
              color: AppColors.navy,
              selected: _filtroEstado == 'todas',
              onTap: () => setState(() => _filtroEstado = 'todas'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _KpiCard(
              value: '$pendientes',
              label: 'Pendiente',
              color: AppColors.warning,
              selected: _filtroEstado == 'pendiente',
              onTap: () => setState(() => _filtroEstado = 'pendiente'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _KpiCard(
              value: '$aprobadas',
              label: 'Aprobadas',
              color: AppColors.success,
              selected: _filtroEstado == 'aprobada',
              onTap: () => setState(() => _filtroEstado = 'aprobada'),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBodySlivers() {
    if (_cargando) {
      return const [
        SliverFillRemaining(
          child: SkeletonListPlaceholder(count: 3, itemHeight: 132),
        ),
      ];
    }

    if (_error != null) {
      return [
        SliverFillRemaining(
          child: ErrorStateView(
            message: _error!,
            onRetry: _cargarSolicitudes,
          ),
        ),
      ];
    }

    final lista = _solicitudesFiltradas;
    if (lista.isEmpty) {
      return [
        SliverFillRemaining(
          child: EmptyStateView(
            icon: Icons.assignment_outlined,
            title: _solicitudes.isEmpty
                ? 'Aún no tienes solicitudes'
                : 'Sin solicitudes en este filtro',
            subtitle: _solicitudes.isEmpty
                ? 'Presiona "+ Nueva" para solicitar un aula adicional o cambio.'
                : 'Toca "Total" para ver todas tus solicitudes registradas.',
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
        sliver: SliverList.separated(
          itemCount: lista.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (_, idx) => _buildSolicitudCard(lista[idx]),
        ),
      ),
    ];
  }

  Widget _buildSolicitudCard(Solicitud s) {
    final (pillColor, pillBg, pillLabel) = switch (s.estado.toLowerCase()) {
      'aprobada' => (AppColors.success, AppColors.successBg, 'Aprobada'),
      'rechazada' => (AppColors.error, AppColors.errorBg, 'Rechazada'),
      'cancelada' => (AppColors.textMuted, AppColors.surfaceMuted, 'Cancelada'),
      _ => (AppColors.warningDark, AppColors.warningBg, 'Pendiente'),
    };

    final subtitulo = s.tipo == 'cambio_aula' && s.aulaOriginal != null
        ? '${s.aulaOriginal} → ${s.aulaSolicitada} · Cambio'
        : 'Aula ${s.aulaSolicitada} · Aula Adicional';

    return AulaSyncCard(
      radius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${s.fecha} · ${s.horaInicio} – ${s.horaFin}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              StatusPill(
                label: pillLabel,
                color: pillColor,
                backgroundColor: pillBg,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            s.materia,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitulo,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.teal,
            ),
          ),
          if (s.motivo.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                s.motivo,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
          if (s.comentariosAdmin != null &&
              s.comentariosAdmin!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Admin: ${s.comentariosAdmin!}',
              style: const TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _KpiCard({
    required this.value,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: selected
              ? Border.all(color: color.withValues(alpha: 0.45), width: 1.5)
              : null,
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppTheme.displayFont(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
