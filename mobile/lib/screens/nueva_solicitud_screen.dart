import 'package:flutter/material.dart';
import '../models/aula.dart';
import '../services/api_service.dart';

class NuevaSolicitudScreen extends StatefulWidget {
  const NuevaSolicitudScreen({super.key});

  @override
  State<NuevaSolicitudScreen> createState() => _NuevaSolicitudScreenState();
}

class _NuevaSolicitudScreenState extends State<NuevaSolicitudScreen> {
  final _formKey = GlobalKey<FormState>();

  String _tipo = 'aula_adicional'; // 'aula_adicional' o 'cambio_aula'
  int? _idMateria;
  int? _idAulaSolicitada;
  int? _idAulaOriginal;

  DateTime _fecha = DateTime.now();
  TimeOfDay _horaInicio = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _horaFin = const TimeOfDay(hour: 10, minute: 0);

  final _motivoCtrl = TextEditingController();
  final _justificacionCtrl = TextEditingController();

  bool _cargandoCatalogos = true;
  bool _enviando = false;
  String? _errorCatalogos;

  List<Map<String, dynamic>> _materias = [];
  List<Aula> _aulas = [];

  final List<String> _motivosSugeridos = [
    'Examen Parcial',
    'Práctica de Laboratorio',
    'Clase de Recuperación',
    'Asesoría Académica Grupal',
  ];

  @override
  void initState() {
    super.initState();
    _cargarCatalogos();
  }

