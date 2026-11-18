-- ============================================================
--  AulaSync — Datos de Prueba Consistentes para Sesión 3
--  Ejecución en MariaDB
-- ============================================================

USE aulas_inteligentes;

-- 1. NODOS IoT (Cerraduras para las 30 aulas)
-- Evitamos duplicados limpiando o insertando con ON DUPLICATE KEY UPDATE
DELETE FROM telemetria;
DELETE FROM alertas_seguridad;
DELETE FROM nodos_iot;

INSERT INTO nodos_iot (id_nodo, id_aula, mac_address, tipo_nodo, firmware_version, estado, bateria_pct, ultimo_ping) VALUES
  -- Edificio A
  (1,  1, '3C:71:BF:11:01:01', 'cerradura', 'v3.2.1', 'online',  95, NOW() - INTERVAL 1 MINUTE),
  (2,  2, '3C:71:BF:11:01:02', 'cerradura', 'v3.2.1', 'online',  88, NOW() - INTERVAL 3 MINUTE),
  (3,  3, '3C:71:BF:11:01:03', 'cerradura', 'v3.2.1', 'online',  92, NOW() - INTERVAL 2 MINUTE),
  (4,  4, '3C:71:BF:11:01:04', 'cerradura', 'v3.2.1', 'online',  74, NOW() - INTERVAL 5 MINUTE),
  (5,  5, '3C:71:BF:11:01:05', 'cerradura', 'v3.2.0', 'online',  18, NOW() - INTERVAL 8 MINUTE),
  (6,  6, '3C:71:BF:11:02:01', 'cerradura', 'v3.1.9', 'offline',  5, NOW() - INTERVAL 90 MINUTE),
  -- Edificio B
  (7,  7, '3C:71:BF:22:01:01', 'cerradura', 'v3.2.1', 'online',  82, NOW() - INTERVAL 2 MINUTE),
  (8,  8, '3C:71:BF:22:01:02', 'cerradura', 'v3.2.1', 'online',  90, NOW() - INTERVAL 4 MINUTE),
  (9,  9, '3C:71:BF:22:01:03', 'cerradura', 'v3.2.1', 'online',  85, NOW() - INTERVAL 1 MINUTE),
  (10, 10, '3C:71:BF:22:01:04', 'cerradura', 'v3.2.1', 'online', 78, NOW() - INTERVAL 6 MINUTE),
  (11, 11, '3C:71:BF:22:01:05', 'cerradura', 'v3.2.1', 'online', 65, NOW() - INTERVAL 3 MINUTE),
  (12, 12, '3C:71:BF:22:02:01', 'cerradura', 'v3.2.1', 'online', 91, NOW() - INTERVAL 2 MINUTE),
  -- Edificio C
  (13, 13, '3C:71:BF:33:01:01', 'cerradura', 'v3.2.1', 'online', 94, NOW() - INTERVAL 1 MINUTE),
  (14, 14, '3C:71:BF:33:01:02', 'cerradura', 'v3.2.1', 'online', 89, NOW() - INTERVAL 4 MINUTE),
  (15, 15, '3C:71:BF:33:01:03', 'cerradura', 'v3.2.1', 'online', 87, NOW() - INTERVAL 2 MINUTE),
  (16, 16, '3C:71:BF:33:01:04', 'cerradura', 'v3.2.1', 'online', 72, NOW() - INTERVAL 5 MINUTE),
  (17, 17, '3C:71:BF:33:01:05', 'cerradura', 'v3.2.1', 'online', 80, NOW() - INTERVAL 3 MINUTE),
  (18, 18, '3C:71:BF:33:02:01', 'cerradura', 'v3.2.1', 'online', 84, NOW() - INTERVAL 2 MINUTE),
  -- Edificio E
  (19, 19, '3C:71:BF:44:01:01', 'cerradura', 'v3.2.1', 'online', 96, NOW() - INTERVAL 1 MINUTE),
  (20, 20, '3C:71:BF:44:01:02', 'cerradura', 'v3.2.1', 'online', 93, NOW() - INTERVAL 3 MINUTE),
  (21, 21, '3C:71:BF:44:01:03', 'cerradura', 'v3.2.1', 'online', 88, NOW() - INTERVAL 2 MINUTE),
  (22, 22, '3C:71:BF:44:01:04', 'cerradura', 'v3.2.1', 'online', 79, NOW() - INTERVAL 4 MINUTE),
  (23, 23, '3C:71:BF:44:01:05', 'cerradura', 'v3.2.1', 'online', 85, NOW() - INTERVAL 3 MINUTE),
  (24, 24, '3C:71:BF:44:02:01', 'cerradura', 'v3.2.1', 'online', 90, NOW() - INTERVAL 2 MINUTE),
  -- Edificio F
  (25, 25, '3C:71:BF:55:01:01', 'cerradura', 'v3.2.1', 'online', 92, NOW() - INTERVAL 1 MINUTE),
  (26, 26, '3C:71:BF:55:01:02', 'cerradura', 'v3.2.1', 'online', 86, NOW() - INTERVAL 3 MINUTE),
  (27, 27, '3C:71:BF:55:01:03', 'cerradura', 'v3.2.1', 'online', 81, NOW() - INTERVAL 2 MINUTE),
  (28, 28, '3C:71:BF:55:01:04', 'cerradura', 'v3.2.1', 'online', 75, NOW() - INTERVAL 4 MINUTE),
  (29, 29, '3C:71:BF:55:01:05', 'cerradura', 'v3.2.0', 'mantenimiento', 40, NOW() - INTERVAL 20 MINUTE),
  (30, 30, '3C:71:BF:55:02:01', 'cerradura', 'v3.2.1', 'online', 94, NOW() - INTERVAL 2 MINUTE);

