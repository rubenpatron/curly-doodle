<?php
/** Lista las aulas disponibles, opcionalmente filtradas por edificio */
require_once __DIR__ . '/helpers.php';
api_boot();
exigir_metodo('GET');
// exigir_login(); // Desactivado temporalmente para pruebas de integración con UI

$edificio_codigo = $_GET['edificio'] ?? '';

$sql = "
    SELECT 
        a.id_aula AS id, 
        a.codigo, 
        a.capacidad, 
        a.tipo, 
        a.estado as estado_aula,
        n.estado as estado_nodo,
        n.bateria_pct,
        e.nombre as edificio
    FROM aulas a
    JOIN edificios e ON a.id_edificio = e.id_edificio
    LEFT JOIN nodos_iot n ON a.id_aula = n.id_aula AND n.tipo_nodo = 'cerradura'
";

$params = [];
if ($edificio_codigo !== '') {
    $sql .= " WHERE e.codigo = :edificio ";
    $params['edificio'] = $edificio_codigo;
}

$sql .= " ORDER BY a.codigo";

$st = db()->prepare($sql);
$st->execute($params);
$aulas = $st->fetchAll();

json_ok(['aulas' => $aulas]);
