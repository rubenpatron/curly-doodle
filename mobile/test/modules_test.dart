import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aulasync_mobile/models/solicitud.dart';
import 'package:aulasync_mobile/models/aula.dart';
import 'package:aulasync_mobile/screens/solicitudes_tab.dart';
import 'package:aulasync_mobile/screens/nueva_solicitud_screen.dart';
import 'package:aulasync_mobile/screens/otp_tab.dart';
import 'package:aulasync_mobile/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Modelos - Módulo 2 y 3', () {
    test('Solicitud.fromJson parsea correctamente', () {
      final json = {
        'id': 10,
        'tipo': 'aula_adicional',
        'aula_solicitada': 'B-101',
        'aula_original': null,
        'materia': 'Ingeniería de Software I',
        'fecha': '2026-11-20',
        'hora_inicio': '10:00',
        'hora_fin': '12:00',
        'motivo': 'Examen Parcial',
        'justificacion': 'Requerimiento de computadoras',
        'estado': 'aprobada',
        'comentarios_admin': 'Aprobado sin problemas',
      };

      final s = Solicitud.fromJson(json);
      expect(s.id, 10);
      expect(s.tipo, 'aula_adicional');
      expect(s.aulaSolicitada, 'B-101');
      expect(s.estado, 'aprobada');
      expect(s.comentariosAdmin, 'Aprobado sin problemas');
    });

    test('Aula.fromJson parsea correctamente', () {
      final json = {
        'id': 5,
        'codigo': 'A-101',
        'capacidad': 35,
        'tipo': 'aula',
        'estado_aula': 'disponible',
        'edificio': 'Edificio A',
        'bateria_pct': 95,
      };

      final a = Aula.fromJson(json);
      expect(a.id, 5);
      expect(a.codigo, 'A-101');
      expect(a.capacidad, 35);
      expect(a.edificio, 'Edificio A');
      expect(a.bateriaPct, 95);
    });
  });

  group('Offline Caching - SharedPreferences', () {
    test('ApiService recupera solicitudes desde caché si servidor no responde', () async {
      SharedPreferences.setMockInitialValues({
        'aulasync_cache_solicitudes': jsonEncode([
          {
            'id': 99,
            'tipo': 'aula_adicional',
            'aula_solicitada': 'C-201',
            'materia': 'Redes',
            'fecha': '2026-11-22',
            'hora_inicio': '08:00',
            'hora_fin': '10:00',
            'motivo': 'Práctica de switches',
            'estado': 'pendiente',
          }
        ]),
      });

      // El mock de baseUrl apunta a localhost inalcanzable para forzar fallback
      final solicitudes = await ApiService().getSolicitudes();
      expect(solicitudes.isNotEmpty, isTrue);
      expect(solicitudes.first.aulaSolicitada, 'C-201');
      expect(solicitudes.first.materia, 'Redes');
    });

    test('ApiService recupera horario desde caché offline', () async {
      SharedPreferences.setMockInitialValues({
        'aulasync_cache_horario': jsonEncode([
          {
            'id': 42,
            'dia_semana': 1,
            'dia_nombre': 'Lunes',
            'hora_inicio': '07:00',
            'hora_fin': '09:00',
            'fecha_inicio': '2026-08-01',
            'fecha_fin': '2026-12-15',
            'materia': 'Bases de Datos',
            'materia_codigo': 'BD401',
            'id_aula': 3,
            'aula': 'A-103',
            'edificio': 'Edificio A',
            'capacidad': 40,
          }
        ]),
      });

      final horarios = await ApiService().getHorario();
      expect(horarios.isNotEmpty, isTrue);
      expect(horarios.first.materia, 'Bases de Datos');
      expect(horarios.first.aula, 'A-103');
    });
  });

  group('Widgets y Componentes Visuales - Módulos 2 y 3', () {
    testWidgets('SolicitudesTab se monta correctamente', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SolicitudesTab(),
          ),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Nueva Solicitud'), findsOneWidget);
    });

    testWidgets('OtpTab se monta con estado animado de cerradura', (tester) async {
      SharedPreferences.setMockInitialValues({
        'aulasync_cache_aulas': jsonEncode([
          {
            'id': 1,
            'codigo': 'A-101',
            'capacidad': 30,
            'tipo': 'aula',
            'estado_aula': 'disponible',
            'edificio': 'Edificio A',
          }
        ]),
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OtpTab(),
          ),
        ),
      );

      // Avanzar unos frames para permitir la renderización inicial
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verificamos que se renderice el componente de estado animado de cerradura
      expect(find.byType(OtpTab), findsOneWidget);
      expect(find.text('Cerradura Asegurada'), findsOneWidget);
    });

    testWidgets('QrMatrixPainter dibuja matriz correctamente sin errores', (tester) async {
      final painter = QrMatrixPainter(
        data: 'A-101:123456',
        isExpired: false,
        isUsed: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: const Size(200, 200),
              painter: painter,
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('NuevaSolicitudScreen se monta correctamente con formulario', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NuevaSolicitudScreen(),
        ),
      );

      expect(find.text('Nueva Solicitud'), findsOneWidget);
    });
  });
}