-- 2. ESTADOS DE AULAS (Consistencia con estados operativos)
UPDATE aulas SET estado = 'disponible';
UPDATE aulas SET estado = 'ocupada' WHERE id_aula IN (2, 7);
UPDATE aulas SET estado = 'mantenimiento' WHERE id_aula = 29; -- F-105

-- 3. TELEMETRÍA (Bitácora de eventos IoT recientes)
INSERT INTO telemetria (id_nodo, tipo_evento, valor, fecha_hora) VALUES
  (1,  'apertura',     'Apertura por PIN temporal (Docente)',         NOW() - INTERVAL 15 MINUTE),
  (1,  'cierre',       'Puerta asegurada correctamente',              NOW() - INTERVAL 10 MINUTE),
  (2,  'apertura',     'Apertura remota por administrador',           NOW() - INTERVAL 8 MINUTE),
  (3,  'ping',         'Heartbeat OK - Batería 92%',                  NOW() - INTERVAL 2 MINUTE),
  (5,  'bateria_baja', 'Nivel de batería: 18%',                       NOW() - INTERVAL 35 MINUTE),
  (6,  'desconexion',  'Cerradura fuera de línea (sin ping)',         NOW() - INTERVAL 90 MINUTE),
  (7,  'apertura',     'Apertura por PIN temporal (Docente)',         NOW() - INTERVAL 5 MINUTE),
  (8,  'ping',         'Heartbeat OK - Batería 90%',                  NOW() - INTERVAL 4 MINUTE),
  (13, 'ping',         'Heartbeat OK - Batería 94%',                  NOW() - INTERVAL 1 MINUTE),
  (4,  'fallo_auth',   'Intento fallido: PIN incorrecto en teclado',  NOW() - INTERVAL 50 MINUTE),
  (29, 'reconexion',   'Nodo en modo diagnóstico técnico',            NOW() - INTERVAL 25 MINUTE);

-- 4. ALERTAS DE SEGURIDAD
INSERT INTO alertas_seguridad (id_nodo, id_usuario, tipo_alerta, severidad, descripcion, estado, resuelta_por, creada_en, resuelta_en) VALUES
  (5, NULL, 'bateria_critica', 'media', 'Nivel de batería bajo (18%) en cerradura de Aula A-105', 'activa', NULL, NOW() - INTERVAL 45 MINUTE, NULL),
  (6, NULL, 'nodo_offline',    'alta',  'Cerradura de Laboratorio A-201 no responde (offline)',   'activa', NULL, NOW() - INTERVAL 90 MINUTE, NULL),
  (4, 7,    'multiples_fallos','baja',  '3 intentos fallidos de OTP registrados en Aula A-104',   'resuelta', 2, NOW() - INTERVAL 3 HOUR, NOW() - INTERVAL 2 HOUR);

