<?php
/** Devuelve el usuario de la sesión actual. */
require_once __DIR__ . '/helpers.php';
api_boot();
exigir_metodo('GET');

$u = usuario_actual();
if (!$u) {
    json_ok(['autenticado' => false]);
}
json_ok(['autenticado' => true, 'usuario' => $u]);
