<?php
/**
 * Módulo 3: Gestión de Aulas y Espacios Físicos.
 * Operaciones CRUD completas para la administración de aulas:
 *   GET    -> Lista aulas (filtro opcional ?edificio=, ?tipo=, ?id=)
 *   POST   -> Registra nueva aula (solo admin)
 *   PUT    -> Actualiza datos de aula existente (solo admin)
 *   DELETE -> Elimina o da de baja un aula (solo admin)
 */
require_once __DIR__ . '/helpers.php';
api_boot();

$pdo = db();
$metodo = $_SERVER['REQUEST_METHOD'] ?? 'GET';

// ---------------------------------------------------------------- GET
if ($metodo === 'GET') {
    $edificio_codigo = $_GET['edificio'] ?? '';
    $tipo = $_GET['tipo'] ?? '';
    $id = isset($_GET['id']) ? (int)$_GET['id'] : null;

    $sql = "
        SELECT 
            a.id_aula AS id, 
            a.id_aula,
            a.id_edificio,
            a.codigo, 
            a.capacidad, 
            a.tipo, 
            a.estado as estado_aula,
            n.id_nodo,
            n.estado as estado_nodo,
            n.bateria_pct,
            e.codigo as edificio_codigo,
            e.nombre as edificio
        FROM aulas a
        JOIN edificios e ON a.id_edificio = e.id_edificio
        LEFT JOIN nodos_iot n ON a.id_aula = n.id_aula AND n.tipo_nodo = 'cerradura'
        WHERE 1=1
    ";

    $params = [];
    if ($id !== null && $id > 0) {
        $sql .= " AND a.id_aula = :id ";
        $params['id'] = $id;
    }
    if ($edificio_codigo !== '') {
        $sql .= " AND e.codigo = :edificio ";
        $params['edificio'] = $edificio_codigo;
    }
    if ($tipo !== '') {
        $sql .= " AND a.tipo = :tipo ";
        $params['tipo'] = $tipo;
    }

    $sql .= " ORDER BY a.codigo";

    $st = $pdo->prepare($sql);
    $st->execute($params);
    $aulas = $st->fetchAll();

    json_ok(['aulas' => $aulas]);
}

// ---------------------------------------------------------------- POST (Crear aula)
if ($metodo === 'POST') {
    exigir_admin();
    $in = leer_json();

    try {
        $codigo     = v_texto($in['codigo'] ?? null, 'codigo', ['min' => 2, 'max' => 15]);
        $idEdificio = v_entero($in['id_edificio'] ?? null, 'id_edificio', ['min' => 1]);
        $capacidad  = v_entero($in['capacidad'] ?? 30, 'capacidad', ['min' => 1, 'max' => 500]);
        $tipo       = v_enum($in['tipo'] ?? 'aula', 'tipo', ['aula', 'laboratorio', 'taller', 'auditorio']);
        $estado     = v_enum($in['estado'] ?? 'disponible', 'estado', ['disponible', 'ocupada', 'mantenimiento', 'clausurada']);
    } catch (ValidacionException $e) {
        json_error($e->getMessage(), 422);
    }

    // Verificar edificio
    $chkEdif = $pdo->prepare('SELECT 1 FROM edificios WHERE id_edificio = ?');
    $chkEdif->execute([$idEdificio]);
    if (!$chkEdif->fetchColumn()) json_error('El edificio especificado no existe.', 404);

    // Verificar código duplicado
    $chkCod = $pdo->prepare('SELECT 1 FROM aulas WHERE codigo = ?');
    $chkCod->execute([$codigo]);
    if ($chkCod->fetchColumn()) json_error("El código de aula '$codigo' ya se encuentra registrado.", 409);

    $ins = $pdo->prepare(
        'INSERT INTO aulas (id_edificio, codigo, capacidad, tipo, estado)
         VALUES (?, ?, ?, ?, ?)'
    );
    $ins->execute([$idEdificio, $codigo, $capacidad, $tipo, $estado]);
    $newId = (int)$pdo->lastInsertId();

    json_ok(['id' => $newId, 'mensaje' => "Aula $codigo registrada exitosamente."], 201);
}

