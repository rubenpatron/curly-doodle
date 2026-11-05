// ==========================================
// Integración con API v2.0 - Aulas Inteligentes
// ==========================================

document.addEventListener('DOMContentLoaded', () => {
    // Cargar datos iniciales
    loadAulas('A');
    loadCerraduras('A');
    loadTelemetria();

    // Refrescar telemetría cada 10 segundos
    setInterval(loadTelemetria, 10000);
});

// Sobreescribir la función changeEdificio que existía en el HTML
window.changeEdificio = function(edificio) {
    document.getElementById('mapTitle').innerHTML = '<i class="fas fa-map me-2" style="color: var(--secondary);"></i>Plano Interactivo — Edificio ' + edificio;
    loadAulas(edificio);
};

// ==========================================
// 1. Cargar Aulas (Plano dinámico)
// ==========================================
async function loadAulas(edificio) {
    const container = document.getElementById('dynamicMapContainer');
    container.innerHTML = '<div class="text-center w-100 text-muted my-5"><i class="fas fa-spinner fa-spin me-2"></i>Cargando aulas...</div>';

    try {
        const res = await fetch(`api/aulas.php?edificio=${edificio}`);
        const json = await res.json();
        
        if (!json.ok) throw new Error(json.error);
        
        container.innerHTML = '';
        
        if (json.data.aulas.length === 0) {
            container.innerHTML = '<div class="text-center w-100 text-muted my-4">No hay aulas registradas en este edificio.</div>';
            return;
        }

        json.data.aulas.forEach(aula => {
            // Determinar clases según estado
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
                // Si está disponible, pero online, puede estar abierta o cerrada, asumamos cerrada por defecto a menos que...
                bgClass = 'bg-success';
                iconClass = 'fa-lock-open';
                statusText = 'Libre';
                roomClass = 'room-open';
            }

            // Crear tarjeta estilo plano
            const card = document.createElement('div');
            card.className = `floor-room ${roomClass}`;
            // En lugar de absolute, usamos relative para que fluyan en flexbox
            card.style.position = 'relative'; 
            card.style.width = '140px';
            card.style.height = '100px';
            card.style.flexShrink = '0';
            
            let extra = '';
            if (aula.tipo === 'laboratorio') extra = ' <small>(Lab)</small>';
            
            card.innerHTML = `
                <span class="floor-room-name">${aula.codigo}${extra}</span>
                <span class="badge ${bgClass}"><i class="fas ${iconClass} me-1"></i>${statusText}</span>
            `;
            
            // Evento de click para modal (reutilizando lógica modal existente)
            card.addEventListener('click', () => {
                window.currentAulaId = aula.id;
                window.currentEdificio = edificio;
                document.getElementById('modalRoomName').textContent = aula.codigo;
                document.getElementById('modalRoomStatus').innerHTML = `<span class="lock-status-indicator status-${aula.estado_nodo === 'offline' ? 'offline' : 'online'}"><span class="lock-status-dot"></span>${statusText}</span>`;
                
                if (!window.roomModalInstance) {
                    window.roomModalInstance = new bootstrap.Modal(document.getElementById('roomDetailModal'));
                }
                window.roomModalInstance.show();
            });

            container.appendChild(card);
        });
        
    } catch (err) {
        container.innerHTML = `<div class="text-danger w-100 p-3">Error al cargar aulas: ${err.message}</div>`;
    }
}

