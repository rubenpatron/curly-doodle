class Aula {
  final int id;
  final String codigo;
  final int capacidad;
  final String tipo;
  final String estadoAula;
  final String? estadoNodo;
  final int? bateriaPct;
  final String edificio;

  Aula({
    required this.id,
    required this.codigo,
    required this.capacidad,
    required this.tipo,
    required this.estadoAula,
    this.estadoNodo,
    this.bateriaPct,
    required this.edificio,
  });

  factory Aula.fromJson(Map<String, dynamic> json) {
    return Aula(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      codigo: json['codigo'] ?? '',
      capacidad: json['capacidad'] is int ? json['capacidad'] : int.tryParse(json['capacidad']?.toString() ?? '30') ?? 30,
      tipo: json['tipo'] ?? 'aula',
      estadoAula: json['estado_aula'] ?? 'disponible',
      estadoNodo: json['estado_nodo'],
      bateriaPct: json['bateria_pct'] is int ? json['bateria_pct'] : int.tryParse(json['bateria_pct']?.toString() ?? '100'),
      edificio: json['edificio'] ?? '',
    );
  }
}
