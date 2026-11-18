<?php
/**
 * Inicio de sesión mediante credenciales locales (correo y contraseña).
 * Valida contraseñas almacenadas de forma segura con algoritmo bcrypt (password_verify).
 * Cumple con el criterio 7 de Seguridad y Administración de Usuarios.
 */
require_once __DIR__ . '/helpers.php';
api_boot();
exigir_metodo('POST');

$in = leer_json();

try {
    $email = v_email($in['email'] ?? '', 'email');
    $password = v_texto($in['password'] ?? '', 'password', ['min' => 4, 'max' => 100]);
} catch (ValidacionException $e) {
    json_error($e->getMessage(), 422);
}

$pdo = db();
$st = $pdo->prepare(
    'SELECT u.*, r.nombre AS rol_nombre
     FROM usuarios u
     JOIN roles r ON r.id_rol = u.id_rol
     WHERE u.email = ?
     LIMIT 1'
);
$st->execute([$email]);
$usuario = $st->fetch();

if (!$usuario) {
    json_error('Credenciales incorrectas.', 401);
}

if (!(int)$usuario['activo']) {
    json_error('La cuenta se encuentra desactivada.', 403);
}

// Validación de la contraseña con bcrypt
if (empty($usuario['password_hash']) || !password_verify($password, $usuario['password_hash'])) {
    json_error('Credenciales incorrectas.', 401);
}

// Generación de token de sesión seguro
$token = bin2hex(random_bytes(32));
$expira = date('Y-m-d H:i:s', time() + 86400 * 7); // 7 días
$ip = $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1';
$userAgent = substr($_SERVER['HTTP_USER_AGENT'] ?? 'Desconocido', 0, 255);

$insSesion = $pdo->prepare(
    'INSERT INTO sesiones (id_usuario, token, ip, user_agent, expira_en)
     VALUES (?, ?, ?, ?, ?)'
);
$insSesion->execute([(int)$usuario['id_usuario'], $token, $ip, $userAgent, $expira]);

// Registro en la sesión PHP
$_SESSION['usuario'] = [
    'id'        => (int) $usuario['id_usuario'],
    'id_usuario'=> (int) $usuario['id_usuario'],
    'email'     => $usuario['email'],
    'nombre'    => $usuario['nombre'],
    'matricula' => $usuario['matricula'],
    'rol'       => $usuario['rol_nombre'],
    'foto'      => $usuario['foto_url'],
    'token'     => $token,
];

json_ok([
    'mensaje'     => 'Inicio de sesión exitoso.',
    'token'       => $token,
    'usuario'     => $_SESSION['usuario'],
    'redireccion' => $usuario['rol_nombre'] === 'admin' ? 'dashboard.html' : 'usuario.html',
]);
