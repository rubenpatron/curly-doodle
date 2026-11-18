class ClaseHorario {
  final int id;
  final int diaSemana;
  final String diaNombre;
  final String horaInicio;
  final String horaFin;
  final String fechaInicio;
  final String fechaFin;
  final String materia;
  final String materiaCodigo;
  final int idAula;
  final String aula;
  final String edificio;
  final int capacidad;

  ClaseHorario({
    required this.id,
    required this.diaSemana,
    required this.diaNombre,
    required this.horaInicio,
    required this.horaFin,
    required this.fechaInicio,
    required this.fechaFin,
    required this.materia,
    required this.materiaCodigo,
    required this.idAula,
    required this.aula,
    required this.edificio,
    required this.capacidad,
  });

  factory ClaseHorario.fromJson(Map<String, dynamic> json) {
    return ClaseHorario(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      diaSemana: json['dia_semana'] is int ? json['dia_semana'] : int.tryParse(json['dia_semana'].toString()) ?? 1,
      diaNombre: json['dia_nombre'] ?? '',
      horaInicio: json['hora_inicio'] ?? '',
      horaFin: json['hora_fin'] ?? '',
      fechaInicio: json['fecha_inicio'] ?? '',
      fechaFin: json['fecha_fin'] ?? '',
      materia: json['materia'] ?? '',
      materiaCodigo: json['materia_codigo'] ?? '',
      idAula: json['id_aula'] is int ? json['id_aula'] : int.tryParse(json['id_aula']?.toString() ?? '0') ?? 0,
      aula: json['aula'] ?? '',
      edificio: json['edificio'] ?? '',
      capacidad: json['capacidad'] is int ? json['capacidad'] : int.tryParse(json['capacidad']?.toString() ?? '30') ?? 30,
    );
  }
}
