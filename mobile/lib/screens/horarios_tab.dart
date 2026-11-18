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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          // Buscador rápido
          TextField(
            onChanged: (val) => setState(() => _filtroBusqueda = val.trim()),
            decoration: InputDecoration(
              hintText: 'Buscar materia, aula o edificio...',
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
              suffixIcon: _filtroBusqueda.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _filtroBusqueda = ''),
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Selector de Días con Chips
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
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          dia['label'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFF334155),
                          ),
                        ),
                        if (isToday && dia['id'] != 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.amberAccent : const Color(0xFF127A6B),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    backgroundColor: const Color(0xFFF8FAFC),
                    selectedColor: const Color(0xFF0B2F4F),
                    checkmarkColor: Colors.white,
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF0B2F4F)
                            : (isToday && dia['id'] != 0
                                ? const Color(0xFF127A6B).withValues(alpha: 0.5)
                                : const Color(0xFFE2E8F0)),
                      ),
                    ),
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: esHoy ? const Color(0xFF127A6B).withValues(alpha: 0.4) : const Color(0xFFE2E8F0),
          width: esHoy ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: esHoy ? const Color(0xFF127A6B) : const Color(0xFF0B2F4F),
                width: 5,
              ),
            ),
          ),
          padding: const EdgeInsets.all(14),
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
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        if (clase.materiaCodigo.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Clave: ${clase.materiaCodigo}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (esHoy)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF127A6B).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.today, size: 14, color: Color(0xFF127A6B)),
                          SizedBox(width: 4),
                          Text(
                            'HOY',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF127A6B),
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
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B2F4F).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.access_time_filled, size: 16, color: Color(0xFF0B2F4F)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${clase.diaNombre}  •  ${clase.horaInicio} - ${clase.horaFin} hrs',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Badges de Ubicación: Aula, Edificio y Capacidad
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildPill(
                    icon: Icons.meeting_room_outlined,
                    label: 'Aula: ${clase.aula}',
                    color: const Color(0xFF0B2F4F),
                  ),
                  _buildPill(
                    icon: Icons.business_outlined,
                    label: 'Edificio: ${clase.edificio}',
                    color: const Color(0xFF475569),
                  ),
                  _buildPill(
                    icon: Icons.people_outline,
                    label: 'Capacidad: ${clase.capacidad}',
                    color: const Color(0xFF64748B),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPill({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
