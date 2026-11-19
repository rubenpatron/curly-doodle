# 🚀 AulaSync — Guía Rápida de Pruebas en Postman (Cheat Sheet)

Guía práctica con ejemplos de peticiones, URLs limpias y cuerpos JSON listos para copiar y pegar en Postman durante la clase de **Programación de Redes**.

* **Servidor Base Local:** `http://localhost/aulasync/api`
* **Cabecera Obligatoria para JSON:** `Content-Type: application/json`
* **Cabecera para Endpoints Protegidos:** `Authorization: Bearer <TOKEN_DE_SESION>`

---

## 📌 1. Autenticación y Usuarios

### 1.1 Iniciar Sesión como Administrador (200 OK)
* **Método:** `POST`
* **URL:** `http://localhost/aulasync/api/login` (o `http://localhost/aulasync/api/auth_login.php`)
* **Headers:** `Content-Type: application/json`
* **Body (`raw` -> `JSON`):**
```json
{
  "email": "admin@universidad.edu",
  "password": "admin123"
}
```
> **Nota:** Copia el campo `"token"` de la respuesta para usarlo en el header `Authorization: Bearer <token>` de las demás peticiones.

---

### 1.2 Iniciar Sesión como Docente / Usuario Estándar (200 OK)
* **Método:** `POST`
* **URL:** `http://localhost/aulasync/api/login`
* **Headers:** `Content-Type: application/json`
* **Body (`raw` -> `JSON`):**
```json
{
  "email": "usuario@universidad.edu",
  "password": "usuario123"
}
```

---

### 1.3 Registrar / Añadir Nuevo Usuario con Contraseña Bcrypt (201 Created)
* **Método:** `POST`
* **URL:** `http://localhost/aulasync/api/usuarios`
* **Headers:** `Content-Type: application/json`
* **Body (`raw` -> `JSON`):**
```json
{
  "nombre": "Dr. Aurelio Mex Mex",
  "email": "aurelio.mex@universidad.edu",
  "password": "password123",
  "matricula": "DOC-100",
  "id_rol": 2
}
```
*(Nota: `id_rol`: 1 = Administrador, 2 = Docente / Usuario).*

---

### 1.4 Consultar Perfil del Token Actual (200 OK)
* **Método:** `GET`
* **URL:** `http://localhost/aulasync/api/me`
* **Headers:** `Authorization: Bearer <TOKEN>`
* **Body:** `none`

---

### 1.5 Listar Todos los Usuarios (200 OK)
* **Método:** `GET`
* **URL:** `http://localhost/aulasync/api/usuarios`
* **Body:** `none`

---

## 📌 2. Módulo 1 — Horarios y Carga Académica

### 2.1 Listar Carga Académica Completa (200 OK)
* **Método:** `GET`
* **URL:** `http://localhost/aulasync/api/carga_academica`
* **Body:** `none`

---

### 2.2 Consultar Horario Propio del Docente Autenticado (200 OK)
* **Método:** `GET`
* **URL:** `http://localhost/aulasync/api/horarios`
* **Headers:** `Authorization: Bearer <TOKEN_DOCENTE>`
* **Body:** `none`

---

### 2.3 Asignar Nueva Clase / Horario (201 Created)
* **Método:** `POST`
* **URL:** `http://localhost/aulasync/api/carga_academica`
* **Headers:** 
  - `Content-Type: application/json`
  - `Authorization: Bearer <TOKEN_ADMIN>`
* **Body (`raw` -> `JSON`):**
```json
{
  "id_docente": 1,
  "id_materia": 2,
  "id_aula": 3,
  "dia_semana": 3,
  "hora_inicio": "11:50:00",
  "hora_fin": "13:30:00",
  "grupo": "4A-IRD",
  "periodo": "2026-3"
}
```

---

### 2.4 Modificar Asignación de Horario (PUT 200 OK)
* **Método:** `PUT`
* **URL:** `http://localhost/aulasync/api/carga_academica?id=1`
* **Headers:** `Content-Type: application/json`
* **Body (`raw` -> `JSON`):**
```json
{
  "hora_inicio": "08:00:00",
  "hora_fin": "09:40:00"
}
```

---

### 2.5 Eliminar Asignación de Horario (DELETE 200 OK)
* **Método:** `DELETE`
* **URL:** `http://localhost/aulasync/api/carga_academica?id=25`
* **Headers:** `Authorization: Bearer <TOKEN_ADMIN>`
* **Body:** `none`

---

## 📌 3. Módulo 2 — Solicitudes de Aulas