-- 5. ACCESOS (Historial de accesos a aulas)
DELETE FROM accesos;
INSERT INTO accesos (id_usuario, id_aula, fecha_hora, tipo_acceso, resultado, detalle) VALUES
  (1, 1, NOW() - INTERVAL 25 MINUTE, 'otp',    'exitoso',  'Apertura exitosa con código OTP'),
  (3, 3, NOW() - INTERVAL 40 MINUTE, 'otp',    'exitoso',  'Apertura exitosa con código OTP'),
  (4, 4, NOW() - INTERVAL 1 HOUR,     'otp',    'exitoso',  'Apertura exitosa con código OTP'),
  (2, 2, NOW() - INTERVAL 2 HOUR,     'remoto', 'exitoso',  'Apertura remota por administrador'),
  (5, 5, NOW() - INTERVAL 3 HOUR,     'otp',    'denegado', 'Código OTP expirado'),
  (7, 2, NOW() - INTERVAL 4 HOUR,     'otp',    'exitoso',  'Apertura exitosa con código OTP'),
  (1, 1, NOW() - INTERVAL 5 HOUR,     'manual', 'exitoso',  'Cierre manual de pestillo'),
  (NULL, 6, NOW() - INTERVAL 6 HOUR,  'otp',    'denegado', 'Código no válido para esta cerradura');

-- 6. SOLICITUDES DE AULAS (Para módulo de gestión de solicitudes)
DELETE FROM solicitudes_aulas;
INSERT INTO solicitudes_aulas (id_usuario, tipo, id_aula_original, id_aula_solicitada, id_materia, fecha, hora_inicio, hora_fin, motivo, justificacion, estado, id_aprobador, fecha_solicitud, fecha_respuesta, comentarios_admin) VALUES
  (3, 'aula_adicional', NULL, 6, 1, CURDATE(), '16:00:00', '18:00:00',
   'Práctica extraordinaria de programación',
   'Se requiere el Laboratorio A-201 para realizar la evaluación práctica de estructuras de datos con el grupo de Sistemas.',
   'pendiente', NULL, NOW() - INTERVAL 2 HOUR, NULL, NULL),

  (4, 'aula_adicional', NULL, 7, 2, CURDATE(), '07:00:00', '23:59:00',
   'Seminario de investigación aplicada',
   'Capacidad extendida requerida para 45 alumnos en sesión conjunta intermodular.',
   'aprobada', 2, NOW() - INTERVAL 1 DAY, NOW() - INTERVAL 10 HOUR,
   'Aprobado. Aula B-101 reservada y vinculada a permisos OTP del docente.'),

  (5, 'cambio_aula', 5, 25, 5, CURDATE() + INTERVAL 2 DAY, '10:00:00', '12:00:00',
   'Cambio por práctica de cableado de telecomunicaciones',
   'Solicito traslado al Laboratorio F-101 por disponibilidad de racks y equipo de medición.',
   'rechazada', 2, NOW() - INTERVAL 1 DAY, NOW() - INTERVAL 8 HOUR,
   'Rechazado temporalmente: el Laboratorio F-101 estará en mantenimiento preventivo esa fecha.');

-- 7. CARGA ACADÉMICA (Horarios consistentes para demostración en vivo)
-- Aseguramos que los docentes principales y el usuario de prueba tengan
-- carga activa en la fecha actual (CURDATE()) de 07:00 a 23:59 para que
-- la generación de OTP y apertura de cerradura funcione en vivo ante el docente.

DELETE FROM carga_academica;

