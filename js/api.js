/**
 * Cliente ligero para consumir las APIs PHP del sistema.
 * Todas las llamadas van al mismo origen (Apache de XAMPP) e incluyen
 * la cookie de sesión automáticamente.
 */
const API_BASE = 'api';

async function apiFetch(ruta, { metodo = 'GET', datos = null } = {}) {
  const opciones = {
    method: metodo,
    headers: {},
    credentials: 'same-origin',
  };
  if (datos !== null) {
    opciones.headers['Content-Type'] = 'application/json';
    opciones.body = JSON.stringify(datos);
  }
  const resp = await fetch(`${API_BASE}/${ruta}`, opciones);
  let cuerpo;
  try {
    cuerpo = await resp.json();
  } catch {
    throw new Error('Respuesta no válida del servidor.');
  }
  if (!resp.ok || cuerpo.ok === false) {
    const err = new Error(cuerpo.error || `Error ${resp.status}`);
    err.status = resp.status;
    throw err;
  }
  return cuerpo.data;
}

/** Devuelve el usuario de la sesión o null. */
async function apiUsuarioActual() {
  const d = await apiFetch('me.php');
  return d.autenticado ? d.usuario : null;
}

/** Exige sesión; si no hay, redirige al login. Devuelve el usuario. */
async function apiExigirSesion(rolRequerido = null) {
  let usuario = null;
  try {
    usuario = await apiUsuarioActual();
  } catch {
    /* ignora */
  }
  if (!usuario) {
    window.location.href = 'login.html';
    throw new Error('sin sesión');
  }
  if (rolRequerido && usuario.rol !== rolRequerido) {
    window.location.href = usuario.rol === 'admin' ? 'dashboard.html' : 'usuario.html';
    throw new Error('rol incorrecto');
  }
  return usuario;
}

async function apiLogout() {
  try {
    await apiFetch('logout.php', { metodo: 'POST' });
  } finally {
    window.location.href = 'login.html';
  }
}

/** Escapa texto para insertarlo de forma segura en HTML. */
function esc(v) {
  return String(v ?? '').replace(/[&<>"']/g, (c) => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  }[c]));
}
