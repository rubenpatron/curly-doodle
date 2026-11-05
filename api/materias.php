<?php
/** Lista de materias (para asignar carga académica). Solo admin. */
require_once __DIR__ . '/helpers.php';
api_boot();
exigir_metodo('GET');
$u = exigir_login();

$st = db()->query('SELECT id_materia AS id, codigo, nombre, departamento FROM materias ORDER BY codigo');
json_ok(['materias' => $st->fetchAll()]);
