<?php
/**
 * Índice de la API REST de AulaSync.
 * Si alguien consulta directamente /api o /api/, devuelve el directorio de endpoints disponibles.
 */
require_once __DIR__ . '/helpers.php';
api_boot();

json_ok([
    'nombre'      => 'AulaSync API REST',
    'institucion' => 'Universidad Tecnológica Metropolitana (UTM)',
    'materia'     => 'Programación de Redes',
    'profesor'    => 'Dr. Aurelio Mex Mex',
    'estado'      => 'Operativa y conectada a MariaDB',
    'nota'        => 'Para realizar operaciones en Postman, añade el nombre del archivo al final de la URL (ej. /api/auth_login.php o /api/usuarios.php).',
    'endpoints_principales' => [
        'POST /api/auth_login.php'   => 'Iniciar sesión con correo y contraseña (Bcrypt)',
        'POST /api/usuarios.php'     => 'Añadir nuevo usuario con contraseña Bcrypt (201 Created)',
        'GET  /api/usuarios.php'     => 'Listar todos los usuarios',
        'GET  /api/aulas.php'        => 'Catálogo de 30 aulas físicas y estados',
        'POST /api/aulas.php'        => 'Alta de nueva aula física (Admin)',
        'GET  /api/carga_academica.php' => 'Listado de carga académica y horarios',
        'POST /api/carga_academica.php' => 'Asignar horario académico (con validación de colisiones 409)',
        'GET  /api/solicitudes.php'  => 'Bandeja de solicitudes de aulas',
        'POST /api/solicitudes.php'  => 'Registrar solicitud de aula adicional o cambio',
        'POST /api/otp_solicitar.php'=> 'Generar PIN OTP de 6 dígitos con vigencia de 5 minutos',
        'POST /api/cerradura_abrir.php' => 'Apertura de cerradura IoT con PIN OTP y bitácora en BD'
    ]
]);
