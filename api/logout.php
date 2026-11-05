<?php
/** Cierra la sesión actual. */
require_once __DIR__ . '/helpers.php';
api_boot();
exigir_metodo('POST');

$_SESSION = [];
if (ini_get('session.use_cookies')) {
    $p = session_get_cookie_params();
    setcookie(session_name(), '', time() - 42000, $p['path'], $p['domain'], $p['secure'], $p['httponly']);
}
session_destroy();
json_ok(['cerrado' => true]);
