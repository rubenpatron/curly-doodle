<?php
/**
 * Genera un código OTP de 6 dígitos para abrir la puerta de un aula.
 * Recibe: { "id_aula": N }
 * En un sistema real el código se enviaría por app/SMS; aquí se devuelve
 * para poder probar el prototipo.
 */
require_once __DIR__ . '/helpers.php';
api_boot();
exigir_metodo('POST');

$u = exigir_login();
$in = leer_json();

try {
    if (empty($in['id_aula'])) {
        throw new ValidacionException("Debes seleccionar un aula de la lista.");
    }
    $idAula = v_entero($in['id_aula'], 'id_aula', ['min' => 1]);
} catch (ValidacionException $e) {
    json_error($e->getMessage(), 422);
}

$pdo = db();

// Verifica que el aula exista
$st = $pdo->prepare('SELECT codigo FROM aulas WHERE id_aula = ?');
$st->execute([$idAula]);
$aula = $st->fetch();
if (!$aula) {
    json_error('El aula indicada no existe.', 404);
}

$tol = sprintf('%02d:%02d:00', intdiv(OTP_TOLERANCIA_MIN, 60), OTP_TOLERANCIA_MIN % 60);

// 1) ¿El aula pertenece al horario del docente (o a una solicitud aprobada)?
$pertenece = $pdo->prepare(
    'SELECT 1 FROM carga_academica
        WHERE id_usuario = ? AND id_aula = ? AND activo = 1
     UNION
     SELECT 1 FROM solicitudes_aulas
        WHERE id_usuario = ? AND id_aula_solicitada = ? AND estado = "aprobada"
     LIMIT 1'
);
$pertenece->execute([$u['id'], $idAula, $u['id'], $idAula]);
if (!$pertenece->fetchColumn()) {
    json_error('No tienes autorización para esta aula. Solo puedes abrir las aulas de tu horario.', 403);
}

// 2) ¿Hay una clase (o solicitud aprobada) ACTIVA ahora en esa aula? (con tolerancia)
$ventana = $pdo->prepare(
    'SELECT 1 FROM carga_academica
        WHERE id_usuario = ? AND id_aula = ? AND activo = 1
          AND CURDATE() BETWEEN fecha_inicio AND fecha_fin
          AND (
            (hora_inicio <= hora_fin 
             AND dia_semana = WEEKDAY(CURDATE()) + 1 
             AND CURTIME() >= SUBTIME(hora_inicio, ?) AND CURTIME() <= ADDTIME(hora_fin, ?))
            OR
            (hora_inicio > hora_fin 
             AND (
               (dia_semana = WEEKDAY(CURDATE()) + 1 AND CURTIME() >= SUBTIME(hora_inicio, ?))
               OR 
               (dia_semana = IF(WEEKDAY(CURDATE()) + 1 = 1, 7, WEEKDAY(CURDATE())) AND CURTIME() <= ADDTIME(hora_fin, ?))
             ))
          )
     UNION
     SELECT 1 FROM solicitudes_aulas
        WHERE id_usuario = ? AND id_aula_solicitada = ? AND estado = "aprobada"
          AND (
            (hora_inicio <= hora_fin 
             AND fecha = CURDATE() 
             AND CURTIME() >= SUBTIME(hora_inicio, ?) AND CURTIME() <= ADDTIME(hora_fin, ?))
            OR
            (hora_inicio > hora_fin 
             AND (
               (fecha = CURDATE() AND CURTIME() >= SUBTIME(hora_inicio, ?))
               OR 
               (fecha = CURDATE() - INTERVAL 1 DAY AND CURTIME() <= ADDTIME(hora_fin, ?))
             ))
          )
     LIMIT 1'
);
$ventana->execute([$u['id'], $idAula, $tol, $tol, $tol, $tol, $u['id'], $idAula, $tol, $tol, $tol, $tol]);
if (!$ventana->fetchColumn()) {
    json_error('Puerta aún no autorizada, fuera de horario.', 403);
}

// Invalida OTPs anteriores no usados del mismo usuario/aula
$pdo->prepare('UPDATE otp_codigos SET usado = 1, usado_en = NOW()
               WHERE id_usuario = ? AND id_aula = ? AND usado = 0')
    ->execute([$u['id'], $idAula]);

// Genera un código de 6 dígitos
$codigo = str_pad((string) random_int(0, 999999), OTP_LONGITUD, '0', STR_PAD_LEFT);
$expira = date('Y-m-d H:i:s', time() + OTP_VIGENCIA_MIN * 60);

$ins = $pdo->prepare('INSERT INTO otp_codigos (id_usuario, id_aula, codigo, expira_en) VALUES (?,?,?,?)');
$ins->execute([$u['id'], $idAula, $codigo, $expira]);

json_ok([
    'codigo'        => $codigo,          // en producción NO se devolvería
    'aula'          => $aula['codigo'],
    'vigencia_min'  => OTP_VIGENCIA_MIN,
    'expira_en'     => $expira,
    'mensaje'       => "Código válido por " . OTP_VIGENCIA_MIN . " minutos.",
]);
