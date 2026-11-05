<?php
/**
 * Utilidades comunes: respuestas JSON, lectura de entrada,
 * validación estricta de tipos de datos y control de sesión.
 */
require_once __DIR__ . '/db.php';

// ---------------------------------------------------------------------------
//  Arranque común de cada endpoint
// ---------------------------------------------------------------------------
function api_boot(): void
{
    header('Content-Type: application/json; charset=utf-8');
    header('X-Content-Type-Options: nosniff');
    if (session_status() === PHP_SESSION_NONE) {
        session_start();
    }
}

// ---------------------------------------------------------------------------
//  Respuestas
// ---------------------------------------------------------------------------
function json_ok($data = [], int $code = 200): void
{
    http_response_code($code);
    echo json_encode(['ok' => true, 'data' => $data], JSON_UNESCAPED_UNICODE);
    exit;
}

function json_error(string $mensaje, int $code = 400, array $extra = []): void
{
    http_response_code($code);
    echo json_encode(array_merge(['ok' => false, 'error' => $mensaje], $extra), JSON_UNESCAPED_UNICODE);
    exit;
}

/** Excepción usada por los validadores. */
class ValidacionException extends Exception {}

// ---------------------------------------------------------------------------
//  Entrada
// ---------------------------------------------------------------------------
/** Exige un método HTTP concreto. */
function exigir_metodo(string $metodo): void
{
    if (($_SERVER['REQUEST_METHOD'] ?? '') !== $metodo) {
        json_error("Método no permitido. Se esperaba $metodo.", 405);
    }
}

/** Lee y decodifica el cuerpo JSON del request. */
function leer_json(): array
{
    $raw = file_get_contents('php://input');
    if ($raw === '' || $raw === false) {
        return [];
    }
    $data = json_decode($raw, true);
    if (!is_array($data)) {
        json_error('El cuerpo de la petición no es JSON válido.', 400);
    }
    return $data;
}

// ---------------------------------------------------------------------------
//  Validadores de tipos de datos
//  Cada uno lanza ValidacionException con un mensaje claro.
// ---------------------------------------------------------------------------

/**
 * Cadena de texto. Opciones:
 *   min, max        -> longitud
 *   solo_texto      -> true: no permite dígitos (nombres, etc.)
 *   patron          -> regex adicional (sin delimitadores)
 */
function v_texto($valor, string $campo, array $op = []): string
{
    if (is_int($valor) || is_float($valor) || is_bool($valor)) {
        throw new ValidacionException("El campo '$campo' debe ser texto, no un número o booleano.");
    }
    if (!is_string($valor)) {
        throw new ValidacionException("El campo '$campo' debe ser texto.");
    }
    $v = trim($valor);
    $min = $op['min'] ?? 1;
    $max = $op['max'] ?? 255;
    $len = mb_strlen($v);
    if ($len < $min) {
        throw new ValidacionException("El campo '$campo' debe tener al menos $min carácter(es).");
    }
    if ($len > $max) {
        throw new ValidacionException("El campo '$campo' no debe superar $max caracteres.");
    }
    if (!empty($op['solo_texto']) && preg_match('/[0-9]/u', $v)) {
        throw new ValidacionException("El campo '$campo' no debe contener números.");
    }
    if (!empty($op['patron']) && !preg_match('/' . $op['patron'] . '/u', $v)) {
        throw new ValidacionException("El campo '$campo' tiene un formato no válido.");
    }
    return $v;
}