// ---------------------------------------------------------------- PUT / PATCH (Actualizar aula)
if ($metodo === 'PUT' || $metodo === 'PATCH') {
    exigir_admin();
    $in = leer_json();

    try {
        $idAula     = v_entero($in['id'] ?? $in['id_aula'] ?? ($_GET['id'] ?? null), 'id', ['min' => 1]);
        $codigo     = v_texto($in['codigo'] ?? null, 'codigo', ['min' => 2, 'max' => 15]);
        $idEdificio = v_entero($in['id_edificio'] ?? null, 'id_edificio', ['min' => 1]);
        $capacidad  = v_entero($in['capacidad'] ?? 30, 'capacidad', ['min' => 1, 'max' => 500]);
        $tipo       = v_enum($in['tipo'] ?? 'aula', 'tipo', ['aula', 'laboratorio', 'taller', 'auditorio']);
        $estado     = v_enum($in['estado'] ?? 'disponible', 'estado', ['disponible', 'ocupada', 'mantenimiento', 'clausurada']);
    } catch (ValidacionException $e) {
        json_error($e->getMessage(), 422);
    }

    $chkAula = $pdo->prepare('SELECT 1 FROM aulas WHERE id_aula = ?');
    $chkAula->execute([$idAula]);
    if (!$chkAula->fetchColumn()) json_error('El aula especificada no existe.', 404);

    $chkCod = $pdo->prepare('SELECT 1 FROM aulas WHERE codigo = ? AND id_aula != ?');
    $chkCod->execute([$codigo, $idAula]);
    if ($chkCod->fetchColumn()) json_error("Ya existe otra aula con el código '$codigo'.", 409);

    $upd = $pdo->prepare(
        'UPDATE aulas
            SET id_edificio = ?, codigo = ?, capacidad = ?, tipo = ?, estado = ?
          WHERE id_aula = ?'
    );
    $upd->execute([$idEdificio, $codigo, $capacidad, $tipo, $estado, $idAula]);

    json_ok(['id' => $idAula, 'mensaje' => "Aula $codigo actualizada correctamente."]);
}

// ---------------------------------------------------------------- DELETE (Eliminar aula)
if ($metodo === 'DELETE') {
    exigir_admin();
    try {
        $idAula = v_entero($_GET['id'] ?? null, 'id', ['min' => 1]);
    } catch (ValidacionException $e) {
        json_error($e->getMessage(), 422);
    }

    $chk = $pdo->prepare('SELECT codigo FROM aulas WHERE id_aula = ?');
    $chk->execute([$idAula]);
    $aula = $chk->fetch();
    if (!$aula) json_error('El aula no existe.', 404);

    // Validar si tiene carga académica asociada
    $chkCarga = $pdo->prepare('SELECT COUNT(*) FROM carga_academica WHERE id_aula = ?');
    $chkCarga->execute([$idAula]);
    if ($chkCarga->fetchColumn() > 0) {
        // En lugar de fallar violentamente por FK, marcamos estado como clausurada
        $pdo->prepare("UPDATE aulas SET estado = 'clausurada' WHERE id_aula = ?")->execute([$idAula]);
        json_ok(['clausurada' => true, 'mensaje' => "El aula {$aula['codigo']} contiene horarios activos; ha sido marcada como 'clausurada'."]);
    }

    $del = $pdo->prepare('DELETE FROM aulas WHERE id_aula = ?');
    $del->execute([$idAula]);
    json_ok(['eliminada' => true, 'mensaje' => "Aula {$aula['codigo']} eliminada correctamente de la base de datos."]);
}

json_error('Método no permitido.', 405);
