// ==========================================
// Integración con API v2.0 - Aulas Inteligentes
// Dashboard IoT Administrativo
// ==========================================

document.addEventListener('DOMContentLoaded', async () => {
    // 1. Validar sesión de Administrador
    try {
        const u = await apiExigirSesion('admin');
        const nameEl = document.getElementById('userName');
        const avatarEl = document.getElementById('userAvatar');
        if (nameEl) nameEl.textContent = u.nombre;
        if (avatarEl) {
            if (u.foto) {
                avatarEl.textContent = '';
                avatarEl.style.backgroundImage = `url('${u.foto}')`;
                avatarEl.style.backgroundSize = 'cover';
                avatarEl.style.backgroundPosition = 'center';
            } else {
                avatarEl.textContent = u.nombre.split(/\s+/).slice(0, 2).map(p => p[0] || '').join('').toUpperCase();
            }
        }
    } catch {
        // Redirigido automáticamente a login.html si no tiene sesión admin
        return;
    }

    // 2. Cargar datos iniciales
    loadKPIs();
    loadAulas('A');
    loadCerraduras('A');
    loadTelemetria();
    loadLogs();
    loadDocentes();

    // 3. Temporizadores de actualización en vivo
    setInterval(loadTelemetria, 10000); // Telemetría cada 10s
    setInterval(loadKPIs, 30000);       // KPIs cada 30s
});

// Selector de Edificio en el mapa
window.changeEdificio = function(edificio) {
    const titleEl = document.getElementById('mapTitle');
    if (titleEl) {
        titleEl.innerHTML = '<i class="fas fa-map me-2" style="color: var(--secondary);"></i>Plano Interactivo — Edificio ' + esc(edificio);
    }
    loadAulas(edificio);
};

// ==========================================
// 1. Cargar KPIs y Estadísticas en Vivo
// ==========================================
async function loadKPIs() {
    try {
        const [statsData, nodosData, aulasData] = await Promise.all([
            apiFetch('admin_stats.php').catch(() => null),
            apiFetch('nodos.php').catch(() => null),
            apiFetch('aulas.php').catch(() => null)
        ]);

        if (nodosData && nodosData.nodos) {
            const totalNodos = nodosData.nodos.length;
            const activos = nodosData.nodos.filter(n => n.estado_nodo === 'online').length;
            const offline = totalNodos - activos;
            const pct = totalNodos > 0 ? Math.round((activos / totalNodos) * 100) : 0;

            const kpiActivos = document.getElementById('kpiNodosActivos');
            if (kpiActivos) kpiActivos.innerHTML = `${activos} <small>/ ${totalNodos}</small>`;

            const kpiFooter = document.getElementById('kpiNodosFooter');
            if (kpiFooter) kpiFooter.innerHTML = `<i class="fas fa-arrow-up me-1"></i>${pct}% Cobertura de red`;

            const kpiOff = document.getElementById('kpiNodosOffline');
            if (kpiOff) kpiOff.textContent = String(offline);
        }

        if (aulasData && aulasData.aulas) {
            const ocupadas = aulasData.aulas.filter(a => a.estado_aula === 'ocupada').length;
            const kpiOcupadas = document.getElementById('kpiAulasOcupadas');
            if (kpiOcupadas) kpiOcupadas.textContent = String(ocupadas);
        }

        if (statsData && statsData.stats) {
            const badge = document.getElementById('badgePendientes');
            if (badge) {
                const pend = statsData.stats.solicitudes_pend || 0;
                badge.textContent = String(pend);
                badge.style.display = pend > 0 ? 'inline-block' : 'none';
            }
        }
    } catch (err) {
        console.warn('Error al actualizar KPIs:', err);
    }
}

