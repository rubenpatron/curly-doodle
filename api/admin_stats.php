<?php
/** Estadísticas en vivo desde la base de datos. Solo admin. */
require_once __DIR__ . '/helpers.php';
api_boot();
exigir_metodo('GET');
exigir_admin();

$pdo = db();
$stats = [
    'docentes'            => (int) $pdo->query("SELECT COUNT(*) FROM usuarios WHERE id_rol = (SELECT id_rol FROM roles WHERE nombre='docente')")->fetchColumn(),
    'aulas'               => (int) $pdo->query('SELECT COUNT(*) FROM aulas')->fetchColumn(),
    'clases'              => (int) $pdo->query('SELECT COUNT(*) FROM carga_academica WHERE activo=1')->fetchColumn(),
    'solicitudes_pend'    => (int) $pdo->query("SELECT COUNT(*) FROM solicitudes_aulas WHERE estado='pendiente'")->fetchColumn(),
    'accesos_hoy'         => (int) $pdo->query('SELECT COUNT(*) FROM accesos WHERE DATE(fecha_hora)=CURDATE()')->fetchColumn(),
    'accesos_exitosos_hoy'=> (int) $pdo->query("SELECT COUNT(*) FROM accesos WHERE DATE(fecha_hora)=CURDATE() AND resultado='exitoso'")->fetchColumn(),
];
json_ok(['stats' => $stats]);
