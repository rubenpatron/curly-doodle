import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/usuario.dart';
import '../models/clase_horario.dart';
import '../models/solicitud.dart';
import '../models/aula.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Usuario? _usuarioActual;
  Usuario? get usuarioActual => _usuarioActual;

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('aulasync_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Inicio de sesión con correo y contraseña (hash bcrypt en servidor)
  Future<Usuario> login(String email, String password) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/auth_login.php');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['ok'] != true) {
      throw Exception(data['error'] ?? 'Error al iniciar sesión');
    }

    final token = data['data']['token'];
    final userJson = data['data']['usuario'];
    final usuario = Usuario.fromJson(userJson, token: token);

    // Guardar en almacenamiento local
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('aulasync_token', token);
    await prefs.setString('aulasync_user', jsonEncode(usuario.toJson()));

    _usuarioActual = usuario;
    return usuario;
  }

  /// Recuperar sesión guardada
  Future<Usuario?> cargarSesionGuardada() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('aulasync_user');
    if (userStr != null) {
      final userMap = jsonDecode(userStr);
      _usuarioActual = Usuario.fromJson(userMap);
      return _usuarioActual;
    }
    return null;
  }

  /// Cierre de sesión
  Future<void> logout() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/logout.php');
      final headers = await _getHeaders();
      await http.post(url, headers: headers);
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('aulasync_token');
    await prefs.remove('aulasync_user');
    _usuarioActual = null;
  }

  /// MÓDULO 1: Carga Académica / Horarios con Caché Offline
  Future<List<ClaseHorario>> getHorario({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/horarios.php');
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 4));

      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['ok'] != true) {
        throw Exception(data['error'] ?? 'Error al cargar horario');
      }

      final List list = data['data']['horario'] ?? [];
      // Persistir en caché local offline
      await prefs.setString('aulasync_cache_horario', jsonEncode(list));
      return list.map((item) => ClaseHorario.fromJson(item)).toList();
    } catch (e) {
      // Si falla la red o el servidor está inaccesible, recurrir a la caché local
      final cachedStr = prefs.getString('aulasync_cache_horario');
      if (cachedStr != null && cachedStr.isNotEmpty) {
        try {
          final List list = jsonDecode(cachedStr);
          return list.map((item) => ClaseHorario.fromJson(item)).toList();
        } catch (_) {}
      }
      throw Exception('Sin conexión al servidor y no hay horarios en caché local.');
    }
  }

  /// MÓDULO 2: Solicitudes de Aulas con Caché Offline
  Future<List<Solicitud>> getSolicitudes({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/solicitudes.php');
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 4));

      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['ok'] != true) {
        throw Exception(data['error'] ?? 'Error al cargar solicitudes');
      }

      final List list = data['data']['solicitudes'] ?? [];
      // Persistir en caché local offline
      await prefs.setString('aulasync_cache_solicitudes', jsonEncode(list));
      return list.map((item) => Solicitud.fromJson(item)).toList();
    } catch (e) {
      // Si falla la red, recuperar del almacenamiento local
      final cachedStr = prefs.getString('aulasync_cache_solicitudes');
      if (cachedStr != null && cachedStr.isNotEmpty) {
        try {
          final List list = jsonDecode(cachedStr);
          return list.map((item) => Solicitud.fromJson(item)).toList();
        } catch (_) {}
      }
      throw Exception('Sin conexión al servidor y no hay solicitudes en caché local.');
    }
  }

  Future<void> crearSolicitud({
    required String tipo,
    required int idMateria,
    required int idAulaSolicitada,
    int? idAulaOriginal,
    required String fecha,
    required String horaInicio,
    required String horaFin,
    required String motivo,
    String? justificacion,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/solicitudes.php');
    final headers = await _getHeaders();
    final body = {
      'tipo': tipo,
      'id_materia': idMateria,
      'id_aula_solicitada': idAulaSolicitada,
      if (idAulaOriginal != null) 'id_aula_original': idAulaOriginal,
      'fecha': fecha,
      'hora_inicio': horaInicio,
      'hora_fin': horaFin,
      'motivo': motivo,
      if (justificacion != null && justificacion.isNotEmpty) 'justificacion': justificacion,
    };

    final response = await http.post(url, headers: headers, body: jsonEncode(body));
    final data = jsonDecode(response.body);
    if (response.statusCode != 200 && response.statusCode != 201 || data['ok'] != true) {
      throw Exception(data['error'] ?? 'Error al registrar solicitud');
    }
  }

  /// MÓDULO 3: Catálogo de Aulas con Caché Offline
  Future<List<Aula>> getAulas() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/aulas.php');
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 4));

      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['ok'] != true) {
        throw Exception(data['error'] ?? 'Error al cargar aulas');
      }

      final List list = data['data']['aulas'] ?? [];
      await prefs.setString('aulasync_cache_aulas', jsonEncode(list));
      return list.map((item) => Aula.fromJson(item)).toList();
    } catch (e) {
      final cachedStr = prefs.getString('aulasync_cache_aulas');
      if (cachedStr != null && cachedStr.isNotEmpty) {
        try {
          final List list = jsonDecode(cachedStr);
          return list.map((item) => Aula.fromJson(item)).toList();
        } catch (_) {}
      }
      throw Exception('Error al cargar aulas: $e');
    }
  }

  /// Catálogo de Materias para Solicitudes con Caché Offline
  Future<List<Map<String, dynamic>>> getMaterias() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/materias.php');
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 4));

      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['ok'] != true) {
        throw Exception(data['error'] ?? 'Error al cargar materias');
      }

      final List list = data['data']['materias'] ?? [];
      await prefs.setString('aulasync_cache_materias', jsonEncode(list));
      return list.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (_) {
      final cachedStr = prefs.getString('aulasync_cache_materias');
      if (cachedStr != null && cachedStr.isNotEmpty) {
        try {
          final List list = jsonDecode(cachedStr);
          return list.map((item) => Map<String, dynamic>.from(item)).toList();
        } catch (_) {}
      }
      // Fallback seguro si la conexión falla y no hay caché
      return [
        {'id': 1, 'codigo': 'CS101', 'nombre': 'Introducción a la Programación'},
        {'id': 2, 'codigo': 'CS202', 'nombre': 'Estructuras de Datos'},
        {'id': 3, 'codigo': 'IS301', 'nombre': 'Ingeniería de Software I'},
        {'id': 4, 'codigo': 'BD401', 'nombre': 'Bases de Datos Avanzadas'},
        {'id': 5, 'codigo': 'NT501', 'nombre': 'Redes y Telecomunicaciones'},
        {'id': 6, 'codigo': 'MA101', 'nombre': 'Cálculo Diferencial'},
      ];
    }
  }

  /// MÓDULO 3: Generación de PIN OTP para abrir cerradura
  Future<Map<String, dynamic>> solicitarOtp(int idAula) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/otp_solicitar.php');
    final headers = await _getHeaders();
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({'id_aula': idAula}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['ok'] != true) {
      throw Exception(data['error'] ?? 'No autorizado para abrir el aula en este horario');
    }

    return data['data']; // Contiene codigo, aula, vigencia_min, expira_en
  }

  /// MÓDULO 3: Simular apertura de cerradura IoT con código
  Future<Map<String, dynamic>> abrirCerradura(int idAula, String codigo) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/cerradura_abrir.php');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id_aula': idAula, 'codigo': codigo}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['ok'] != true) {
      throw Exception(data['error'] ?? 'Código denegado');
    }

    return data['data'];
  }
}
