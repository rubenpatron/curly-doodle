import 'package:flutter_test/flutter_test.dart';
import 'package:aulasync_mobile/models/clase_horario.dart';
import 'package:aulasync_mobile/models/usuario.dart';
import 'package:aulasync_mobile/screens/home_screen.dart';
import 'package:aulasync_mobile/screens/horarios_tab.dart';
import 'package:flutter/material.dart';

void main() {
  group('ClaseHorario Model Test', () {
    test('Parsea correctamente JSON de horario académico', () {
      final json = {
        'id': 10,
        'dia_semana': 1,
        'dia_nombre': 'Lunes',
        'hora_inicio': '07:00:00',
        'hora_fin': '09:00:00',
        'fecha_inicio': '2026-01-15',
        'fecha_fin': '2026-06-30',
        'materia': 'Sistemas Embebidos',
        'materia_codigo': 'SE101',
        'id_aula': 5,
        'aula': 'A-101',
        'edificio': 'A',
        'capacidad': 35,
      };

      final clase = ClaseHorario.fromJson(json);

      expect(clase.id, 10);
      expect(clase.diaSemana, 1);
      expect(clase.diaNombre, 'Lunes');
      expect(clase.horaInicio, '07:00:00');
      expect(clase.horaFin, '09:00:00');
      expect(clase.materia, 'Sistemas Embebidos');
      expect(clase.materiaCodigo, 'SE101');
      expect(clase.aula, 'A-101');
      expect(clase.edificio, 'A');
      expect(clase.capacidad, 35);
    });
  });

  group('HomeScreen and HorariosTab Widget Tests', () {
    testWidgets('HorariosTab se inicializa y muestra estructura de búsqueda', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HorariosTab(),
          ),
        ),
      );

      // Verificamos presencia de elementos de filtro
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Buscar materia, aula o edificio...'), findsOneWidget);
      expect(find.text('Todos'), findsOneWidget);
      expect(find.text('Lun'), findsOneWidget);
    });

    testWidgets('HomeScreen se inicializa con 4 destinos de navegación', (tester) async {
      final testUser = Usuario(
        id: 1,
        email: 'docente@universidad.edu',
        nombre: 'Profesor de Prueba',
        matricula: 'DOC-1234',
        rol: 'docente',
        token: 'token_prueba',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(usuario: testUser),
        ),
      );

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Horarios'), findsOneWidget);
      expect(find.text('Solicitudes'), findsOneWidget);
      expect(find.text('Apertura OTP'), findsOneWidget);
      expect(find.text('Perfil'), findsOneWidget);
    });
  });
}
