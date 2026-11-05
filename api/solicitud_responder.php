<?php
/**
 * El administrador aprueba o rechaza una solicitud.
 * Recibe: { "id": N, "accion": "aprobar"|"rechazar", "comentarios": "..." }
 */
require_once __DIR__ . '/helpers.php';
api_boot();
exigir_metodo('POST');

$admin = exigir_admin();
$in = leer_json();

try {
    $id      = v_entero($in['id'] ?? null, 'id', ['min' => 1]);
    $accion  = v_enum($in['accion'] ?? null, 'accion', ['aprobar', 'rechazar']);
    $coment  = isset($in['comentarios']) && $in['comentarios'] !== ''
        ? v_texto($in['comentarios'], 'comentarios', ['min' => 1, 'max' => 2000])
        : null;
    if ($accion === 'rechazar' && $coment === null) {
        throw new ValidacionException('Debes indicar el motivo del rechazo en comentarios.');
    }
} catch (ValidacionException $e) {
    json_error($e->getMessage(), 422);
}

$pdo = db();
$st = $pdo->prepare('SELECT * FROM solicitudes_aulas WHERE id_solicitud = ?');
$st->execute([$id]);
$sol = $st->fetch();
if (!$sol) {
    json_error('La solicitud no existe.', 404);
}
if ($sol['estado'] !== 'pendiente') {
    json_error('La solicitud ya fue procesada (estado: ' . $sol['estado'] . ').', 409);
}

$nuevoEstado = $accion === 'aprobar' ? 'aprobada' : 'rechazada';
$pdo->prepare(
    'UPDATE solicitudes_aulas
        SET estado = ?, id_aprobador = ?, fecha_respuesta = NOW(), comentarios_admin = ?
      WHERE id_solicitud = ?'
)->execute([$nuevoEstado, $admin['id'], $coment, $id]);

// Si es cambio de aula aprobado, actualiza la carga académica de esa fecha/hora
if ($accion === 'aprobar' && $sol['tipo'] === 'cambio_aula' && $sol['id_aula_original']) {
    $pdo->prepare(
        'UPDATE carga_academica
            SET id_aula = ?
          WHERE id_usuario = ? AND id_aula = ?
            AND hora_inicio = ? AND hora_fin = ?
            AND dia_semana = DAYOFWEEK(?) - 1'
    )->execute([
        $sol['id_aula_solicitada'], $sol['id_usuario'], $sol['id_aula_original'],
        $sol['hora_inicio'], $sol['hora_fin'], $sol['fecha'],
    ]);
}

json_ok(['estado' => $nuevoEstado, 'mensaje' => 'Solicitud ' . $nuevoEstado . '.']);
