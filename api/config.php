<?php
/**
 * Configuración central del sistema de Aulas Inteligentes.
 * Conexión a MariaDB (servidor independiente, NO el MySQL de XAMPP).
 */

// ---------------------------------------------------------------------------
//  Base de datos MariaDB
// ---------------------------------------------------------------------------
// El prefijo del DSN "mysql:" es solo el nombre del driver pdo_mysql de PHP,
// que es el driver oficial y compatible para conectarse a MariaDB.
define('DB_HOST', '127.0.0.1');
define('DB_PORT', '3306');
define('DB_NAME', 'aulas_inteligentes');
define('DB_USER', 'root');
define('DB_PASS', '');
define('DB_CHARSET', 'utf8mb4');

// ---------------------------------------------------------------------------
//  Login con Google (Google Identity Services)
// ---------------------------------------------------------------------------
// Coloca aquí el Client ID de tu proyecto de Google Cloud cuando lo tengas.
// Mientras esté vacío, el sistema funciona con el "modo demo" de acceso.
define('GOOGLE_CLIENT_ID', '120379547172-1lgn56iv3uhd4r6124u6r3ik8bimpc3o.apps.googleusercontent.com');

// ---------------------------------------------------------------------------
//  OTP (código para abrir la puerta)
// ---------------------------------------------------------------------------
define('OTP_LONGITUD', 6);       // dígitos
define('OTP_VIGENCIA_MIN', 5);   // minutos de validez
define('OTP_TOLERANCIA_MIN', 15); // minutos de tolerancia antes/después de la clase

// ---------------------------------------------------------------------------
//  Zona horaria
// ---------------------------------------------------------------------------
date_default_timezone_set('America/Mexico_City');
