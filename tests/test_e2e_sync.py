#!/usr/bin/env python3
"""
AulaSync — Suite de Pruebas End-to-End (E2E) Bidireccional
==========================================================
Demuestra y valida el ciclo completo e interactivo del sistema:
  1. Autenticación de Administrador y Docente (Bcrypt / Tokens de Sesión)
  2. Módulo 1 (Carga Académica): Consulta y detección de conflictos
  3. Módulo 2 (Solicitudes): Docente solicita aula adicional (A-201)
  4. Módulo 2 (Aprobación): Administrador aprueba la solicitud
  5. Sincronización en MariaDB: Verificación directa de estado 'aprobada'
  6. Módulo 3 (Autorización): El aula solicitada se refleja como 'activa_ahora'
  7. Módulo 3 (Emisión OTP): Docente genera PIN temporal de 6 dígitos
  8. Desbloqueo Físico IoT: Cerradura procesa OTP y abre la puerta
  9. Protección Anti-Replay: Intento de reutilización de OTP denegado (409)
 10. Bitácora MariaDB: Comprobación directa de inserción en tabla `accesos`
 11. Bitácora API: Comprobación de auditoría en GET /api/accesos.php
 12. Limpieza idempotente de datos temporales de prueba

Autor: data-verifier (Swarm AulaSync)
Evaluación: F-SGC-033 — Sesiones 7 y 8
"""

import sys
import json
import time
import subprocess
from datetime import datetime, date
import urllib.request
import urllib.error

API_BASE = "http://localhost/aulasync/api"
MYSQL_CLI = r"C:\xampp\mysql\bin\mysql.exe"
DB_NAME = "aulas_inteligentes"

# ANSI Colors
GREEN = "\033[92m"
RED = "\033[91m"
YELLOW = "\033[93m"
CYAN = "\033[96m"
BOLD = "\033[1m"
RESET = "\033[0m"

passed_tests = 0
failed_tests = 0

def log_header(title):
    print(f"\n{BOLD}{CYAN}{'='*75}{RESET}")
    print(f"{BOLD}{CYAN}  {title}{RESET}")
    print(f"{BOLD}{CYAN}{'='*75}{RESET}")

def log_step(step_num, title):
    print(f"\n{BOLD}[PASO {step_num}] {title}{RESET}")

def assert_true(condition, message):
    global passed_tests, failed_tests
    if condition:
        print(f"  {GREEN}✓ PASS:{RESET} {message}")
        passed_tests += 1
    else:
        print(f"  {RED}✗ FAIL:{RESET} {message}")
        failed_tests += 1
        raise AssertionError(message)

def api_request(endpoint, method="GET", data=None, token=None):
    """Realiza una petición HTTP a la API REST de AulaSync."""
    url = f"{API_BASE}/{endpoint}"
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
        headers["X-Session-Token"] = token

    payload = json.dumps(data).encode("utf-8") if data else None
    req = urllib.request.Request(url, data=payload, headers=headers, method=method)

    try:
        with urllib.request.urlopen(req, timeout=5) as response:
            status_code = response.status
            body = response.read().decode("utf-8")
            parsed = json.loads(body) if body else {}
            return status_code, parsed
    except urllib.error.HTTPError as e:
        status_code = e.code
        body = e.read().decode("utf-8")
        try:
            parsed = json.loads(body)
        except Exception:
            parsed = {"error": body}
        return status_code, parsed
    except Exception as e:
        return 500, {"error": str(e)}

def query_mariadb(sql):
    """Ejecuta una consulta SQL directamente en MariaDB usando mysql.exe."""
    cmd = [MYSQL_CLI, "-u", "root", DB_NAME, "-e", sql]
    res = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8")
    if res.returncode != 0:
        raise RuntimeError(f"Error MariaDB CLI: {res.stderr}")
    return res.stdout.strip()

