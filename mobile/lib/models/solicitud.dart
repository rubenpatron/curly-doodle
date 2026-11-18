class Solicitud {
  final int id;
  final String tipo;
  final String? aulaOriginal;
  final String aulaSolicitada;
  final String materia;
  final String fecha;
  final String horaInicio;
  final String horaFin;
  final String motivo;
  final String? justificacion;
  final String estado;
  final String? comentariosAdmin;
  final String? fechaSolicitud;

  Solicitud({
    required this.id,
    required this.tipo,
    this.aulaOriginal,
    required this.aulaSolicitada,
    required this.materia,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    required this.motivo,
    this.justificacion,
    required this.estado,
    this.comentariosAdmin,
    this.fechaSolicitud,
  });

  factory Solicitud.fromJson(Map<String, dynamic> json) {
    return Solicitud(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      tipo: json['tipo'] ?? 'aula_adicional',
      aulaOriginal: json['aula_original'],
      aulaSolicitada: json['aula_solicitada'] ?? '',
      materia: json['materia'] ?? '',
      fecha: json['fecha'] ?? '',
      horaInicio: json['hora_inicio'] ?? '',
      horaFin: json['hora_fin'] ?? '',
      motivo: json['motivo'] ?? '',
      justificacion: json['justificacion'],
      estado: json['estado'] ?? 'pendiente',
      comentariosAdmin: json['comentarios_admin'],
      fechaSolicitud: json['fecha_solicitud'],
    );
  }
}
