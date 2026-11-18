import 'package:flutter/material.dart';
import '../models/solicitud.dart';
import '../services/api_service.dart';
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
  String _filtroEstado = 'todas'; // 'todas', 'pendiente', 'aprobada', 'rechazada'

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

  Widget _buildEstadoChip(String estado) {
    Color bg;
    Color fg;
    IconData icon;
    String label;

    switch (estado.toLowerCase()) {
      case 'aprobada':
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF065F46);
        icon = Icons.check_circle_rounded;
        label = 'Aprobada';
        break;
      case 'rechazada':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFF991B1B);
        icon = Icons.cancel_rounded;
        label = 'Rechazada';
        break;
      case 'cancelada':
        bg = const Color(0xFFE2E8F0);
        fg = const Color(0xFF475569);
        icon = Icons.block_rounded;
        label = 'Cancelada';
        break;
      case 'pendiente':
      default:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        icon = Icons.access_time_filled_rounded;
        label = 'Pendiente';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipoBadge(String tipo) {
    final esCambio = tipo == 'cambio_aula';
    final bg = esCambio ? const Color(0xFFEEF2FF) : const Color(0xFFF0FDF4);
    final fg = esCambio ? const Color(0xFF4338CA) : const Color(0xFF15803D);
    final text = esCambio ? 'Cambio de Aula' : 'Aula Adicional';
    final icon = esCambio ? Icons.swap_horiz : Icons.add_home_work_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolicitudCard(Solicitud s) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila superior: Tipo y Estado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTipoBadge(s.tipo),
                _buildEstadoChip(s.estado),
              ],
            ),
            const SizedBox(height: 10),

            // Materia
            Text(
              s.materia.isNotEmpty ? s.materia : 'Materia no especificada',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),

            // Aula solicitada (y original si aplica)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.meeting_room, size: 18, color: Color(0xFF0B2F4F)),
                  const SizedBox(width: 8),
                  if (s.tipo == 'cambio_aula' &&
                      s.aulaOriginal != null &&
                      s.aulaOriginal!.isNotEmpty) ...[
                    Text(
                      'Aula ${s.aulaOriginal}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.arrow_forward, size: 14, color: Color(0xFF0B2F4F)),
                    ),
                  ],
                  Text(
                    'Aula ${s.aulaSolicitada}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0B2F4F),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Fecha y Horario
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 15, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(
                  s.fecha,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 15, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(
                  '${s.horaInicio} - ${s.horaFin}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Motivo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 13, color: Color(0xFF475569)),
                      const SizedBox(width: 4),
                      Text(
                        'Motivo:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.motivo,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                  ),
                  if (s.justificacion != null && s.justificacion!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Justificación: ${s.justificacion}',
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey.shade700),
                    ),
                  ],
                ],
              ),
            ),

            // Comentarios del Administrador (si existen)
            if (s.comentariosAdmin != null && s.comentariosAdmin!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: s.estado == 'aprobada'
                      ? const Color(0xFFECFDF5)
                      : s.estado == 'rechazada'
                          ? const Color(0xFFFEF2F2)
                          : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: s.estado == 'aprobada'
                        ? const Color(0xFFA7F3D0)
                        : s.estado == 'rechazada'
                            ? const Color(0xFFFECACA)
                            : const Color(0xFFBFDBFE),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      s.estado == 'aprobada'
                          ? Icons.check_circle_outline
                          : Icons.info_outline,
                      size: 16,
                      color: s.estado == 'aprobada'
                          ? const Color(0xFF047857)
                          : const Color(0xFFB91C1C),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Respuesta del Administrador:',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: s.estado == 'aprobada'
                                  ? const Color(0xFF065F46)
                                  : const Color(0xFF991B1B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.comentariosAdmin!,
                            style: TextStyle(
                              fontSize: 12,
                              color: s.estado == 'aprobada'
                                  ? const Color(0xFF064E3B)
                                  : const Color(0xFF7F1D1D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFiltrosChips() {
    final opciones = [
      {'key': 'todas', 'label': 'Todas (${_solicitudes.length})'},
      {
        'key': 'pendiente',
        'label': 'Pendientes (${_solicitudes.where((s) => s.estado == 'pendiente').length})'
      },
      {
        'key': 'aprobada',
        'label': 'Aprobadas (${_solicitudes.where((s) => s.estado == 'aprobada').length})'
      },
      {
        'key': 'rechazada',
        'label': 'Rechazadas (${_solicitudes.where((s) => s.estado == 'rechazada').length})'
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: opciones.map((op) {
          final isSelected = _filtroEstado == op['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(op['label']!),
              selected: isSelected,
              selectedColor: const Color(0xFF0B2F4F),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF475569),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              side: BorderSide(
                color: isSelected ? const Color(0xFF0B2F4F) : const Color(0xFFCBD5E1),
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _filtroEstado = op['key']!);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _cargarSolicitudes,
        color: const Color(0xFF0B2F4F),
        child: Column(
          children: [
            // Filtros de estado
            if (!_cargando && _error == null && _solicitudes.isNotEmpty)
              _buildFiltrosChips(),

            Expanded(
              child: _cargando
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF0B2F4F)),
                          SizedBox(height: 12),
                          Text(
                            'Cargando solicitudes...',
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    )
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                                const SizedBox(height: 12),
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _cargarSolicitudes,
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
                      : _solicitudesFiltradas.isEmpty
                          ? ListView(
                              padding: const EdgeInsets.all(24.0),
                              children: [
                                const SizedBox(height: 60),
                                Center(
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE2E8F0),
                                      borderRadius: BorderRadius.circular(40),
                                    ),
                                    child: const Icon(
                                      Icons.assignment_outlined,
                                      size: 40,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _filtroEstado == 'todas'
                                      ? 'No tienes solicitudes registradas'
                                      : 'No hay solicitudes con estado "$_filtroEstado"',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Crea una solicitud si necesitas un cambio de aula o un espacio adicional para exámenes o eventos.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Center(
                                  child: ElevatedButton.icon(
                                    onPressed: _abrirNuevaSolicitud,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Crear Primera Solicitud'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0B2F4F),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              itemCount: _solicitudesFiltradas.length,
                              itemBuilder: (context, index) {
                                return _buildSolicitudCard(
                                    _solicitudesFiltradas[index]);
                              },
                            ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirNuevaSolicitud,
        backgroundColor: const Color(0xFF0B2F4F),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Solicitud', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
