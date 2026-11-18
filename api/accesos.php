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
$conds = [];
$args = [];
if ($u['rol'] !== 'admin') {
    $conds[] = 'ac.id_usuario = ?';
    $args[] = $u['id'];
}
if (!empty($_GET['id_aula']) && is_numeric($_GET['id_aula'])) {
    $conds[] = 'ac.id_aula = ?';
    $args[] = (int)$_GET['id_aula'];
}
if (!empty($conds)) {
    $sql .= ' WHERE ' . implode(' AND ', $conds);
}

$limite = isset($_GET['limite']) ? (int)$_GET['limite'] : 50;
if ($limite < 1) $limite = 10;
if ($limite > 100) $limite = 100;

$sql .= " ORDER BY ac.fecha_hora DESC LIMIT $limite";

$st = $pdo->prepare($sql);
$st->execute($args);
json_ok(['accesos' => $st->fetchAll()]);
