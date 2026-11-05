<?php
/** Lista de docentes (para asignar carga académica). Solo admin. */
require_once __DIR__ . '/helpers.php';
api_boot();
exigir_metodo('GET');
exigir_admin();

$st = db()->query("
    SELECT u.id_usuario AS id, u.nombre, u.email, u.matricula 
    FROM usuarios u 
    JOIN roles r ON u.id_rol = r.id_rol 
    WHERE r.nombre = 'docente' AND u.activo = 1 
    ORDER BY u.nombre
");
json_ok(['docentes' => $st->fetchAll()]);