// ==========================================
// 2. Cargar Aulas (Plano dinámico)
// ==========================================
async function loadAulas(edificio) {
    const container = document.getElementById('dynamicMapContainer');
    if (!container) return;
    container.innerHTML = '<div class="text-center w-100 text-muted my-5"><i class="fas fa-spinner fa-spin me-2"></i>Cargando aulas...</div>';

    try {
        const json = await apiFetch(`aulas.php?edificio=${encodeURIComponent(edificio)}`);
        container.innerHTML = '';

        if (!json.aulas || json.aulas.length === 0) {
            container.innerHTML = '<div class="text-center w-100 text-muted my-4">No hay aulas registradas en este edificio.</div>';
            return;
        }

        json.aulas.forEach(aula => {
            let bgClass = 'bg-secondary';
            let iconClass = 'fa-lock';
            let statusText = 'Cerrada';
            let roomClass = 'room-closed';

            if (aula.estado_nodo === 'offline') {
                bgClass = 'bg-danger';
                iconClass = 'fa-wifi';
                statusText = 'Offline';
                roomClass = 'room-offline pulse-glow';
            } else if (aula.estado_aula === 'ocupada') {
                bgClass = 'bg-success';
                iconClass = 'fa-lock-open';
                statusText = 'En uso';
                roomClass = 'room-open';
            } else if (aula.estado_aula === 'disponible') {
                bgClass = 'bg-secondary';
                iconClass = 'fa-lock';
                statusText = 'Disponible';
                roomClass = 'room-closed';
            }

            const card = document.createElement('div');
            card.className = `floor-room ${roomClass}`;
            card.style.position = 'relative';
            card.style.width = '140px';
            card.style.height = '100px';
            card.style.flexShrink = '0';
            card.style.cursor = 'pointer';

            let extra = '';
            if (aula.tipo === 'laboratorio') extra = ' <small>(Lab)</small>';
            else if (aula.tipo === 'auditorio') extra = ' <small>(Aud)</small>';

            card.innerHTML = `
                <span class="floor-room-name">${esc(aula.codigo)}${extra}</span>
                <span class="badge ${bgClass}"><i class="fas ${iconClass} me-1"></i>${statusText}</span>
            `;

            card.addEventListener('click', () => {
                window.currentAulaId = aula.id;
                window.currentEdificio = edificio;
                document.getElementById('modalRoomName').textContent = aula.codigo;
                document.getElementById('modalRoomStatus').innerHTML =
                    `<span class="lock-status-indicator status-${aula.estado_nodo === 'offline' ? 'offline' : (aula.estado_aula === 'ocupada' ? 'open' : 'locked')}"><span class="lock-status-dot"></span>${statusText}</span>`;

                const batText = document.getElementById('modalRoomBattery');
                const batIcon = document.getElementById('modalRoomBatteryIcon');
                if (batText && batIcon) {
                    if (aula.bateria_pct !== null && aula.bateria_pct !== undefined) {
                        batText.textContent = `${aula.bateria_pct}% Batería`;
                        batIcon.className = aula.bateria_pct < 25 ? 'fas fa-battery-quarter text-danger' : 'fas fa-battery-three-quarters text-success';
                    } else {
                        batText.textContent = 'Alimentación AC';
                        batIcon.className = 'fas fa-plug text-primary';
                    }
                }

                loadRoomAccessLog(aula.id);

                if (!window.roomModalInstance) {
                    window.roomModalInstance = new bootstrap.Modal(document.getElementById('roomDetailModal'));
                }
                window.roomModalInstance.show();
            });

            container.appendChild(card);
        });
    } catch (err) {
        container.innerHTML = `<div class="text-danger w-100 p-3">Error al cargar aulas: ${esc(err.message)}</div>`;
    }
}

// Carga la bitácora del aula en el modal
async function loadRoomAccessLog(idAula) {
    const logBox = document.getElementById('modalRoomAccessLog');
    if (!logBox) return;
    logBox.innerHTML = '<div class="p-3 text-muted text-center"><i class="fas fa-spinner fa-spin me-1"></i>Cargando accesos...</div>';

    try {
        const d = await apiFetch(`accesos.php?id_aula=${idAula}&limite=5`);
        if (!d.accesos || d.accesos.length === 0) {
            logBox.innerHTML = '<div class="p-3 text-muted text-center small">Sin eventos recientes registrados en esta aula.</div>';
            return;
        }

        logBox.innerHTML = d.accesos.map(a => {
            const isOk = a.resultado === 'exitoso';
            const icon = isOk ? 'fa-door-open' : 'fa-times';
            const iconBg = isOk ? 'rgba(15,204,146,0.12)' : 'rgba(231,76,94,0.12)';
            const iconCol = isOk ? 'var(--accent)' : 'var(--danger-color)';
            return `
                <div class="telemetry-item p-3 border-bottom d-flex align-items-start gap-3">
                    <div style="width:32px;height:32px;border-radius:50%;display:flex;align-items:center;justify-content:center;background:${iconBg};color:${iconCol};flex-shrink:0;">
                        <i class="fas ${icon}"></i>
                    </div>
                    <div class="flex-grow-1">
                        <div style="font-size:0.85rem;font-weight:600;">${esc(a.usuario || 'Sistema / Cerradura')}</div>
                        <div class="text-muted" style="font-size:0.75rem;">${esc(a.tipo_acceso.toUpperCase())} · ${esc(a.detalle || a.resultado)}</div>
                    </div>
                    <div class="text-muted" style="font-size:0.7rem;white-space:nowrap;">${esc(a.fecha_hora ? a.fecha_hora.substring(11, 16) : '')}</div>
                </div>
            `;
        }).join('');
    } catch (e) {
        logBox.innerHTML = `<div class="p-3 text-danger small">Error: ${esc(e.message)}</div>`;
    }
}

