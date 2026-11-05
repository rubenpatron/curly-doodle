<?php
/**
 * Lista de cerraduras/aulas para el simulador físico de la puerta.
 * Público: una cerradura es un dispositivo, no una sesión de usuario.
 */
require_once __DIR__ . '/helpers.php';
api_boot();
exigir_metodo('GET');

$st = db()->query("
    SELECT 
        a.id_aula AS id, 
        a.codigo, 
        e.nombre AS edificio, 
        n.id_nodo AS id_cerradura
    FROM aulas a
    JOIN edificios e ON a.id_edificio = e.id_edificio
    LEFT JOIN nodos_iot n ON a.id_aula = n.id_aula AND n.tipo_nodo = 'cerradura'
    ORDER BY a.codigo
");
json_ok(['aulas' => $st->fetchAll()]);