// ==========================================
// 2. Cargar Cerraduras (Tabla)
// ==========================================
window.loadCerraduras = async function(edificio) {
    const tbody = document.getElementById('cerradurasTableBody');
    if(!tbody) return;
    
    tbody.innerHTML = '<tr><td colspan="6" class="text-center text-muted"><i class="fas fa-spinner fa-spin me-2"></i>Cargando cerraduras...</td></tr>';

    try {
        const res = await fetch(`api/nodos.php?edificio=${edificio}`);
        const json = await res.json();
        
        if (!json.ok) throw new Error(json.error);
        
        tbody.innerHTML = '';
        
        if (json.data.nodos.length === 0) {
            tbody.innerHTML = '<tr><td colspan="6" class="text-center text-muted">No hay nodos en este edificio.</td></tr>';
            return;
        }

        json.data.nodos.forEach(nodo => {
            const isOffline = nodo.estado_nodo === 'offline';
            const bat = nodo.bateria_pct;
            
            let batHtml = `<td style="color: var(--text-muted);">— Desconocida</td>`;
            if (bat !== null) {
                let colorClass = 'bg-success';
                let textClass = 'text-muted';
                if (bat < 20) { colorClass = 'bg-danger'; textClass = 'text-danger fw-bold'; }
                else if (bat < 40) { colorClass = 'bg-warning'; }
                
                batHtml = `<td><div class="d-flex align-items-center gap-2"><div class="progress" style="width:60px;height:6px;"><div class="progress-bar ${colorClass}" style="width:${bat}%;"></div></div><small class="${textClass}">${bat}%</small></div></td>`;
            }

            const tr = document.createElement('tr');
            if (isOffline) tr.style.background = 'rgba(231,76,94,0.03)';
            
            tr.innerHTML = `
                <td class="fw-semibold ${isOffline ? 'text-danger' : ''}">${nodo.aula_codigo}</td>
                <td><span class="lock-status-indicator status-${isOffline ? 'offline' : 'locked'}"><span class="lock-status-dot"></span>${isOffline ? 'Sin señal' : 'Cerrada'}</span></td>
                <td><span class="lock-status-indicator status-${isOffline ? 'offline' : 'online'}"><span class="lock-status-dot"></span>${isOffline ? 'Offline' : 'Online'}</span></td>
                ${batHtml}
                <td style="font-size: 0.78rem; color: var(--text-secondary);">${nodo.ultimo_ping || 'Sin registro'}</td>
                <td><span class="badge bg-${isOffline ? 'secondary' : 'success'}" style="font-size: 0.65rem;">${nodo.firmware_version || 'v1.0'}</span></td>
            `;
            tbody.appendChild(tr);
        });
        
    } catch (err) {
        tbody.innerHTML = `<tr><td colspan="6" class="text-danger">Error: ${err.message}</td></tr>`;
    }
}

// ==========================================
// 3. Cargar Telemetría (Feed en vivo)
// ==========================================
async function loadTelemetria() {
    const container = document.getElementById('telemetryContainer');
    if(!container) return;

    try {
        const res = await fetch(`api/telemetria.php?limite=5`);
        const json = await res.json();
        
        if (!json.ok) return;
        
        container.innerHTML = '';
        
        if (json.data.telemetria.length === 0) {
            container.innerHTML = '<div class="text-muted p-3 text-center">No hay eventos recientes.</div>';
            return;
        }

        json.data.telemetria.forEach(t => {
            let icon = 'fa-check';
            let iconClass = 'icon-success';
            let titleClass = '';
            let valClass = '';
            let title = 'Evento';
            let isDanger = false;

            switch(t.tipo_evento) {
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
            
            // Format time nicely (just simple string for now)
            const d = new Date(t.fecha_hora);
            const timeStr = d.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});

            div.innerHTML = `
                <div class="telemetry-icon ${iconClass}"><i class="fas ${icon}"></i></div>
                <div class="telemetry-text">
                    <strong class="${titleClass}">${title}</strong>
                    <p class="${valClass}" style="opacity:0.8;">${t.valor || ''}</p>
                    <span class="telemetry-time">${timeStr}</span>
                </div>
            `;
            container.appendChild(div);
        });
        
    } catch (err) {
        console.error("Error telemetria:", err);
    }
}

// Modal de aviso
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
    
    text.innerHTML = msg || 'Operación realizada con éxito.';
    
    // Ocultar modal de aula si está abierto, para evitar traslapes de z-index
    if (window.roomModalInstance) {
        window.roomModalInstance.hide();
    }
    
    const m = bootstrap.Modal.getOrCreateInstance(document.getElementById('modalExito'));
    m.show();
};

// Control Remoto (Abrir/Cerrar)
window.controlRemoto = async function(accion) {
    if (!window.currentAulaId) return;
    
    try {
        const res = await fetch('api/nodo_control.php', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ id_aula: window.currentAulaId, accion: accion })
        });
        const data = await res.json();
        
        if (data.ok) {
            modalAviso(true, data.mensaje || 'Operación completada con éxito.');
            // Refrescar el mapa dinámico para ver el cambio de color
            if (window.currentEdificio) {
                loadAulas(window.currentEdificio);
            }
        } else {
            modalAviso(false, data.error || 'Error desconocido.');
        }
    } catch (err) {
        modalAviso(false, 'Error de conexión: ' + err.message);
    }
};
