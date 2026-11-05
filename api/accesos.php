<?php
/**
 * Historial de accesos del usuario autenticado (o de todos si es admin).
 */
require_once __DIR__ . '/helpers.php';
api_boot();
exigir_metodo('GET');

$u = exigir_login();
$pdo = db();

$sql = 'SELECT ac.id_acceso AS id, ac.fecha_hora, ac.tipo_acceso, ac.resultado, ac.detalle,
               a.codigo AS aula, us.nombre AS usuario
        FROM accesos ac
        JOIN aulas a ON a.id_aula = ac.id_aula
        LEFT JOIN usuarios us ON us.id_usuario = ac.id_usuario';
$args = [];
if ($u['rol'] !== 'admin') {
    $sql .= ' WHERE ac.id_usuario = ?';
    $args[] = $u['id'];
}
$sql .= ' ORDER BY ac.fecha_hora DESC LIMIT 50';

$st = $pdo->prepare($sql);
$st->execute($args);
json_ok(['accesos' => $st->fetchAll()]);
