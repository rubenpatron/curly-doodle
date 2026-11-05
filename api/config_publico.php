<?php
/**
 * Configuración pública que el frontend necesita (sin secretos).
 * Permite tener el Client ID de Google en un solo lugar: api/config.php
 */
require_once __DIR__ . '/helpers.php';
api_boot();
exigir_metodo('GET');

json_ok([
    'google_client_id' => GOOGLE_CLIENT_ID,
]);
