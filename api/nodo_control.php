<?php
/**
 * API para control remoto administrativo (Abrir/Cerrar puerta manualmente)
 * Recibe: { "id_aula": N, "accion": "abrir" | "cerrar" }
 */
require_once __DIR__ . '/helpers.php';
api_boot();
exigir_metodo('POST');
exigir_login(); // El admin debe estar logueado (sesión)

$in = leer_json();

try {
    $idAula = v_entero($in['id_aula'] ?? null, 'id_aula', ['min' => 1]);
    $accion = $in['accion'] ?? '';
    if (!in_array($accion, ['abrir', 'cerrar'])) {
        throw new ValidacionException("Acción inválida. Use 'abrir' o 'cerrar'.");
    }
} catch (ValidacionException $e) {
    json_error($e->getMessage(), 422);
}

$pdo = db();

// Verificar que el usuario tenga rol de admin o mantenimiento
$rol = $_SESSION['usuario']['rol'] ?? '';
if ($rol !== 'admin' && $rol !== 'mantenimiento') {
    json_error('No tienes permisos para control remoto.', 403);
}

// Determinar el nuevo estado
$nuevoEstadoAula = ($accion === 'abrir') ? 'ocupada' : 'libre';
$detalleAcceso = ($accion === 'abrir') ? 'Apertura remota por administrador' : 'Cierre remoto por administrador';

try {
    $pdo->beginTransaction();

    // Actualizar estado del aula
    $stmt = $pdo->prepare('UPDATE aulas SET estado = ? WHERE id_aula = ?');
    $stmt->execute([$nuevoEstadoAula, $idAula]);
    
    // Registrar el acceso en la bitácora
    $stmt = $pdo->prepare('INSERT INTO accesos (id_usuario, id_aula, tipo_acceso, resultado, detalle) VALUES (?, ?, ?, ?, ?)');
    $stmt->execute([$_SESSION['usuario']['id'], $idAula, 'remoto', 'exitoso', $detalleAcceso]);

    $pdo->commit();
    
    json_ok(['mensaje' => 'Control remoto ejecutado con éxito.']);
} catch (Exception $e) {
    $pdo->rollBack();
    json_error('Error al ejecutar control remoto: ' . $e->getMessage(), 500);
}