### 3.1 Listar Solicitudes (200 OK)
* **Método:** `GET`
* **URL:** `http://localhost/aulasync/api/solicitudes`
* **Headers:** `Authorization: Bearer <TOKEN>`
* **Body:** `none`

---

### 3.2 Crear Solicitud de Aula Adicional (201 Created)
* **Método:** `POST`
* **URL:** `http://localhost/aulasync/api/solicitudes`
* **Headers:** 
  - `Content-Type: application/json`
  - `Authorization: Bearer <TOKEN_DOCENTE>`
* **Body (`raw` -> `JSON`):**
```json
{
  "tipo_solicitud": "aula_adicional",
  "id_materia": 1,
  "id_aula_solicitada": 2,
  "fecha_uso": "2026-11-20",
  "hora_inicio": "09:00:00",
  "hora_fin": "10:40:00",
  "motivo": "Examen de recuperación de Programación de Redes"
}
```

---

### 3.3 Crear Solicitud de Cambio de Aula (201 Created)
* **Método:** `POST`
* **URL:** `http://localhost/aulasync/api/solicitudes`
* **Headers:** `Content-Type: application/json`
* **Body (`raw` -> `JSON`):**
```json
{
  "tipo_solicitud": "cambio_aula",
  "id_materia": 1,
  "id_aula_original": 1,
  "id_aula_solicitada": 6,
  "fecha_uso": "2026-11-21",
  "hora_inicio": "11:50:00",
  "hora_fin": "13:30:00",
  "motivo": "Requerimiento de computadoras de laboratorio para práctica"
}
```

---

### 3.4 Aprobar Solicitud de Aula por el Administrador (200 OK)
* **Método:** `POST`
* **URL:** `http://localhost/aulasync/api/solicitudes/responder` (o `http://localhost/aulasync/api/solicitud_responder.php`)
* **Headers:** 
  - `Content-Type: application/json`
  - `Authorization: Bearer <TOKEN_ADMIN>`
* **Body (`raw` -> `JSON`):**
```json
{
  "id_solicitud": 1,
  "accion": "aprobar",
  "comentarios": "Aprobado por jefatura de carrera para práctica de laboratorio."
}
```

---

### 3.5 Rechazar Solicitud de Aula (200 OK)
* **Método:** `POST`
* **URL:** `http://localhost/aulasync/api/solicitudes/responder`
* **Headers:** `Content-Type: application/json`
* **Body (`raw` -> `JSON`):**
```json
{
  "id_solicitud": 2,
  "accion": "rechazar",
  "comentarios": "El espacio solicitado ya se encuentra reservado para mantenimiento."
}
```

---

## 📌 4. Módulo 3 — Aulas, Cerraduras IoT y Apertura con OTP

### 4.1 Listar Catálogo de 30 Aulas Físicas (200 OK)
* **Método:** `GET`
* **URL:** `http://localhost/aulasync/api/aulas`
* **Body:** `none`

---

### 4.2 Listar Aulas Autorizadas del Docente (200 OK)
* **Método:** `GET`
* **URL:** `http://localhost/aulasync/api/aulas/autorizadas` (o `http://localhost/aulasync/api/aulas_autorizadas.php`)
* **Headers:** `Authorization: Bearer <TOKEN_DOCENTE>`
* **Body:** `none`

---

### 4.3 Generar PIN Temporal OTP de 6 Dígitos (200 OK)
* **Método:** `POST`
* **URL:** `http://localhost/aulasync/api/otp` (o `http://localhost/aulasync/api/otp_solicitar.php`)
* **Headers:** 
  - `Content-Type: application/json`
  - `Authorization: Bearer <TOKEN_DOCENTE>`
* **Body (`raw` -> `JSON`):**
```json
{
  "id_aula": 2
}
```
> **Respuesta:** Devuelve el PIN de 6 dígitos numéricos (ej. `"codigo": "748291"`) con vigencia estricta de 5 minutos.

---

### 4.4 Abrir Cerradura Digital IoT con el PIN Generado (200 OK)
* **Método:** `POST`
* **URL:** `http://localhost/aulasync/api/cerradura/abrir` (o `http://localhost/aulasync/api/cerradura_abrir.php`)
* **Headers:** `Content-Type: application/json`
* **Body (`raw` -> `JSON`):**
```json
{
  "id_aula": 2,
  "codigo_otp": "748291"
}
```
> **Respuesta:** `{"ok": true, "data": {"mensaje": "Acceso concedido. Puerta abierta.", "estado": "abierta"}}`. Inserta automáticamente el registro en la tabla `accesos` de MariaDB.

---

