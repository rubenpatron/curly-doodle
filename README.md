# AulaSync — Sistema de Aulas Inteligentes Biométricas (UTM)

Sistema administrativo Web y Móvil para la gestión de aulas, horarios, solicitudes de espacios y control de acceso mediante cerraduras inteligentes IoT, tokens de sesión y contraseñas seguras con hash bcrypt.

**Asignatura:** Programación de Redes  
**Profesor:** Dr. Aurelio Mex Mex  
**Carrera:** TSU en Infraestructura de Redes Digitales (4° Cuatrimestre) — UTM  
**Equipo:** Edgar Patron, Valeria Almeida, Juan Aké y Kevin Ehrenzweig  

---

## Estructura Organizada del Proyecto

```text
Nueva carpeta/
├── api/                    # Backend API REST en PHP (Arquitectura MVC liviana)
│   ├── auth_login.php      # Login local con validación de contraseña bcrypt
│   ├── auth_google.php     # Autenticación con Google Identity Services
│   ├── carga_academica.php # CRUD completo Módulo 1 (Horarios y Carga)
│   ├── solicitudes.php     # CRUD completo Módulo 2 (Solicitudes de aulas)
│   ├── solicitud_responder.php # Aprobación/Rechazo de solicitudes
│   ├── aulas.php           # CRUD completo Módulo 3 (Aulas y Espacios)
│   ├── otp_solicitar.php   # Generación de PIN temporal OTP (5 min)
│   ├── cerradura_abrir.php # Simulación de apertura IoT y bitácora
│   ├── helpers.php         # Validadores estrictos y autenticación (Sesión/Bearer)
│   └── ...
├── css/                    # Estilos visuales (Bootstrap 5, FontAwesome, SaaS UI)
├── js/                     # Controladores frontend (api.js, dashboard_api.js)
├── images/                 # Recursos gráficos y fondos
├── docs/                   # Documentación técnica e investigación
│   ├── FASE1_DISENO_BD.md  # Especificación de la Fase 1 y diccionario
│   ├── ORGANIGRAMA_Y_MINUTAS.md # Plan de trabajo por sesiones
│   └── investigacion_aulasync.pdf # Documento formal de investigación
├── reporte/                # Reportes oficiales imprimibles para evaluación
│   ├── FASE1_Reporte.pdf   # Reporte visual de Fase 1 (Base de Datos)
│   ├── FASE1_Reporte.html  # Versión HTML del reporte de Fase 1
│   ├── ORGANIGRAMA_Y_MINUTAS_SESIONES.pdf  # PDF oficial de sesiones y firmas
│   └── ORGANIGRAMA_Y_MINUTAS_SESIONES.html # Fuente HTML del organigrama
├── postman/                # Colección de pruebas de endpoints
│   └── AulaSync_API.postman_collection.json # Colección Postman v2.1
├── sql/                    # Base de datos relacional MariaDB
│   ├── schema.sql          # Creación de 13 tablas, 20 FK, CHECK y datos de prueba
│   ├── verificacion_fase1.sql # Consultas de comprobación
│   └── diagrama_er_aulasync.* # Diagrama Entidad-Relación (Draw.io, PNG, SVG, MMD)
├── *.html                  # Plataforma Web administrativa (Dashboard, Horarios, Solicitudes, Login)
└── README.md
```

---

## Puesta en Marcha con XAMPP

1. Iniciar **Apache** y **MySQL/MariaDB** desde el panel de control de XAMPP.
2. La base de datos `aulas_inteligentes` ya se encuentra importada con 13 tablas y datos de prueba:
   * **Admin:** `admin@universidad.edu` | Contraseña: `admin123`
   * **Docente:** `usuario@universidad.edu` | Contraseña: `usuario123`
   * **Docente titular:** `juan.perez@universidad.edu` | Contraseña: `docente123`
3. El proyecto está enlazado directamente a Apache en:
   * **URL Web:** [http://localhost/aulasync/login.html](http://localhost/aulasync/login.html)
   * **URL Alternativa:** [http://localhost/aulasync/dashboard.html](http://localhost/aulasync/dashboard.html)
4. Todas las llamadas a la API REST son relativas (`/api/...`) y compatibles tanto con sesiones de navegador web como con **Bearer Tokens** para clientes móviles o Postman.
