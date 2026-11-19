<?php
/**
 * CRUD de Usuarios:
 * GET: Listar usuarios registrados
 * POST: Registrar nuevo usuario con contraseña cifrada en Bcrypt
 * DELETE: Desactivar o eliminar usuario
 */
require_once __DIR__ . '/helpers.php';
api_boot();

$pdo = db();
$metodo = $_SERVER['REQUEST_METHOD'] ?? 'GET';

// ---------------------------------------------------------------------------
// GET: Listado de usuarios
// ---------------------------------------------------------------------------
if ($metodo === 'GET') {
    $st = $pdo->query(
        "SELECT u.id_usuario, u.nombre, u.email, u.matricula, u.id_rol, r.nombre AS rol, u.activo, u.creado_en
         FROM usuarios u
         JOIN roles r ON r.id_rol = u.id_rol
         ORDER BY u.id_usuario DESC"
    );
    json_ok(['usuarios' => $st->fetchAll()]);
}

// ---------------------------------------------------------------------------
// POST: Registrar nuevo usuario (Añadir usuario con Bcrypt)
// ---------------------------------------------------------------------------
if ($metodo === 'POST') {
    $in = leer_json();

    try {
        $nombre = v_texto($in['nombre'] ?? '', 'nombre', ['min' => 3, 'max' => 120]);
        $email = v_email($in['email'] ?? '', 'email');
        $password = v_texto($in['password'] ?? '', 'password', ['min' => 4, 'max' => 100]);
        $matricula = !empty($in['matricula']) ? trim($in['matricula']) : null;
        $idRol = isset($in['id_rol']) ? (int) $in['id_rol'] : 2; // Por defecto 2: usuario/docente
    } catch (ValidacionException $e) {
        json_error($e->getMessage(), 422);
    }

    if (!in_array($idRol, [1, 2], true)) {
        json_error("El campo 'id_rol' debe ser 1 (admin) o 2 (usuario).", 422);
    }

    // Verificar si el correo ya existe
    $chk = $pdo->prepare("SELECT id_usuario FROM usuarios WHERE email = ? LIMIT 1");
    $chk->execute([$email]);
    if ($chk->fetch()) {
        json_error("El correo institucional '$email' ya se encuentra registrado.", 409);
    }

    // Verificar si la matrícula ya existe
    if ($matricula !== null) {
        $chkMat = $pdo->prepare("SELECT id_usuario FROM usuarios WHERE matricula = ? LIMIT 1");
        $chkMat->execute([$matricula]);
        if ($chkMat->fetch()) {
            json_error("La matrícula '$matricula' ya se encuentra registrada.", 409);
        }
    }

    // Hashear contraseña con Bcrypt
    $passwordHash = password_hash($password, PASSWORD_BCRYPT);

    $ins = $pdo->prepare(
        "INSERT INTO usuarios (nombre, email, password_hash, matricula, id_rol, activo)
         VALUES (?, ?, ?, ?, ?, 1)"
    );
    $ins->execute([$nombre, $email, $passwordHash, $matricula, $idRol]);
    $newId = (int) $pdo->lastInsertId();

    json_ok([
        'mensaje' => 'Usuario registrado exitosamente con contraseña segura (Bcrypt).',
        'usuario' => [
            'id_usuario' => $newId,
            'nombre'     => $nombre,
            'email'      => $email,
            'matricula'  => $matricula,
            'id_rol'     => $idRol,
            'activo'     => 1
        ]
    ], 201);
}

// ---------------------------------------------------------------------------
// DELETE: Desactivar usuario
// ---------------------------------------------------------------------------
if ($metodo === 'DELETE') {
    $id = isset($_GET['id']) ? (int) $_GET['id'] : 0;
    if ($id <= 0) {
        json_error("ID de usuario no proporcionado o inválido.", 422);
    }

    // Prevenir auto-eliminación o eliminar admin #1
    if ($id === 1) {
        json_error("No se puede eliminar el usuario administrador principal.", 403);
    }

    $del = $pdo->prepare("DELETE FROM usuarios WHERE id_usuario = ?");
    $del->execute([$id]);

    json_ok(['mensaje' => "Usuario #$id eliminado correctamente."]);
}

json_error("Método HTTP no soportado.", 405);
