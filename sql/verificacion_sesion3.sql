-- ============================================================
--  AulaSync — Script de Verificación para Sesión 3
--  Verifica el estado de MariaDB para los 3 módulos del sistema:
--   Módulo 1: Usuarios y roles con autenticación bcrypt
--   Módulo 2: Aulas con estados operativos y cerraduras IoT
--   Módulo 3: Materias, Carga Académica y Solicitudes
-- ============================================================

USE aulas_inteligentes;

-- 1. Resumen general de tablas y registros
SELECT 
    TABLE_NAME AS tabla, 
    TABLE_ROWS AS filas_estimadas,
    DATA_LENGTH AS bytes_datos,
    AUTO_INCREMENT AS siguiente_id
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = DATABASE() AND TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

-- 2. Módulo 1: Docentes y Usuarios con Bcrypt
SELECT 
    u.id_usuario,
    u.email,
    u.nombre,
    u.matricula,
    r.nombre AS rol,
    LEFT(u.password_hash, 10) AS hash_prefix,
    LENGTH(u.password_hash) AS hash_len,
    u.activo
FROM usuarios u
JOIN roles r ON u.id_rol = r.id_rol
ORDER BY u.id_rol, u.id_usuario;

-- 3. Módulo 2: Aulas, Estados y Cerraduras IoT por Edificio
SELECT 
    e.codigo AS edificio,
    COUNT(a.id_aula) AS total_aulas,
    SUM(CASE WHEN a.estado = 'disponible' THEN 1 ELSE 0 END) AS aulas_disponibles,
    SUM(CASE WHEN a.estado = 'ocupada' THEN 1 ELSE 0 END) AS aulas_ocupadas,
    SUM(CASE WHEN a.estado = 'mantenimiento' THEN 1 ELSE 0 END) AS aulas_mantenimiento,
    COUNT(n.id_nodo) AS total_cerraduras,
    SUM(CASE WHEN n.estado = 'online' THEN 1 ELSE 0 END) AS cerraduras_online,
    SUM(CASE WHEN n.estado = 'offline' THEN 1 ELSE 0 END) AS cerraduras_offline,
    SUM(CASE WHEN n.estado = 'mantenimiento' THEN 1 ELSE 0 END) AS cerraduras_mantenimiento
FROM edificios e
JOIN aulas a ON e.id_edificio = a.id_edificio
LEFT JOIN nodos_iot n ON a.id_aula = n.id_aula AND n.tipo_nodo = 'cerradura'
GROUP BY e.codigo
ORDER BY e.codigo;

-- 4. Módulo 3: Materias y Carga Académica de Hoy
SELECT 
    ca.id_carga_academica,
    u.nombre AS docente,
    u.email,
    m.codigo AS materia_cod,
    m.nombre AS materia,
    a.codigo AS aula,
    ca.dia_semana,
    ca.hora_inicio,
    ca.hora_fin,
    ca.activo
FROM carga_academica ca
JOIN usuarios u ON ca.id_usuario = u.id_usuario
JOIN materias m ON ca.id_materia = m.id_materia
JOIN aulas a ON ca.id_aula = a.id_aula
WHERE ca.dia_semana = WEEKDAY(CURDATE()) + 1 AND ca.activo = 1
ORDER BY a.codigo;

-- 5. Solicitudes de Aulas para demostración en vivo
SELECT 
    s.id_solicitud,
    u.nombre AS docente,
    s.tipo,
    ao.codigo AS aula_original,
    asol.codigo AS aula_solicitada,
    m.nombre AS materia,
    s.fecha,
    s.hora_inicio,
    s.hora_fin,
    s.estado,
    s.motivo
FROM solicitudes_aulas s
JOIN usuarios u ON s.id_usuario = u.id_usuario
JOIN materias m ON s.id_materia = m.id_materia
LEFT JOIN aulas ao ON s.id_aula_original = ao.id_aula
JOIN aulas asol ON s.id_aula_solicitada = asol.id_aula
ORDER BY s.id_solicitud;

-- 6. Bitácora de Accesos y Telemetría reciente
SELECT 
    ac.id_acceso,
    COALESCE(u.nombre, 'Desconocido') AS usuario,
    a.codigo AS aula,
    ac.fecha_hora,
    ac.tipo_acceso,
    ac.resultado,
    ac.detalle
FROM accesos ac
JOIN aulas a ON ac.id_aula = a.id_aula
LEFT JOIN usuarios u ON ac.id_usuario = u.id_usuario
ORDER BY ac.fecha_hora DESC
LIMIT 10;
