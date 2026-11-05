<?php
/**
 * Inicio de sesión.
 *  - Modo Google:  recibe { "credential": "<JWT de Google Identity Services>" }
 *  - Modo demo:    recibe { "demo": "docente" | "admin" }
 *
 * En el prototipo el JWT de Google se decodifica para extraer los datos del
 * perfil. En producción se debería verificar la firma contra las llaves de
 * Google y validar el "aud" contra GOOGLE_CLIENT_ID.
 */
require_once __DIR__ . '/helpers.php';
api_boot();
exigir_metodo('POST');

$in = leer_json();

try {
    if (!empty($in['credential'])) {
        // ---- Modo Google real: decodifica el JWT que devuelve Google -----
        $payload = decodificar_jwt_google((string) $in['credential']);
        $email = v_email($payload['email'] ?? '', 'email');
        $nombre = v_texto($payload['name'] ?? 'Usuario', 'nombre', ['max' => 120]);
        $sub = isset($payload['sub']) ? substr((string) $payload['sub'], 0, 64) : null;
        $foto = isset($payload['picture']) ? substr((string) $payload['picture'], 0, 400) : null;
        $usuario = buscar_o_crear_usuario($email, $sub, $foto, 'docente', $nombre);
    } elseif (!empty($in['perfil']) && is_array($in['perfil'])) {
        // ---- Modo Google simulado: los datos que "devolvería" Google -----
        //      Sirve para dar de alta cuentas sin configurar OAuth todavía.
        $p = $in['perfil'];
        $email  = v_email($p['email'] ?? '', 'email');
        $nombre = v_texto($p['nombre'] ?? '', 'nombre', ['min' => 3, 'max' => 120, 'solo_texto' => true]);
        $foto   = isset($p['foto']) && $p['foto'] !== '' ? substr((string) $p['foto'], 0, 400) : null;
        // Identificador estable simulado (como el 'sub' de Google) derivado del correo.
        $sub = 'sim-' . substr(sha1(strtolower($email)), 0, 16);
        $usuario = buscar_o_crear_usuario($email, $sub, $foto, 'docente', $nombre);
    } else {
        json_error('Falta el credential de Google.', 400);
    }
} catch (ValidacionException $e) {
    json_error($e->getMessage(), 422);
}

if (!$usuario['activo']) {
    json_error('La cuenta está desactivada.', 403);
}

// Guarda la sesión
$_SESSION['usuario'] = [
    'id'        => (int) $usuario['id_usuario'],
    'email'     => $usuario['email'],
    'nombre'    => $usuario['nombre'],
    'matricula' => $usuario['matricula'],
    'rol'       => $usuario['rol'],
    'foto'      => $usuario['foto_url'],
];

json_ok([
    'usuario'     => $_SESSION['usuario'],
    'nuevo'       => $GLOBALS['usuario_recien_creado'] ?? false,
    'redireccion' => $usuario['rol'] === 'admin' ? 'dashboard.html' : 'usuario.html',
]);


// ---------------------------------------------------------------------------
function decodificar_jwt_google(string $jwt): array
{
    $partes = explode('.', $jwt);
    if (count($partes) !== 3) {
        json_error('El token de Google no tiene un formato válido.', 400);
    }
    $json = base64_decode(strtr($partes[1], '-_', '+/'));
    $payload = json_decode($json, true);
    if (!is_array($payload) || empty($payload['email'])) {
        json_error('No se pudo leer el perfil de Google.', 400);
    }
    // Verificación básica opcional del destinatario (aud)
    if (GOOGLE_CLIENT_ID !== '' && ($payload['aud'] ?? '') !== GOOGLE_CLIENT_ID) {
        json_error('El token de Google no corresponde a esta aplicación.', 401);
    }
    return $payload;
}

/**
 * Busca al usuario por email; si no existe lo crea. Si viene de Google y aún
 * no tenía google_sub, lo actualiza.
 */
function buscar_o_crear_usuario(string $email, ?string $sub, ?string $foto, string $rolPorDefecto, ?string $nombre = null): array
{
    $pdo = db();
    $st = $pdo->prepare('
        SELECT u.id_usuario AS id, u.*, r.nombre AS rol 
        FROM usuarios u 
        JOIN roles r ON u.id_rol = r.id_rol 
        WHERE u.email = ?
    ');
    $st->execute([$email]);
    $u = $st->fetch();

    if ($u) {
        $GLOBALS['usuario_recien_creado'] = false;
        // Completa datos de Google si faltaban
        if ($sub && empty($u['google_sub'])) {
            $up = $pdo->prepare('UPDATE usuarios SET google_sub = ?, foto_url = COALESCE(?, foto_url) WHERE id_usuario = ?');
            $up->execute([$sub, $foto, $u['id_usuario']]);
            $u['google_sub'] = $sub;
            if ($foto) $u['foto_url'] = $foto;
        }
        return $u;
    }

    $GLOBALS['usuario_recien_creado'] = true;
    // Crear nuevo usuario (docente por defecto)
    $nombre = $nombre ?: 'Usuario Nuevo';
    
    $stRol = $pdo->prepare('SELECT id_rol FROM roles WHERE nombre = ?');
    $stRol->execute([$rolPorDefecto]);
    $id_rol = $stRol->fetchColumn();
    if (!$id_rol) $id_rol = 2;

    $ins = $pdo->prepare(
        'INSERT INTO usuarios (google_sub, email, nombre, id_rol, foto_url) VALUES (?,?,?,?,?)'
    );
    $ins->execute([$sub, $email, $nombre, $id_rol, $foto]);
    $id = (int) $pdo->lastInsertId();
    
    $st = $pdo->prepare('
        SELECT u.id_usuario AS id, u.*, r.nombre AS rol 
        FROM usuarios u 
        JOIN roles r ON u.id_rol = r.id_rol 
        WHERE u.id_usuario = ?
    ');
    $st->execute([$id]);
    return $st->fetch();
}
