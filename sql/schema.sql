-- ============================================================
--  Sistema de Aulas Inteligentes Biométricas — UTM
--  Esquema de base de datos - MariaDB
--  Fuerte validación de tipos de datos (CHECK constraints)
--  Versión 2.2 — FASE 1: roles Admin/Usuario, 13 tablas, 20 FK
--  Ejecutar con: mysql -u root -p < schema.sql
-- ============================================================

CREATE DATABASE IF NOT EXISTS aulas_inteligentes
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE aulas_inteligentes;

-- Orden de borrado respetando llaves foráneas (hijos primero)
DROP TABLE IF EXISTS alertas_seguridad;
DROP TABLE IF EXISTS telemetria;
DROP TABLE IF EXISTS otp_codigos;
DROP TABLE IF EXISTS accesos;
DROP TABLE IF EXISTS solicitudes_aulas;
DROP TABLE IF EXISTS carga_academica;
DROP TABLE IF EXISTS sesiones;
DROP TABLE IF EXISTS nodos_iot;
DROP TABLE IF EXISTS aulas;
DROP TABLE IF EXISTS edificios;
DROP TABLE IF EXISTS materias;
DROP TABLE IF EXISTS usuarios;
DROP TABLE IF EXISTS roles;

-- ============================================================
-- 1. ROLES
-- ============================================================
CREATE TABLE roles (
  id_rol        INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre        VARCHAR(30)  NOT NULL,
  descripcion   VARCHAR(200) NULL,
  creado_en     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_rol),
  UNIQUE KEY uq_roles_nombre (nombre)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Roles iniciales del sistema (rúbrica FASE 1: Admin y Usuario)
INSERT INTO roles (nombre, descripcion) VALUES
  ('admin',         'Administrador: acceso total al dashboard IoT, gestión de usuarios, aprobación de solicitudes y seguridad'),
  ('usuario',       'Usuario estándar (docente/estudiante): consulta su horario, solicita aulas y genera PIN temporal'),
  ('mantenimiento', 'Rol técnico opcional: visualiza nodos IoT, gestiona alertas técnicas y mantenimiento de cerraduras');

