import 'package:flutter/material.dart';
import '../models/aula.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/aulasync_widgets.dart';

class NuevaSolicitudScreen extends StatefulWidget {
  const NuevaSolicitudScreen({super.key});

  @override
  State<NuevaSolicitudScreen> createState() => _NuevaSolicitudScreenState();
}

class _NuevaSolicitudScreenState extends State<NuevaSolicitudScreen> {
  final _formKey = GlobalKey<FormState>();

  String _tipo = 'aula_adicional';
  int? _idMateria;
  int? _idAulaSolicitada;
  int? _idAulaOriginal;

  DateTime _fecha = DateTime.now();
  TimeOfDay _horaInicio = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _horaFin = const TimeOfDay(hour: 11, minute: 0);

  final _motivoCtrl = TextEditingController();
  final _justificacionCtrl = TextEditingController();

  bool _cargandoCatalogos = true;
  bool _enviando = false;
  String? _errorCatalogos;

  List<Map<String, dynamic>> _materias = [];
  List<Aula> _aulas = [];

  final List<String> _motivosSugeridos = const [
    'Examen Parcial',
    'Práctica de Laboratorio',
    'Evaluación Final',
    'Asesoría Grupal',
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

  String _formatearFechaCorta(DateTime dt) {
    const meses = [
      '',
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic'
    ];
    return '${dt.day} ${meses[dt.month]}';
  }

  String _formatearHora(TimeOfDay t) {
    final hour = t.hour.toString().padLeft(2, '0');
    final minute = t.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  bool _esHoraFinPosterior(TimeOfDay inicio, TimeOfDay fin) =>
      (fin.hour * 60 + fin.minute) > (inicio.hour * 60 + inicio.minute);

  Future<void> _seleccionarFecha() async {
    final ahora = DateTime.now();
    final seleccionada = await showDatePicker(
      context: context,
      initialDate: _fecha.isBefore(ahora) ? ahora : _fecha,
      firstDate: ahora.subtract(const Duration(days: 1)),
      lastDate: ahora.add(const Duration(days: 180)),
    );
    if (seleccionada != null && mounted) {
      setState(() => _fecha = seleccionada);
    }
  }

  Future<void> _seleccionarHoraInicio() async {
    final seleccionada = await showTimePicker(
      context: context,
      initialTime: _horaInicio,
    );
    if (seleccionada != null && mounted) {
      setState(() {
        _horaInicio = seleccionada;
        if (!_esHoraFinPosterior(_horaInicio, _horaFin)) {
          final h = (_horaInicio.hour + 2).clamp(0, 23);
          _horaFin = TimeOfDay(hour: h, minute: _horaInicio.minute);
        }
      });
    }
  }

  Future<void> _seleccionarHoraFin() async {
    final seleccionada = await showTimePicker(
      context: context,
      initialTime: _horaFin,
    );
    if (seleccionada != null && mounted) {
      if (!_esHoraFinPosterior(_horaInicio, seleccionada)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La hora de fin debe ser posterior a la de inicio.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      setState(() => _horaFin = seleccionada);
    }
  }

  Future<void> _enviarSolicitud() async {
    if (!_formKey.currentState!.validate()) return;
    if (_idMateria == null || _idAulaSolicitada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona materia y aula solicitada.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_tipo == 'cambio_aula' && _idAulaOriginal == _idAulaSolicitada) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El aula solicitada debe diferir de la original.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (!_esHoraFinPosterior(_horaInicio, _horaFin)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La hora de fin debe ser posterior a la de inicio.'),
          backgroundColor: AppColors.error,
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
          content: Text('Solicitud enviada correctamente.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: AppShadows.card,
                          ),
                          child: const Icon(Icons.arrow_back_rounded,
                              size: 18, color: AppColors.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Nueva Solicitud',
                        style: AppTheme.displayFont(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _cargandoCatalogos
                      ? const SkeletonListPlaceholder(count: 3, itemHeight: 90)
                      : _errorCatalogos != null
                          ? ErrorStateView(
                              message: _errorCatalogos!,
                              onRetry: _cargarCatalogos,
                            )
                          : _buildFormBody(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Segmented toggle estilo Figma 04
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppShadows.card,
              ),
              child: Row(
                children: [
                  _SegmentButton(
                    label: 'Aula Adicional',
                    selected: _tipo == 'aula_adicional',
                    onTap: () => setState(() => _tipo = 'aula_adicional'),
                  ),
                  _SegmentButton(
                    label: 'Cambio de Aula',
                    selected: _tipo == 'cambio_aula',
                    onTap: () => setState(() => _tipo = 'cambio_aula'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Tarjeta blanca agrupada estilo Figma 04
            AulaSyncCard(
              radius: 24,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('Materia Académica'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    initialValue: _idMateria,
                    isExpanded: true,
                    decoration: const InputDecoration(),
                    items: _materias
                        .map((m) => DropdownMenuItem<int>(
                              value: m['id'] as int,
                              child: Text(
                                '${m['codigo'] ?? ''} · ${m['nombre'] ?? ''}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _idMateria = v),
                  ),
                  const SizedBox(height: 14),
                  if (_tipo == 'cambio_aula') ...[
                    _FieldLabel('Aula Original'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      initialValue: _idAulaOriginal,
                      isExpanded: true,
                      decoration: const InputDecoration(),
                      items: _aulas
                          .map((a) => DropdownMenuItem<int>(
                                value: a.id,
                                child: Text(
                                  'Aula ${a.codigo} · ${a.edificio}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                ),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _idAulaOriginal = v),
                    ),
                    const SizedBox(height: 14),
                  ],
                  _FieldLabel('Aula Solicitada'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    initialValue: _idAulaSolicitada,
                    isExpanded: true,
                    decoration: const InputDecoration(),
                    items: _aulas
                        .map((a) => DropdownMenuItem<int>(
                              value: a.id,
                              child: Text(
                                'Aula ${a.codigo} · ${a.edificio} (Cap: ${a.capacidad})',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _idAulaSolicitada = v),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _PickerTile(
                          label: 'Fecha',
                          value: _formatearFechaCorta(_fecha),
                          onTap: _seleccionarFecha,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _PickerTile(
                          label: 'Inicio',
                          value: _formatearHora(_horaInicio),
                          onTap: _seleccionarHoraInicio,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _PickerTile(
                          label: 'Fin',
                          value: _formatearHora(_horaFin),
                          onTap: _seleccionarHoraFin,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _FieldLabel('Motivo de Solicitud'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _motivoCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Ej. Evaluación Final Presencial 4A-IRD',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Ingresa el motivo'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _motivosSugeridos
                        .map((m) => ActionChip(
                              label: Text(m, style: const TextStyle(fontSize: 11)),
                              backgroundColor: AppColors.surfaceMuted,
                              side: BorderSide.none,
                              onPressed: () =>
                                  setState(() => _motivoCtrl.text = m),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            AulaSyncGradientButton(
              label: 'Enviar Solicitud',
              loading: _enviando,
              onPressed: _enviarSolicitud,
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.navy : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: selected ? Colors.white : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _PickerTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
