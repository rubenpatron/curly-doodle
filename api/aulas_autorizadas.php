<?php
/**
 * Devuelve las aulas del docente (horario + solicitudes aprobadas) e indica,
 * para cada una, si en ESTE momento hay una clase activa (dentro de la ventana
 * horaria con tolerancia). El frontend usa 'activa_ahora' para avisar al usuario.
 */
require_once __DIR__ . '/helpers.php';
api_boot();
exigir_metodo('GET');

$u = exigir_login();
$pdo = db();

$tol = sprintf('%02d:%02d:00', intdiv(OTP_TOLERANCIA_MIN, 60), OTP_TOLERANCIA_MIN % 60);

$sql = 'SELECT a.id_aula AS id, a.codigo, e.codigo as edificio, a.capacidad,
        (
          EXISTS (
            SELECT 1 FROM carga_academica ca
            WHERE ca.id_aula = a.id_aula AND ca.id_usuario = :u1 AND ca.activo = 1
              AND CURDATE() BETWEEN ca.fecha_inicio AND ca.fecha_fin
              AND (
                (ca.hora_inicio <= ca.hora_fin 
                 AND ca.dia_semana = WEEKDAY(CURDATE()) + 1 
                 AND CURTIME() >= SUBTIME(ca.hora_inicio, :t1) AND CURTIME() <= ADDTIME(ca.hora_fin, :t2))
                OR
                (ca.hora_inicio > ca.hora_fin 
                 AND (
                   (ca.dia_semana = WEEKDAY(CURDATE()) + 1 AND CURTIME() >= SUBTIME(ca.hora_inicio, :t1a))
                   OR 
                   (ca.dia_semana = IF(WEEKDAY(CURDATE()) + 1 = 1, 7, WEEKDAY(CURDATE())) AND CURTIME() <= ADDTIME(ca.hora_fin, :t2a))
                 ))
              )
          )
          OR EXISTS (
            SELECT 1 FROM solicitudes_aulas s
            WHERE s.id_aula_solicitada = a.id_aula AND s.id_usuario = :u2 AND s.estado = "aprobada"
              AND (
                (s.hora_inicio <= s.hora_fin 
                 AND s.fecha = CURDATE() 
                 AND CURTIME() >= SUBTIME(s.hora_inicio, :t3) AND CURTIME() <= ADDTIME(s.hora_fin, :t4))
                OR
                (s.hora_inicio > s.hora_fin 
                 AND (
                   (s.fecha = CURDATE() AND CURTIME() >= SUBTIME(s.hora_inicio, :t3a))
                   OR 
                   (s.fecha = CURDATE() - INTERVAL 1 DAY AND CURTIME() <= ADDTIME(s.hora_fin, :t4a))
                 ))
              )
          )
        ) AS activa_ahora
        FROM aulas a
        JOIN edificios e ON e.id_edificio = a.id_edificio
        WHERE a.id_aula IN (
            SELECT ca.id_aula FROM carga_academica ca
            WHERE ca.id_usuario = :u3 AND ca.activo = 1
        )
        OR a.id_aula IN (
            SELECT s.id_aula_solicitada FROM solicitudes_aulas s
            WHERE s.id_usuario = :u4 AND s.estado = "aprobada"
        )
        ORDER BY activa_ahora DESC, a.codigo';

$st = $pdo->prepare($sql);
$st->execute([
    ':u1' => $u['id'], ':u2' => $u['id'], ':u3' => $u['id'], ':u4' => $u['id'],
    ':t1' => $tol, ':t2' => $tol, ':t1a' => $tol, ':t2a' => $tol,
    ':t3' => $tol, ':t4' => $tol, ':t3a' => $tol, ':t4a' => $tol,
]);

$aulas = array_map(function ($r) {
    $r['activa_ahora'] = (bool) $r['activa_ahora'];
    return $r;
}, $st->fetchAll());

json_ok(['aulas' => $aulas]);
