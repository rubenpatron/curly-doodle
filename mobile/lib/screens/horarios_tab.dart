import 'package:flutter/material.dart';
import '../models/clase_horario.dart';
import '../services/api_service.dart';

class HorariosTab extends StatefulWidget {
  const HorariosTab({super.key});

  @override
  State<HorariosTab> createState() => _HorariosTabState();
}

class _HorariosTabState extends State<HorariosTab> {
  final ApiService _apiService = ApiService();
  List<ClaseHorario> _horarios = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _filtroDia = 0; // 0 = Todos, 1-7 = Lunes a Domingo
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

  Future<void> _cargarHorarios() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _apiService.getHorario();
      if (mounted) {
        setState(() {
          _horarios = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  List<ClaseHorario> get _horariosFiltrados {
    return _horarios.where((clase) {
      if (_filtroDia != 0 && clase.diaSemana != _filtroDia) {
        return false;
      }
      if (_filtroBusqueda.isNotEmpty) {
        final query = _filtroBusqueda.toLowerCase();
        final matchMateria = clase.materia.toLowerCase().contains(query);
        final matchCodigo = clase.materiaCodigo.toLowerCase().contains(query);
        final matchAula = clase.aula.toLowerCase().contains(query);
        final matchEdificio = clase.edificio.toLowerCase().contains(query);
        return matchMateria || matchCodigo || matchAula || matchEdificio;
      }
      return true;
    }).toList();
  }

  int get _diaActual => DateTime.now().weekday;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _cargarHorarios,
        color: const Color(0xFF0B2F4F),
        child: Column(
          children: [
            // Barra de búsqueda y selector de días
            _buildBarraFiltros(),
            
            // Contenido principal
            Expanded(
              child: _buildContenido(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarraFiltros() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        children: [
          // Buscador rápido estilo Material 3
          TextField(
            onChanged: (val) => setState(() => _filtroBusqueda = val.trim()),
            decoration: InputDecoration(
              hintText: 'Buscar materia, aula o edificio...',
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF0B2F4F)),
              suffixIcon: _filtroBusqueda.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () => setState(() => _filtroBusqueda = ''),
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: const BorderSide(color: Color(0xFF0B2F4F), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Selector de Días con Chips Modernos
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
                          dia['label'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFF334155),
                          ),
                        ),
                        if (isToday && dia['id'] != 0) ...[
                          const SizedBox(width: 5),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF34D399) : const Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    backgroundColor: const Color(0xFFF8FAFC),
                    selectedColor: const Color(0xFF0B2F4F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF0B2F4F)
                            : (isToday && dia['id'] != 0
                                ? const Color(0xFF10B981)
                                : const Color(0xFFE2E8F0)),
                        width: isToday && !isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    onSelected: (selected) {
                      setState(() {
                        _filtroDia = selected ? dia['id'] : 0;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContenido() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF0B2F4F)),
            SizedBox(height: 16),
            Text(
              'Cargando carga académica...',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, size: 54, color: Colors.redAccent),
                  const SizedBox(height: 14),
                  const Text(
                    'Error al sincronizar horario',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _cargarHorarios,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Reintentar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B2F4F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final lista = _horariosFiltrados;
    if (lista.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Icon(Icons.event_busy_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 14),
                  const Text(
                    'Sin clases asignadas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _filtroDia != 0 || _filtroBusqueda.isNotEmpty
                        ? 'No hay registros que coincidan con los filtros aplicados.'
                        : 'No tienes carga académica registrada en este ciclo.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),
                  if (_filtroDia != 0 || _filtroBusqueda.isNotEmpty)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _filtroDia = 0;
                          _filtroBusqueda = '';
                        });
                      },
                      icon: const Icon(Icons.filter_alt_off, size: 18),
                      label: const Text('Limpiar Filtros'),
                    ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: lista.length,
      itemBuilder: (context, index) {
        return _buildTarjetaHorario(lista[index]);
      },
    );
  }

  Widget _buildTarjetaHorario(ClaseHorario clase) {
    final bool esHoy = clase.diaSemana == _diaActual;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: esHoy ? const Color(0xFF10B981).withValues(alpha: 0.5) : const Color(0xFFE2E8F0),
          width: esHoy ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: esHoy ? const Color(0xFF10B981).withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: esHoy ? const Color(0xFF10B981) : const Color(0xFF0B2F4F),
                width: 5,
              ),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila superior: Materia + Código y Etiqueta de Hoy
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          clase.materia,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (clase.materiaCodigo.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Clave: ${clase.materiaCodigo}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (esHoy)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt_rounded, size: 14, color: Color(0xFF047857)),
                          SizedBox(width: 4),
                          Text(
                            'HOY',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF047857),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 12),

              // Datos del horario: Día y Rango Horario
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B2F4F).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.schedule_rounded, size: 16, color: Color(0xFF0B2F4F)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${clase.diaNombre}  •  ${clase.horaInicio} - ${clase.horaFin} hrs',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Badges de Ubicación: Aula, Edificio y Capacidad
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildPill(
                    icon: Icons.meeting_room_rounded,
                    label: 'Aula: ${clase.aula}',
                    color: const Color(0xFF0B2F4F),
                    bgColor: const Color(0xFFEFF6FF),
                  ),
                  _buildPill(
                    icon: Icons.business_rounded,
                    label: 'Edificio: ${clase.edificio}',
                    color: const Color(0xFF475569),
                    bgColor: const Color(0xFFF8FAFC),
                  ),
                  _buildPill(
                    icon: Icons.people_alt_rounded,
                    label: 'Capacidad: ${clase.capacidad}',
                    color: const Color(0xFF0F766E),
                    bgColor: const Color(0xFFF0FDFA),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPill({required IconData icon, required String label, required Color color, Color? bgColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor ?? const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