// ==========================================
// 3. Cargar Cerraduras (Tabla)
// ==========================================
window.loadCerraduras = async function(edificio) {
    const tbody = document.getElementById('cerradurasTableBody');
    if (!tbody) return;

    tbody.innerHTML = '<tr><td colspan="6" class="text-center text-muted"><i class="fas fa-spinner fa-spin me-2"></i>Cargando cerraduras...</td></tr>';

    try {
        const json = await apiFetch(`nodos.php?edificio=${encodeURIComponent(edificio || '')}`);
        tbody.innerHTML = '';

        if (!json.nodos || json.nodos.length === 0) {
            tbody.innerHTML = '<tr><td colspan="6" class="text-center text-muted">No hay nodos en este edificio.</td></tr>';
            return;
        }

        json.nodos.forEach(nodo => {
            const isOffline = nodo.estado_nodo === 'offline';
            const bat = nodo.bateria_pct;

            let batHtml = `<td style="color: var(--text-muted);">— Red AC</td>`;
            if (bat !== null && bat !== undefined) {
                let colorClass = 'bg-success';
                let textClass = 'text-muted';
                if (bat < 20) { colorClass = 'bg-danger'; textClass = 'text-danger fw-bold'; }
                else if (bat < 40) { colorClass = 'bg-warning'; }

                batHtml = `<td><div class="d-flex align-items-center gap-2"><div class="progress" style="width:60px;height:6px;"><div class="progress-bar ${colorClass}" style="width:${bat}%;"></div></div><small class="${textClass}">${bat}%</small></div></td>`;
            }

            const tr = document.createElement('tr');
            if (isOffline) tr.style.background = 'rgba(231,76,94,0.03)';

            tr.innerHTML = `
                <td class="fw-semibold ${isOffline ? 'text-danger' : ''}">${esc(nodo.aula_codigo)}</td>
                <td><span class="lock-status-indicator status-${isOffline ? 'offline' : 'locked'}"><span class="lock-status-dot"></span>${isOffline ? 'Sin señal' : 'Cerrada'}</span></td>
                <td><span class="lock-status-indicator status-${isOffline ? 'offline' : 'online'}"><span class="lock-status-dot"></span>${isOffline ? 'Offline' : 'Online'}</span></td>
                ${batHtml}
                <td style="font-size: 0.78rem; color: var(--text-secondary);">${esc(nodo.ultimo_ping || 'Sin registro')}</td>
                <td><span class="badge bg-${isOffline ? 'secondary' : 'success'}" style="font-size: 0.65rem;">${esc(nodo.firmware_version || 'v2.1')}</span></td>
            `;
            tbody.appendChild(tr);
        });
    } catch (err) {
        tbody.innerHTML = `<tr><td colspan="6" class="text-danger">Error: ${esc(err.message)}</td></tr>`;
    }
};

