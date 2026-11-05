<?php
/**
 * GET  -> lista solicitudes (docente ve las suyas; admin ve todas, filtro ?estado=)
 * POST -> crea una solicitud (cambio de aula o aula adicional)
 */
require_once __DIR__ . '/helpers.php';
api_boot();

$u = exigir_login();
$metodo = $_SERVER['REQUEST_METHOD'] ?? 'GET';
$pdo = db();

if ($metodo === 'GET') {
    $base = 'SELECT s.id_solicitud AS id, s.*, us.nombre AS docente, m.nombre AS materia,
                    ao.codigo AS aula_original, asol.codigo AS aula_solicitada
             FROM solicitudes_aulas s
             JOIN usuarios us ON us.id_usuario = s.id_usuario
             JOIN materias m  ON m.id_materia = s.id_materia
             LEFT JOIN aulas ao   ON ao.id_aula = s.id_aula_original
             JOIN aulas asol      ON asol.id_aula = s.id_aula_solicitada';
    $cond = [];
    $args = [];

    if ($u['rol'] !== 'admin') {
        $cond[] = 's.id_usuario = ?';
        $args[] = $u['id'];
    }
    if (isset($_GET['estado'])) {
        try {
            $estado = v_enum($_GET['estado'], 'estado', ['pendiente', 'aprobada', 'rechazada', 'cancelada']);
        } catch (ValidacionException $e) {
            json_error($e->getMessage(), 422);
        }
        $cond[] = 's.estado = ?';
        $args[] = $estado;
    }
    if ($cond) {
        $base .= ' WHERE ' . implode(' AND ', $cond);
    }
    $base .= ' ORDER BY s.fecha_solicitud DESC';

    $st = $pdo->prepare($base);
    $st->execute($args);
    $filas = $st->fetchAll();
    foreach ($filas as &$f) {
        $f['hora_inicio'] = substr($f['hora_inicio'], 0, 5);
        $f['hora_fin']    = substr($f['hora_fin'], 0, 5);
    }
    unset($f);
    json_ok(['solicitudes' => $filas]);
}

if ($metodo === 'POST') {
    $in = leer_json();
    try {
        $tipo = v_enum($in['tipo'] ?? null, 'tipo', ['aula_adicional', 'cambio_aula']);
        if (empty($in['id_materia'])) {
            throw new ValidacionException("Debes seleccionar una materia para poder hacer la solicitud. Si no tienes materias, contacta a la administración.");
        }
        $idMateria = v_entero($in['id_materia'], 'id_materia', ['min' => 1]);
        $idAulaSolicitada = v_entero($in['id_aula_solicitada'] ?? null, 'id_aula_solicitada', ['min' => 1]);

        $idAulaOriginal = null;
        if ($tipo === 'cambio_aula') {
            $idAulaOriginal = v_entero($in['id_aula_original'] ?? null, 'id_aula_original', ['min' => 1]);
        }

        $fecha       = v_fecha($in['fecha'] ?? null, 'fecha');
        $horaInicio  = v_hora($in['hora_inicio'] ?? null, 'hora_inicio');
        $horaFin     = v_hora($in['hora_fin'] ?? null, 'hora_fin');
        
        $motivo = v_texto($in['motivo'] ?? null, 'motivo', ['min' => 3, 'max' => 500]);
        $justificacion = isset($in['justificacion']) && $in['justificacion'] !== ''
            ? v_texto($in['justificacion'], 'justificacion', ['min' => 3, 'max' => 2000])
            : null;
    } catch (ValidacionException $e) {
        json_error($e->getMessage(), 422);
    }

    // Verifica que existan
    $chkMateria = $pdo->prepare('SELECT COUNT(*) FROM materias WHERE id_materia = ?');
    $chkMateria->execute([$idMateria]);
    if (!$chkMateria->fetchColumn()) {
        json_error('La materia no existe.', 404);
    }

    $chk = $pdo->prepare('SELECT COUNT(*) FROM aulas WHERE id_aula = ?');
    $chk->execute([$idAulaSolicitada]);
    if (!$chk->fetchColumn()) {
        json_error('El aula solicitada no existe.', 404);
    }
    if ($idAulaOriginal !== null) {
        $chk->execute([$idAulaOriginal]);
        if (!$chk->fetchColumn()) {
            json_error('El aula original no existe.', 404);
        }
    }

    $ins = $pdo->prepare(
        'INSERT INTO solicitudes_aulas
            (id_usuario, tipo, id_materia, id_aula_original, id_aula_solicitada, fecha, hora_inicio, hora_fin, motivo, justificacion)
         VALUES (?,?,?,?,?,?,?,?,?,?)'
    );
    $ins->execute([$u['id'], $tipo, $idMateria, $idAulaOriginal, $idAulaSolicitada, $fecha, $horaInicio, $horaFin, $motivo, $justificacion]);

    json_ok(['id' => (int) $pdo->lastInsertId(), 'mensaje' => 'Solicitud enviada correctamente.'], 201);
}

json_error('Método no permitido.', 405);
