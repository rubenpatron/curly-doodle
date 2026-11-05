<?php
/** Obtiene los eventos de telemetría más recientes (bitácora en vivo) */
require_once __DIR__ . '/helpers.php';
api_boot();
exigir_metodo('GET');

$limite = $_GET['limite'] ?? 5;
$limite = (int) $limite;
if ($limite > 50) $limite = 50;
if ($limite < 1) $limite = 5;

$sql = "
    SELECT 
        t.id_telemetria AS id,
        t.tipo_evento,
        t.valor,
        t.fecha_hora,
        n.tipo_nodo,
        a.codigo as aula_codigo
    FROM telemetria t
    JOIN nodos_iot n ON t.id_nodo = n.id_nodo
    JOIN aulas a ON n.id_aula = a.id_aula
    ORDER BY t.fecha_hora DESC
    LIMIT $limite
";

$st = db()->query($sql);
$eventos = $st->fetchAll();

json_ok(['telemetria' => $eventos]);