// ==========================================
// 4. Cargar Telemetría (Feed en vivo)
// ==========================================
async function loadTelemetria() {
    const container = document.getElementById('telemetryContainer');
    if (!container) return;

    try {
        const json = await apiFetch('telemetria.php?limite=5');
        if (!json.telemetria) return;

        container.innerHTML = '';
        if (json.telemetria.length === 0) {
            container.innerHTML = '<div class="text-muted p-3 text-center">No hay eventos recientes.</div>';
            return;
        }

        let fallasCount = 0;
        json.telemetria.forEach(t => {
            let icon = 'fa-check';
            let iconClass = 'icon-success';
            let titleClass = '';
            let valClass = '';
            let title = 'Evento';
            let isDanger = false;

            switch (t.tipo_evento) {
                case 'apertura':
                    title = 'Apertura: ' + t.aula_codigo;
                    icon = 'fa-unlock';
                    break;
                case 'cierre':
                    title = 'Cierre: ' + t.aula_codigo;
                    icon = 'fa-lock';
                    iconClass = 'icon-muted';
                    break;
                case 'fallo_auth':
                    title = 'Fallo Autenticación: ' + t.aula_codigo;
                    icon = 'fa-times';
                    iconClass = 'icon-danger';
                    titleClass = 'text-danger';
                    valClass = 'text-danger';
                    isDanger = true;
                    fallasCount++;
                    break;
                case 'desconexion':
                    title = 'Desconexión: ' + t.aula_codigo;
                    icon = 'fa-wifi';
                    iconClass = 'icon-danger';
                    titleClass = 'text-danger';
                    isDanger = true;
                    break;
                default:
                    title = t.tipo_evento + ': ' + t.aula_codigo;
            }

            const div = document.createElement('div');
            div.className = `telemetry-item ${isDanger ? 'item-danger' : ''}`;

            const d = new Date(t.fecha_hora);
            const timeStr = isNaN(d.getTime()) ? t.fecha_hora : d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

            div.innerHTML = `
                <div class="telemetry-icon ${iconClass}"><i class="fas ${icon}"></i></div>
                <div class="telemetry-text">
                    <strong class="${titleClass}">${esc(title)}</strong>
                    <p class="${valClass}" style="opacity:0.8;">${esc(t.valor || '')}</p>
                    <span class="telemetry-time">${esc(timeStr)}</span>
                </div>
            `;
            container.appendChild(div);
        });

        const kpiFallas = document.getElementById('kpiFallasAuth');
        if (kpiFallas && fallasCount > 0) {
            kpiFallas.textContent = String(fallasCount);
        }
    } catch (err) {
        console.warn('Error telemetría:', err);
    }
}

// ==========================================
// 5. Cargar Bitácora Completa (Logs de Acceso)
// ==========================================
window.loadLogs = async function() {
    const tbody = document.getElementById('logsTableBody');
    if (!tbody) return;

    try {
        const d = await apiFetch('accesos.php?limite=20');
        if (!d.accesos || d.accesos.length === 0) {
            tbody.innerHTML = '<tr><td colspan="6" class="text-center text-muted py-4">No hay registros de acceso en la base de datos.</td></tr>';
            return;
        }

        tbody.innerHTML = d.accesos.map(a => {
            const isOk = a.resultado === 'exitoso';
            const hora = a.fecha_hora ? a.fecha_hora.substring(11, 16) : '--:--';
            const fecha = a.fecha_hora ? a.fecha_hora.substring(0, 10) : '';

            let badgeMetodo = '<span class="badge bg-secondary" style="font-size:0.65rem;"><i class="fas fa-key me-1"></i>PIN</span>';
            if (a.tipo_acceso === 'biometria' || a.tipo_acceso === 'huella') {
                badgeMetodo = '<span class="badge bg-primary" style="font-size:0.65rem;"><i class="fas fa-fingerprint me-1"></i>Biometría</span>';
            } else if (a.tipo_acceso === 'otp') {
                badgeMetodo = '<span class="badge" style="font-size:0.65rem;background:rgba(245,166,35,0.15);color:var(--warning-color);"><i class="fas fa-clock me-1"></i>OTP</span>';
            } else if (a.tipo_acceso === 'remoto') {
                badgeMetodo = '<span class="badge bg-dark" style="font-size:0.65rem;"><i class="fas fa-sliders-h me-1"></i>Remoto</span>';
            }

            return `
                <tr style="${isOk ? '' : 'background: rgba(231,76,94,0.03);'}">
                    <td style="white-space:nowrap;color:var(--text-muted);"><span class="fw-semibold">${esc(hora)}</span> <small>${esc(fecha)}</small></td>
                    <td class="fw-semibold ${isOk ? '' : 'text-danger'}">${esc(a.detalle || (isOk ? 'Apertura' : 'Acceso Denegado'))}</td>
                    <td><span class="badge bg-light text-dark border">${esc(a.aula)}</span></td>
                    <td>${esc(a.usuario || 'Docente')}</td>
                    <td>${badgeMetodo}</td>
                    <td><span class="badge bg-${isOk ? 'success' : 'danger'}" style="font-size:0.65rem;">${isOk ? 'Exitoso' : 'Rechazado'}</span></td>
                </tr>
            `;
        }).join('');
    } catch (err) {
        tbody.innerHTML = `<tr><td colspan="6" class="text-danger text-center py-4">Error al cargar bitácora: ${esc(err.message)}</td></tr>`;
    }
};