/** Entero estricto (rechaza texto no numérico y decimales). */
function v_entero($valor, string $campo, array $op = []): int
{
    if (is_bool($valor)) {
        throw new ValidacionException("El campo '$campo' debe ser un número entero.");
    }
    if (is_string($valor)) {
        if (!preg_match('/^-?\d+$/', trim($valor))) {
            throw new ValidacionException("El campo '$campo' debe ser un número entero válido.");
        }
        $valor = (int) $valor;
    } elseif (is_float($valor)) {
        if (floor($valor) != $valor) {
            throw new ValidacionException("El campo '$campo' no admite decimales.");
        }
        $valor = (int) $valor;
    } elseif (!is_int($valor)) {
        throw new ValidacionException("El campo '$campo' debe ser un número entero.");
    }
    if (isset($op['min']) && $valor < $op['min']) {
        throw new ValidacionException("El campo '$campo' debe ser mayor o igual a {$op['min']}.");
    }
    if (isset($op['max']) && $valor > $op['max']) {
        throw new ValidacionException("El campo '$campo' debe ser menor o igual a {$op['max']}.");
    }
    return $valor;
}

/** Correo electrónico. */
function v_email($valor, string $campo = 'email'): string
{
    if (!is_string($valor)) {
        throw new ValidacionException("El campo '$campo' debe ser texto.");
    }
    $v = trim($valor);
    if (!filter_var($v, FILTER_VALIDATE_EMAIL)) {
        throw new ValidacionException("El campo '$campo' no es un correo válido.");
    }
    if (mb_strlen($v) > 150) {
        throw new ValidacionException("El correo es demasiado largo.");
    }
    return $v;
}

/** Fecha en formato YYYY-MM-DD y que exista en el calendario. */
function v_fecha($valor, string $campo): string
{
    if (!is_string($valor) || !preg_match('/^\d{4}-\d{2}-\d{2}$/', trim($valor))) {
        throw new ValidacionException("El campo '$campo' debe tener formato AAAA-MM-DD.");
    }
    $v = trim($valor);
    [$a, $m, $d] = array_map('intval', explode('-', $v));
    if (!checkdate($m, $d, $a)) {
        throw new ValidacionException("El campo '$campo' no es una fecha válida.");
    }
    return $v;
}

/** Hora en formato HH:MM o HH:MM:SS. Devuelve HH:MM:SS. */
function v_hora($valor, string $campo): string
{
    if (!is_string($valor) || !preg_match('/^([01]\d|2[0-3]):([0-5]\d)(:([0-5]\d))?$/', trim($valor), $m)) {
        throw new ValidacionException("El campo '$campo' debe tener formato HH:MM (24 horas).");
    }
    $seg = $m[4] ?? '00';
    return sprintf('%s:%s:%s', $m[1], $m[2], $seg);
}

/** Valor dentro de un conjunto permitido (enum). */
function v_enum($valor, string $campo, array $permitidos): string
{
    if (!is_string($valor) || !in_array($valor, $permitidos, true)) {
        throw new ValidacionException("El campo '$campo' debe ser uno de: " . implode(', ', $permitidos) . '.');
    }
    return $valor;
}

/** Cadena de exactamente N dígitos (OTP, PIN). */
function v_digitos($valor, string $campo, int $longitud): string
{
    $v = is_string($valor) ? trim($valor) : (string) $valor;
    if (!preg_match('/^\d{' . $longitud . '}$/', $v)) {
        throw new ValidacionException("El campo '$campo' debe tener exactamente $longitud dígitos numéricos.");
    }
    return $v;
}

// ---------------------------------------------------------------------------
//  Sesión / autenticación
// ---------------------------------------------------------------------------
function usuario_actual(): ?array
{
    if (!isset($_SESSION['usuario']) || !is_array($_SESSION['usuario'])) {
        return null;
    }
    $u = $_SESSION['usuario'];
    $id = $u['id'] ?? $u['id_usuario'] ?? null;
    if ($id !== null) {
        $u['id'] = (int) $id;
        $u['id_usuario'] = (int) $id;
    }
    return $u;
}

function exigir_login(): array
{
    $u = usuario_actual();
    if (!$u) {
        json_error('No has iniciado sesión.', 401);
    }
    return $u;
}

function exigir_admin(): array
{
    $u = exigir_login();
    if (($u['rol'] ?? '') !== 'admin') {
        json_error('Se requieren permisos de administrador.', 403);
    }
    return $u;
}

