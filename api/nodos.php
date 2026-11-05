<?php
/** Lista el estado de todos los nodos IoT (Cerraduras) */
require_once __DIR__ . '/helpers.php';
api_boot();
exigir_metodo('GET');

$edificio_codigo = $_GET['edificio'] ?? '';

$sql = "
    SELECT 
        n.id_nodo,
        n.mac_address,
        n.tipo_nodo,
        n.estado as estado_nodo,
        n.bateria_pct,
        n.ultimo_ping,
        n.firmware_version,
        a.codigo as aula_codigo,
        e.codigo as edificio_codigo
    FROM nodos_iot n
    JOIN aulas a ON n.id_aula = a.id_aula
    JOIN edificios e ON a.id_edificio = e.id_edificio
    WHERE n.tipo_nodo = 'cerradura'
";

$params = [];
if ($edificio_codigo !== '') {
    $sql .= " AND e.codigo = :edificio ";
    $params['edificio'] = $edificio_codigo;
}

$sql .= " ORDER BY a.codigo";

$st = db()->prepare($sql);
$st->execute($params);
$nodos = $st->fetchAll();

json_ok(['nodos' => $nodos]);
