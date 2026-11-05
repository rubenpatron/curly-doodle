<?php
/**
 * Simula la cerradura física: recibe el código tecleado en la puerta.
 *   Recibe: { "id_aula": N, "codigo": "123456" }
 *
 * No requiere sesión (la cerradura es un dispositivo). La validación es:
 *   - el código debe existir para ESA aula
 *   - no debe estar usado ni expirado
 * Al abrir, registra el acceso a nombre del docente dueño del OTP.
 */
require_once __DIR__ . '/helpers.php';
api_boot();
exigir_metodo('POST');

$in = leer_json();

try {
    $idAula = v_entero($in['id_aula'] ?? null, 'id_aula', ['min' => 1]);
    $codigo = v_digitos($in['codigo'] ?? null, 'codigo', OTP_LONGITUD);
} catch (ValidacionException $e) {
    json_error($e->getMessage(), 422);
}

$pdo = db();

// Verifica que la cerradura (aula) exista
$stA = $pdo->prepare('SELECT codigo FROM aulas WHERE id_aula = ?');
$stA->execute([$idAula]);
$aula = $stA->fetch();
if (!$aula) {
    json_error('Cerradura no encontrada.', 404);
}

// Busca un OTP para ESA aula con ese código
$st = $pdo->prepare(
    'SELECT * FROM otp_codigos WHERE id_aula = ? AND codigo = ? ORDER BY id_otp DESC LIMIT 1'
);
$st->execute([$idAula, $codigo]);
$otp = $st->fetch();

// Registra el intento en la bitácora (id_usuario del dueño del OTP si existe)
$registrar = function (?int $idUsuario, string $resultado, string $detalle) use ($pdo, $idAula) {
    $pdo->prepare('INSERT INTO accesos (id_usuario, id_aula, tipo_acceso, resultado, detalle) VALUES (?,?,?,?,?)')
        ->execute([$idUsuario, $idAula, 'otp', $resultado, $detalle]);
};

if (!$otp) {
    $registrar(null, 'denegado', 'Código no válido para esta cerradura');
    json_error('Código incorrecto para esta puerta.', 401);
}
if ((int) $otp['usado'] === 1) {
    $registrar((int) $otp['id_usuario'], 'denegado', 'Código ya utilizado');
    json_error('Ese código ya fue utilizado.', 409);
}
if (strtotime($otp['expira_en']) < time()) {
    $registrar((int) $otp['id_usuario'], 'denegado', 'Código expirado');
    json_error('El código ha expirado.', 410);
}

// Abre: marca usado y registra acceso exitoso
$pdo->prepare('UPDATE otp_codigos SET usado = 1, usado_en = NOW() WHERE id_otp = ?')->execute([$otp['id_otp']]);
$registrar((int) $otp['id_usuario'], 'exitoso', 'Puerta abierta con OTP');

json_ok(['abierta' => true, 'aula' => $aula['codigo'], 'mensaje' => 'Acceso concedido. Puerta abierta.']);
