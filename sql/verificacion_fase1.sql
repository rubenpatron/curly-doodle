-- ============================================================
--  FASE 1 — Verificación de la base de datos AulaSync
--  Ejecutar después de schema.sql:
--    mysql -u root -p aulas_inteligentes < verificacion_fase1.sql
--  Cada consulta produce evidencia para las actividades 1.1 y 1.2.
-- ============================================================

USE aulas_inteligentes;

-- 1) Inventario de tablas (rúbrica: mínimo 5 tablas relacionadas)
SELECT TABLE_NAME AS tabla, TABLE_ROWS AS filas_aprox
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = DATABASE() AND TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

-- 2) Total de tablas y columnas
SELECT COUNT(*) AS total_tablas FROM information_schema.TABLES
WHERE TABLE_SCHEMA = DATABASE() AND TABLE_TYPE = 'BASE TABLE';

SELECT COUNT(*) AS total_columnas FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE();

-- 3) Claves primarias (PK) por tabla
SELECT TABLE_NAME AS tabla, COLUMN_NAME AS columna_pk
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = DATABASE() AND CONSTRAINT_NAME = 'PRIMARY'
ORDER BY TABLE_NAME, ORDINAL_POSITION;

-- 4) Claves foráneas (FK) con su tabla/columna destino
SELECT k.TABLE_NAME       AS tabla_origen,
       k.COLUMN_NAME      AS columna_fk,
       k.REFERENCED_TABLE_NAME  AS tabla_destino,
       k.REFERENCED_COLUMN_NAME AS columna_destino,
       r.DELETE_RULE      AS al_borrar,
       r.UPDATE_RULE      AS al_actualizar
FROM information_schema.KEY_COLUMN_USAGE k
JOIN information_schema.REFERENTIAL_CONSTRAINTS r
  ON r.CONSTRAINT_SCHEMA = k.CONSTRAINT_SCHEMA
 AND r.CONSTRAINT_NAME   = k.CONSTRAINT_NAME
WHERE k.TABLE_SCHEMA = DATABASE() AND k.REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY k.TABLE_NAME, k.ORDINAL_POSITION;

-- 5) Total de FK (rúbrica: relaciones PK/FK)
SELECT COUNT(*) AS total_fk
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = DATABASE() AND REFERENCED_TABLE_NAME IS NOT NULL;

-- 6) Roles del sistema (rúbrica 1.2: Admin y Usuario)
SELECT id_rol, nombre, descripcion FROM roles ORDER BY id_rol;

-- 7) Usuarios de prueba y su rol
SELECT u.id_usuario, u.email, u.nombre, u.matricula, r.nombre AS rol, u.activo
FROM usuarios u
JOIN roles r ON r.id_rol = u.id_rol
ORDER BY u.id_usuario;

-- 8) Conteo de usuarios por rol
SELECT r.nombre AS rol, COUNT(*) AS usuarios
FROM usuarios u JOIN roles r ON r.id_rol = u.id_rol
GROUP BY r.nombre;

-- 9) Datos iniciales precargados
SELECT 'edificios' AS entidad, COUNT(*) AS registros FROM edificios
UNION ALL SELECT 'aulas', COUNT(*) FROM aulas
UNION ALL SELECT 'materias', COUNT(*) FROM materias
UNION ALL SELECT 'usuarios', COUNT(*) FROM usuarios
UNION ALL SELECT 'carga_academica', COUNT(*) FROM carga_academica;

-- 10) Restricciones CHECK registradas (validación estricta de datos)
SELECT CONSTRAINT_NAME, CHECK_CLAUSE
FROM information_schema.CHECK_CONSTRAINTS
WHERE CONSTRAINT_SCHEMA = DATABASE()
ORDER BY CONSTRAINT_NAME;
