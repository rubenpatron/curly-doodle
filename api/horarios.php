<?php
/**
 * Devuelve el horario (carga académica) del docente autenticado,
 * leído desde MariaDB. Un admin puede consultar el de otro docente
 * pasando ?id_usuario=N.
 */
require_once __DIR__ . '/helpers.php';
api_boot();
exigir_metodo('GET');

$u = exigir_login();

try {
    $idUsuario = $u['id'];
    if ($u['rol'] === 'admin' && isset($_GET['id_usuario'])) {
        $idUsuario = v_entero($_GET['id_usuario'], 'id_usuario', ['min' => 1]);
    }
} catch (ValidacionException $e) {
    json_error($e->getMessage(), 422);
}

$sql = 'SELECT ca.id_carga_academica AS id, ca.dia_semana, ca.hora_inicio, ca.hora_fin,
               ca.fecha_inicio, ca.fecha_fin,
               m.codigo AS materia_codigo, m.nombre AS materia,
               a.id_aula AS id_aula, a.codigo AS aula, e.codigo AS edificio, a.capacidad, a.estado
        FROM carga_academica ca
        JOIN materias m ON m.id_materia = ca.id_materia
        JOIN aulas    a ON a.id_aula = ca.id_aula
        JOIN edificios e ON e.id_edificio = a.id_edificio
        WHERE ca.id_usuario = ? AND ca.activo = 1
        ORDER BY ca.dia_semana, ca.hora_inicio';

$st = db()->prepare($sql);
$st->execute([$idUsuario]);
$filas = $st->fetchAll();

$dias = [1 => 'Lunes', 2 => 'Martes', 3 => 'Miércoles', 4 => 'Jueves', 5 => 'Viernes', 6 => 'Sábado', 7 => 'Domingo'];
foreach ($filas as &$f) {
    $f['dia_nombre'] = $dias[(int) $f['dia_semana']] ?? '';
    $f['hora_inicio'] = substr($f['hora_inicio'], 0, 5);
    $f['hora_fin']    = substr($f['hora_fin'], 0, 5);
}
unset($f);

json_ok(['horario' => $filas]);
