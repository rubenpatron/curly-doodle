<?php
/**
 * Gestión de la carga académica (horarios). Solo admin.
 *   GET    -> lista todas las clases (con joins). Filtro opcional ?id_usuario=
 *   POST   -> crea una clase (valida tipos y detecta conflictos de aula)
 *   DELETE -> elimina una clase (?id=N)
 */
require_once __DIR__ . '/helpers.php';
api_boot();
exigir_admin();

$pdo = db();
$metodo = $_SERVER['REQUEST_METHOD'] ?? 'GET';

$DIAS = [1 => 'Lunes', 2 => 'Martes', 3 => 'Miércoles', 4 => 'Jueves', 5 => 'Viernes', 6 => 'Sábado', 7 => 'Domingo'];

// ---------------------------------------------------------------- GET
if ($metodo === 'GET') {
    $sql = 'SELECT ca.id_carga_academica AS id, ca.dia_semana, ca.hora_inicio, ca.hora_fin, ca.fecha_inicio, ca.fecha_fin, ca.activo,
                   u.id_usuario AS id_usuario, u.nombre AS docente,
                   m.codigo AS materia_codigo, m.nombre AS materia,
                   a.codigo AS aula, e.nombre AS edificio
            FROM carga_academica ca
            JOIN usuarios u ON u.id_usuario = ca.id_usuario
            JOIN materias m ON m.id_materia = ca.id_materia
            JOIN aulas    a ON a.id_aula = ca.id_aula
            JOIN edificios e ON e.id_edificio = a.id_edificio';
    $args = [];
    if (isset($_GET['id_usuario'])) {
        try { $args[] = v_entero($_GET['id_usuario'], 'id_usuario', ['min' => 1]); }
        catch (ValidacionException $e) { json_error($e->getMessage(), 422); }
        $sql .= ' WHERE ca.id_usuario = ?';
    }
    $sql .= ' ORDER BY ca.dia_semana, ca.hora_inicio';
    $st = $pdo->prepare($sql);
    $st->execute($args);
    $filas = $st->fetchAll();
    foreach ($filas as &$f) {
        $f['dia_nombre'] = $DIAS[(int) $f['dia_semana']] ?? '';
        $f['hora_inicio'] = substr($f['hora_inicio'], 0, 5);
        $f['hora_fin']    = substr($f['hora_fin'], 0, 5);
    }
    unset($f);
    json_ok(['clases' => $filas]);
}

// ---------------------------------------------------------------- POST
if ($metodo === 'POST') {
    $in = leer_json();
    try {
        $idUsuario = v_entero($in['id_usuario'] ?? null, 'id_usuario', ['min' => 1]);
        $idMateria = v_entero($in['id_materia'] ?? null, 'id_materia', ['min' => 1]);
        $idAula    = v_entero($in['id_aula'] ?? null, 'id_aula', ['min' => 1]);
        $dia       = v_entero($in['dia_semana'] ?? null, 'dia_semana', ['min' => 1, 'max' => 7]);
        $hi        = v_hora($in['hora_inicio'] ?? null, 'hora_inicio');
        $hf        = v_hora($in['hora_fin'] ?? null, 'hora_fin');
        $fi        = v_fecha($in['fecha_inicio'] ?? null, 'fecha_inicio');
        $ff        = v_fecha($in['fecha_fin'] ?? null, 'fecha_fin');
        if ($ff < $fi) throw new ValidacionException('La fecha de fin no puede ser anterior a la de inicio.');
    } catch (ValidacionException $e) {
        json_error($e->getMessage(), 422);
    }

    // Validar existencia de llaves foráneas
    $existe = function (string $tabla, string $pkCol, int $id) use ($pdo): bool {
        $s = $pdo->prepare("SELECT 1 FROM $tabla WHERE $pkCol = ?");
        $s->execute([$id]);
        return (bool) $s->fetchColumn();
    };
    if (!$existe('usuarios', 'id_usuario', $idUsuario)) json_error('El docente no existe.', 404);
    if (!$existe('materias', 'id_materia', $idMateria)) json_error('La materia no existe.', 404);
    if (!$existe('aulas', 'id_aula', $idAula))       json_error('El aula no existe.', 404);

    // Detección de conflictos: misma aula, mismo día, horarios que se traslapan
    // y con periodos de fechas que se cruzan.
    $conf = $pdo->prepare(
        'SELECT m.nombre AS materia, u.nombre AS docente, ca.hora_inicio, ca.hora_fin
           FROM carga_academica ca
           JOIN materias m ON m.id_materia = ca.id_materia
           JOIN usuarios u ON u.id_usuario = ca.id_usuario
          WHERE ca.id_aula = ? AND ca.activo = 1 AND ca.dia_semana = ?
            AND ca.hora_inicio < ? AND ca.hora_fin > ?
            AND ca.fecha_inicio <= ? AND ca.fecha_fin >= ?
          LIMIT 1'
    );
    $conf->execute([$idAula, $dia, $hf, $hi, $ff, $fi]);
    if ($c = $conf->fetch()) {
        json_error(
            'Conflicto de aula: ya existe "' . $c['materia'] . '" (' . $c['docente'] . ') de '
            . substr($c['hora_inicio'], 0, 5) . ' a ' . substr($c['hora_fin'], 0, 5) . ' ese día.',
            409
        );
    }

    $ins = $pdo->prepare(
        'INSERT INTO carga_academica (id_usuario, id_materia, id_aula, dia_semana, hora_inicio, hora_fin, fecha_inicio, fecha_fin)
         VALUES (?,?,?,?,?,?,?,?)'
    );
    $ins->execute([$idUsuario, $idMateria, $idAula, $dia, $hi, $hf, $fi, $ff]);
    json_ok(['id' => (int) $pdo->lastInsertId(), 'mensaje' => 'Clase guardada en la base de datos.'], 201);
}

// ---------------------------------------------------------------- DELETE
if ($metodo === 'DELETE') {
    try {
        $id = v_entero($_GET['id'] ?? null, 'id', ['min' => 1]);
    } catch (ValidacionException $e) {
        json_error($e->getMessage(), 422);
    }
    $del = $pdo->prepare('DELETE FROM carga_academica WHERE id_carga_academica = ?');
    $del->execute([$id]);
    if ($del->rowCount() === 0) json_error('La clase no existe.', 404);
    json_ok(['eliminada' => true, 'mensaje' => 'Clase eliminada de la base de datos.']);
}

json_error('Método no permitido.', 405);