def run_e2e_suite():
    global passed_tests, failed_tests
    log_header("AULASYNC — PRUEBA END-TO-END (E2E) BIDIRECCIONAL")
    print(f"Fecha de Ejecución: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"Endpoint API:       {API_BASE}")
    print(f"Base de Datos:      MariaDB ({DB_NAME})")

    created_solicitud_id = None
    generated_otp_code = None
    test_aula_id = 6  # Aula A-201 (Laboratorio)
    test_materia_id = 1  # CS101

    try:
        # -------------------------------------------------------------
        # PASO 1: Verificación de Conectividad Base
        # -------------------------------------------------------------
        log_step(1, "Verificación de Conectividad API y MariaDB")
        code, resp = api_request("aulas.php")
        assert_true(code == 200, f"API REST responde HTTP 200 en aulas.php (recibido {code})")
        assert_true("aulas" in resp.get("data", {}), "Catálogo de aulas recibido con éxito")

        db_check = query_mariadb("SELECT COUNT(*) FROM aulas;")
        assert_true("30" in db_check, f"MariaDB conectada y con 30 aulas (resultado: {db_check})")

        # -------------------------------------------------------------
        # PASO 2: Autenticación de Administrador y Docente (Bcrypt)
        # -------------------------------------------------------------
        log_step(2, "Autenticación Local con Hashes Bcrypt (Roles Admin y Docente)")
        # 2a: Login Admin
        code, resp = api_request("auth_login.php", "POST", {
            "email": "admin@universidad.edu",
            "password": "admin123"
        })
        assert_true(code == 200, f"Login Administrador exitoso (HTTP 200)")
        admin_token = resp["data"]["token"]
        admin_user = resp["data"]["usuario"]
        assert_true(admin_user["rol"] == "admin", f"Rol de Administrador confirmado: {admin_user['rol']}")

        # 2b: Login Docente
        code, resp = api_request("auth_login.php", "POST", {
            "email": "juan.perez@universidad.edu",
            "password": "docente123"
        })
        assert_true(code == 200, f"Login Docente exitoso (HTTP 200)")
        docente_token = resp["data"]["token"]
        docente_user = resp["data"]["usuario"]
        docente_id = docente_user["id"]
        assert_true(docente_user["rol"] == "usuario", f"Rol Docente confirmado: {docente_user['rol']}")

        # -------------------------------------------------------------
        # PASO 3: Módulo 1 — Verificación y Detección de Conflictos de Horario
        # -------------------------------------------------------------
        log_step(3, "Módulo 1: Consulta de Horarios y Validación de Conflictos (409)")
        code, resp = api_request("carga_academica.php", "GET", token=admin_token)
        assert_true(code == 200, f"Admin consulta horarios globales (HTTP 200)")
        clases = resp.get("data", {}).get("clases", [])
        assert_true(len(clases) >= 10, f"Total clases cargadas en sistema: {len(clases)}")

        # Intentar colisión deliberada en misma aula y hora
        colision_payload = {
            "id_usuario": docente_id,
            "id_materia": test_materia_id,
            "id_aula": 1,  # A-101 ya ocupada
            "dia_semana": 1,
            "hora_inicio": "08:00:00",
            "hora_fin": "10:00:00",
            "fecha_inicio": "2026-01-01",
            "fecha_fin": "2026-12-31"
        }
        code, resp = api_request("carga_academica.php", "POST", colision_payload, token=admin_token)
        assert_true(code == 409, f"Detección de conflicto de horario exitosa: HTTP 409 Conflict ({resp.get('error')})")

        # -------------------------------------------------------------
        # PASO 4: Módulo 2 — Docente solicita Aula Adicional Excepcional
        # -------------------------------------------------------------
        log_step(4, "Módulo 2: Docente Emite Solicitud de Aula Excepcional")
        hoy_str = date.today().isoformat()
        solicitud_payload = {
            "tipo": "aula_adicional",
            "id_aula_solicitada": test_aula_id,
            "id_materia": test_materia_id,
            "fecha": hoy_str,
            "hora_inicio": "07:00:00",
            "hora_fin": "23:59:00",
            "motivo": "Evaluación Práctica E2E Automatizada",
            "justificacion": "Prueba de certificación de flujo bidireccional para evaluación F-SGC-033."
        }
        code, resp = api_request("solicitudes.php", "POST", solicitud_payload, token=docente_token)
        assert_true(code == 201, f"Solicitud registrada exitosamente: HTTP 201 Created")
        created_solicitud_id = resp.get("data", {}).get("id")
        assert_true(created_solicitud_id is not None, f"ID de Solicitud generado: #{created_solicitud_id}")

        # Comprobar que en listado del docente aparece en estado 'pendiente'
        code, resp = api_request("solicitudes.php", "GET", token=docente_token)
        solicitudes_doc = resp.get("data", {}).get("solicitudes", [])
        encontrada = next((s for s in solicitudes_doc if s["id"] == created_solicitud_id), None)
        assert_true(encontrada is not None, "Solicitud localizada en la bandeja del docente")
        assert_true(encontrada["estado"] == "pendiente", f"Estado inicial verificado: {encontrada['estado']}")

        # -------------------------------------------------------------
        # PASO 5: Módulo 2 — Administrador Aprueba la Solicitud
        # -------------------------------------------------------------
        log_step(5, "Módulo 2: Administrador Aprueba Solicitud vía API")
        responder_payload = {
            "id": created_solicitud_id,
            "accion": "aprobar",
            "comentarios": "Aprobado por el Administrador en ejecución de pruebas E2E."
        }
        code, resp = api_request("solicitud_responder.php", "POST", responder_payload, token=admin_token)
        assert_true(code == 200, f"Solicitud aprobada por el Administrador: HTTP 200 OK")
        assert_true(resp.get("data", {}).get("estado") == "aprobada", "Estado actualizado a 'aprobada'")

        # -------------------------------------------------------------
        # PASO 6: Comprobación Directa en MariaDB (BD State Check)
        # -------------------------------------------------------------
        log_step(6, "Comprobación Directa en MariaDB del Estado Aprobado")
        sql_check = f"SELECT estado, id_aprobador FROM solicitudes_aulas WHERE id_solicitud = {created_solicitud_id};"
        db_res = query_mariadb(sql_check)
        assert_true("aprobada" in db_res, f"MariaDB confirma estado persistido: 'aprobada'")
        assert_true(str(admin_user["id"]) in db_res, f"MariaDB confirma ID de aprobador: {admin_user['id']}")

        # -------------------------------------------------------------
        # PASO 7: Módulo 3 — Verificación de Permiso Dinámico de Aula
        # -------------------------------------------------------------
        log_step(7, "Módulo 3: Sincronización de Aulas Autorizadas del Docente")
        code, resp = api_request("aulas_autorizadas.php", "GET", token=docente_token)
        assert_true(code == 200, "Consulta de aulas autorizadas exitosa: HTTP 200")
        aulas_aut = resp.get("data", {}).get("aulas", [])
        aula_concedida = next((a for a in aulas_aut if a["id"] == test_aula_id), None)
        assert_true(aula_concedida is not None, f"Aula A-201 aparece en la lista de aulas autorizadas del docente")
        assert_true(aula_concedida["activa_ahora"] is True, f"Aula autorizada tiene estado 'activa_ahora' = True")

        # -------------------------------------------------------------
        # PASO 8: Módulo 3 — Emisión de PIN OTP Temporal
        # -------------------------------------------------------------
        log_step(8, "Módulo 3: Emisión de PIN Temporal OTP (6 dígitos, 5 min)")
        code, resp = api_request("otp_solicitar.php", "POST", {"id_aula": test_aula_id}, token=docente_token)
        assert_true(code == 200, f"Código OTP generado exitosamente: HTTP 200 OK")
        generated_otp_code = resp.get("data", {}).get("codigo")
        assert_true(len(generated_otp_code) == 6 and generated_otp_code.isdigit(),
                    f"PIN de 6 dígitos numéricos emitido: [{generated_otp_code}]")
        assert_true(resp.get("data", {}).get("vigencia_min") == 5, "Vigencia estricta de 5 minutos configurada")

        # Verificación directa en MariaDB de la inserción del OTP
        sql_otp = f"SELECT codigo, usado, expira_en > NOW() as vigente FROM otp_codigos WHERE codigo = '{generated_otp_code}' AND id_aula = {test_aula_id} ORDER BY id_otp DESC LIMIT 1;"
        res_otp = query_mariadb(sql_otp)
        assert_true(generated_otp_code in res_otp and "1" in res_otp, "OTP registrado en MariaDB en estado no usado y vigente")

        # -------------------------------------------------------------
        # PASO 9: Desbloqueo Físico IoT (Cerradura) y Bitácora
        # -------------------------------------------------------------
        log_step(9, "Simulación IoT: Apertura Física de Cerradura con Código OTP")
        code, resp = api_request("cerradura_abrir.php", "POST", {
            "id_aula": test_aula_id,
            "codigo": generated_otp_code
        })
        assert_true(code == 200, f"Cerradura IoT procesó el PIN: HTTP 200 OK")
        assert_true(resp.get("data", {}).get("abierta") is True, f"Puerta abierta con éxito: {resp.get('data', {}).get('mensaje')}")

        # Comprobación inmediata en MariaDB del acceso exitoso
        sql_acceso_ok = f"""
            SELECT id_usuario, id_aula, tipo_acceso, resultado, detalle 
            FROM accesos 
            WHERE id_aula = {test_aula_id} AND id_usuario = {docente_id} AND tipo_acceso = 'otp' AND resultado = 'exitoso'
            ORDER BY id_acceso DESC LIMIT 1;
        """
        res_acceso_ok = query_mariadb(sql_acceso_ok)
        assert_true("exitoso" in res_acceso_ok, "Bitácora en MariaDB registra evento 'exitoso'")

        # -------------------------------------------------------------
        # PASO 10: Prueba de Seguridad Anti-Replay (Reutilización de OTP)
        # -------------------------------------------------------------
        log_step(10, "Seguridad: Intento de Reutilización del Código OTP (Anti-Replay)")
        code, resp = api_request("cerradura_abrir.php", "POST", {
            "id_aula": test_aula_id,
            "codigo": generated_otp_code
        })
        assert_true(code == 409, f"Cerradura rechazó el código ya utilizado: HTTP 409 Conflict ({resp.get('error')})")

        # Comprobación en MariaDB del registro de rechazo
        sql_acceso_den = f"""
            SELECT id_usuario, id_aula, tipo_acceso, resultado, detalle 
            FROM accesos 
            WHERE id_aula = {test_aula_id} AND id_usuario = {docente_id} AND tipo_acceso = 'otp' AND resultado = 'denegado'
            ORDER BY id_acceso DESC LIMIT 1;
        """
        res_acceso_den = query_mariadb(sql_acceso_den)
        assert_true("denegado" in res_acceso_den, "Bitácora en MariaDB registra intento denegado por código ya utilizado")

        # -------------------------------------------------------------
        # PASO 11: Comprobación Bidireccional en MariaDB (Estado de OTP y Bitácora)
        # -------------------------------------------------------------
        log_step(11, "Auditoría en MariaDB: Verificación de Inserción y Marcado de OTP")
        # Verificar que el OTP ahora está marcado como usado en MariaDB
        sql_usado = f"SELECT usado FROM otp_codigos WHERE codigo = '{generated_otp_code}' AND id_aula = {test_aula_id};"
        res_usado = query_mariadb(sql_usado)
        assert_true("1" in res_usado, "MariaDB confirma OTP marcado como usado = 1 y quemado")

        # -------------------------------------------------------------
        # PASO 12: Comprobación de Auditoría vía API REST (api/accesos.php)
        # -------------------------------------------------------------
        log_step(12, "Auditoría API: Verificación en Endpoint /api/accesos.php")
        code, resp = api_request("accesos.php", "GET", token=docente_token)
        assert_true(code == 200, "Endpoint de accesos responde HTTP 200")
        historial = resp.get("data", {}).get("accesos", [])
        ultimo_evento = historial[0] if historial else {}
        assert_true(ultimo_evento.get("resultado") == "exitoso", "Último evento en API es 'exitoso'")
        assert_true("A-201" in ultimo_evento.get("aula", ""), f"Aula registrada en bitácora coincide: {ultimo_evento.get('aula')}")

        # -------------------------------------------------------------
        # PASO 13: Comprobación de Métricas en Vivo en Dashboard Admin
        # -------------------------------------------------------------
        log_step(13, "Métricas Dashboard: Verificación de KPIs en Vivo")
        code, resp = api_request("admin_stats.php", "GET", token=admin_token)
        assert_true(code == 200, "Métricas del Dashboard obtenidas (HTTP 200)")
        stats = resp.get("data", {}).get("stats", {})
        assert_true(stats.get("accesos_hoy", 0) > 0, f"Accesos hoy reflejados en dashboard: {stats.get('accesos_hoy')}")
        assert_true(stats.get("accesos_exitosos_hoy", 0) > 0, f"Accesos exitosos hoy: {stats.get('accesos_exitosos_hoy')}")

    except Exception as e:
        print(f"\n{RED}{BOLD}ERROR FATAL EN SUITE E2E: {e}{RESET}")
    finally:
        # -------------------------------------------------------------
        # LIMPIEZA IDEMPOTENTE
        # -------------------------------------------------------------
        log_step("FINAL", "Limpieza Idempotente de Registros Temporales de Prueba")
        if created_solicitud_id:
            query_mariadb(f"DELETE FROM solicitudes_aulas WHERE id_solicitud = {created_solicitud_id};")
            print(f"  {CYAN}• Solicitud temporal #{created_solicitud_id} eliminada.{RESET}")
        if generated_otp_code:
            query_mariadb(f"DELETE FROM otp_codigos WHERE codigo = '{generated_otp_code}' AND id_aula = {test_aula_id};")
            print(f"  {CYAN}• Código OTP temporal [{generated_otp_code}] eliminado.{RESET}")

    # RESUMEN FINAL
    log_header("RESUMEN DE RESULTADOS — SUITE E2E AULASYNC")
    total = passed_tests + failed_tests
    print(f"Total de Aserciones: {total}")
    print(f"{GREEN}Pruebas Aprobadas:  {passed_tests}{RESET}")
    print(f"{RED}Pruebas Fallidas:   {failed_tests}{RESET}")
    success_rate = (passed_tests / total * 100) if total > 0 else 0
    print(f"Tasa de Éxito:       {BOLD}{success_rate:.1f}%{RESET}")

    if failed_tests == 0:
        print(f"\n{GREEN}{BOLD}>>> TODAS LAS PRUEBAS E2E PASARON SATISFACTORIAMENTE (100% OPERATIVO) <<<{RESET}\n")
        return 0
    else:
        print(f"\n{RED}{BOLD}>>> SE DETECTARON FALLOS EN LA SUITE E2E <<<{RESET}\n")
        return 1

if __name__ == "__main__":
    sys.exit(run_e2e_suite())