-- Edgar Patron Salazar (id 1)
INSERT INTO carga_academica (id_usuario, id_materia, id_aula, dia_semana, hora_inicio, hora_fin, fecha_inicio, fecha_fin, activo) VALUES
  (1, 1, 1, 1, '07:00:00', '23:59:00', '2026-01-01', '2026-12-31', 1), -- Lunes (activo hoy)
  (1, 1, 1, 2, '07:00:00', '23:59:00', '2026-01-01', '2026-12-31', 1), -- Martes
  (1, 1, 1, 3, '07:00:00', '23:59:00', '2026-01-01', '2026-12-31', 1), -- Miércoles
  (1, 1, 1, 4, '07:00:00', '23:59:00', '2026-01-01', '2026-12-31', 1), -- Jueves
  (1, 1, 1, 5, '07:00:00', '23:59:00', '2026-01-01', '2026-12-31', 1); -- Viernes

-- Dr. Juan Pérez (id 3)
INSERT INTO carga_academica (id_usuario, id_materia, id_aula, dia_semana, hora_inicio, hora_fin, fecha_inicio, fecha_fin, activo) VALUES
  (3, 3, 3, 1, '07:00:00', '23:59:00', '2026-01-01', '2026-12-31', 1), -- A-103
  (3, 3, 3, 2, '08:00:00', '12:00:00', '2026-01-01', '2026-12-31', 1),
  (3, 1, 3, 3, '07:00:00', '23:59:00', '2026-01-01', '2026-12-31', 1),
  (3, 1, 3, 4, '08:00:00', '12:00:00', '2026-01-01', '2026-12-31', 1),
  (3, 3, 3, 5, '07:00:00', '23:59:00', '2026-01-01', '2026-12-31', 1);

-- Mtra. María Gómez (id 4)
INSERT INTO carga_academica (id_usuario, id_materia, id_aula, dia_semana, hora_inicio, hora_fin, fecha_inicio, fecha_fin, activo) VALUES
  (4, 2, 4, 1, '07:00:00', '23:59:00', '2026-01-01', '2026-12-31', 1), -- A-104
  (4, 2, 4, 2, '09:00:00', '13:00:00', '2026-01-01', '2026-12-31', 1),
  (4, 4, 4, 3, '07:00:00', '23:59:00', '2026-01-01', '2026-12-31', 1),
  (4, 2, 4, 4, '09:00:00', '13:00:00', '2026-01-01', '2026-12-31', 1),
  (4, 4, 4, 5, '07:00:00', '23:59:00', '2026-01-01', '2026-12-31', 1);

-- Ing. Carlos Ruiz (id 5)
INSERT INTO carga_academica (id_usuario, id_materia, id_aula, dia_semana, hora_inicio, hora_fin, fecha_inicio, fecha_fin, activo) VALUES
  (5, 5, 5, 1, '07:00:00', '23:59:00', '2026-01-01', '2026-12-31', 1), -- A-105
  (5, 5, 5, 2, '10:00:00', '14:00:00', '2026-01-01', '2026-12-31', 1),
  (5, 5, 5, 3, '07:00:00', '23:59:00', '2026-01-01', '2026-12-31', 1),
  (5, 5, 5, 4, '10:00:00', '14:00:00', '2026-01-01', '2026-12-31', 1),
  (5, 5, 5, 5, '07:00:00', '23:59:00', '2026-01-01', '2026-12-31', 1);

-- Usuario canónico de prueba: usuario@universidad.edu (id 7)
INSERT INTO carga_academica (id_usuario, id_materia, id_aula, dia_semana, hora_inicio, hora_fin, fecha_inicio, fecha_fin, activo) VALUES
  (7, 4, 2, 1, '07:00:00', '23:59:00', '2026-01-01', '2026-12-31', 1), -- A-102 activo hoy
  (7, 4, 2, 2, '07:00:00', '23:59:00', '2026-01-01', '2026-12-31', 1),
  (7, 4, 2, 3, '07:00:00', '23:59:00', '2026-01-01', '2026-12-31', 1),
  (7, 4, 2, 4, '07:00:00', '23:59:00', '2026-01-01', '2026-12-31', 1),
  (7, 4, 2, 5, '07:00:00', '23:59:00', '2026-01-01', '2026-12-31', 1);