### 4.5 Apertura / Cierre Remoto Administrativo de Aula (200 OK)
* **Método:** `POST`
* **URL:** `http://localhost/aulasync/api/nodos/control` (o `http://localhost/aulasync/api/nodo_control.php`)
* **Headers:** 
  - `Content-Type: application/json`
  - `Authorization: Bearer <TOKEN_ADMIN>`
* **Body (`raw` -> `JSON`):**
```json
{
  "id_aula": 1,
  "accion": "abrir"
}
```
*(Para cerrar o bloquear, cambiar `"accion": "cerrar"` o `"accion": "bloquear"`).*

---

### 4.6 Dar de Alta Nueva Aula Física (201 Created)
* **Método:** `POST`
* **URL:** `http://localhost/aulasync/api/aulas`
* **Headers:** `Content-Type: application/json`
* **Body (`raw` -> `JSON`):**
```json
{
  "codigo": "G-101",
  "capacidad": 35,
  "tipo": "laboratorio",
  "id_edificio": 5
}
```

---

## 📌 5. Módulo 4 — Dashboard, Telemetría y Bitácora

### 5.1 Métricas y KPIs en Vivo del Dashboard (200 OK)
* **Método:** `GET`
* **URL:** `http://localhost/aulasync/api/dashboard` (o `http://localhost/aulasync/api/admin_stats.php`)
* **Headers:** `Authorization: Bearer <TOKEN_ADMIN>`
* **Body:** `none`

---

### 5.2 Feed de Telemetría IoT en Vivo (200 OK)
* **Método:** `GET`
* **URL:** `http://localhost/aulasync/api/telemetria`
* **Body:** `none`

---

### 5.3 Bitácora Histórica de Accesos (200 OK)
* **Método:** `GET`
* **URL:** `http://localhost/aulasync/api/accesos`
* **Headers:** `Authorization: Bearer <TOKEN_ADMIN>`
* **Body:** `none`

---

## ⚠️ 6. Casos de Prueba de Errores (Demostración de Rúbrica)

Para demostrarle al Dr. Aurelio Mex Mex el manejo estricto de códigos HTTP y validaciones de seguridad:

| Caso de Prueba | Método | URL | Body JSON / Header | Código Esperado | Mensaje / Razón |
|---|:---:|---|---|:---:|---|
| **Contraseña Errónea** | `POST` | `/api/login` | `{"email":"admin@universidad.edu","password":"MAL"}` | **`401 Unauthorized`** | `"Credenciales incorrectas."` (Bcrypt) |
| **Sin Token en Privado** | `GET` | `/api/dashboard` | *Sin header Authorization* | **`401 Unauthorized`** | `"Se requiere token de autenticación."` |
| **PIN Erróneo en Cerradura** | `POST` | `/api/cerradura/abrir` | `{"id_aula":1,"codigo_otp":"000000"}` | **`401 Unauthorized`** | `"Código OTP incorrecto o expirado."` |
| **Reuso de PIN (Anti-Replay)** | `POST` | `/api/cerradura/abrir` | *(Enviar el mismo PIN dos veces)* | **`409 Conflict`** | `"Ese código ya fue utilizado."` |
| **Colisión de Horario en Aula** | `POST` | `/api/carga_academica` | *(Misma aula y horario solapado)* | **`409 Conflict`** | `"Conflicto de aula: ya existe una clase en ese horario."` |
| **Aula Duplicada** | `POST` | `/api/aulas` | `{"codigo":"A-101","capacidad":30}` | **`409 Conflict`** | `"Ya existe un aula con el código A-101."` |
| **Docente sin Permiso Admin** | `POST` | `/api/carga_academica` | *(Con token de docente)* | **`403 Forbidden`** | `"Acceso denegado: se requiere rol de administrador."` |
| **Horas Invertidas** | `POST` | `/api/solicitudes` | `{"hora_inicio":"14:00","hora_fin":"10:00",...}` | **`422 Unprocessable`** | `"La hora_fin debe ser posterior a la hora_inicio."` |
| **Motivo Demasiado Corto** | `POST` | `/api/solicitudes` | `{"motivo":"ok",...}` | **`422 Unprocessable`** | `"El campo 'motivo' debe tener al menos 3 caracteres."` |
| **Correo Malformado** | `POST` | `/api/usuarios` | `{"email":"correo_invalido",...}` | **`422 Unprocessable`** | `"El correo electrónico no tiene un formato válido."` |

---

### 💡 Atajo en Consola (Ejecutar las 43 pruebas en 2 segundos):
```powershell
python tests/test_api_suite.py
```
