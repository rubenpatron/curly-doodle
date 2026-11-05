-- ============================================================
--  Sistema de Aulas Inteligentes Biométricas — UTM
--  Esquema de base de datos - MariaDB
--  Fuerte validación de tipos de datos (CHECK constraints)
--  Versión 2.1 — Llaves primarias descriptivas (id_rol, id_usuario, etc.)
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

-- Roles iniciales del sistema
INSERT INTO roles (nombre, descripcion) VALUES
  ('admin',         'Acceso total: dashboard IoT, gestión de usuarios, aprobación de solicitudes, seguridad'),
  ('docente',       'Portal docente: agendar aulas, generar PIN temporal, consultar historial propio'),
  ('mantenimiento', 'Visualizar estado de nodos IoT, gestionar alertas técnicas y mantenimiento de cerraduras');

-- ============================================================
-- 2. USUARIOS (login con Google + FK a roles)
-- ============================================================
CREATE TABLE usuarios (
  id_usuario    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  google_sub    VARCHAR(64)  NULL,                       -- subject id de Google (numérico como texto)
  email         VARCHAR(150) NOT NULL,
  nombre        VARCHAR(120) NOT NULL,
  matricula     VARCHAR(20)  NULL,                       -- matrícula / no. de empleado
  id_rol        INT UNSIGNED NOT NULL DEFAULT 2,         -- 2 = docente por defecto
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
-- DATOS DE PRUEBA INICIALES (Docentes, Materias y Carga Académica)
-- ============================================================
INSERT INTO materias (codigo, nombre, departamento) VALUES
  ('CS101', 'Introducción a la Programación', 'Ciencias de la Computación'),
  ('CS202', 'Estructuras de Datos', 'Ciencias de la Computación'),
  ('IS301', 'Ingeniería de Software I', 'Sistemas de Información'),
  ('BD401', 'Bases de Datos Avanzadas', 'Sistemas de Información'),
  ('NT501', 'Redes y Telecomunicaciones', 'Tecnología'),
  ('MA101', 'Cálculo Diferencial', 'Matemáticas');

INSERT INTO usuarios (google_sub, email, nombre, matricula, id_rol, activo) VALUES
  (NULL, 'nicevalrock@gmail.com', 'Edgar Patron Salazar', 'EMP-2024-0417', 2, 1),
  (NULL, 'erpatron72@gmail.com',  'Edgar Patron',         'ADM-2024-0001', 1, 1),
  ('test-doc-1', 'juan.perez@universidad.edu', 'Dr. Juan Pérez', 'D-1001', 2, 1),
  ('test-doc-2', 'maria.gomez@universidad.edu', 'Mtra. María Gómez', 'D-1002', 2, 1),
  ('test-doc-3', 'carlos.ruiz@universidad.edu', 'Ing. Carlos Ruiz', 'D-1003', 2, 1);

INSERT INTO carga_academica (id_usuario, id_materia, id_aula, dia_semana, hora_inicio, hora_fin, fecha_inicio, fecha_fin, activo) VALUES
  (1, 1, 1, WEEKDAY(CURDATE()) + 1, '07:00:00', '23:59:00', '2026-01-01', '2026-12-31', 1),
  (1, 4, 2, 1, '08:00:00', '10:00:00', '2026-01-01', '2026-12-31', 1),
  (1, 5, 1, 2, '09:00:00', '10:00:00', '2026-01-01', '2026-12-31', 1),
  (1, 3, 3, 3, '10:00:00', '12:00:00', '2026-01-01', '2026-12-31', 1),
  (1, 6, 2, 4, '09:00:00', '10:00:00', '2026-01-01', '2026-12-31', 1),
  (1, 2, 3, 5, '09:00:00', '10:00:00', '2026-01-01', '2026-12-31', 1),
  (2, 4, 1, WEEKDAY(CURDATE()) + 1, '07:00:00', '23:59:00', '2026-01-01', '2026-12-31', 1),
  (2, 5, 1, 2, '09:00:00', '10:00:00', '2026-01-01', '2026-12-31', 1),
  (2, 6, 2, 4, '09:00:00', '10:00:00', '2026-01-01', '2026-12-31', 1),
  (2, 2, 3, 5, '09:00:00', '10:00:00', '2026-01-01', '2026-12-31', 1),
  (3, 1, 3, 2, '08:00:00', '10:00:00', '2026-01-01', '2026-12-31', 1),
  (4, 2, 4, 4, '09:00:00', '11:00:00', '2026-01-01', '2026-12-31', 1),
  (5, 5, 5, 1, '11:00:00', '13:00:00', '2026-01-01', '2026-12-31', 1);