// ==========================================
// 6. Modal de Aviso
// ==========================================
window.modalAviso = function(exito, msg) {
    const header = document.getElementById('modalHeader');
    const icon = document.getElementById('modalIcon');
    const title = document.getElementById('modalTitle');
    const btn = document.getElementById('modalBtn');
    const text = document.getElementById('modalExitoText');

    if (exito) {
        header.style.background = 'linear-gradient(135deg, #0fcc92, #0aad7a)';
        icon.className = 'fas fa-check-circle fa-3x text-success mb-3';
        title.innerHTML = '<i class="fas fa-check-circle me-2"></i>Listo';
        btn.className = 'btn btn-success';
    } else {
        header.style.background = 'linear-gradient(135deg, #e74c5e, #c93d4f)';
        icon.className = 'fas fa-times-circle fa-3x text-danger mb-3';
        title.innerHTML = '<i class="fas fa-exclamation-circle me-2"></i>Error';
        btn.className = 'btn btn-danger';
    }

    text.innerHTML = esc(msg || 'Operación realizada con éxito.');

    if (window.roomModalInstance) {
        window.roomModalInstance.hide();
    }

    const m = bootstrap.Modal.getOrCreateInstance(document.getElementById('modalExito'));
    m.show();
};

// ==========================================
// 7. Control Remoto y Bloqueo de Emergencia
// ==========================================
window.controlRemoto = async function(accion) {
    if (!window.currentAulaId) return;

    try {
        const data = await apiFetch('nodo_control.php', {
            metodo: 'POST',
            datos: { id_aula: window.currentAulaId, accion: accion }
        });

        modalAviso(true, data.mensaje || 'Operación completada con éxito.');

        if (window.currentEdificio) {
            loadAulas(window.currentEdificio);
        }
        loadKPIs();
        loadTelemetria();
        loadLogs();
    } catch (err) {
        modalAviso(false, err.message || 'Error al ejecutar control remoto.');
    }
};

window.bloqueoEmergencia = function() {
    if (!window.currentAulaId) return;
    controlRemoto('cerrar');
};


// ==========================================
// 6. Gestión de Docentes (Alta vía API REST)
// ==========================================
async function loadDocentes() {
    const tbody = document.getElementById('docentesTableBody');
    if (!tbody) return;
    try {
        const data = await apiFetch('docentes.php');
        const docentes = data.docentes || [];
        if (!docentes.length) {
            tbody.innerHTML = '<tr><td colspan="4" class="text-center text-muted py-4">No hay profesores registrados.</td></tr>';
            return;
        }
        tbody.innerHTML = docentes.map(d => `
            <tr>
                <td class="ps-4 fw-semibold">${esc(d.nombre)}</td>
                <td class="text-muted">${esc(d.email)}</td>
                <td><span class="badge bg-light text-dark">${esc(d.matricula || 'Sin matrícula')}</span></td>
                <td class="text-end pe-4">
                    <button class="btn btn-sm btn-outline-danger" onclick="eliminarDocenteApi(${d.id}, '${esc(d.nombre)}')">
                        <i class="fas fa-trash-alt"></i>
                    </button>
                </td>
            </tr>
        `).join('');
    } catch (err) {
        tbody.innerHTML = `<tr><td colspan="4" class="text-center text-danger py-4">${esc(err.message)}</td></tr>`;
    }
}

window.registrarDocenteApi = async function(e) {
    e.preventDefault();
    const btn = document.getElementById('btnGuardarDocente');
    const alertBox = document.getElementById('docAlert');
    const nombre = document.getElementById('docNombre').value.trim();
    const email = document.getElementById('docEmail').value.trim();
    const password = document.getElementById('docPassword').value;
    const matricula = document.getElementById('docMatricula').value.trim();

    alertBox.className = 'alert d-none';
    btn.disabled = true;
    btn.innerHTML = '<i class="fas fa-spinner fa-spin me-2"></i>Registrando...';

    try {
        const res = await apiFetch('usuarios.php', {
            method: 'POST',
            body: JSON.stringify({
                nombre,
                email,
                password,
                matricula: matricula || null,
                id_rol: 2
            })
        });
        alertBox.className = 'alert alert-success py-2 px-3';
        alertBox.textContent = res.mensaje || 'Profesor registrado correctamente.';
        document.getElementById('formAltaDocente').reset();
        await loadDocentes();
    } catch (err) {
        alertBox.className = 'alert alert-danger py-2 px-3';
        alertBox.textContent = err.message;
    } finally {
        btn.disabled = false;
        btn.innerHTML = '<i class="fas fa-save me-2"></i>Registrar Profesor';
    }
};

window.eliminarDocenteApi = async function(id, nombre) {
    if (!confirm(`¿Eliminar al profesor ${nombre}?`)) return;
    try {
        await apiFetch(`usuarios.php?id=${id}`, { method: 'DELETE' });
        await loadDocentes();
    } catch (err) {
        alert(err.message);
    }
};