-- ============================================================
-- 2. USUARIOS (login con Google + FK a roles)
-- ============================================================
CREATE TABLE usuarios (
  id_usuario    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  google_sub    VARCHAR(64)  NULL,                       -- subject id de Google (numérico como texto)
  email         VARCHAR(150) NOT NULL,
  nombre        VARCHAR(120) NOT NULL,
  matricula     VARCHAR(20)  NULL,                       -- matrícula / no. de empleado
  id_rol        INT UNSIGNED NOT NULL DEFAULT 2,         -- 2 = usuario (rol por defecto)
  password_hash VARCHAR(255) NULL,                       -- Hash seguro con algoritmo bcrypt
  foto_url      VARCHAR(400) NULL,
  activo        TINYINT(1)   NOT NULL DEFAULT 1,
  creado_en     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_usuario),
  UNIQUE KEY uq_usuarios_email      (email),
  UNIQUE KEY uq_usuarios_google_sub (google_sub),
  UNIQUE KEY uq_usuarios_matricula  (matricula),
  KEY idx_usuarios_rol (id_rol),
  CONSTRAINT fk_usuarios_rol    FOREIGN KEY (id_rol) REFERENCES roles(id_rol),
  CONSTRAINT chk_usuarios_email CHECK (email LIKE '%_@_%.__%'),
  CONSTRAINT chk_usuarios_nombre CHECK (nombre NOT REGEXP '[0-9]'),
  CONSTRAINT chk_usuarios_activo CHECK (activo IN (0,1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 3. SESIONES (gestión de sesión OAuth)
-- ============================================================
CREATE TABLE sesiones (
  id_sesion     INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_usuario    INT UNSIGNED NOT NULL,
  token         VARCHAR(255) NOT NULL,
  ip            VARCHAR(45)  NULL,                       -- IPv4 o IPv6
  user_agent    VARCHAR(255) NULL,
  creada_en     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  expira_en     DATETIME     NOT NULL,
  PRIMARY KEY (id_sesion),
  UNIQUE KEY uq_sesiones_token (token),
  KEY idx_sesiones_usuario (id_usuario),
  CONSTRAINT fk_sesiones_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
  CONSTRAINT chk_sesiones_expira CHECK (expira_en > creada_en)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 4. EDIFICIOS
-- ============================================================
CREATE TABLE edificios (
  id_edificio   INT UNSIGNED NOT NULL AUTO_INCREMENT,
  codigo        VARCHAR(10)  NOT NULL,                   -- A, B, C, E, F, etc.
  nombre        VARCHAR(120) NOT NULL,
  descripcion   VARCHAR(255) NULL,
  activo        TINYINT(1)   NOT NULL DEFAULT 1,
  PRIMARY KEY (id_edificio),
  UNIQUE KEY uq_edificios_codigo (codigo),
  CONSTRAINT chk_edificios_activo CHECK (activo IN (0,1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Edificios de la UTM
INSERT INTO edificios (codigo, nombre, descripcion) VALUES
  ('A', 'Edificio A', 'Centro de Información y CSAE'),
  ('B', 'Edificio B', 'Rectoría y Control Escolar'),
  ('C', 'Edificio C', 'Dirección TIC'),
  ('E', 'Edificio E', 'Docencia'),
  ('F', 'Edificio F', 'Laboratorios');

-- ============================================================
-- 5. AULAS (con FK a edificios)
-- ============================================================
CREATE TABLE aulas (
  id_aula       INT UNSIGNED      NOT NULL AUTO_INCREMENT,
  id_edificio   INT UNSIGNED      NOT NULL,
  codigo        VARCHAR(20)       NOT NULL,              -- ej. A-101
  capacidad     SMALLINT UNSIGNED NOT NULL,
  tipo          ENUM('aula','laboratorio','taller','auditorio') NOT NULL DEFAULT 'aula',
  estado        ENUM('disponible','ocupada','mantenimiento')    NOT NULL DEFAULT 'disponible',
  PRIMARY KEY (id_aula),
  UNIQUE KEY uq_aulas_codigo (codigo),
  KEY idx_aulas_edificio (id_edificio),
  CONSTRAINT fk_aulas_edificio FOREIGN KEY (id_edificio) REFERENCES edificios(id_edificio) ON DELETE RESTRICT,
  CONSTRAINT chk_aulas_capacidad CHECK (capacidad > 0 AND capacidad <= 1000)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Aulas de ejemplo por edificio
INSERT INTO aulas (id_edificio, codigo, capacidad, tipo) VALUES
  -- Edificio A
  (1, 'A-101', 40, 'aula'),
  (1, 'A-102', 40, 'aula'),
  (1, 'A-103', 35, 'aula'),
  (1, 'A-104', 30, 'aula'),
  (1, 'A-105', 40, 'aula'),
  (1, 'A-201', 25, 'laboratorio'),
  -- Edificio B
  (2, 'B-101', 45, 'aula'),
  (2, 'B-102', 45, 'aula'),
  (2, 'B-103', 40, 'aula'),
  (2, 'B-104', 35, 'aula'),
  (2, 'B-105', 40, 'aula'),
  (2, 'B-201', 20, 'laboratorio'),
  -- Edificio C
  (3, 'C-101', 50, 'aula'),
  (3, 'C-102', 50, 'aula'),
  (3, 'C-103', 45, 'aula'),
  (3, 'C-104', 40, 'aula'),
  (3, 'C-105', 45, 'aula'),
  (3, 'C-201', 30, 'laboratorio'),
  -- Edificio E
  (4, 'E-101', 35, 'aula'),
  (4, 'E-102', 35, 'aula'),
  (4, 'E-103', 30, 'aula'),
  (4, 'E-104', 30, 'aula'),
  (4, 'E-105', 35, 'aula'),
  (4, 'E-201', 20, 'laboratorio'),
  -- Edificio F
  (5, 'F-101', 40, 'laboratorio'),
  (5, 'F-102', 40, 'laboratorio'),
  (5, 'F-103', 35, 'laboratorio'),
  (5, 'F-104', 35, 'laboratorio'),
  (5, 'F-105', 30, 'laboratorio'),
  (5, 'F-201', 25, 'laboratorio');

-- ============================================================
-- 6. NODOS IoT (cerraduras, sensores por aula)
-- ============================================================
CREATE TABLE nodos_iot (
  id_nodo           INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_aula           INT UNSIGNED NOT NULL,
  mac_address       VARCHAR(17)  NOT NULL,               -- formato AA:BB:CC:DD:EE:FF
  tipo_nodo         ENUM('cerradura','sensor_movimiento','camara') NOT NULL DEFAULT 'cerradura',
  firmware_version  VARCHAR(20)  NULL,                   -- ej. v3.2.1
  estado            ENUM('online','offline','mantenimiento') NOT NULL DEFAULT 'offline',
  bateria_pct       TINYINT UNSIGNED NULL,               -- 0-100, NULL si alimentado por red
  ultimo_ping       DATETIME     NULL,                   -- última señal recibida del nodo
  registrado_en     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_nodo),
  UNIQUE KEY uq_nodos_mac (mac_address),
  KEY idx_nodos_aula (id_aula),
  CONSTRAINT fk_nodos_aula FOREIGN KEY (id_aula) REFERENCES aulas(id_aula),
  CONSTRAINT chk_nodos_mac     CHECK (mac_address REGEXP '^[0-9A-Fa-f]{2}(:[0-9A-Fa-f]{2}){5}$'),
  CONSTRAINT chk_nodos_bateria CHECK (bateria_pct IS NULL OR (bateria_pct >= 0 AND bateria_pct <= 100))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 7. MATERIAS
-- ============================================================
CREATE TABLE materias (
  id_materia    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  codigo        VARCHAR(20)  NOT NULL,
  nombre        VARCHAR(120) NOT NULL,
  departamento  VARCHAR(120) NULL,
  PRIMARY KEY (id_materia),
  UNIQUE KEY uq_materias_codigo (codigo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 8. CARGA ACADÉMICA (horarios precargados)
-- ============================================================
CREATE TABLE carga_academica (
  id_carga_academica INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_usuario         INT UNSIGNED NOT NULL,
  id_materia         INT UNSIGNED NOT NULL,
  id_aula            INT UNSIGNED NOT NULL,
  dia_semana         TINYINT UNSIGNED NOT NULL,            -- 1=Lunes ... 7=Domingo
  hora_inicio        TIME NOT NULL,
  hora_fin           TIME NOT NULL,
  fecha_inicio       DATE NOT NULL,
  fecha_fin          DATE NOT NULL,
  activo             TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (id_carga_academica),
  KEY idx_carga_usuario (id_usuario),
  KEY idx_carga_aula    (id_aula),
  KEY idx_carga_materia (id_materia),
  CONSTRAINT fk_carga_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
  CONSTRAINT fk_carga_materia FOREIGN KEY (id_materia) REFERENCES materias(id_materia),
  CONSTRAINT fk_carga_aula    FOREIGN KEY (id_aula)    REFERENCES aulas(id_aula),
  CONSTRAINT chk_carga_dia    CHECK (dia_semana BETWEEN 1 AND 7),
  CONSTRAINT chk_carga_horas  CHECK (hora_fin > hora_inicio),
  CONSTRAINT chk_carga_fechas CHECK (fecha_fin >= fecha_inicio),
  CONSTRAINT chk_carga_activo CHECK (activo IN (0,1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 9. SOLICITUDES EXCEPCIONALES DE AULAS
-- ============================================================
CREATE TABLE solicitudes_aulas (
  id_solicitud       INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_usuario         INT UNSIGNED NOT NULL,
  tipo               ENUM('aula_adicional','cambio_aula') NOT NULL,
  id_aula_original   INT UNSIGNED NULL,
  id_aula_solicitada INT UNSIGNED NOT NULL,
  id_materia         INT UNSIGNED NOT NULL,
  fecha              DATE NOT NULL,
  hora_inicio        TIME NOT NULL,
  hora_fin           TIME NOT NULL,
  motivo             VARCHAR(200) NOT NULL,
  justificacion      TEXT NULL,
  estado             ENUM('pendiente','aprobada','rechazada','cancelada') NOT NULL DEFAULT 'pendiente',
  id_aprobador       INT UNSIGNED NULL,
  fecha_solicitud    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_respuesta    DATETIME NULL,
  comentarios_admin  TEXT NULL,
  PRIMARY KEY (id_solicitud),
  KEY idx_sol_usuario (id_usuario),
  KEY idx_sol_estado  (estado),
  CONSTRAINT fk_sol_usuario   FOREIGN KEY (id_usuario)         REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
  CONSTRAINT fk_sol_aula_ori  FOREIGN KEY (id_aula_original)   REFERENCES aulas(id_aula),
  CONSTRAINT fk_sol_aula_sol  FOREIGN KEY (id_aula_solicitada) REFERENCES aulas(id_aula),
  CONSTRAINT fk_sol_aprobador FOREIGN KEY (id_aprobador)       REFERENCES usuarios(id_usuario),
  CONSTRAINT fk_sol_materia   FOREIGN KEY (id_materia)         REFERENCES materias(id_materia),
  CONSTRAINT chk_sol_horas    CHECK (hora_fin > hora_inicio)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 10. ACCESOS (bitácora de accesos a aulas)
-- ============================================================
CREATE TABLE accesos (
  id_acceso    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_usuario   INT UNSIGNED NULL,                        -- NULL si fue intento de usuario desconocido
  id_aula      INT UNSIGNED NOT NULL,
  fecha_hora   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  tipo_acceso  ENUM('otp','manual','remoto') NOT NULL,
  resultado    ENUM('exitoso','denegado') NOT NULL,
  detalle      VARCHAR(200) NULL,                        -- ej. "Apertura exitosa por huella índice derecho"
  PRIMARY KEY (id_acceso),
  KEY idx_acc_usuario   (id_usuario),
  KEY idx_acc_aula      (id_aula),
  KEY idx_acc_fecha     (fecha_hora),
  CONSTRAINT fk_acc_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE SET NULL,
  CONSTRAINT fk_acc_aula    FOREIGN KEY (id_aula)    REFERENCES aulas(id_aula)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 11. CÓDIGOS OTP (apertura de puerta por PIN temporal)
-- ============================================================
CREATE TABLE otp_codigos (
  id_otp      INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_usuario  INT UNSIGNED NOT NULL,
  id_aula     INT UNSIGNED NOT NULL,
  codigo      CHAR(6)      NOT NULL,
  creado_en   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  expira_en   DATETIME     NOT NULL,
  usado       TINYINT(1)   NOT NULL DEFAULT 0,
  usado_en    DATETIME     NULL,
  PRIMARY KEY (id_otp),
  KEY idx_otp_usuario (id_usuario),
  KEY idx_otp_aula    (id_aula),
  UNIQUE KEY uq_otp_activo (id_aula, codigo, usado),
  CONSTRAINT fk_otp_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
  CONSTRAINT fk_otp_aula    FOREIGN KEY (id_aula)    REFERENCES aulas(id_aula),
  CONSTRAINT chk_otp_codigo CHECK (codigo REGEXP '^[0-9]{6}$'),
  CONSTRAINT chk_otp_usado  CHECK (usado IN (0,1)),
  CONSTRAINT chk_otp_expira CHECK (expira_en > creado_en)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 12. TELEMETRÍA (eventos IoT en tiempo real)
-- ============================================================
CREATE TABLE telemetria (
  id_telemetria INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_nodo       INT UNSIGNED NOT NULL,
  tipo_evento   ENUM('apertura','cierre','bateria_baja','desconexion','reconexion','fallo_auth','ping') NOT NULL,
  valor         VARCHAR(255) NULL,                       -- dato adicional, ej. "78%" o "huella no reconocida"
  fecha_hora    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_telemetria),
  KEY idx_tele_nodo  (id_nodo),
  KEY idx_tele_fecha (fecha_hora),
  CONSTRAINT fk_tele_nodo FOREIGN KEY (id_nodo) REFERENCES nodos_iot(id_nodo) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 13. ALERTAS DE SEGURIDAD
-- ============================================================
CREATE TABLE alertas_seguridad (
  id_alerta     INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_nodo       INT UNSIGNED NULL,                       -- NULL si no está vinculada a un nodo específico
  id_usuario    INT UNSIGNED NULL,                       -- usuario que provocó la alerta (si aplica)
  tipo_alerta   ENUM('acceso_no_autorizado','nodo_offline','bateria_critica','multiples_fallos','manipulacion_fisica') NOT NULL,
  severidad     ENUM('baja','media','alta','critica') NOT NULL DEFAULT 'media',
  descripcion   VARCHAR(255) NOT NULL,
  estado        ENUM('activa','resuelta','ignorada') NOT NULL DEFAULT 'activa',
  resuelta_por  INT UNSIGNED NULL,                       -- admin que resolvió la alerta
  creada_en     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  resuelta_en   DATETIME     NULL,
  PRIMARY KEY (id_alerta),
  KEY idx_alerta_nodo    (id_nodo),
  KEY idx_alerta_estado  (estado),
  KEY idx_alerta_fecha   (creada_en),
  CONSTRAINT fk_alerta_nodo     FOREIGN KEY (id_nodo)      REFERENCES nodos_iot(id_nodo) ON DELETE SET NULL,
  CONSTRAINT fk_alerta_usuario  FOREIGN KEY (id_usuario)   REFERENCES usuarios(id_usuario) ON DELETE SET NULL,
  CONSTRAINT fk_alerta_resuelve FOREIGN KEY (resuelta_por) REFERENCES usuarios(id_usuario) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- DATOS DE PRUEBA INICIALES (Usuarios, Materias, Nodos, Carga, Solicitudes, etc.)
-- ============================================================
INSERT INTO materias (codigo, nombre, departamento) VALUES
  ('CS101', 'Introducción a la Programación', 'Ciencias de la Computación'),
  ('CS202', 'Estructuras de Datos', 'Ciencias de la Computación'),
  ('IS301', 'Ingeniería de Software I', 'Sistemas de Información'),
  ('BD401', 'Bases de Datos Avanzadas', 'Sistemas de Información'),
  ('NT501', 'Redes y Telecomunicaciones', 'Tecnología'),
  ('MA101', 'Cálculo Diferencial', 'Matemáticas');

-- Usuarios de prueba: el rol se toma de la tabla roles (1=admin, 2=usuario).
-- El acceso puede ser con Google Identity Services o mediante credenciales locales con hash bcrypt.
-- Contraseñas de prueba: 'admin123' para roles admin, 'usuario123' para roles usuario, 'docente123' para docentes.
INSERT INTO usuarios (google_sub, email, nombre, matricula, id_rol, password_hash, activo) VALUES
  (NULL, 'nicevalrock@gmail.com', 'Edgar Patron Salazar', 'EMP-2024-0417', 2, '$2y$12$Bf6lduBb5ft77e8U4sLdse7U7aFvK2O26K6FmP1dGyv8lC6YQjY7K', 1),
  (NULL, 'erpatron72@gmail.com',  'Edgar Patron',         'ADM-2024-0001', 1, '$2y$12$lRrJwFH56xHNM7k5uP5PteZ9e7XqX7R8pG1dK6dGyv8lC6YQjY7K', 1),
  ('test-doc-1', 'juan.perez@universidad.edu', 'Dr. Juan Pérez', 'D-1001', 2, '$2y$12$Un/KrZs2DieCj8M5N7K8zeZ9e7XqX7R8pG1dK6dGyv8lC6YQjY7K', 1),
  ('test-doc-2', 'maria.gomez@universidad.edu', 'Mtra. María Gómez', 'D-1002', 2, '$2y$12$Un/KrZs2DieCj8M5N7K8zeZ9e7XqX7R8pG1dK6dGyv8lC6YQjY7K', 1),
  ('test-doc-3', 'carlos.ruiz@universidad.edu', 'Ing. Carlos Ruiz', 'D-1003', 2, '$2y$12$Un/KrZs2DieCj8M5N7K8zeZ9e7XqX7R8pG1dK6dGyv8lC6YQjY7K', 1),
  -- Cuentas canónicas para demostrar los dos roles de la rúbrica
  ('test-admin-1', 'admin@universidad.edu',   'Administrador de Prueba', 'ADM-0001', 1, '$2y$12$lRrJwFH56xHNM7k5uP5PteZ9e7XqX7R8pG1dK6dGyv8lC6YQjY7K', 1),
  ('test-user-1',  'usuario@universidad.edu', 'Usuario de Prueba',       'USR-0001', 2, '$2y$12$Bf6lduBb5ft77e8U4sLdse7U7aFvK2O26K6FmP1dGyv8lC6YQjY7K', 1);

-- Nodos IoT (Cerraduras electrónicas para todas las aulas)
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

-- Estados de aulas
UPDATE aulas SET estado = 'ocupada' WHERE id_aula IN (2, 7);
UPDATE aulas SET estado = 'mantenimiento' WHERE id_aula = 29;

-- Telemetría de eventos IoT
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

-- Alertas de seguridad
INSERT INTO alertas_seguridad (id_nodo, id_usuario, tipo_alerta, severidad, descripcion, estado, resuelta_por, creada_en, resuelta_en) VALUES
  (5, NULL, 'bateria_critica', 'media', 'Nivel de batería bajo (18%) en cerradura de Aula A-105', 'activa', NULL, NOW() - INTERVAL 45 MINUTE, NULL),
  (6, NULL, 'nodo_offline',    'alta',  'Cerradura de Laboratorio A-201 no responde (offline)',   'activa', NULL, NOW() - INTERVAL 90 MINUTE, NULL),
  (4, 7,    'multiples_fallos','baja',  '3 intentos fallidos de OTP registrados en Aula A-104',   'resuelta', 2, NOW() - INTERVAL 3 HOUR, NOW() - INTERVAL 2 HOUR);

-- Accesos históricos
INSERT INTO accesos (id_usuario, id_aula, fecha_hora, tipo_acceso, resultado, detalle) VALUES
  (1, 1, NOW() - INTERVAL 25 MINUTE, 'otp',    'exitoso',  'Apertura exitosa con código OTP'),
  (3, 3, NOW() - INTERVAL 40 MINUTE, 'otp',    'exitoso',  'Apertura exitosa con código OTP'),
  (4, 4, NOW() - INTERVAL 1 HOUR,     'otp',    'exitoso',  'Apertura exitosa con código OTP'),
  (2, 2, NOW() - INTERVAL 2 HOUR,     'remoto', 'exitoso',  'Apertura remota por administrador'),
  (5, 5, NOW() - INTERVAL 3 HOUR,     'otp',    'denegado', 'Código OTP expirado'),
  (7, 2, NOW() - INTERVAL 4 HOUR,     'otp',    'exitoso',  'Apertura exitosa con código OTP'),
  (1, 1, NOW() - INTERVAL 5 HOUR,     'manual', 'exitoso',  'Cierre manual de pestillo'),
  (NULL, 6, NOW() - INTERVAL 6 HOUR,  'otp',    'denegado', 'Código no válido para esta cerradura');

-- Solicitudes de aulas
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

-- Carga académica (Horarios consistentes para demostración en vivo)
INSERT INTO carga_academica (id_usuario, id_materia, id_aula, dia_semana, hora_inicio, hora_fin, fecha_inicio, fecha_fin, activo) VALUES
  -- Edgar Patron Salazar (id 1)
  (1, 1, 1, 1, '07:00:00', '23:59:00', '2026-01-01', '2026-12-31', 1),
  (1, 1, 1, 2, '07:00:00', '23:59:00', '2026-01-01', '2026-12-31', 1),
  (1, 1, 1, 3, '07:00:00', '23:59:00', '2026-01-01', '2026-12-31', 1),
  (1, 1, 1, 4, '07:00:00', '23:59:00', '2026-01-01', '2026-12-31', 1),
  (1, 1, 1, 5, '07:00:00', '23:59:00', '2026-01-01', '2026-12-31', 1),

  -- Dr. Juan Pérez (id 3)
  (3, 3, 3, 1, '07:00:00', '23:59:00', '2026-01-01', '2026-12-31', 1),
  (3, 3, 3, 2, '08:00:00', '12:00:00', '2026-01-01', '2026-12-31', 1),
  (3, 1, 3, 3, '07:00:00', '23:59:00', '2026-01-01', '2026-12-31', 1),
  (3, 1, 3, 4, '08:00:00', '12:00:00', '2026-01-01', '2026-12-31', 1),
  (3, 3, 3, 5, '07:00:00', '23:59:00', '2026-01-01', '2026-12-31', 1),

  -- Mtra. María Gómez (id 4)
  (4, 2, 4, 1, '07:00:00', '23:59:00', '2026-01-01', '2026-12-31', 1),
  (4, 2, 4, 2, '09:00:00', '13:00:00', '2026-01-01', '2026-12-31', 1),
  (4, 4, 4, 3, '07:00:00', '23:59:00', '2026-01-01', '2026-12-31', 1),
  (4, 2, 4, 4, '09:00:00', '13:00:00', '2026-01-01', '2026-12-31', 1),
  (4, 4, 4, 5, '07:00:00', '23:59:00', '2026-01-01', '2026-12-31', 1),

  -- Ing. Carlos Ruiz (id 5)
  (5, 5, 5, 1, '07:00:00', '23:59:00', '2026-01-01', '2026-12-31', 1),
  (5, 5, 5, 2, '10:00:00', '14:00:00', '2026-01-01', '2026-12-31', 1),
  (5, 5, 5, 3, '07:00:00', '23:59:00', '2026-01-01', '2026-12-31', 1),
  (5, 5, 5, 4, '10:00:00', '14:00:00', '2026-01-01', '2026-12-31', 1),
  (5, 5, 5, 5, '07:00:00', '23:59:00', '2026-01-01', '2026-12-31', 1),

  -- Usuario canónico de prueba (id 7)
  (7, 4, 2, 1, '07:00:00', '23:59:00', '2026-01-01', '2026-12-31', 1),
  (7, 4, 2, 2, '07:00:00', '23:59:00', '2026-01-01', '2026-12-31', 1),
  (7, 4, 2, 3, '07:00:00', '23:59:00', '2026-01-01', '2026-12-31', 1),
  (7, 4, 2, 4, '07:00:00', '23:59:00', '2026-01-01', '2026-12-31', 1),
  (7, 4, 2, 5, '07:00:00', '23:59:00', '2026-01-01', '2026-12-31', 1);


