#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
=============================================================================
 AulaSync — Suite de Pruebas Automatizadas de API REST (Sesión 4)
 Rúbrica de Evaluación del Dr. Aurelio:
   - 200 OK (Listados, autenticación exitosa, consultas y apertura)
   - 201 Created (Nuevas solicitudes, asignación de horarios, nuevas aulas)
   - 401 Unauthorized (Peticiones sin token, token inválido o credenciales erróneas)
   - 403 Forbidden (Acceso denegado por rol o fuera de horario académico)
   - 409 Conflict (Colisión de horarios de aula, duplicados o estados terminales)
   - 422 Unprocessable Entity (Faltan campos, formato inválido, horas invertidas)
=============================================================================
"""

import sys
import json
import time
import urllib.request
import urllib.error
from typing import Tuple, Dict, Any, Optional

BASE_URL = "http://localhost/aulasync/api"

# ANSI Colors for terminal output
GREEN = "\033[92m"
RED = "\033[91m"
YELLOW = "\033[93m"
BLUE = "\033[94m"
CYAN = "\033[96m"
BOLD = "\033[1m"
RESET = "\033[0m"


class ApiTestRunner:
    def __init__(self, base_url: str = BASE_URL):
        self.base_url = base_url.rstrip("/")
        self.total = 0
        self.passed = 0
        self.failed = 0
        self.results = []
        self.code_counts = {200: 0, 201: 0, 401: 0, 403: 0, 409: 0, 422: 0}
        self.admin_token = ""
        self.docente_token = ""
        self.created_ids = {
            "carga_academica": [],
            "solicitudes": [],
            "aulas": []
        }

    def request(
        self,
        endpoint: str,
        method: str = "GET",
        data: Optional[Dict[str, Any]] = None,
        token: Optional[str] = None
    ) -> Tuple[int, Dict[str, Any]]:
        """Ejecuta una petición HTTP contra la API REST."""
        url = f"{self.base_url}/{endpoint.lstrip('/')}"
        headers = {"Content-Type": "application/json; charset=utf-8"}
        if token:
            headers["Authorization"] = f"Bearer {token}"

        body = json.dumps(data).encode("utf-8") if data is not None else None
        req = urllib.request.Request(url, data=body, headers=headers, method=method)

        try:
            with urllib.request.urlopen(req, timeout=10) as resp:
                status = resp.status
                raw = resp.read().decode("utf-8")
                try:
                    payload = json.loads(raw)
                except Exception:
                    payload = {"raw": raw}
                return status, payload
        except urllib.error.HTTPError as e:
            status = e.code
            raw = e.read().decode("utf-8")
            try:
                payload = json.loads(raw)
            except Exception:
                payload = {"raw": raw}
            return status, payload
        except Exception as ex:
            return 0, {"error": str(ex)}

    def assert_case(
        self,
        name: str,
        expected_status: int,
        endpoint: str,
        method: str = "GET",
        data: Optional[Dict[str, Any]] = None,
        token: Optional[str] = None,
        check_fn: Optional[callable] = None
    ) -> Dict[str, Any]:
        """Ejecuta y valida un caso de prueba contra el código HTTP esperado."""
        self.total += 1
        t0 = time.time()
        status, resp = self.request(endpoint, method, data, token)
        elapsed_ms = int((time.time() - t0) * 1000)

        ok = (status == expected_status)
        if ok and check_fn:
            try:
                ok = bool(check_fn(resp))
            except Exception:
                ok = False

        if ok:
            self.passed += 1
            if expected_status in self.code_counts:
                self.code_counts[expected_status] += 1
            print(f"  {GREEN}✔ [{status} {self._status_text(status)}]{RESET} {name} {CYAN}({elapsed_ms}ms){RESET}")
        else:
            self.failed += 1
            err_msg = resp.get("error") if isinstance(resp, dict) else str(resp)
            print(f"  {RED}✘ [{status} vs exp {expected_status}]{RESET} {name} {YELLOW}→ {err_msg}{RESET}")

        record = {
            "name": name,
            "endpoint": endpoint,
            "method": method,
            "expected": expected_status,
            "actual": status,
            "passed": ok,
            "elapsed_ms": elapsed_ms,
            "response": resp
        }
        self.results.append(record)
        return resp

    def _status_text(self, code: int) -> str:
        texts = {
            200: "OK",
            201: "Created",
            400: "Bad Request",
            401: "Unauthorized",
            403: "Forbidden",
            404: "Not Found",
            409: "Conflict",
            422: "Unprocessable"
        }
        return texts.get(code, str(code))

    # =========================================================================
    # SUITE DE PRUEBAS
    # =========================================================================

    def run_all(self):
        print(f"\n{BOLD}{CYAN}====================================================================={RESET}")
        print(f"{BOLD}{CYAN}      AULASYNC — SUITE DE VALIDACIÓN AUTOMATIZADA DE API REST         {RESET}")
        print(f"{CYAN}      Objetivo: Validación Integral de Códigos HTTP (Rúbrica Dr. Aurelio){RESET}")
        print(f"{BOLD}{CYAN}====================================================================={RESET}\n")

        start_time = time.time()

        self.test_modulo_0_auth()
        self.test_modulo_1_horarios()
        self.test_modulo_2_solicitudes()
        self.test_modulo_3_aulas_iot()
        self.test_modulo_4_dashboard()

        self.cleanup()

        total_time = round(time.time() - start_time, 2)
        self.print_summary(total_time)

    # -------------------------------------------------------------------------
    # 0. Autenticación y Seguridad de Acceso
    # -------------------------------------------------------------------------
    def test_modulo_0_auth(self):
        print(f"{BOLD}{BLUE}▶ MÓDULO 0: Autenticación, Sesión y Control de Acceso (Bcrypt/Token){RESET}")

        # 200 OK: Login Admin exitoso
        resp_admin = self.assert_case(
            "Login Exitoso como Administrador (admin@universidad.edu)",
            200, "auth_login.php", "POST",
            {"email": "admin@universidad.edu", "password": "admin123"},
            check_fn=lambda r: r.get("ok") and "token" in r.get("data", {})
        )
        if resp_admin.get("ok"):
            self.admin_token = resp_admin["data"]["token"]

        # 200 OK: Login Docente exitoso
        resp_doc = self.assert_case(
            "Login Exitoso como Docente (usuario@universidad.edu)",
            200, "auth_login.php", "POST",
            {"email": "usuario@universidad.edu", "password": "usuario123"},
            check_fn=lambda r: r.get("ok") and "token" in r.get("data", {})
        )
        if resp_doc.get("ok"):
            self.docente_token = resp_doc["data"]["token"]

        # 200 OK: Validar sesión del token actual (/me)
        self.assert_case(
            "Consultar Usuario Actual con Bearer Token (/me.php)",
            200, "me.php", "GET", token=self.admin_token,
            check_fn=lambda r: r.get("data", {}).get("autenticado") is True
        )

        # 401 Unauthorized: Login con contraseña incorrecta
        self.assert_case(
            "Login Rechazado: Contraseña Inválida (Bcrypt Verify)",
            401, "auth_login.php", "POST",
            {"email": "admin@universidad.edu", "password": "password_incorrecto_123"},
            check_fn=lambda r: r.get("ok") is False
        )

        # 401 Unauthorized: Login con cuenta inexistente
        self.assert_case(
            "Login Rechazado: Correo Institucional No Registrado",
            401, "auth_login.php", "POST",
            {"email": "no_existe_999@universidad.edu", "password": "password123"},
            check_fn=lambda r: r.get("ok") is False
        )

        # 401 Unauthorized: Acceso a endpoint privado sin Header Authorization
        self.assert_case(
            "Rechazo por Falta de Token en Endpoint Privado (admin_stats.php)",
            401, "admin_stats.php", "GET",
            check_fn=lambda r: r.get("ok") is False
        )

        # 401 Unauthorized: Acceso con Bearer Token falso o vencido
        self.assert_case(
            "Rechazo con Bearer Token Inválido o Modificado",
            401, "admin_stats.php", "GET", token="token_falso_invalido_xyz1234567890",
            check_fn=lambda r: r.get("ok") is False
        )

        # 422 Unprocessable Entity: Login con correo en formato inválido
        self.assert_case(
            "Validación Fallida: Formato de Correo Malformado",
            422, "auth_login.php", "POST",
            {"email": "correo-sin-arroba", "password": "admin123"},
            check_fn=lambda r: r.get("ok") is False
        )

        # 422 Unprocessable Entity: Login sin contraseña obligatoria
        self.assert_case(
            "Validación Fallida: Falta Campo Obligatorio 'password'",
            422, "auth_login.php", "POST",
            {"email": "admin@universidad.edu"},
            check_fn=lambda r: r.get("ok") is False
        )
        print()

    # -------------------------------------------------------------------------
    # 1. Módulo Horarios y Carga Académica
    # -------------------------------------------------------------------------
    def test_modulo_1_horarios(self):
        print(f"{BOLD}{BLUE}▶ MÓDULO 1: Horarios Académicos y Gestión de Aulas (CRUD + Conflictos){RESET}")

        # 200 OK: Listar clases de la carga académica (Admin)
        self.assert_case(
            "Listar Carga Académica Completa desde MariaDB",
            200, "carga_academica.php", "GET", token=self.admin_token,
            check_fn=lambda r: "clases" in r.get("data", {})
        )

        # 200 OK: Consultar horario propio del docente autenticado
        self.assert_case(
            "Consultar Horario Semanal Propio del Docente (/horarios.php)",
            200, "horarios.php", "GET", token=self.docente_token,
            check_fn=lambda r: "horario" in r.get("data", {})
        )

        # 201 Created: Alta de nueva clase válida (Día 7 Domingo para no colisionar)
        new_class_data = {
            "id_usuario": 1,
            "id_materia": 2,
            "id_aula": 4,
            "dia_semana": 7,
            "hora_inicio": "14:00",
            "hora_fin": "16:00",
            "fecha_inicio": "2026-11-01",
            "fecha_fin": "2026-11-30"
        }
        res_class = self.assert_case(
            "Registrar Nueva Clase Académica (201 Created)",
            201, "carga_academica.php", "POST", new_class_data, token=self.admin_token,
            check_fn=lambda r: r.get("ok") and "id" in r.get("data", {})
        )
        if res_class.get("ok"):
            class_id = res_class["data"]["id"]
            self.created_ids["carga_academica"].append(class_id)

            # 200 OK: Actualizar la clase recién creada (PUT)
            update_data = {
                "id": class_id,
                "id_usuario": 1,
                "id_materia": 2,
                "id_aula": 4,
                "dia_semana": 7,
                "hora_inicio": "15:00",
                "hora_fin": "17:00",
                "fecha_inicio": "2026-11-01",
                "fecha_fin": "2026-11-30",
                "activo": 1
            }
            self.assert_case(
                "Actualizar Horario de Clase Existente (PUT 200 OK)",
                200, "carga_academica.php", "PUT", update_data, token=self.admin_token,
                check_fn=lambda r: r.get("ok")
            )

        # 409 Conflict: Detección estricta de traslape / colisión de horario en la misma aula
        # Aula A-101 (id 1) ya tiene clase activa los Jueves (dia 4) de 07:00 a 23:59
        collision_data = {
            "id_usuario": 1,
            "id_materia": 1,
            "id_aula": 1,
            "dia_semana": 4,
            "hora_inicio": "10:00",
            "hora_fin": "12:00",
            "fecha_inicio": "2026-11-01",
            "fecha_fin": "2026-11-30"
        }
        self.assert_case(
            "Detección de Conflicto: Colisión de Aula y Horario Existente (409 Conflict)",
            409, "carga_academica.php", "POST", collision_data, token=self.admin_token,
            check_fn=lambda r: r.get("ok") is False and "Conflicto" in r.get("error", "")
        )

        # 403 Forbidden: Docente intentando dar de alta horarios (rol no autorizado)
        self.assert_case(
            "Control de Roles: Docente Denegado al Intentar Asignar Horario (403)",
            403, "carga_academica.php", "POST", new_class_data, token=self.docente_token,
            check_fn=lambda r: r.get("ok") is False
        )

        # 422 Unprocessable Entity: Validación de horas invertidas (hora_fin <= hora_inicio)
        invalid_hours_data = {
            "id_usuario": 1,
            "id_materia": 1,
            "id_aula": 2,
            "dia_semana": 3,
            "hora_inicio": "12:00",
            "hora_fin": "10:00",
            "fecha_inicio": "2026-11-01",
            "fecha_fin": "2026-11-30"
        }
        self.assert_case(
            "Validación de Lógica Temporal: hora_fin Menor a hora_inicio (422)",
            422, "carga_academica.php", "POST", invalid_hours_data, token=self.admin_token,
            check_fn=lambda r: r.get("ok") is False
        )

        # 422 Unprocessable Entity: Fechas invertidas (fecha_fin < fecha_inicio)
        invalid_dates_data = {
            "id_usuario": 1,
            "id_materia": 1,
            "id_aula": 2,
            "dia_semana": 3,
            "hora_inicio": "10:00",
            "hora_fin": "12:00",
            "fecha_inicio": "2026-12-01",
            "fecha_fin": "2026-10-01"
        }
        self.assert_case(
            "Validación de Calendario: fecha_fin Menor a fecha_inicio (422)",
            422, "carga_academica.php", "POST", invalid_dates_data, token=self.admin_token,
            check_fn=lambda r: r.get("ok") is False
        )

        # 200 OK: Eliminación limpia de la clase de prueba creada
        if self.created_ids["carga_academica"]:
            del_id = self.created_ids["carga_academica"].pop()
            self.assert_case(
                f"Eliminar Clase de Prueba ID #{del_id} (DELETE 200 OK)",
                200, f"carga_academica.php?id={del_id}", "DELETE", token=self.admin_token,
                check_fn=lambda r: r.get("ok") and r.get("data", {}).get("eliminada") is True
            )
        print()

    # -------------------------------------------------------------------------
    # 2. Módulo Solicitudes de Aulas
    # -------------------------------------------------------------------------
    def test_modulo_2_solicitudes(self):
        print(f"{BOLD}{BLUE}▶ MÓDULO 2: Solicitudes de Aulas Excepcionales y Flujo de Aprobación{RESET}")

        # 200 OK: Listar solicitudes como Docente
        self.assert_case(
            "Listar Solicitudes del Docente Autenticado",
            200, "solicitudes.php", "GET", token=self.docente_token,
            check_fn=lambda r: "solicitudes" in r.get("data", {})
        )

        # 200 OK: Listar solicitudes como Admin filtradas por estado
        self.assert_case(
            "Listar Solicitudes Pendientes como Administrador",
            200, "solicitudes.php?estado=pendiente", "GET", token=self.admin_token,
            check_fn=lambda r: "solicitudes" in r.get("data", {})
        )

        # 201 Created: Crear nueva solicitud de aula adicional
        sol_data = {
            "tipo": "aula_adicional",
            "id_materia": 1,
            "id_aula_solicitada": 3,
            "fecha": "2026-11-25",
            "hora_inicio": "10:00",
            "hora_fin": "12:00",
            "motivo": "Examen de recuperación de programación",
            "justificacion": "Se necesita aula con computadoras adicionales"
        }
        res_sol = self.assert_case(
            "Crear Solicitud de Aula Adicional (201 Created)",
            201, "solicitudes.php", "POST", sol_data, token=self.docente_token,
            check_fn=lambda r: r.get("ok") and "id" in r.get("data", {})
        )

        sol_id = None
        if res_sol.get("ok"):
            sol_id = res_sol["data"]["id"]
            self.created_ids["solicitudes"].append(sol_id)

            # 200 OK: Modificar solicitud propia en estado pendiente (PUT)
            mod_data = {
                "id": sol_id,
                "tipo": "aula_adicional",
                "id_materia": 1,
                "id_aula_solicitada": 4,
                "fecha": "2026-11-25",
                "hora_inicio": "10:00",
                "hora_fin": "12:00",
                "motivo": "Examen de recuperación de programación (Aula corregida)",
                "justificacion": "Ajuste de laboratorio solicitado"
            }
            self.assert_case(
                "Modificar Solicitud en Estado Pendiente (PUT 200 OK)",
                200, "solicitudes.php", "PUT", mod_data, token=self.docente_token,
                check_fn=lambda r: r.get("ok")
            )

            # 200 OK: Administrador aprueba la solicitud
            resp_aprob = self.assert_case(
                "Administrador Aprueba Solicitud (solicitud_responder.php)",
                200, "solicitud_responder.php", "POST",
                {"id": sol_id, "accion": "aprobar", "comentarios": "Aprobado por jefatura académica"},
                token=self.admin_token,
                check_fn=lambda r: r.get("ok") and r.get("data", {}).get("estado") == "aprobada"
            )

            # 409 Conflict: Intentar responder nuevamente solicitud ya aprobada
            self.assert_case(
                "Conflicto de Estado: Solicitud ya Procesada (409 Conflict)",
                409, "solicitud_responder.php", "POST",
                {"id": sol_id, "accion": "rechazar", "comentarios": "Intento inválido"},
                token=self.admin_token,
                check_fn=lambda r: r.get("ok") is False and "ya fue procesada" in r.get("error", "")
            )

        # 422 Unprocessable Entity: Solicitud con motivo demasiado corto (< 3 caracteres)
        invalid_motivo = {
            "tipo": "aula_adicional",
            "id_materia": 1,
            "id_aula_solicitada": 2,
            "fecha": "2026-11-25",
            "hora_inicio": "10:00",
            "hora_fin": "12:00",
            "motivo": "ab"
        }
        self.assert_case(
            "Validación: Motivo Demasiado Corto (< 3 caracteres) (422)",
            422, "solicitudes.php", "POST", invalid_motivo, token=self.docente_token,
            check_fn=lambda r: r.get("ok") is False
        )

        # 422 Unprocessable Entity: Cambio de aula con aula_original igual a aula_solicitada
        invalid_same_room = {
            "tipo": "cambio_aula",
            "id_materia": 1,
            "id_aula_original": 2,
            "id_aula_solicitada": 2,
            "fecha": "2026-11-25",
            "hora_inicio": "10:00",
            "hora_fin": "12:00",
            "motivo": "Solicitud redundante"
        }
        self.assert_case(
            "Validación Cruzada: Aula Solicitada Idéntica a Original (422)",
            422, "solicitudes.php", "POST", invalid_same_room, token=self.docente_token,
            check_fn=lambda r: r.get("ok") is False
        )

        # 200 OK: Eliminación de solicitud de prueba
        if sol_id:
            self.assert_case(
                f"Eliminar Solicitud de Prueba ID #{sol_id} (DELETE 200 OK)",
                200, f"solicitudes.php?id={sol_id}", "DELETE", token=self.admin_token,
                check_fn=lambda r: r.get("ok") and r.get("data", {}).get("eliminada") is True
            )
            self.created_ids["solicitudes"].remove(sol_id)
        print()

    # -------------------------------------------------------------------------
    # 3. Módulo Aulas, Cerraduras y Simulación IoT
    # -------------------------------------------------------------------------
    def test_modulo_3_aulas_iot(self):
        print(f"{BOLD}{BLUE}▶ MÓDULO 3: Aulas Físicas, Cerraduras IoT y Apertura con OTP{RESET}")

        # 200 OK: Listar catálogo completo de aulas
        self.assert_case(
            "Listar Catálogo de Aulas Físicas (/aulas.php)",
            200, "aulas.php", "GET",
            check_fn=lambda r: len(r.get("data", {}).get("aulas", [])) > 0
        )

        # 200 OK: Listar nodos IoT / Cerraduras
        self.assert_case(
            "Listar Nodos IoT y Estado de Señal/Batería (/nodos.php)",
            200, "nodos.php", "GET",
            check_fn=lambda r: "nodos" in r.get("data", {})
        )

        # 200 OK: Listar aulas autorizadas del docente (identifica clase activa hoy)
        res_aut = self.assert_case(
            "Listar Aulas Autorizadas del Docente (/aulas_autorizadas.php)",
            200, "aulas_autorizadas.php", "GET", token=self.docente_token,
            check_fn=lambda r: "aulas" in r.get("data", {})
        )

        # 201 Created: Alta de aula nueva por Admin
        test_room_code = f"T-{int(time.time()) % 1000:03d}"
        new_room = {
            "codigo": test_room_code,
            "id_edificio": 1,
            "capacidad": 35,
            "tipo": "laboratorio",
            "estado": "disponible"
        }
        res_aula = self.assert_case(
            f"Registrar Nueva Aula Física '{test_room_code}' (201 Created)",
            201, "aulas.php", "POST", new_room, token=self.admin_token,
            check_fn=lambda r: r.get("ok") and "id" in r.get("data", {})
        )
        if res_aula.get("ok"):
            new_room_id = res_aula["data"]["id"]
            self.created_ids["aulas"].append(new_room_id)

            # 409 Conflict: Intentar registrar aula con código duplicado
            self.assert_case(
                f"Conflicto de Aula: Código Duplicado '{test_room_code}' (409 Conflict)",
                409, "aulas.php", "POST", new_room, token=self.admin_token,
                check_fn=lambda r: r.get("ok") is False and "ya se encuentra registrado" in r.get("error", "")
            )

            # 200 OK: Eliminar aula de prueba creada
            self.assert_case(
                f"Eliminar Aula de Prueba '{test_room_code}' (DELETE 200 OK)",
                200, f"aulas.php?id={new_room_id}", "DELETE", token=self.admin_token,
                check_fn=lambda r: r.get("ok") and r.get("data", {}).get("eliminada") is True
            )
            self.created_ids["aulas"].remove(new_room_id)

        # 403 Forbidden: Solicitar OTP para aula NO autorizada o fuera de horario
        self.assert_case(
            "Rechazo de OTP: Aula No Autorizada / Fuera de Ventana (403)",
            403, "otp_solicitar.php", "POST", {"id_aula": 10}, token=self.docente_token,
            check_fn=lambda r: r.get("ok") is False and "No tienes autorización" in r.get("error", "")
        )

        # Identificar aula activa hoy para generar OTP exitoso
        active_room_id = None
        if res_aut.get("ok"):
            for a in res_aut["data"]["aulas"]:
                if a.get("activa_ahora") is True:
                    active_room_id = a.get("id")
                    break
            if not active_room_id and res_aut["data"]["aulas"]:
                active_room_id = res_aut["data"]["aulas"][0]["id"]

        otp_code = None
        if active_room_id:
            # 200 OK: Generar código OTP válido para aula en horario activo
            res_otp = self.assert_case(
                f"Generar PIN OTP de 6 Dígitos para Aula #{active_room_id} (200 OK)",
                200, "otp_solicitar.php", "POST", {"id_aula": active_room_id}, token=self.docente_token,
                check_fn=lambda r: r.get("ok") and len(str(r.get("data", {}).get("codigo", ""))) == 6
            )
            if res_otp.get("ok"):
                otp_code = res_otp["data"]["codigo"]

                # 200 OK: Simulación IoT de apertura de cerradura tecleando el PIN OTP
                self.assert_case(
                    f"Apertura de Cerradura IoT con PIN '{otp_code}' (cerradura_abrir.php 200 OK)",
                    200, "cerradura_abrir.php", "POST",
                    {"id_aula": active_room_id, "codigo": otp_code},
                    check_fn=lambda r: r.get("ok") and r.get("data", {}).get("abierta") is True
                )

        # 401 Unauthorized: Intentar abrir cerradura con código OTP incorrecto
        self.assert_case(
            "Rechazo de Cerradura: Código OTP Erróneo o Expirado (401)",
            401, "cerradura_abrir.php", "POST",
            {"id_aula": active_room_id or 1, "codigo": "000000"},
            check_fn=lambda r: r.get("ok") is False
        )

        # 200 OK: Control Remoto Administrativo (Abrir puerta)
        self.assert_case(
            "Control Remoto Administrativo: Apertura de Aula (nodo_control.php)",
            200, "nodo_control.php", "POST",
            {"id_aula": active_room_id or 1, "accion": "abrir"}, token=self.admin_token,
            check_fn=lambda r: r.get("ok")
        )

        # 200 OK: Control Remoto Administrativo (Cerrar puerta - 'disponible')
        self.assert_case(
            "Control Remoto Administrativo: Cierre de Aula (nodo_control.php)",
            200, "nodo_control.php", "POST",
            {"id_aula": active_room_id or 1, "accion": "cerrar"}, token=self.admin_token,
            check_fn=lambda r: r.get("ok")
        )

        # 200 OK: Consultar bitácora de accesos y verificar registro generado
        self.assert_case(
            "Verificar Registro en Bitácora de MariaDB (/accesos.php)",
            200, "accesos.php?limite=5", "GET", token=self.admin_token,
            check_fn=lambda r: len(r.get("data", {}).get("accesos", [])) > 0
        )
        print()

    # -------------------------------------------------------------------------
    # 4. Dashboard y Métricas
    # -------------------------------------------------------------------------
    def test_modulo_4_dashboard(self):
        print(f"{BOLD}{BLUE}▶ MÓDULO 4: Dashboard General, Métricas y Telemetría en Vivo{RESET}")

        # 200 OK: Consultar estadísticas del sistema como Admin
        self.assert_case(
            "Consultar Métricas del Dashboard (admin_stats.php)",
            200, "admin_stats.php", "GET", token=self.admin_token,
            check_fn=lambda r: all(k in r.get("data", {}).get("stats", {}) for k in ["docentes", "aulas", "clases"])
        )

        # 200 OK: Consultar feed de telemetría IoT en vivo
        self.assert_case(
            "Consultar Feed de Telemetría IoT en Vivo (telemetria.php)",
            200, "telemetria.php?limite=10", "GET",
            check_fn=lambda r: "telemetria" in r.get("data", {})
        )

        # 403 Forbidden: Docente intentando consultar estadísticas del Admin
        self.assert_case(
            "Restricción de Privilegios: Docente Denegado a Estadísticas Admin (403)",
            403, "admin_stats.php", "GET", token=self.docente_token,
            check_fn=lambda r: r.get("ok") is False
        )
        print()

    # -------------------------------------------------------------------------
    # Limpieza de datos residuales
    # -------------------------------------------------------------------------
    def cleanup(self):
        """Elimina cualquier registro de prueba que haya quedado pendiente."""
        for cid in self.created_ids["carga_academica"]:
            try:
                self.request(f"carga_academica.php?id={cid}", "DELETE", token=self.admin_token)
            except Exception:
                pass
        for sid in self.created_ids["solicitudes"]:
            try:
                self.request(f"solicitudes.php?id={sid}", "DELETE", token=self.admin_token)
            except Exception:
                pass
        for aid in self.created_ids["aulas"]:
            try:
                self.request(f"aulas.php?id={aid}", "DELETE", token=self.admin_token)
            except Exception:
                pass

    # -------------------------------------------------------------------------
    # Reporte y Resumen de Ejecución
    # -------------------------------------------------------------------------
    def print_summary(self, total_time: float):
        print(f"{BOLD}{CYAN}====================================================================={RESET}")
        print(f"{BOLD}{CYAN}                RESUMEN DE PRUEBAS AUTOMATIZADAS                      {RESET}")
        print(f"{BOLD}{CYAN}====================================================================={RESET}")

        status_color = GREEN if self.failed == 0 else RED
        print(f"  Estado Global:       {status_color}{BOLD}{'APROBADO AL 100%' if self.failed == 0 else 'CON FALLOS'}{RESET}")
        print(f"  Total de Pruebas:    {self.total}")
        print(f"  Pruebas Exitosas:    {GREEN}{self.passed}{RESET}")
        print(f"  Pruebas Fallidas:    {RED if self.failed > 0 else GREEN}{self.failed}{RESET}")
        print(f"  Tiempo de Ejecución: {CYAN}{total_time} segundos{RESET}\n")

        print(f"{BOLD}  DISTRIBUCIÓN POR CÓDIGO HTTP (RÚBRICA DR. AURELIO):{RESET}")
        headers_info = [
            (200, "OK (Operaciones exitosas, consultas, apertura)", GREEN),
            (201, "Created (Nuevos registros en BD: horario, solicitud, aula)", GREEN),
            (401, "Unauthorized (Sin credenciales o PIN erróneo)", YELLOW),
            (403, "Forbidden (Fuera de horario o rol no autorizado)", YELLOW),
            (409, "Conflict (Colisión de horarios de aula y duplicados)", RED),
            (422, "Unprocessable Entity (Validaciones de tipo y horas invertidas)", RED),
        ]

        print("  ┌──────┬───────────────┬────────────────────────────────────────────────────────┐")
        print("  │ HTTP │  Verificadas  │ Rúbrica / Significado Académico                        │")
        print("  ├──────┼───────────────┼────────────────────────────────────────────────────────┤")
        for code, desc, color in headers_info:
            count = self.code_counts.get(code, 0)
            print(f"  │ {BOLD}{code}{RESET}  │      {color}{count:>2}{RESET}       │ {desc:<54} │")
        print("  └──────┴───────────────┴────────────────────────────────────────────────────────┘\n")

        if self.failed > 0:
            print(f"{RED}Pruebas fallidas detalladas:{RESET}")
            for r in self.results:
                if not r["passed"]:
                    print(f"  - {r['name']} (Esperado {r['expected']}, Obtenido {r['actual']})")
            sys.exit(1)
        else:
            print(f"{GREEN}{BOLD}✔ Todos los códigos de respuesta y reglas de negocio validados con éxito.{RESET}\n")


if __name__ == "__main__":
    runner = ApiTestRunner()
    runner.run_all()