  @override
  void dispose() {
    _motivoCtrl.dispose();
    _justificacionCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarCatalogos() async {
    setState(() {
      _cargandoCatalogos = true;
      _errorCatalogos = null;
    });

    try {
      final futures = await Future.wait([
        ApiService().getMaterias(),
        ApiService().getAulas(),
      ]);

      if (!mounted) return;

      final materias = futures[0] as List<Map<String, dynamic>>;
      final aulas = futures[1] as List<Aula>;

      setState(() {
        _materias = materias;
        _aulas = aulas;
        if (_materias.isNotEmpty) {
          _idMateria = _materias.first['id'] as int?;
        }
        if (_aulas.isNotEmpty) {
          _idAulaSolicitada = _aulas.first.id;
          if (_aulas.length > 1) {
            _idAulaOriginal = _aulas[1].id;
          }
        }
        _cargandoCatalogos = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorCatalogos = e.toString().replaceAll('Exception: ', '');
        _cargandoCatalogos = false;
      });
    }
  }

  String _formatearFecha(DateTime dt) {
    final year = dt.year.toString().padLeft(4, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _formatearHora(TimeOfDay t) {
    final hour = t.hour.toString().padLeft(2, '0');
    final minute = t.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  bool _esHoraFinPosterior(TimeOfDay inicio, TimeOfDay fin) {
    final minInicio = inicio.hour * 60 + inicio.minute;
    final minFin = fin.hour * 60 + fin.minute;
    return minFin > minInicio;
  }

  Future<void> _seleccionarFecha() async {
    final ahora = DateTime.now();
    final seleccionada = await showDatePicker(
      context: context,
      initialDate: _fecha.isBefore(ahora) ? ahora : _fecha,
      firstDate: ahora.subtract(const Duration(days: 1)),
      lastDate: ahora.add(const Duration(days: 180)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0B2F4F),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (seleccionada != null && mounted) {
      setState(() => _fecha = seleccionada);
    }
  }

  Future<void> _seleccionarHoraInicio() async {
    final seleccionada = await showTimePicker(
      context: context,
      initialTime: _horaInicio,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0B2F4F),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (seleccionada != null && mounted) {
      setState(() {
        _horaInicio = seleccionada;
        // Ajustar horaFin si queda antes o igual
        if (!_esHoraFinPosterior(_horaInicio, _horaFin)) {
          int nuevaHora = _horaInicio.hour + 2;
          if (nuevaHora >= 24) nuevaHora = 23;
          _horaFin = TimeOfDay(hour: nuevaHora, minute: _horaInicio.minute);
        }
      });
    }
  }

  Future<void> _seleccionarHoraFin() async {
    final seleccionada = await showTimePicker(
      context: context,
      initialTime: _horaFin,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0B2F4F),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (seleccionada != null && mounted) {
      if (!_esHoraFinPosterior(_horaInicio, seleccionada)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La hora de fin debe ser posterior a la hora de inicio.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      setState(() => _horaFin = seleccionada);
    }
  }

  Future<void> _enviarSolicitud() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_idMateria == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una materia.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_idAulaSolicitada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona el aula solicitada.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_tipo == 'cambio_aula') {
      if (_idAulaOriginal == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes seleccionar el aula original para un cambio.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_idAulaOriginal == _idAulaSolicitada) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El aula solicitada debe ser diferente al aula original.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (!_esHoraFinPosterior(_horaInicio, _horaFin)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La hora de fin debe ser posterior a la hora de inicio.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _enviando = true);

    try {
      await ApiService().crearSolicitud(
        tipo: _tipo,
        idMateria: _idMateria!,
        idAulaSolicitada: _idAulaSolicitada!,
        idAulaOriginal: _tipo == 'cambio_aula' ? _idAulaOriginal : null,
        fecha: _formatearFecha(_fecha),
        horaInicio: _formatearHora(_horaInicio),
        horaFin: _formatearHora(_horaFin),
        motivo: _motivoCtrl.text.trim(),
        justificacion: _justificacionCtrl.text.trim().isNotEmpty
            ? _justificacionCtrl.text.trim()
            : null,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Solicitud registrada exitosamente.')),
            ],
          ),
          backgroundColor: Color(0xFF127A6B),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Nueva Solicitud',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF0B2F4F),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _cargandoCatalogos
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF0B2F4F)),
                  SizedBox(height: 12),
                  Text('Cargando catálogo de aulas y materias...',
                      style: TextStyle(color: Color(0xFF64748B))),
                ],
              ),
            )
          : _errorCatalogos != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(
                          _errorCatalogos!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _cargarCatalogos,
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
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Selector de Tipo de Solicitud
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tipo de Solicitud',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SegmentedButton<String>(
                                  segments: const [
                                    ButtonSegment(
                                      value: 'aula_adicional',
                                      label: Text('Aula Adicional'),
                                      icon: Icon(Icons.add_home_work_outlined),
                                    ),
                                    ButtonSegment(
                                      value: 'cambio_aula',
                                      label: Text('Cambio de Aula'),
                                      icon: Icon(Icons.swap_horiz_outlined),
                                    ),
                                  ],
                                  selected: {_tipo},
                                  onSelectionChanged: (newSelection) {
                                    setState(() => _tipo = newSelection.first);
                                  },
                                  style: ButtonStyle(
                                    backgroundColor:
                                        WidgetStateProperty.resolveWith((states) {
                                      if (states.contains(WidgetState.selected)) {
                                        return const Color(0xFF0B2F4F);
                                      }
                                      return Colors.white;
                                    }),
                                    foregroundColor:
                                        WidgetStateProperty.resolveWith((states) {
                                      if (states.contains(WidgetState.selected)) {
                                        return Colors.white;
                                      }
                                      return const Color(0xFF0F172A);
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Card: Materia y Aulas
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.school_outlined,
                                        size: 20, color: Color(0xFF0B2F4F)),
                                    SizedBox(width: 8),
                                    Text(
                                      'Materia y Espacios',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                // Materia Dropdown
                                DropdownButtonFormField<int>(
                                  initialValue: _idMateria,
                                  decoration: InputDecoration(
                                    labelText: 'Materia Académica *',
                                    prefixIcon: const Icon(Icons.menu_book),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    contentPadding:
                                        const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  isExpanded: true,
                                  items: _materias.map((m) {
                                    final id = m['id'] is int
                                        ? m['id'] as int
                                        : int.tryParse(m['id'].toString()) ?? 0;
                                    final codigo = m['codigo'] ?? '';
                                    final nombre = m['nombre'] ?? '';
                                    return DropdownMenuItem<int>(
                                      value: id,
                                      child: Text('$codigo - $nombre',
                                          overflow: TextOverflow.ellipsis),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() => _idMateria = val);
                                  },
                                  validator: (v) => v == null ? 'Selecciona una materia' : null,
                                ),

                                // Aula Original si es cambio de aula
                                if (_tipo == 'cambio_aula') ...[
                                  const SizedBox(height: 14),
                                  DropdownButtonFormField<int>(
                                    initialValue: _idAulaOriginal,
                                    decoration: InputDecoration(
                                      labelText: 'Aula Original (Actual) *',
                                      prefixIcon: const Icon(Icons.meeting_room_outlined),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 14),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    isExpanded: true,
                                    items: _aulas.map((a) {
                                      return DropdownMenuItem<int>(
                                        value: a.id,
                                        child: Text(
                                          'Aula ${a.codigo} - ${a.edificio} (Cap: ${a.capacidad})',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      setState(() => _idAulaOriginal = val);
                                    },
                                    validator: (v) {
                                      if (_tipo == 'cambio_aula' && v == null) {
                                        return 'Selecciona el aula original';
                                      }
                                      return null;
                                    },
                                  ),
                                ],

                                const SizedBox(height: 14),

                                // Aula Solicitada
                                DropdownButtonFormField<int>(
                                  initialValue: _idAulaSolicitada,
                                  decoration: InputDecoration(
                                    labelText: _tipo == 'cambio_aula'
                                        ? 'Aula Nueva Solicitada *'
                                        : 'Aula Solicitada *',
                                    prefixIcon: const Icon(Icons.door_front_door_outlined),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    contentPadding:
                                        const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  isExpanded: true,
                                  items: _aulas.map((a) {
                                    return DropdownMenuItem<int>(
                                      value: a.id,
                                      child: Text(
                                        'Aula ${a.codigo} - ${a.edificio} (Cap: ${a.capacidad})',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() => _idAulaSolicitada = val);
                                  },
                                  validator: (v) =>
                                      v == null ? 'Selecciona el aula solicitada' : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Card: Fecha y Horario
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.calendar_month_outlined,
                                        size: 20, color: Color(0xFF0B2F4F)),
                                    SizedBox(width: 8),
                                    Text(
                                      'Fecha y Horario',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                // Selector de Fecha
                                InkWell(
                                  onTap: _seleccionarFecha,
                                  borderRadius: BorderRadius.circular(10),
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: 'Fecha de Uso *',
                                      prefixIcon: const Icon(Icons.event),
                                      suffixIcon: const Icon(Icons.arrow_drop_down),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 14),
                                    ),
                                    child: Text(
                                      _formatearFecha(_fecha),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Horas Inicio y Fin
                                Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: _seleccionarHoraInicio,
                                        borderRadius: BorderRadius.circular(10),
                                        child: InputDecorator(
                                          decoration: InputDecoration(
                                            labelText: 'Hora Inicio *',
                                            prefixIcon: const Icon(Icons.access_time),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 12),
                                          ),
                                          child: Text(
                                            _formatearHora(_horaInicio),
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: InkWell(
                                        onTap: _seleccionarHoraFin,
                                        borderRadius: BorderRadius.circular(10),
                                        child: InputDecorator(
                                          decoration: InputDecoration(
                                            labelText: 'Hora Fin *',
                                            prefixIcon: const Icon(Icons.access_time_filled),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 12),
                                          ),
                                          child: Text(
                                            _formatearHora(_horaFin),
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Card: Motivo y Justificación
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.edit_note_outlined,
                                        size: 20, color: Color(0xFF0B2F4F)),
                                    SizedBox(width: 8),
                                    Text(
                                      'Motivo y Justificación',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Sugerencias rápidas de motivos
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: _motivosSugeridos.map((m) {
                                    return ActionChip(
                                      label: Text(m, style: const TextStyle(fontSize: 11)),
                                      backgroundColor: const Color(0xFFF1F5F9),
                                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                                      onPressed: () {
                                        setState(() => _motivoCtrl.text = m);
                                      },
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 10),

                                // Campo Motivo
                                TextFormField(
                                  controller: _motivoCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'Motivo de la solicitud *',
                                    hintText: 'Ej. Aplicación de examen parcial presencial',
                                    prefixIcon: const Icon(Icons.help_outline),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().length < 3) {
                                      return 'Ingresa un motivo de al menos 3 caracteres';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),

                                // Campo Justificación (opcional)
                                TextFormField(
                                  controller: _justificacionCtrl,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    labelText: 'Justificación detallada (Opcional)',
                                    hintText:
                                        'Detalles adicionales para la aprobación del administrador...',
                                    alignLabelWithHint: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Botón Enviar Solicitud
                        ElevatedButton(
                          onPressed: _enviando ? null : _enviarSolicitud,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0B2F4F),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: _enviando
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.send_rounded, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Enviar Solicitud',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
    );
  }
}
