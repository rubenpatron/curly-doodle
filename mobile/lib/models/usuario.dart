class Usuario {
  final int id;
  final String email;
  final String nombre;
  final String matricula;
  final String rol;
  final String? foto;
  final String? token;

  Usuario({
    required this.id,
    required this.email,
    required this.nombre,
    required this.matricula,
    required this.rol,
    this.foto,
    this.token,
  });

  factory Usuario.fromJson(Map<String, dynamic> json, {String? token}) {
    return Usuario(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      email: json['email'] ?? '',
      nombre: json['nombre'] ?? '',
      matricula: json['matricula'] ?? '',
      rol: json['rol'] ?? 'usuario',
      foto: json['foto'],
      token: token ?? json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nombre': nombre,
      'matricula': matricula,
      'rol': rol,
      'foto': foto,
      'token': token,
    };
  }
}
