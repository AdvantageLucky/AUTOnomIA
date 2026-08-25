/* AUTOnomIA · Dashboard Admin — sin build step */
(() => {
  const API_BASE = "/api/v1";
  const TOKEN_KEY = "autonomia_admin_token";

  /* ─── i18n ─────────────────────────────── */
  const STRINGS = {
    es: {
      brand_sub: "Control de acceso",
      login_title: "Panel de administración",
      login_sub: "Inicia sesión para supervisar los accesos de tu comunidad.",
      login_email: "Correo electrónico",
      login_pass: "Contraseña",
      login_btn: "Entrar",
      or: "o continúa con",
      google_btn: "Continuar con Google",
      no_account: "¿No tienes cuenta?",
      create_account: "Crear cuenta de administrador",
      hero_title: "Quién entró, cuándo y por dónde.",
      hero_sub: "Auto-registro de visitantes para comunidades cerradas. Supervisa bitácoras, verifica visitas y gestiona tus entradas desde un solo lugar.",
      dark_mode: "Modo oscuro",
      light_mode: "Modo claro",
      preferences: "Preferencias",
      pref_theme: "Apariencia",
      pref_lang: "Idioma",
      nav_general: "General",
      nav_dashboard: "Inicio",
      nav_visitas: "Visitas",
      nav_entradas: "Entradas",
      nav_config: "Configuración",
      nav_accesos: "Accesos",
      nav_perfil: "Perfil",
      role_admin: "Administrador",
      dash_sub: "Resumen de tu comunidad",
      stat_today: "Entradas hoy",
      stat_attention: "Requieren atención",
      stat_approved: "Aprobadas hoy",
      stat_residents: "Residentes activos",
      stat_week: "Últimos 7 días",
      stat_total: "Total registros",
      stat_pending: "Pendientes",
      q_visitas_title: "Ver bitácora de entradas",
      q_visitas_sub: "Filtros por tipo: residente, con QR o sin app",
      recent_title: "Entradas recientes",
      see_all: "Ver todas ›",
      vis_sub: "Bitácora de registros",
      all_docs: "Todos los tipos",
      all_tipos: "Todos los tipos",
      pasaporte: "Pasaporte",
      licencia: "Licencia",
      all_states: "Todos los estados",
      pendiente: "Pendiente",
      aprobado: "Aprobado",
      rechazado: "Rechazado",
      revision: "Revisión",
      col_visitor: "VISITANTE",
      col_doc: "DOCUMENTO",
      col_access: "ACCESO",
      col_estado: "ESTADO",
      col_date: "FECHA",
      vis_empty_title: "Sin entradas registradas",
      vis_empty_text: "Cuando alguien ingrese o se registre en un kiosko, aparecerá aquí automáticamente.",
      load_err_title: "Error al cargar",
      load_err_text: "Revisa tu conexión e inténtalo de nuevo.",
      retry: "Reintentar",
      prev: "‹ Anterior",
      next: "Siguiente ›",
      detail_title: "Detalle de entrada",
      accesos_sub: "Entradas y casetas de tu comunidad",
      new_acceso: "Nuevo acceso",
      perfil_sub: "Tus datos personales y seguridad",
      personal_data: "Datos personales",
      first_name: "Nombre",
      email: "Correo",
      paternal: "Apellido paterno",
      maternal: "Apellido materno",
      confirm_pass: "Confirmar contraseña",
      pass_hint: "La API requiere reenviar tu contraseña al actualizar el perfil.",
      password: "Contraseña",
      profile_saved: "Perfil actualizado correctamente.",
      save: "Guardar cambios",
      modal_new_acceso: "Nuevo acceso",
      modal_acceso_sub: "Define el nombre y ubicación de la entrada.",
      name: "Nombre",
      location: "Ubicación",
      acceso_key_hint: "La clave de kiosko se genera automáticamente al crear el acceso.",
      cancel: "Cancelar",
      acceso_created: "Acceso creado",
      acceso_created_sub: "Copia esta clave ahora y configúrala en el kiosko. No se mostrará de nuevo.",
      access_id: "ID del acceso",
      kiosk_key: "Clave de kiosko",
      copied: "Listo, ya la copié",
      delete_acceso: "¿Eliminar acceso?",
      delete_acceso_text: "Esta acción no se puede deshacer. El acceso dejará de estar disponible.",
      delete: "Eliminar",
      casa_destino: "Casa / Destino",
      placa: "Placa",
      no_placa: "Sin placa",
      autorizado_por: "Autorizado por",
      sin_resolver: "Sin resolver",
      autorizador_admin: "Admin",
      autorizador_residente: "Residente",
      autorizador_agente: "Agente IA",
      autorizador_sistema: "Sistema (sin respuesta)",
      visits: n => `${n} entrada${n !== 1 ? "s" : ""} registrada${n !== 1 ? "s" : ""}`,
      hello: name => `Hola, ${name}`,
      nav_inicio: "Inicio",
      nav_solicitudes: "Solicitudes",
      nav_residentes: "Residentes",
      nav_kioskos: "Kioskos",
      nav_instalacion: "Centro",
      tab_activos: "Activos",
      tab_solicitudes: "Solicitudes",
      tab_lista: "Lista",
      tab_equipo: "Equipo",
      tab_destinos: "Destinos",
      tab_config: "Configuración",
      nuevo_kiosko: "+ Nuevo kiosko",
      nuevo_destino: "+ Nuevo destino",
      nuevo_residente: "+ Nuevo residente",
      res_title: "Residentes",
      kio_title: "Kioskos",
      inst_title: "Centro Habitacional",
      inst_sub: "Casas del fraccionamiento y datos generales del centro",
      sol_title: "Solicitudes de acceso",
      sol_sub: "Visitantes pendientes de aprobación",
      approbar: "Aprobar",
      rechazar: "Rechazar",
      sin_solicitudes: "Sin solicitudes pendientes",
      sin_solicitudes_text: "Cuando alguien solicite acceso, aparecerá aquí.",
    },
    en: {
      brand_sub: "Access control",
      login_title: "Admin dashboard",
      login_sub: "Sign in to monitor access to your community.",
      login_email: "Email address",
      login_pass: "Password",
      login_btn: "Sign in",
      or: "or continue with",
      google_btn: "Continue with Google",
      no_account: "Don't have an account?",
      create_account: "Create admin account",
      hero_title: "Who entered, when and where.",
      hero_sub: "Self-registration for gated communities. Monitor logs, verify visits and manage your entries from one place.",
      dark_mode: "Dark mode",
      light_mode: "Light mode",
      preferences: "Preferences",
      pref_theme: "Appearance",
      pref_lang: "Language",
      nav_general: "General",
      nav_dashboard: "Home",
      nav_visitas: "Visits",
      nav_entradas: "Entries",
      nav_config: "Settings",
      nav_accesos: "Entries",
      nav_perfil: "Profile",
      role_admin: "Administrator",
      loading: "Loading…",
      dash_sub: "Community summary",
      stat_today: "Today's entries",
      stat_attention: "Require attention",
      stat_approved: "Approved today",
      stat_residents: "Active residents",
      stat_week: "Last 7 days",
      stat_total: "Total records",
      stat_pending: "Pending",
      q_visitas_title: "View entry log",
      q_visitas_sub: "Filter by type: resident, QR guest or walk-in",
      recent_title: "Recent entries",
      see_all: "See all ›",
      vis_sub: "Entry log",
      all_docs: "All types",
      all_tipos: "All types",
      pasaporte: "Passport",
      licencia: "Driver's license",
      all_states: "All statuses",
      pendiente: "Pending",
      aprobado: "Approved",
      rechazado: "Rejected",
      revision: "Under review",
      col_visitor: "VISITOR",
      col_doc: "DOCUMENT",
      col_access: "ENTRY",
      col_estado: "STATUS",
      col_date: "DATE",
      vis_empty_title: "No entries recorded",
      vis_empty_text: "When someone enters or registers at a kiosk, they'll appear here.",
      load_err_title: "Failed to load",
      load_err_text: "Check your connection and try again.",
      retry: "Try again",
      prev: "‹ Previous",
      next: "Next ›",
      detail_title: "Entry detail",
      accesos_sub: "Entry points and booths in your community",
      new_acceso: "New entry",
      perfil_sub: "Your personal data and security",
      personal_data: "Personal information",
      first_name: "First name",
      email: "Email",
      paternal: "First surname",
      maternal: "Second surname",
      confirm_pass: "Confirm password",
      pass_hint: "The API requires your password when updating your profile.",
      password: "Password",
      profile_saved: "Profile updated successfully.",
      save: "Save changes",
      modal_new_acceso: "New entry",
      modal_acceso_sub: "Set the name and location for this entry point.",
      name: "Name",
      location: "Location",
      acceso_key_hint: "The kiosk key is auto-generated when the entry is created.",
      cancel: "Cancel",
      acceso_created: "Entry created",
      acceso_created_sub: "Copy this key and configure it in the kiosk now. It won't be shown again.",
      access_id: "Entry ID",
      kiosk_key: "Kiosk key",
      copied: "Done, I copied it",
      delete_acceso: "Delete entry?",
      delete_acceso_text: "This cannot be undone. The entry will no longer be available.",
      delete: "Delete",
      casa_destino: "House / Destination",
      placa: "License plate",
      no_placa: "No plate",
      autorizado_por: "Authorized by",
      sin_resolver: "Unresolved",
      autorizador_admin: "Admin",
      autorizador_residente: "Resident",
      autorizador_agente: "AI agent",
      autorizador_sistema: "System (no response)",
      visits: n => `${n} entr${n !== 1 ? "ies" : "y"} recorded`,
      hello: name => `Hello, ${name}`,
      nav_inicio: "Home",
      nav_solicitudes: "Requests",
      nav_residentes: "Residents",
      nav_kioskos: "Kiosks",
      nav_instalacion: "Complex",
      tab_activos: "Active",
      tab_solicitudes: "Requests",
      tab_lista: "List",
      tab_equipo: "Staff",
      tab_destinos: "Destinations",
      tab_config: "Settings",
      nuevo_kiosko: "+ New kiosk",
      nuevo_destino: "+ New destination",
      nuevo_residente: "+ New resident",
      res_title: "Residents",
      kio_title: "Kiosks",
      inst_title: "Residential Complex",
      inst_sub: "Houses in the complex and general settings",
      sol_title: "Access requests",
      sol_sub: "Visitors pending approval",
      approbar: "Approve",
      rechazar: "Reject",
      sin_solicitudes: "No pending requests",
      sin_solicitudes_text: "When someone requests access, they'll appear here.",
    },
  };

  let lang = localStorage.getItem("autonomia_lang") || "es";

  function t(key) {
    const v = STRINGS[lang][key];
    return v !== undefined ? v : STRINGS.es[key] ?? key;
  }

  function applyI18n() {
    document.querySelectorAll("[data-i18n]").forEach(el => {
      const key = el.dataset.i18n;
      const val = STRINGS[lang][key];
      if (val !== undefined && typeof val === "string") el.textContent = val;
    });
    document.getElementById("label-lang").textContent = lang === "es" ? "EN" : "ES";
    const isDark = document.documentElement.dataset.theme === "dark";
    document.getElementById("label-theme").textContent = isDark ? t("light_mode") : t("dark_mode");
  }

  /* ─── Dark / Light ──────────────────────── */
  function initTheme() {
    const saved = localStorage.getItem("autonomia_theme");
    const prefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
    const dark = saved ? saved === "dark" : prefersDark;
    setTheme(dark ? "dark" : "light", false);
  }

  function setTheme(theme, animate = true) {
    if (animate) {
      document.documentElement.classList.add("theme-transitioning");
      setTimeout(() => document.documentElement.classList.remove("theme-transitioning"), 260);
    }
    document.documentElement.dataset.theme = theme;
    localStorage.setItem("autonomia_theme", theme);
    document.getElementById("icon-theme-dark").hidden = theme === "dark";
    document.getElementById("icon-theme-light").hidden = theme === "light";
    document.getElementById("label-theme").textContent = theme === "dark" ? t("light_mode") : t("dark_mode");
    const subEl = document.getElementById("pref-theme-sub");
    if (subEl) subEl.textContent = theme === "dark" ? t("light_mode") : t("dark_mode");
  }

  document.getElementById("btn-theme")?.addEventListener("click", () => {
    const current = document.documentElement.dataset.theme;
    setTheme(current === "dark" ? "light" : "dark");
  });

  document.getElementById("btn-lang")?.addEventListener("click", () => {
    lang = lang === "es" ? "en" : "es";
    localStorage.setItem("autonomia_lang", lang);
    applyI18n();
  });

  initTheme();

  /* ─── State ─────────────────────────────── */
  const MESES_ES = ["ene","feb","mar","abr","may","jun","jul","ago","sep","oct","nov","dic"];
  const MESES_EN = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];

  const TIPO_BADGE  = { INE: "badge--ine", PASAPORTE: "badge--pasaporte", LICENCIA: "badge--licencia" };
  const TIPO_VIS_BADGE = { RESIDENTE: "badge--residente", INVITADO: "badge--invitado", VISITANTE: "badge--visitante" };
  const TIPO_VIS_LABEL = {
    RESIDENTE: { es: "Residente",  en: "Resident" },
    INVITADO:  { es: "Con QR",     en: "QR Guest" },
    VISITANTE: { es: "Sin app",    en: "Walk-in" },
  };
  function tipoVisLabel(tv) {
    const entry = TIPO_VIS_LABEL[tv];
    if (!entry) return tv || "—";
    return entry[lang] || entry.es;
  }
  const ESTADO_BADGE = { PENDIENTE: "badge--pendiente", APROBADO: "badge--aprobado", RECHAZADO: "badge--rechazado", REVISION: "badge--revision" };

  const RUTAS_POR_ROL = {
    admin:     ["dashboard","solicitudes","visitas","detalle","residentes","residente-detalle","kioskos","configuracion","instalacion","perfil"],
    vigilante: ["solicitudes","perfil"],
  };

  const state = {
    adminId: null,
    admin: null,
    tenant: null,
    rol: "admin",
    accesosById: new Map(),
    visPage: 1,
    visPageSize: 20,
    visTotal: 0,
    editingAccesoId: null,
    deletingAccesoId: null,
    visSearchTimeout: null,
    solPollingId: null,
    sseSource: null,
    residentesFull: [],
    resSearchTimeout: null,
  };

  /* ─── Auth helpers ──────────────────────── */
  function getToken()  { return localStorage.getItem(TOKEN_KEY); }
  function setToken(t) { localStorage.setItem(TOKEN_KEY, t); }
  function clearToken(){ localStorage.removeItem(TOKEN_KEY); }

  function decodeJWT(token) {
    try {
      const p = token.split(".")[1];
      return JSON.parse(atob(p.replace(/-/g, "+").replace(/_/g, "/")));
    } catch { return null; }
  }

  function getRolFromToken(token) {
    return decodeJWT(token)?.rol || "admin";
  }

  function aplicarRol(rol) {
    state.rol = rol;
    const rutas = RUTAS_POR_ROL[rol] || RUTAS_POR_ROL.admin;
    document.querySelectorAll(".nav-btn[data-nav]").forEach(btn => {
      btn.hidden = !rutas.includes(btn.dataset.nav);
    });
    const esVigilante = rol === "vigilante";
    document.getElementById("screen-solicitudes")?.classList.toggle("sol-vigilante-mode", esVigilante);
  }

  function mostrarToast(msg, tipo = "info") {
    const container = document.getElementById("toast-container");
    if (!container) return;
    const toast = document.createElement("div");
    toast.className = `toast toast--${tipo}`;
    toast.textContent = msg;
    toast.style.cssText = "background:var(--bg-2);border:1px solid var(--border);border-radius:8px;padding:10px 16px;font-size:13px;box-shadow:0 4px 16px rgba(0,0,0,.18);pointer-events:auto;cursor:pointer;max-width:320px;opacity:0;transform:translateY(8px);transition:opacity .2s,transform .2s";
    container.appendChild(toast);
    requestAnimationFrame(() => { toast.style.opacity = "1"; toast.style.transform = "translateY(0)"; });
    const remove = () => { toast.style.opacity = "0"; setTimeout(() => toast.remove(), 200); };
    toast.addEventListener("click", remove);
    setTimeout(remove, 5000);
  }

  function initSSE(token) {
    if (state.sseSource) { state.sseSource.close(); state.sseSource = null; }
    const url = `${API_BASE}/kioskos/solicitudes/stream?token=${encodeURIComponent(token)}`;
    const es = new EventSource(url);
    state.sseSource = es;

    const dot = document.getElementById("sse-dot");

    es.onopen = () => { if (dot) { dot.className = "sse-dot sse-dot--on"; dot.title = "Stream conectado"; } };
    es.onerror = () => { if (dot) { dot.className = "sse-dot"; dot.title = "Stream desconectado"; } };

    es.onmessage = e => {
      try {
        const v = JSON.parse(e.data);
        const nombre = v.titular || "Nuevo visitante";
        if (v.estado === "REVISION") {
          mostrarToast(`⚠ Requiere revisión manual: ${nombre}`, "revision");
        } else {
          mostrarToast(`Nueva solicitud: ${nombre}`);
        }
        loadSolicitudes();
      } catch { /* ignorar mensajes malformados */ }
    };
  }

  async function api(path, opts = {}) {
    const headers = Object.assign({ "Content-Type": "application/json" }, opts.headers || {});
    const token = getToken();
    if (token) headers.Authorization = "Bearer " + token;
    const res = await fetch(API_BASE + path, Object.assign({}, opts, { headers }));
    if (res.status === 401) { showLogin(); return null; }
    return res;
  }

  /* ─── Formato de fecha ──────────────────── */
  function fmtDate(iso) {
    const d = new Date(iso);
    const meses = lang === "en" ? MESES_EN : MESES_ES;
    return `${d.getDate()} ${meses[d.getMonth()]} ${d.getFullYear()}, ${d.getHours().toString().padStart(2,"0")}:${d.getMinutes().toString().padStart(2,"0")}`;
  }

  function fmtDateShort(iso) {
    const d = new Date(iso);
    const meses = lang === "en" ? MESES_EN : MESES_ES;
    return `${d.getDate()} ${meses[d.getMonth()]}`;
  }

  function fmtElapsed(iso) {
    const diff = Date.now() - new Date(iso).getTime();
    const mins = Math.floor(diff / 60000);
    if (mins < 1)  return "hace un momento";
    if (mins < 60) return `hace ${mins} min`;
    const hrs = Math.floor(mins / 60);
    return `hace ${hrs}h`;
  }

  /* ─── Navegación ────────────────────────── */
  function showLogin() {
    document.getElementById("screen-login").hidden = false;
    document.getElementById("app-shell").hidden = true;
    clearToken();
    stopSolPolling();
  }

  function showApp() {
    document.getElementById("screen-login").hidden = true;
    document.getElementById("app-shell").hidden = false;
    applyI18n();
  }

  function navTo(screen) {
    const rutas = RUTAS_POR_ROL[state.rol] || RUTAS_POR_ROL.admin;
    if (!rutas.includes(screen)) screen = state.rol === "vigilante" ? "solicitudes" : "dashboard";

    document.querySelectorAll(".screen").forEach(s => s.classList.remove("active"));
    document.querySelectorAll(".nav-btn").forEach(b => b.classList.remove("active"));

    const screenEl = document.getElementById(`screen-${screen}`);
    if (screenEl) { screenEl.hidden = false; screenEl.classList.add("active"); }

    document.querySelectorAll(`[data-nav="${screen}"]`).forEach(b => b.classList.add("active"));

    stopSolPolling();
    if (screen === "dashboard")     loadDashboard();
    if (screen === "visitas")       loadVisitas(1);
    if (screen === "solicitudes")   startSolPolling();
    if (screen === "residentes")    { loadResidentes(); loadResidentesPendientesBadge(); }
    if (screen === "kioskos")       loadAccesos();
    if (screen === "instalacion")   { loadDestinosSection(); }
    if (screen === "configuracion") loadConfigAccesos();
    if (screen === "perfil")        loadPerfil();
  }

  document.addEventListener("click", e => {
    const nav = e.target.closest("[data-nav]");
    if (nav) navTo(nav.dataset.nav);
  });

  /* ─── Login ─────────────────────────────── */
  let loginMode = "login";

  document.getElementById("login-toggle-mode")?.addEventListener("click", () => {
    loginMode = loginMode === "login" ? "register" : "login";
    const isReg = loginMode === "register";
    document.getElementById("login-submit").textContent = isReg ? (lang === "en" ? "Create account" : "Crear cuenta") : t("login_btn");
    document.querySelector("#login-toggle-mode").previousElementSibling.textContent =
      isReg ? (lang === "en" ? "Already have an account?" : "¿Ya tienes cuenta?") : t("no_account");
    document.getElementById("login-toggle-mode").textContent =
      isReg ? (lang === "en" ? "Sign in" : "Iniciar sesión") : t("create_account");
    document.getElementById("login-error").hidden = true;
    renderGoogleButton();
  });

  document.getElementById("login-form")?.addEventListener("submit", async e => {
    e.preventDefault();
    const correo   = document.getElementById("login-correo").value;
    const password = document.getElementById("login-password").value;
    const errEl    = document.getElementById("login-error");
    const btn      = document.getElementById("login-submit");

    btn.disabled = true;
    errEl.hidden = true;

    const endpoint = loginMode === "register" ? "/auth/sign-in" : "/auth/login";

    try {
      const res = await fetch(API_BASE + endpoint, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ correo, password }),
      });

      const data = await res.json();
      if (!res.ok) {
        let msg = data.error || "Error";
        if (msg.includes("duplicate key") || msg.includes("idx_admins_correo") || msg.includes("23505"))
          msg = lang === "en" ? "An account with this email already exists." : "Ya existe una cuenta con este correo electrónico.";
        errEl.textContent = msg;
        errEl.hidden = false;
        return;
      }

      setToken(data.access_token);
      const claims = decodeJWT(data.access_token);
      state.adminId  = claims?.admin_id;
      state.tenantId = claims?.tenant_id;
      await bootstrapApp();
    } catch { errEl.textContent = "Error de conexión"; errEl.hidden = false; }
    finally  { btn.disabled = false; }
  });

  /* ─── Google Login ──────────────────────── */
  // Se usa el botón que Google renderiza (renderButton), no el prompt de
  // One Tap — Google suprime automáticamente el prompt tras el primer
  // descarte o error, dejando el botón muerto para el resto de la sesión.
  // renderButton abre el selector de cuenta en cada clic, sin ese límite.
  let googleInitialized = false;

  async function googleCallback({ credential }) {
    const errEl = document.getElementById("login-error");
    // El endpoint depende del modo activo al momento del clic — registro
    // crea la cuenta, login solo la busca. Antes siempre pegaba a login,
    // así que "crear cuenta" con Google en realidad intentaba iniciar
    // sesión con una cuenta que no existe.
    const endpoint = loginMode === "register" ? "/auth/google/sign-in" : "/auth/google";
    try {
      const res = await fetch(API_BASE + endpoint, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ credential }),
      });
      const data = await res.json();
      if (!res.ok) { errEl.textContent = data.error || "Google login fallido"; errEl.hidden = false; return; }
      setToken(data.access_token);
      const claims = decodeJWT(data.access_token);
      state.adminId  = claims?.admin_id;
      state.tenantId = claims?.tenant_id;
      await bootstrapApp();
    } catch { errEl.textContent = "Error de conexión"; errEl.hidden = false; }
  }

  function renderGoogleButton() {
    const container = document.getElementById("google-btn-container");
    if (!container || typeof google === "undefined" || !google.accounts) return;

    const clientId = window.__GOOGLE_CLIENT_ID__ || "";
    if (!clientId) return; // sin configurar todavía — no se muestra el botón

    if (!googleInitialized) {
      google.accounts.id.initialize({ client_id: clientId, callback: googleCallback });
      googleInitialized = true;
    }
    container.innerHTML = "";
    // Mismo ancho que el botón naranja (btn-block = 100% del contenedor) —
    // Google no acepta porcentaje, solo píxeles, así que se mide en vivo.
    const ancho = Math.round(container.getBoundingClientRect().width) || 320;
    google.accounts.id.renderButton(container, {
      theme: "outline", size: "large", width: ancho,
      text: loginMode === "register" ? "signup_with" : "signin_with",
      locale: lang === "en" ? "en" : "es",
    });
  }

  // El script de Google carga async — puede terminar antes o después de
  // este punto, así que se reintenta hasta que exista window.google.
  (function esperarGoogleSDK() {
    if (typeof google !== "undefined" && google.accounts) { renderGoogleButton(); return; }
    setTimeout(esperarGoogleSDK, 200);
  })();

  /* ─── Bootstrap ─────────────────────────── */
  async function bootstrapApp() {
    if (!state.adminId) return;
    const token = getToken();
    state.rol = getRolFromToken(token);
    await Promise.all([loadAdminData(), preloadAccesos(), loadTenantData()]);
    if (!state.admin) { clearToken(); showLogin(); applyI18n(); return; }
    showApp();
    aplicarRol(state.rol);
    initSSE(token);
    loadSolicitudes();
    if (state.rol !== 'vigilante' && !state.tenant?.nombre) {
      showOnboarding();
    } else {
      navTo(state.rol === "vigilante" ? "solicitudes" : "dashboard");
    }
  }

  async function loadTenantData() {
    try {
      const res = await api(`/tenants/${state.tenantId || 1}`);
      if (res && res.ok) state.tenant = await res.json();
    } catch { /* continúa con datos parciales */ }
  }

  async function preloadAccesos() {
    const res = await api("/kioskos/");
    if (!res || !res.ok) return;
    const data = await res.json();
    const list = Array.isArray(data) ? data : (data.kioskos || []);
    list.forEach(a => state.accesosById.set(a.id, a));
  }

  async function loadAdminData() {
    try {
      const res = await api(`/admins/${state.adminId}`);
      if (res && res.ok) {
        state.admin = await res.json();
      }
    } catch { /* continúa con datos parciales */ }

    const nombre = state.admin
      ? ([state.admin.nombre, state.admin.apellido_paterno].filter(Boolean).join(" ") || state.admin.correo)
      : (decodeJWT(getToken())?.correo || "—");

    const initials = state.admin
      ? ((state.admin.nombre?.[0] || "") + (state.admin.apellido_paterno?.[0] || ""))
        || (state.admin.correo?.[0] || "")
      : (decodeJWT(getToken())?.correo?.[0] || "");

    document.getElementById("nav-profile-initials").textContent = (initials || "?").toUpperCase();
    document.getElementById("pd-name").textContent  = nombre;
    document.getElementById("pd-email").textContent = state.admin?.correo || decodeJWT(getToken())?.correo || "";
    document.getElementById("perfil-avatar").textContent = initials || "·";
    document.getElementById("perfil-nombre-completo").textContent = nombre;
    document.getElementById("dash-greeting").textContent = STRINGS[lang].hello(state.admin?.nombre || nombre);
  }

  /* ─── Logout ─────────────────────────────── */
  function logout() {
    if (state.sseSource) { state.sseSource.close(); state.sseSource = null; }
    clearToken();
    state.adminId = null;
    state.admin = null;
    state.rol = "admin";
    showLogin();
  }
  document.getElementById("pd-logout-btn")?.addEventListener("click", logout);

  /* ─── Profile ball dropdown ──────────────── */
  const profileBtn = document.getElementById("nav-profile-btn");
  const profileDd  = document.getElementById("profile-dropdown");
  profileBtn?.addEventListener("click", e => {
    e.stopPropagation();
    if (profileDd) profileDd.hidden = !profileDd.hidden;
  });
  document.addEventListener("click", () => { if (profileDd) profileDd.hidden = true; });
  document.getElementById("pd-perfil-btn")?.addEventListener("click", () => {
    if (profileDd) profileDd.hidden = true;
    navTo("perfil");
  });
  document.getElementById("pd-btn-theme")?.addEventListener("click", () => {
    const cur = document.documentElement.dataset.theme;
    setTheme(cur === "dark" ? "light" : "dark");
    syncPdTheme();
  });
  document.getElementById("pd-btn-lang")?.addEventListener("click", () => {
    lang = lang === "es" ? "en" : "es";
    localStorage.setItem("autonomia_lang", lang);
    applyI18n();
    document.getElementById("pd-label-lang").textContent = lang === "es" ? "EN" : "ES";
  });
  function syncPdTheme() {
    const dark = document.documentElement.dataset.theme === "dark";
    const dkIcon = document.getElementById("pd-icon-theme-dark");
    const ltIcon = document.getElementById("pd-icon-theme-light");
    const lbl    = document.getElementById("pd-label-theme");
    if (dkIcon) dkIcon.hidden = !dark;
    if (ltIcon) ltIcon.hidden = dark;
    if (lbl)    lbl.textContent = dark ? "Claro" : "Oscuro";
  }
  syncPdTheme();

  /* ─── Tabs genéricos ────────────────────── */
  function switchTab(sectionId, tabId, onActivate) {
    const section = document.getElementById(sectionId);
    if (!section) return;
    section.querySelectorAll('.tab-btn').forEach(b =>
      b.classList.toggle('active', b.dataset.tab === tabId)
    );
    // Los paneles tienen IDs que coinciden con los valores data-tab de los botones
    section.querySelectorAll('.tab-btn').forEach(b => {
      const panel = document.getElementById(b.dataset.tab);
      if (panel) panel.hidden = b.dataset.tab !== tabId;
    });
    if (onActivate) onActivate();
  }

  document.querySelectorAll('#screen-kioskos .tab-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      const tab = btn.dataset.tab;
      switchTab('screen-kioskos', tab,
        tab === 'kio-lista'   ? loadAccesos :
        tab === 'kio-equipo'  ? loadEquipo : null
      );
    });
  });

  document.querySelectorAll('#screen-residentes .tab-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      const tab = btn.dataset.tab;
      switchTab('screen-residentes', tab,
        tab === 'res-activos'     ? loadResidentes :
        tab === 'res-solicitudes' ? loadResidentesPendientes : null
      );
    });
  });

  document.querySelectorAll('#screen-instalacion .tab-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      const tab = btn.dataset.tab;
      switchTab('screen-instalacion', tab,
        tab === 'inst-unidades' ? loadDestinosSection :
        tab === 'inst-config'   ? loadInstalacionConfig : null
      );
    });
  });

  /* ─── Dashboard ─────────────────────────── */
  async function loadDashboard() {
    const [resVisitas, resResidentes] = await Promise.all([
      api("/visitas/?page_size=100"),
      api("/residentes/")
    ]);

    let visitas = [];
    if (resVisitas && resVisitas.ok) {
      const data = await resVisitas.json();
      visitas = data.visitas || [];
    }

    let residentesCount = 0;
    if (resResidentes && resResidentes.ok) {
      const resList = await resResidentes.json();
      residentesCount = Array.isArray(resList) ? resList.length : 0;
    }

    const hoy = new Date(); hoy.setHours(0, 0, 0, 0);

    const hoyCount      = visitas.filter(v => new Date(v.created_at) >= hoy).length;
    const pendCount     = visitas.filter(v => v.estado === "PENDIENTE" || v.estado === "REVISION").length;
    const pendSolo      = visitas.filter(v => v.estado === "PENDIENTE").length;
    const revSolo       = visitas.filter(v => v.estado === "REVISION").length;
    const aprobHoyCount = visitas.filter(v => new Date(v.created_at) >= hoy && v.estado === "APROBADO").length;

    animateStat("stat-hoy",        hoyCount);
    animateStat("stat-pendientes", pendCount);
    animateStat("stat-aprobadas",  aprobHoyCount);
    animateStat("stat-residentes", residentesCount);

    const subPend = document.getElementById("stat-sub-pendientes");
    if (subPend) {
      if (pendCount > 0) {
        subPend.textContent = `${pendSolo} ${lang === 'en' ? 'pending' : 'pendientes'} · ${revSolo} ${lang === 'en' ? 'in review' : 'en revisión'}`;
      } else {
        subPend.textContent = lang === 'en' ? "Up to date" : "Al día";
      }
    }

    const container = document.getElementById("dash-recent-rows");
    const recent = visitas.slice(0, 8);
    if (recent.length === 0) {
      container.innerHTML = `<div class="empty-state"><div class="empty-icon"><svg width="22" height="22" viewBox="0 0 18 18" fill="none" stroke="currentColor" stroke-width="1.6"><circle cx="4" cy="4.5" r="1.7"/><line x1="8" y1="4.5" x2="16" y2="4.5"/><circle cx="4" cy="9" r="1.7"/><line x1="8" y1="9" x2="16" y2="9"/><circle cx="4" cy="13.5" r="1.7"/><line x1="8" y1="13.5" x2="16" y2="13.5"/></svg></div><div class="empty-title">${t("vis_empty_title")}</div><div class="empty-text">${t("vis_empty_text")}</div></div>`;
      return;
    }
    container.innerHTML = recent.map((v, i) => renderDashRow(v, i)).join("");
    container.querySelectorAll("[data-id]").forEach(row => {
      row.addEventListener("click", () => loadDetalle(row.dataset.id));
    });
  }

  function animateStat(id, value) {
    const el = document.getElementById(id);
    if (!el) return;
    el.textContent = "0";
    const duration = 600;
    const start = performance.now();
    const step = ts => {
      const p = Math.min((ts - start) / duration, 1);
      el.textContent = Math.round(p * value);
      if (p < 1) requestAnimationFrame(step);
    };
    requestAnimationFrame(step);
  }

  function renderDashRow(v, i) {
    const tvBadge = TIPO_VIS_BADGE[v.tipo_visitante] || "";
    const tvLabel = tipoVisLabel(v.tipo_visitante);
    return `<div class="row-item" style="grid-template-columns:2fr auto 1fr 80px;gap:12px;align-items:center;animation-delay:${i*40}ms" data-id="${v.id}">
      <div>
        <div class="row-name">${esc(v.titular)}</div>
        <div class="row-sub">${esc(v.casa_destino || "")}</div>
      </div>
      <div><span class="badge ${tvBadge}">${esc(tvLabel)}</span></div>
      <div class="row-date">${fmtDateShort(v.created_at)}</div>
      <div><span class="badge ${ESTADO_BADGE[v.estado] || ""}">${estadoLabel(v.estado)}</span></div>
    </div>`;
  }

  function estadoLabel(e) {
    const map = { PENDIENTE: t("pendiente"), APROBADO: t("aprobado"), RECHAZADO: t("rechazado"), REVISION: t("revision") };
    return map[e] || e;
  }

  function autorizadorLabel(v) {
    if (!v.autorizado_por_tipo) return t("sin_resolver");
    const map = {
      ADMIN: t("autorizador_admin"),
      RESIDENTE: t("autorizador_residente"),
      AGENTE: t("autorizador_agente"),
      SISTEMA: t("autorizador_sistema"),
    };
    const tipo = map[v.autorizado_por_tipo] || v.autorizado_por_tipo;
    return v.autorizado_por_nombre ? `${tipo} — ${esc(v.autorizado_por_nombre)}` : tipo;
  }

  /* ─── Visitas ────────────────────────────── */
  async function loadVisitas(page) {
    state.visPage = page;
    const tipo   = document.getElementById("vis-filter-tipo").value;
    const estado = document.getElementById("vis-filter-estado").value;
    const q      = document.getElementById("vis-quick-search").value.trim();

    let params = `?page=${page}&page_size=${state.visPageSize}`;
    if (tipo)   params += `&tipo_visitante=${tipo}`;
    if (estado) params += `&estado=${estado}`;
    if (q)      params += `&q=${encodeURIComponent(q)}`;

    showVisState("loading");

    const res = await api("/visitas/" + params);
    if (!res || !res.ok) { showVisState("error"); return; }

    const data = await res.json();
    const visitas = data.visitas || [];
    state.visTotal = data.total || 0;

    if (visitas.length === 0) { showVisState("empty"); return; }

    const container = document.getElementById("vis-rows");
    container.innerHTML = visitas.map((v, i) => renderVisRow(v, i)).join("");
    container.querySelectorAll("[data-id]").forEach(row => {
      row.addEventListener("click", () => loadDetalle(row.dataset.id));
    });
    showVisState("rows");

    const totalPages = Math.ceil(state.visTotal / state.visPageSize);
    const pag = document.getElementById("vis-pagination");
    if (totalPages > 1) {
      pag.hidden = false;
      document.getElementById("vis-page-label").textContent = `${state.visTotal} ${lang === "en" ? "records" : "registros"}`;
      document.getElementById("vis-page-current").textContent = page;
      document.getElementById("vis-prev").disabled = page <= 1;
      document.getElementById("vis-next").disabled = page >= totalPages;
    } else {
      pag.hidden = true;
    }

    document.getElementById("vis-subtitle").textContent = `${state.visTotal} ${lang === "en" ? "records" : "registros"}`;
  }

  function showVisState(s) {
    ["loading","rows","empty","error"].forEach(x => {
      const el = document.getElementById(`vis-${x}`);
      if (el) el.hidden = x !== s;
    });
    document.getElementById("vis-pagination").hidden = s !== "rows";
  }

  function renderVisRow(v, i) {
    const acceso = state.accesosById.get(v.kiosko_id);
    const tvBadge = TIPO_VIS_BADGE[v.tipo_visitante] || "";
    const tvLabel = tipoVisLabel(v.tipo_visitante);
    return `<div class="row-item vis-row-grid--list" style="animation-delay:${i*30}ms" data-id="${v.id}">
      <div><div class="row-name">${esc(v.titular)}</div><div class="row-sub">${esc(v.casa_destino || "")}</div></div>
      <div><span class="badge ${tvBadge}">${esc(tvLabel)}</span></div>
      <div class="row-sub">${acceso ? esc(acceso.nombre) : `#${v.kiosko_id}`}</div>
      <div><span class="badge ${ESTADO_BADGE[v.estado] || ""}">${estadoLabel(v.estado)}</span></div>
      <div class="row-date">${fmtDateShort(v.created_at)}</div>
    </div>`;
  }

  document.getElementById("vis-prev")?.addEventListener("click",  () => loadVisitas(state.visPage - 1));
  document.getElementById("vis-next")?.addEventListener("click",  () => loadVisitas(state.visPage + 1));
  document.getElementById("vis-retry")?.addEventListener("click", () => loadVisitas(state.visPage));

  ["vis-quick-search","vis-filter-tipo","vis-filter-estado"].forEach(id => {
    document.getElementById(id)?.addEventListener("input", () => {
      clearTimeout(state.visSearchTimeout);
      state.visSearchTimeout = setTimeout(() => loadVisitas(1), 350);
    });
  });

  /* ─── Detalle de visita + expediente ───── */
  async function loadDetalle(id) {
    navTo("detalle");
    const body = document.getElementById("detalle-body");
    body.innerHTML = `<div class="loading-state"><div class="spinner"></div></div>`;

    const res = await api(`/visitas/${id}`);
    if (!res || !res.ok) {
      body.innerHTML = `<div class="empty-state"><div class="empty-title">${t("load_err_title")}</div></div>`;
      return;
    }
    const v = await res.json();
    const acceso = state.accesosById.get(v.kiosko_id);
    const tvBadge = TIPO_VIS_BADGE[v.tipo_visitante] || "";
    const tvLabel = tipoVisLabel(v.tipo_visitante);

    body.innerHTML = `
      <div class="detalle-hero">
        <div class="detalle-fotos">
          ${v.foto_documento_url ? `<img class="detalle-foto" src="${esc(v.foto_documento_url)}" alt="Documento" loading="lazy">` : ""}
          ${v.foto_rostro_url    ? `<img class="detalle-foto" src="${esc(v.foto_rostro_url)}"    alt="Rostro"    loading="lazy">` : ""}
          ${v.foto_placa_url     ? `<img class="detalle-foto" src="${esc(v.foto_placa_url)}"     alt="Placa"     loading="lazy">` : ""}
        </div>
        <div class="detalle-info">
          <div style="display:flex;gap:8px;align-items:center;flex-wrap:wrap;margin-bottom:8px">
            <span class="badge ${tvBadge}">${esc(tvLabel)}</span>
            ${v.tipo_documento && v.tipo_documento !== v.tipo_visitante ? `<span class="badge ${TIPO_BADGE[v.tipo_documento] || 'badge--neutral'}">${esc(v.tipo_documento)}</span>` : ""}
            <span class="badge ${ESTADO_BADGE[v.estado] || ""}">${estadoLabel(v.estado)}</span>
            ${v.intervenida ? `<span class="badge badge--intervenida">Revisada por IA</span>` : ""}
          </div>
          <div class="detalle-nombre">${esc(v.titular)}</div>
          <div class="row-sub" style="margin-top:4px">${acceso ? esc(acceso.nombre) : `Kiosko #${v.kiosko_id}`} · ${fmtDate(v.created_at)}</div>
          <div class="detalle-campos">
            <div><div class="campo-label">CURP</div><div class="campo-value campo-mono">${esc(v.curp || "—")}</div></div>
            <div><div class="campo-label">${t("casa_destino")}</div><div class="campo-value">${esc(v.casa_destino || "—")}</div></div>
            <div><div class="campo-label">${t("placa")}</div><div class="campo-value">${v.placa ? esc(v.placa) : t("no_placa")}</div></div>
            <div><div class="campo-label">${t("autorizado_por")}</div><div class="campo-value">${autorizadorLabel(v)}</div></div>
          </div>
        </div>
      </div>
      <div class="expediente-section">
        <div class="expediente-header">
          <span class="expediente-title">Historial de esta persona</span>
          <span class="expediente-count" id="exp-count"></span>
        </div>
        <div class="expediente-timeline" id="exp-timeline">
          <div class="loading-state" style="padding:20px"><div class="spinner"></div></div>
        </div>
      </div>`;

    cargarExpediente(v);
  }

  async function cargarExpediente(visitaActual) {
    const timeline = document.getElementById("exp-timeline");
    if (!timeline) return;

    const curp = visitaActual.curp?.trim();
    let mismaPersona = [];

    if (curp) {
      /* /visitas/buscar devuelve VisitaResponse completo (con curp, fotos, etc.) */
      const res = await api(`/visitas/buscar?curp=${encodeURIComponent(curp)}`);
      if (!res || !res.ok) {
        timeline.innerHTML = renderExpEmpty("No se pudo cargar el historial.");
        return;
      }
      const data = await res.json();
      mismaPersona = (data.visitas || []).sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
    } else {
      /* fallback: busca por nombre en la lista paginada */
      const nombre = visitaActual.nombre?.trim();
      if (!nombre) {
        timeline.innerHTML = renderExpEmpty("Sin identificador para buscar historial.");
        return;
      }
      const res = await api(`/visitas/?q=${encodeURIComponent(nombre)}&page_size=100`);
      if (!res || !res.ok) {
        timeline.innerHTML = renderExpEmpty("No se pudo cargar el historial.");
        return;
      }
      const data = await res.json();
      mismaPersona = (data.visitas || []).sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
    }

    const countEl = document.getElementById("exp-count");
    if (countEl) {
      const otras = mismaPersona.filter(v => String(v.id) !== String(visitaActual.id)).length;
      countEl.textContent = otras === 0 ? "primera visita registrada" : `${otras} visita${otras !== 1 ? "s" : ""} anterior${otras !== 1 ? "es" : ""}`;
    }

    if (mismaPersona.length === 0) {
      timeline.innerHTML = renderExpEmpty("Primera visita registrada.");
      return;
    }

    timeline.innerHTML = mismaPersona.map((v, i) => {
      const esCurrent = String(v.id) === String(visitaActual.id);
      const acceso = state.accesosById.get(v.kiosko_id);
      const accNombre = acceso ? esc(acceso.nombre) : `Kiosko #${v.kiosko_id}`;
      const meta = [accNombre, v.casa_destino ? esc(v.casa_destino) : null].filter(Boolean).join(" · ");
      return `<div class="exp-row${esCurrent ? " exp-row--current" : ""}" style="animation-delay:${i*25}ms" data-id="${v.id}">
        <div class="exp-marker"><div class="exp-dot"></div></div>
        <div class="exp-info">
          <div class="exp-nombre">${esc(v.titular)}</div>
          <div class="exp-meta">${meta}</div>
        </div>
        <div class="exp-right">
          <span class="badge ${ESTADO_BADGE[v.estado] || ""}">${estadoLabel(v.estado)}</span>
          <span class="exp-date">${fmtDate(v.created_at)}</span>
          ${esCurrent ? `<span class="exp-current-label">Esta visita</span>` : ""}
        </div>
      </div>`;
    }).join("");

    timeline.querySelectorAll(".exp-row:not(.exp-row--current)").forEach(row => {
      row.addEventListener("click", () => loadDetalle(row.dataset.id));
    });
  }

  function renderExpEmpty(msg) {
    return `<div class="empty-state" style="padding:24px">
      <div class="empty-icon"><svg width="20" height="20" viewBox="0 0 18 18" fill="none" stroke="currentColor" stroke-width="1.6"><circle cx="9" cy="9" r="7"/><line x1="9" y1="6" x2="9" y2="9"/><circle cx="9" cy="12" r=".6" fill="currentColor" stroke="none"/></svg></div>
      <div class="empty-text">${esc(msg)}</div>
    </div>`;
  }

  /* ─── Solicitudes ───────────────────────── */
  function startSolPolling() {
    loadSolicitudes();
    state.solPollingId = setInterval(loadSolicitudes, 15000);
  }

  function stopSolPolling() {
    if (state.solPollingId) {
      clearInterval(state.solPollingId);
      state.solPollingId = null;
    }
  }

  function updateNavBadge(count) {
    const badge = document.getElementById("nav-badge-solicitudes");
    if (!badge) return;
    badge.textContent = count > 99 ? "99+" : String(count);
    badge.hidden = count <= 0;
  }

  function updateNavAlert(activo) {
    const navBtn = document.querySelector('.nav-btn[data-nav="solicitudes"]');
    if (navBtn) navBtn.classList.toggle("nav-btn--alert", activo);
  }

  async function loadSolicitudes() {
    const [resPend, resRev] = await Promise.all([
      api("/visitas/?estado=PENDIENTE&page_size=50"),
      api("/visitas/?estado=REVISION&page_size=50"),
    ]);
    const now = new Date();
    const timeStr = `${now.getHours().toString().padStart(2,"0")}:${now.getMinutes().toString().padStart(2,"0")}`;
    const lastEl = document.getElementById("sol-last-update");
    if (lastEl) lastEl.textContent = timeStr;

    if (!resPend || !resPend.ok || !resRev || !resRev.ok) {
      showSolState("error");
      return;
    }

    const dataPend = await resPend.json();
    const dataRev = await resRev.json();
    const revisionCount = (dataRev.visitas || []).length;
    const visitas = [...(dataPend.visitas || []), ...(dataRev.visitas || [])]
      .sort((a, b) => new Date(a.created_at) - new Date(b.created_at));

    const countEl = document.getElementById("sol-count");
    if (countEl) countEl.textContent = visitas.length || "0";
    updateNavBadge(visitas.length);
    updateNavAlert(revisionCount > 0);

    if (visitas.length === 0) {
      showSolState("empty");
      return;
    }

    const container = document.getElementById("sol-rows");
    if (!container) return;
    container.innerHTML = visitas.map((v, i) => renderSolRow(v, i)).join("");

    container.querySelectorAll("[data-aprobar]").forEach(btn => {
      btn.addEventListener("click", () => actualizarEstado(btn.dataset.aprobar, "APROBADO"));
    });
    container.querySelectorAll("[data-rechazar]").forEach(btn => {
      btn.addEventListener("click", () => actualizarEstado(btn.dataset.rechazar, "RECHAZADO"));
    });

    showSolState("rows");
  }

  function showSolState(s) {
    ["loading","empty","error"].forEach(x => {
      const el = document.getElementById(`sol-${x}`);
      if (el) el.hidden = x !== s;
    });
    const rows = document.getElementById("sol-rows");
    if (rows) rows.hidden = s !== "rows";
  }

  function renderSolRow(v, i) {
    const acceso = state.accesosById.get(v.kiosko_id);
    return `<div class="sol-card" style="animation-delay:${i*40}ms">
      <div class="sol-card-left">
        <div class="feed-dot"></div>
        <div>
          <div class="row-name">${esc(v.titular)} <span class="badge ${ESTADO_BADGE[v.estado] || ""}">${estadoLabel(v.estado)}</span></div>
          <div class="row-sub">${acceso ? esc(acceso.nombre) : `Kiosko #${v.kiosko_id}`} · ${esc(v.casa_destino || "sin destino")} · <span class="feed-elapsed">${fmtElapsed(v.created_at)}</span></div>
        </div>
      </div>
      <div class="sol-card-actions">
        <button class="btn-aprobar" data-aprobar="${v.id}">Aprobar</button>
        <button class="btn-rechazar" data-rechazar="${v.id}">Rechazar</button>
      </div>
    </div>`;
  }

  async function actualizarEstado(id, estado) {
    const res = await api(`/visitas/${id}/estado`, {
      method: "PATCH",
      body: JSON.stringify({ estado }),
    });
    if (res && res.ok) loadSolicitudes();
  }

  /* ─── Residentes ────────────────────────── */
  async function loadResidentes() {
    const loadEl  = document.getElementById("res-loading");
    const emptyEl = document.getElementById("res-empty");
    const gridEl  = document.getElementById("res-grid");

    if (loadEl)  loadEl.hidden = false;
    if (emptyEl) emptyEl.hidden = true;
    if (gridEl)  gridEl.innerHTML = "";

    const res = await api("/residentes/");
    if (loadEl) loadEl.hidden = true;

    if (!res || !res.ok) {
      if (gridEl) gridEl.innerHTML = `<div class="empty-title">${t("load_err_title")}</div>`;
      return;
    }

    state.residentesFull = await res.json();
    renderResidentesGrid(state.residentesFull);
  }

  function renderResidentesGrid(list) {
    const emptyEl = document.getElementById("res-empty");
    const gridEl  = document.getElementById("res-grid");

    if (list.length === 0) {
      if (emptyEl) emptyEl.hidden = false;
      if (gridEl)  gridEl.innerHTML = "";
      return;
    }
    if (emptyEl) emptyEl.hidden = true;
    if (gridEl) {
      gridEl.innerHTML = list.map((r, i) => renderResidenteCard(r, i)).join("");
      gridEl.querySelectorAll("[data-residente-id]").forEach(card => {
        card.addEventListener("click", () => loadResidenteDetalle(card.dataset.residenteId));
      });
    }
  }

  function renderResidenteCard(r, i) {
    const initials = ((r.nombre?.[0] || "") + (r.apellido_paterno?.[0] || "")).toUpperCase();
    const nombre   = [r.nombre, r.apellido_paterno, r.apellido_materno].filter(Boolean).join(" ");
    return `<div class="residente-card" style="animation-delay:${i*30}ms" data-residente-id="${r.id}">
      <div class="avatar avatar--lg">${esc(initials) || "·"}</div>
      <div class="residente-card-info">
        <div class="residente-card-nombre">${esc(nombre)}</div>
        <div class="residente-card-casa">${esc(r.casa_destino || "—")}</div>
        ${r.telefono ? `<div class="row-sub">${esc(r.telefono)}</div>` : ""}
      </div>
      <div class="residente-card-arrow">›</div>
    </div>`;
  }

  document.getElementById("res-search")?.addEventListener("input", e => {
    clearTimeout(state.resSearchTimeout);
    state.resSearchTimeout = setTimeout(() => {
      const q = e.target.value.toLowerCase();
      const filtered = state.residentesFull.filter(r => {
        const nombre = [r.nombre, r.apellido_paterno, r.apellido_materno].filter(Boolean).join(" ").toLowerCase();
        return nombre.includes(q) || (r.casa_destino || "").toLowerCase().includes(q);
      });
      renderResidentesGrid(filtered);
    }, 250);
  });

  async function loadResidenteDetalle(residenteId) {
    navTo("residente-detalle");
    const body = document.getElementById("residente-detalle-body");
    body.innerHTML = `<div class="loading-state"><div class="spinner"></div></div>`;

    const res = await api(`/residentes/${residenteId}/me`.replace("/me",""));

    let r = state.residentesFull.find(x => String(x.id) === String(residenteId));
    if (!r) {
      body.innerHTML = `<div class="empty-state"><div class="empty-title">${t("load_err_title")}</div></div>`;
      return;
    }

    const nombre   = [r.nombre, r.apellido_paterno, r.apellido_materno].filter(Boolean).join(" ");
    const initials = ((r.nombre?.[0] || "") + (r.apellido_paterno?.[0] || "")).toUpperCase();
    const accesoNombre = state.accesosById.get(r.kiosko_id)?.nombre || `Kiosko #${r.kiosko_id || "—"}`;

    body.innerHTML = `
      <div class="panel panel-padded" style="margin-bottom:16px">
        <div class="profile-head">
          <div class="avatar avatar--lg">${esc(initials) || "·"}</div>
          <div>
            <div class="profile-name">${esc(nombre)}</div>
            <div class="profile-role">${esc(accesoNombre)} · ${esc(r.casa_destino || "—")}</div>
          </div>
        </div>
        <div class="detalle-campos" style="margin-top:16px">
          <div><div class="campo-label">Casa / Destino</div><div class="campo-value">${esc(r.casa_destino || "—")}</div></div>
          ${r.telefono ? `<div><div class="campo-label">Teléfono</div><div class="campo-value">${esc(r.telefono)}</div></div>` : ""}
          ${r.tiempo_espera_seg !== undefined && r.tiempo_espera_seg !== null
            ? `<div><div class="campo-label">Tiempo de espera</div><div class="campo-value">${r.tiempo_espera_seg} s</div></div>`
            : ""}
        </div>
      </div>

      <div class="panel panel-padded" style="margin-bottom:16px">
        <div class="panel-header" style="margin-bottom:12px">
          <div class="panel-title">Invitación QR</div>
          <span class="row-sub">Placeholder — invitaciones aún no implementadas</span>
        </div>
        <div id="qr-placeholder" style="display:flex;align-items:center;gap:16px">
          <canvas id="qr-canvas" width="120" height="120" style="border-radius:8px;background:var(--bg-2)"></canvas>
          <div class="row-sub" style="font-size:12px">El QR real se generará cuando se implemente el modelo de invitaciones.<br>Este es un QR de demostración con el ID del residente.</div>
        </div>
      </div>

      <div class="panel">
        <div class="panel-header">
          <div class="panel-title">Historial de visitas</div>
        </div>
        <div id="residente-visitas-rows">
          <div class="loading-state"><div class="spinner"></div></div>
        </div>
      </div>`;

    renderQRPlaceholder(r.id, "qr-canvas");
    loadResidenteVisitas(r);
  }

  function renderQRPlaceholder(id, canvasId) {
    const canvas = document.getElementById(canvasId);
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    const size = canvas.width;
    const cellSize = 4;
    const cols = Math.floor(size / cellSize);

    const data = `AUTONOMIA:RESIDENTE:${id}`;
    let hash = 0;
    for (let i = 0; i < data.length; i++) hash = (Math.imul(31, hash) + data.charCodeAt(i)) | 0;

    const isDark = document.documentElement.dataset.theme === "dark";
    const fg = isDark ? "#FFFFFF" : "#111111";
    const bg = isDark ? "#1a1a1a" : "#F5F5F5";

    ctx.fillStyle = bg;
    ctx.fillRect(0, 0, size, size);
    ctx.fillStyle = fg;

    for (let y = 0; y < cols; y++) {
      for (let x = 0; x < cols; x++) {
        const bit = (hash ^ (x * 7 + y * 13) ^ (x ^ y)) & 1;
        if (bit) ctx.fillRect(x * cellSize, y * cellSize, cellSize - 1, cellSize - 1);
      }
    }

    ctx.fillStyle = bg;
    ctx.fillRect(0, 0, 28, 28);
    ctx.fillRect(size - 28, 0, 28, 28);
    ctx.fillRect(0, size - 28, 28, 28);
    ctx.fillStyle = fg;
    [0, size - 28, 0].forEach((ox, i) => {
      const oy = i === 2 ? size - 28 : i * (size - 28);
      ctx.fillRect(ox, oy, 24, 24);
      ctx.fillStyle = bg;
      ctx.fillRect(ox + 4, oy + 4, 16, 16);
      ctx.fillStyle = fg;
      ctx.fillRect(ox + 8, oy + 8, 8, 8);
    });
  }

  async function loadResidenteVisitas(r) {
    const container = document.getElementById("residente-visitas-rows");
    if (!container) return;

    const q = [r.nombre, r.apellido_paterno].filter(Boolean).join(" ");
    const res = await api(`/visitas/?q=${encodeURIComponent(q)}&page_size=20`);
    if (!res || !res.ok) {
      container.innerHTML = `<div class="empty-state"><div class="empty-title">${t("load_err_title")}</div></div>`;
      return;
    }

    const data = await res.json();
    const visitas = (data.visitas || []).filter(v => v.kiosko_id === r.kiosko_id);

    if (visitas.length === 0) {
      container.innerHTML = `<div class="empty-state"><div class="empty-icon"><svg width="22" height="22" viewBox="0 0 18 18" fill="none" stroke="currentColor" stroke-width="1.6"><circle cx="4" cy="4.5" r="1.7"/><line x1="8" y1="4.5" x2="16" y2="4.5"/><circle cx="4" cy="9" r="1.7"/><line x1="8" y1="9" x2="16" y2="9"/><circle cx="4" cy="13.5" r="1.7"/><line x1="8" y1="13.5" x2="16" y2="13.5"/></svg></div><div class="empty-title">Sin entradas registradas</div><div class="empty-text">Este residente aún no registra entradas ni invitaciones.</div></div>`;
      return;
    }

    container.innerHTML = visitas.map((v, i) => `
      <div class="row-item" style="grid-template-columns:2fr 1fr 80px;animation-delay:${i*30}ms" data-id="${v.id}">
        <div>
          <div class="row-name">${esc(v.titular)}</div>
          <div class="row-sub">${esc(v.casa_destino || "—")}</div>
        </div>
        <div class="row-date">${fmtDate(v.created_at)}</div>
        <div><span class="badge ${ESTADO_BADGE[v.estado] || ""}">${estadoLabel(v.estado)}</span></div>
      </div>`).join("");

    container.querySelectorAll("[data-id]").forEach(row => {
      row.addEventListener("click", () => loadDetalle(row.dataset.id));
    });
  }

  document.getElementById("btn-nuevo-residente")?.addEventListener("click", () => {
    alert("Formulario de nuevo residente — próximamente.");
  });

  /* ─── Accesos ────────────────────────────── */
  async function loadAccesos() {
    const loadEl  = document.getElementById("kio-loading");
    const emptyEl = document.getElementById("kio-empty");
    const container = document.getElementById("accesos-list");

    if (loadEl) loadEl.hidden = false;
    if (emptyEl) emptyEl.hidden = true;
    if (container) container.innerHTML = "";

    const res = await api("/kioskos/");
    if (loadEl) loadEl.hidden = true;

    if (!res || !res.ok) {
      if (container) container.innerHTML = `<div class="empty-state"><div class="empty-icon empty-icon--err"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"><path d="M12 4 L21 19 H3 Z"/><line x1="12" y1="10" x2="12" y2="14"/><circle cx="12" cy="16.6" r=".6" fill="currentColor" stroke="none"/></svg></div><div class="empty-title">${t("load_err_title")}</div><div class="empty-text">${t("load_err_text")}</div></div>`;
      return;
    }

    const data = await res.json();
    const list = Array.isArray(data) ? data : (data.kioskos || []);
    list.forEach(a => state.accesosById.set(a.id, a));

    if (list.length === 0) {
      if (emptyEl) emptyEl.hidden = false;
      return;
    }

    if (emptyEl) emptyEl.hidden = true;
    container.innerHTML = list.map(a => `
      <div class="acceso-card">
        <div class="acceso-info">
          <div class="acceso-nombre">${esc(a.nombre)}</div>
          ${a.ubicacion ? `<div class="acceso-ubi">${esc(a.ubicacion)}</div>` : ""}
          <div class="acceso-id">ID ${a.id} · ${esc(a.tipo || "—")}</div>
        </div>
        <div class="acceso-actions">
          <button class="btn-ghost" data-cfg-acceso="${a.id}" title="Configuración">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6z"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>
          </button>
          <button class="btn-ghost" data-edit-acceso="${a.id}" title="Editar">
            <svg width="14" height="14" viewBox="0 0 18 18" fill="none" stroke="currentColor" stroke-width="1.7"><path d="M12 3l3 3-9 9H3v-3z"/></svg>
          </button>
          <button class="btn-ghost" data-del-acceso="${a.id}" style="color:var(--red)" title="Eliminar">
            <svg width="14" height="14" viewBox="0 0 18 18" fill="none" stroke="currentColor" stroke-width="1.7"><line x1="4" y1="5" x2="14" y2="5"/><path d="M6 5V3.5h6V5"/><path d="M5 5l.7 9a1 1 0 0 0 1 .9h4.6a1 1 0 0 0 1-.9L13 5"/></svg>
          </button>
        </div>
      </div>`).join("");

    container.querySelectorAll("[data-cfg-acceso]").forEach(btn => {
      btn.addEventListener("click", () => openConfigParaAcceso(parseInt(btn.dataset.cfgAcceso)));
    });
    container.querySelectorAll("[data-edit-acceso]").forEach(btn => {
      btn.addEventListener("click", () => openAccesoModal(parseInt(btn.dataset.editAcceso)));
    });
    container.querySelectorAll("[data-del-acceso]").forEach(btn => {
      btn.addEventListener("click", () => openDeleteModal(parseInt(btn.dataset.delAcceso)));
    });
  }

  document.getElementById("btn-nuevo-acceso")?.addEventListener("click", () => openNuevoKioskoWizard());

  /* ─── Wizard: nuevo kiosko ───────────────── */
  let nkPendingCode = '';

  function setNkStep(n) {
    [1,2,3].forEach(i => {
      const step = document.getElementById(`nk-step-${i}`);
      if (step) step.hidden = i !== n;
      const dot = document.getElementById(`nk-dot-${i}`);
      if (dot) {
        dot.classList.toggle('active', i===n);
        dot.classList.toggle('done',   i<n);
      }
    });
    [1,2].forEach(i => {
      document.getElementById(`nk-line-${i}`)?.classList.toggle('done', i<n);
    });
  }

  // onCreado: se llama en cuanto el kiosko queda vinculado al dispositivo
  // (aunque el admin todavía no haya guardado/saltado el paso de
  // configuración) — es el momento en que el kiosko "existe" de verdad.
  // onCancelado: se llama solo si se cierra el wizard sin haber llegado ahí.
  let nkOnCreado = null;
  let nkOnCancelado = null;

  function openNuevoKioskoWizard(onCreado, onCancelado) {
    nkOnCreado = onCreado || null;
    nkOnCancelado = onCancelado || null;
    nkPendingCode = '';
    document.getElementById('nk-code').value = '';
    document.getElementById('nk-code-error').hidden = true;
    document.getElementById('nk-nombre').value = '';
    document.getElementById('nk-tipo').value = 'PEATONAL';
    document.getElementById('nk-ubicacion').value = '';
    document.getElementById('nk-form-error').hidden = true;
    setNkStep(1);
    document.getElementById('modal-nuevo-kiosko').hidden = false;
  }

  function cerrarNuevoKioskoWizard() {
    document.getElementById('modal-nuevo-kiosko').hidden = true;
  }

  document.getElementById('nk-cancel-1')?.addEventListener('click', () => {
    cerrarNuevoKioskoWizard();
    const cb = nkOnCancelado;
    nkOnCreado = null;
    nkOnCancelado = null;
    if (cb) cb();
  });
  document.getElementById('nk-back-2')?.addEventListener('click', () => setNkStep(1));

  document.getElementById('nk-verificar')?.addEventListener('click', async () => {
    const code  = document.getElementById('nk-code').value.trim().toUpperCase();
    const errEl = document.getElementById('nk-code-error');
    errEl.hidden = true;
    if (!code || code.length < 9) {
      errEl.textContent = 'Ingresa el código con formato XXXX-XXXX';
      errEl.hidden = false;
      return;
    }
    const res = await api(`/device/validar?user_code=${encodeURIComponent(code)}`);
    if (!res) return;
    if (!res.ok) {
      errEl.textContent = 'Código inválido o ya utilizado';
      errEl.hidden = false;
      return;
    }
    const d = await res.json();
    if (!d.valid) {
      errEl.textContent = 'El código no está activo o ya expiró';
      errEl.hidden = false;
      return;
    }
    nkPendingCode = d.user_code || code;
    setNkStep(2);
  });

  document.getElementById('nk-code')?.addEventListener('input', e => {
    let v = e.target.value.replace(/[^A-Za-z0-9]/g, '').toUpperCase();
    if (v.length > 4) v = v.slice(0, 4) + '-' + v.slice(4, 8);
    e.target.value = v;
  });

  document.getElementById('nk-code')?.addEventListener('keydown', e => {
    if (e.key === 'Enter') document.getElementById('nk-verificar')?.click();
  });

  document.getElementById('nk-form')?.addEventListener('submit', async e => {
    e.preventDefault();
    const errEl = document.getElementById('nk-form-error');
    errEl.hidden = true;

    const nombre    = document.getElementById('nk-nombre').value.trim();
    const tipo      = document.getElementById('nk-tipo').value;
    const ubicacion = document.getElementById('nk-ubicacion').value.trim();

    const resKiosko = await api('/kioskos/', { method: 'POST', body: JSON.stringify({ nombre, tipo, ubicacion }) });
    if (!resKiosko) return;
    if (!resKiosko.ok) {
      const d = await resKiosko.json();
      errEl.textContent = d.error || 'Error al crear kiosko';
      errEl.hidden = false;
      return;
    }
    const kiosko = await resKiosko.json();
    state.accesosById.set(kiosko.id, kiosko);

    const resAprobar = await api(`/device/${encodeURIComponent(nkPendingCode)}/aprobar`, {
      method: 'POST', body: JSON.stringify({ kiosko_id: kiosko.id, clave_kiosko: kiosko.clave_kiosko || '' }),
    });
    if (!resAprobar || !resAprobar.ok) {
      errEl.textContent = 'Kiosko creado pero no se pudo vincular al dispositivo';
      errEl.hidden = false;
      return;
    }

    nkNuevoKioskoId = kiosko.id;
    setNkStep(3);
    loadAccesos();

    const cb = nkOnCreado;
    nkOnCreado = null;
    nkOnCancelado = null;
    if (cb) cb();
  });

  let nkNuevoKioskoId = null;

  async function nkGuardarConfig() {
    if (!nkNuevoKioskoId) { cerrarNuevoKioskoWizard(); return; }
    const errEl = document.getElementById('nk-cfg-error');
    errEl.hidden = true;
    const payload = {
      color_kiosko:          document.getElementById('nk-cfg-color').value,
      idioma_kiosko:         document.getElementById('nk-cfg-idioma').value,
      foto_rostro_visitante: document.getElementById('nk-cfg-rostro').checked,
      auto_pass_habilitado:  document.getElementById('nk-cfg-autopass').checked,
      mensaje_bienvenida:    document.getElementById('nk-cfg-mensaje').value.trim(),
    };
    const res = await api(`/kioskos/${nkNuevoKioskoId}/config`, {
      method: 'PATCH', body: JSON.stringify(payload),
    });
    if (!res || !res.ok) {
      const d = res ? await res.json() : {};
      errEl.textContent = d.error || 'Error al guardar configuración';
      errEl.hidden = false;
      return;
    }
    cerrarNuevoKioskoWizard();
    mostrarToast('Kiosko configurado y listo', 'ok');
  }

  document.getElementById('nk-cfg-guardar')?.addEventListener('click', nkGuardarConfig);
  document.getElementById('nk-cfg-saltar')?.addEventListener('click', () => {
    cerrarNuevoKioskoWizard();
    mostrarToast('Kiosko activado. Configúralo cuando quieras desde Kioskos.', 'ok');
  });

  /* ─── Modal: editar kiosko ───────────────── */
  function openAccesoModal(accesoId) {
    if (!accesoId) return;
    state.editingAccesoId = accesoId;
    const a = state.accesosById.get(accesoId);
    document.getElementById("acceso-nombre").value    = a?.nombre    || "";
    document.getElementById("acceso-tipo").value      = a?.tipo      || "PEATONAL";
    document.getElementById("acceso-ubicacion").value = a?.ubicacion || "";
    document.getElementById("acceso-form-error").hidden = true;
    document.getElementById("modal-acceso").hidden = false;
  }

  document.getElementById("acceso-cancel")?.addEventListener("click", () => {
    document.getElementById("modal-acceso").hidden = true;
  });

  document.getElementById("acceso-form")?.addEventListener("submit", async e => {
    e.preventDefault();
    const errEl = document.getElementById("acceso-form-error");
    errEl.hidden = true;
    const body = {
      nombre:    document.getElementById("acceso-nombre").value.trim(),
      tipo:      document.getElementById("acceso-tipo").value,
      ubicacion: document.getElementById("acceso-ubicacion").value.trim(),
    };
    const res = await api(`/kioskos/${state.editingAccesoId}`, { method: "PATCH", body: JSON.stringify(body) });
    if (!res) return;
    if (!res.ok) {
      const data = await res.json();
      errEl.textContent = data.error || "Error";
      errEl.hidden = false;
      return;
    }
    document.getElementById("modal-acceso").hidden = true;
    await loadAccesos();
    mostrarToast("Kiosko actualizado", "ok");
  });

  function openDeleteModal(accesoId) {
    state.deletingAccesoId = accesoId;
    const a = state.accesosById.get(accesoId);
    document.getElementById("modal-delete-title").textContent = `¿${t("delete")} "${a?.nombre || `#${accesoId}`}"?`;
    document.getElementById("modal-delete").hidden = false;
  }

  document.getElementById("delete-cancel")?.addEventListener("click", () => {
    document.getElementById("modal-delete").hidden = true;
  });

  document.getElementById("delete-confirm")?.addEventListener("click", async () => {
    const res = await api(`/kioskos/${state.deletingAccesoId}`, { method: "DELETE" });
    document.getElementById("modal-delete").hidden = true;
    if (res && res.ok) await loadAccesos();
  });

  document.addEventListener("keydown", e => {
    if (e.key === "Escape") {
      document.querySelectorAll(".modal-overlay").forEach(m => m.hidden = true);
    }
  });

  /* ─── Configuración ─────────────────────── */
  let cfgAccesoId = null;

  async function openConfigParaAcceso(accesoId) {
    // Mostrar screen-configuracion sin pasar por navTo (que requeriría la ruta en RUTAS_POR_ROL)
    document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
    document.querySelectorAll('.nav-btn').forEach(b => b.classList.remove('active'));
    const screenEl = document.getElementById('screen-configuracion');
    if (screenEl) { screenEl.hidden = false; screenEl.classList.add('active'); }
    stopSolPolling();

    await loadConfigAccesos();
    const select = document.getElementById('cfg-acceso-select');
    if (select) select.value = accesoId;
    cfgAccesoId = accesoId;
    await loadConfig(accesoId);
  }

  async function loadConfigAccesos() {
    const select = document.getElementById("cfg-acceso-select");
    if (!select) return;

    if (state.accesosById.size === 0) await preloadAccesos();

    select.innerHTML = `<option value="">— Selecciona un acceso —</option>`;
    state.accesosById.forEach(a => {
      const opt = document.createElement("option");
      opt.value = a.id;
      opt.textContent = `${a.nombre}${a.ubicacion ? ` (${a.ubicacion})` : ""}`;
      select.appendChild(opt);
    });

    document.getElementById("cfg-form-wrap").hidden = true;
    document.getElementById("cfg-idle").hidden = false;
  }

  document.getElementById("cfg-acceso-select")?.addEventListener("change", async e => {
    const id = parseInt(e.target.value);
    if (!id) {
      document.getElementById("cfg-form-wrap").hidden = true;
      document.getElementById("cfg-idle").hidden = false;
      return;
    }
    cfgAccesoId = id;
    await loadConfig(id);
  });

  const PIPELINE_DEFS = {
    ROSTRO: {
      id: "ROSTRO",
      icon: "👤",
      title: "Foto de Rostro",
      desc: "Captura facial de verificación y reconocimiento",
      defaultChecked: true,
    },
    DESTINO: {
      id: "DESTINO",
      icon: "🏠",
      title: "Selección de Destino",
      desc: "Búsqueda y selección de calle, edificio o casa",
      defaultChecked: true,
    },
    PLACA: {
      id: "PLACA",
      icon: "🚗",
      title: "Captura de Placa Vehicular",
      desc: "Lectura de matrícula (obligatoria en accesos vehiculares)",
      defaultChecked: false,
    },
    INE: {
      id: "INE",
      icon: "🪪",
      title: "Escaneo de INE / Identificación",
      desc: "Lectura de credencial con OCR (opcional según hardware)",
      defaultChecked: false,
    },
  };

  function renderPipeline(cfg, esPeatonal) {
    const listEl = document.getElementById("cfg-pipeline-list");
    if (!listEl) return;
    listEl.innerHTML = "";

    const rawPasos = Array.isArray(cfg.pasos_sin_invitacion) && cfg.pasos_sin_invitacion.length
      ? cfg.pasos_sin_invitacion
      : (esPeatonal ? ["ROSTRO", "DESTINO"] : ["PLACA", "ROSTRO", "DESTINO"]);

    const orderedIds = [...new Set([...rawPasos, "ROSTRO", "DESTINO", "PLACA", "INE"])];

    const checkedMap = {
      ROSTRO: cfg.foto_rostro_visitante !== undefined ? !!cfg.foto_rostro_visitante : true,
      DESTINO: true,
      PLACA: !esPeatonal ? true : !!cfg.foto_placa_visitante,
      INE: !!cfg.foto_ine_visitante,
    };

    orderedIds.forEach((stepId) => {
      const def = PIPELINE_DEFS[stepId];
      if (!def) return;

      const isChecked = checkedMap[stepId] ?? def.defaultChecked;
      const isPlacaVehicular = !esPeatonal && stepId === "PLACA";

      const item = document.createElement("div");
      item.className = `pipeline-item ${!isChecked ? "disabled" : ""}`;
      item.draggable = true;
      item.dataset.stepId = stepId;

      item.innerHTML = `
        <div class="pipeline-handle" title="Arrastrar para reordenar">⠿</div>
        <div class="pipeline-order-badge">—</div>
        <div class="pipeline-icon">${def.icon}</div>
        <div class="pipeline-info">
          <div class="pipeline-title">${def.title}</div>
          <div class="pipeline-desc">${def.desc}</div>
        </div>
        <div class="pipeline-actions">
          <div class="pipeline-move-btns">
            <button type="button" class="pipeline-btn-move btn-move-up" title="Mover arriba">▲</button>
            <button type="button" class="pipeline-btn-move btn-move-down" title="Mover abajo">▼</button>
          </div>
          <label class="toggle-switch">
            <input type="checkbox" class="pipeline-toggle" ${isChecked ? "checked" : ""} ${isPlacaVehicular ? "disabled" : ""}>
            <span class="toggle-slider"></span>
          </label>
        </div>
      `;

      const toggle = item.querySelector(".pipeline-toggle");
      toggle.addEventListener("change", () => {
        item.classList.toggle("disabled", !toggle.checked);
        updatePipelineBadges();
      });

      item.querySelector(".btn-move-up").addEventListener("click", (e) => {
        e.stopPropagation();
        const prev = item.previousElementSibling;
        if (prev) {
          listEl.insertBefore(item, prev);
          updatePipelineBadges();
        }
      });
      item.querySelector(".btn-move-down").addEventListener("click", (e) => {
        e.stopPropagation();
        const next = item.nextElementSibling;
        if (next) {
          listEl.insertBefore(next, item);
          updatePipelineBadges();
        }
      });

      item.addEventListener("dragstart", (e) => {
        item.classList.add("dragging");
        e.dataTransfer.effectAllowed = "move";
        e.dataTransfer.setData("text/plain", stepId);
      });

      item.addEventListener("dragend", () => {
        item.classList.remove("dragging");
        listEl.querySelectorAll(".pipeline-item").forEach(el => el.classList.remove("drag-over"));
        updatePipelineBadges();
      });

      item.addEventListener("dragover", (e) => {
        e.preventDefault();
        e.dataTransfer.dropEffect = "move";
        const dragging = listEl.querySelector(".dragging");
        if (dragging && dragging !== item) {
          const rect = item.getBoundingClientRect();
          const next = (e.clientY - rect.top) / (rect.bottom - rect.top) > 0.5;
          listEl.insertBefore(dragging, next ? item.nextSibling : item);
        }
      });

      listEl.appendChild(item);
    });

    updatePipelineBadges();
  }

  function updatePipelineBadges() {
    const listEl = document.getElementById("cfg-pipeline-list");
    if (!listEl) return;
    let order = 1;
    listEl.querySelectorAll(".pipeline-item").forEach((item) => {
      const badge = item.querySelector(".pipeline-order-badge");
      const toggle = item.querySelector(".pipeline-toggle");
      if (toggle && toggle.checked) {
        badge.textContent = order++;
      } else {
        badge.textContent = "—";
      }
    });
  }

  async function loadConfig(accesoId) {
    const wrap = document.getElementById("cfg-form-wrap");
    const idle = document.getElementById("cfg-idle");

    const res = await api(`/kioskos/${accesoId}/config`);
    if (!res || !res.ok) {
      alert("No se pudo cargar la configuración.");
      return;
    }

    const cfg = await res.json();
    const acceso = state.accesosById.get(accesoId);
    const esPeatonal = acceso?.tipo === "PEATONAL";

    // badge de tipo
    const tipoBadge = document.getElementById("cfg-tipo-badge");
    if (tipoBadge) {
      tipoBadge.textContent = acceso?.tipo || "—";
      tipoBadge.style.background = esPeatonal ? "#1e3a2f" : "#1e2d3a";
      tipoBadge.style.color      = esPeatonal ? "#4ade80" : "#60a5fa";
    }

    document.getElementById("cfg-color").value        = cfg.color_kiosko       || "oscuro";
    document.getElementById("cfg-idioma").value       = cfg.idioma_kiosko      || "es";
    document.getElementById("cfg-mensaje").value      = cfg.mensaje_bienvenida || "";
    document.getElementById("cfg-ine-invitado").checked     = !!cfg.foto_ine_invitado;
    document.getElementById("cfg-rostro-invitado").checked  = !!cfg.foto_rostro_invitado;
    document.getElementById("cfg-placa-invitado").checked   = esPeatonal ? false : !!cfg.foto_placa_invitado;
    document.getElementById("cfg-tiempo-espera").value = cfg.tiempo_espera_seg ?? 60;
    document.getElementById("cfg-horario-inicio").value = cfg.horario_inicio || "00:00";
    document.getElementById("cfg-horario-fin").value    = cfg.horario_fin    || "23:59";

    const rowPlacaInv = document.getElementById("cfg-row-placa-invitado");
    if (rowPlacaInv) rowPlacaInv.style.opacity = esPeatonal ? "0.35" : "1";
    document.getElementById("cfg-placa-invitado").disabled = esPeatonal;

    // Renderizar pipeline arrastrable
    renderPipeline(cfg, esPeatonal);

    document.getElementById("cfg-error").hidden   = true;
    document.getElementById("cfg-success").hidden = true;
    idle.hidden = true;
    wrap.hidden = false;
  }

  document.getElementById("cfg-save-btn")?.addEventListener("click", async () => {
    if (!cfgAccesoId) return;
    const errEl = document.getElementById("cfg-error");
    const okEl  = document.getElementById("cfg-success");
    errEl.hidden = true;
    okEl.hidden  = true;

    const listEl = document.getElementById("cfg-pipeline-list");
    const activeSteps = [];
    let fotoRostro = false, fotoPlaca = false, fotoIne = false;

    if (listEl) {
      listEl.querySelectorAll(".pipeline-item").forEach((item) => {
        const stepId = item.dataset.stepId;
        const toggle = item.querySelector(".pipeline-toggle");
        if (toggle && toggle.checked) {
          activeSteps.push(stepId);
          if (stepId === "ROSTRO") fotoRostro = true;
          if (stepId === "PLACA") fotoPlaca = true;
          if (stepId === "INE") fotoIne = true;
        }
      });
    }

    const payload = {
      color_kiosko:          document.getElementById("cfg-color").value,
      idioma_kiosko:         document.getElementById("cfg-idioma").value,
      mensaje_bienvenida:    document.getElementById("cfg-mensaje").value,
      foto_rostro_visitante: fotoRostro,
      foto_placa_visitante:  fotoPlaca,
      foto_ine_visitante:    fotoIne,
      pasos_sin_invitacion:  activeSteps,
      foto_ine_invitado:     document.getElementById("cfg-ine-invitado").checked,
      foto_rostro_invitado:  document.getElementById("cfg-rostro-invitado").checked,
      foto_placa_invitado:   document.getElementById("cfg-placa-invitado").checked,
      tiempo_espera_seg:     parseInt(document.getElementById("cfg-tiempo-espera").value) || 0,
      horario_inicio:        document.getElementById("cfg-horario-inicio").value,
      horario_fin:           document.getElementById("cfg-horario-fin").value,
    };

    const res = await api(`/kioskos/${cfgAccesoId}/config`, {
      method: "PATCH",
      body: JSON.stringify(payload),
    });

    if (!res) return;
    if (!res.ok) {
      const data = await res.json();
      errEl.textContent = data.error || "Error al guardar";
      errEl.hidden = false;
      return;
    }
    okEl.hidden = false;
    setTimeout(() => { okEl.hidden = true; }, 3000);
  });

  /* ─── Equipo ─────────────────────────────── */
  async function loadEquipo() {
    const loadEl  = document.getElementById("equipo-loading");
    const emptyEl = document.getElementById("equipo-empty");
    const rowsEl  = document.getElementById("equipo-rows");

    if (loadEl)  loadEl.hidden = false;
    if (emptyEl) emptyEl.hidden = true;
    if (rowsEl)  rowsEl.innerHTML = "";

    const res = await api("/admins/?rol=vigilante");
    if (loadEl) loadEl.hidden = true;

    if (!res || !res.ok) {
      if (rowsEl) rowsEl.innerHTML = `<div class="empty-title">${t("load_err_title")}</div>`;
      return;
    }

    const data = await res.json();
    const vigilantes = data.admins || [];

    if (vigilantes.length === 0) {
      if (emptyEl) emptyEl.hidden = false;
      return;
    }

    rowsEl.innerHTML = vigilantes.map((v, i) => {
      const nombre = [v.nombre, v.apellido_paterno].filter(Boolean).join(" ") || v.correo;
      const initials = ((v.nombre?.[0] || "") + (v.apellido_paterno?.[0] || "")).toUpperCase();
      return `<div class="acceso-card" style="animation-delay:${i*30}ms">
        <div class="acceso-info" style="display:flex;align-items:center;gap:12px">
          <div class="avatar">${esc(initials) || "·"}</div>
          <div>
            <div class="acceso-nombre">${esc(nombre)}</div>
            <div class="acceso-ubi">${esc(v.correo)}</div>
          </div>
        </div>
        <div class="acceso-actions">
          <button class="btn-ghost" style="color:var(--red)" data-del-vigilante="${v.id}" title="Eliminar vigilante">
            <svg width="14" height="14" viewBox="0 0 18 18" fill="none" stroke="currentColor" stroke-width="1.7"><line x1="4" y1="5" x2="14" y2="5"/><path d="M6 5V3.5h6V5"/><path d="M5 5l.7 9a1 1 0 0 0 1 .9h4.6a1 1 0 0 0 1-.9L13 5"/></svg>
          </button>
        </div>
      </div>`;
    }).join("");

    rowsEl.querySelectorAll("[data-del-vigilante]").forEach(btn => {
      btn.addEventListener("click", () => eliminarVigilante(parseInt(btn.dataset.delVigilante)));
    });
  }

  async function eliminarVigilante(id) {
    if (!confirm("¿Eliminar este vigilante?")) return;
    const res = await api(`/admins/${id}`, { method: "DELETE" });
    if (res && res.ok) loadEquipo();
    else mostrarToast("No se pudo eliminar el vigilante", "err");
  }

  document.getElementById("btn-nuevo-vigilante")?.addEventListener("click", () => {
    document.getElementById("vig-nombre").value   = "";
    document.getElementById("vig-paterno").value  = "";
    document.getElementById("vig-correo").value   = "";
    document.getElementById("vig-password").value = "";
    document.getElementById("vig-error").hidden   = true;
    document.getElementById("modal-vigilante").hidden = false;
  });

  document.getElementById("vig-cancel")?.addEventListener("click", () => {
    document.getElementById("modal-vigilante").hidden = true;
  });

  document.getElementById("vigilante-form")?.addEventListener("submit", async e => {
    e.preventDefault();
    const errEl = document.getElementById("vig-error");
    errEl.hidden = true;

    const payload = {
      correo:          document.getElementById("vig-correo").value,
      password:        document.getElementById("vig-password").value,
      nombre:          document.getElementById("vig-nombre").value,
      apellido_paterno:document.getElementById("vig-paterno").value,
      rol:             "vigilante",
    };

    const res = await api("/auth/sign-in", { method: "POST", body: JSON.stringify(payload) });
    if (!res) return;

    if (!res.ok) {
      const data = await res.json();
      errEl.textContent = data.error || "Error al crear vigilante";
      errEl.hidden = false;
      return;
    }

    document.getElementById("modal-vigilante").hidden = true;
    mostrarToast("Vigilante creado correctamente");
    loadEquipo();
  });

  /* ─── Perfil ─────────────────────────────── */
  async function loadPerfil() {
    if (!state.admin) return;
    document.getElementById("perfil-nombre").value   = state.admin.nombre || "";
    document.getElementById("perfil-correo").value   = state.admin.correo || "";
    document.getElementById("perfil-paterno").value  = state.admin.apellido_paterno || "";
    document.getElementById("perfil-materno").value  = state.admin.apellido_materno || "";
  }

  document.getElementById("perfil-form").addEventListener("submit", async e => {
    e.preventDefault();
    const payload = {
      nombre:           document.getElementById("perfil-nombre").value,
      correo:           document.getElementById("perfil-correo").value,
      apellido_paterno: document.getElementById("perfil-paterno").value,
      apellido_materno: document.getElementById("perfil-materno").value,
      password:         document.getElementById("perfil-password").value,
    };

    const errEl = document.getElementById("perfil-error");
    const okEl  = document.getElementById("perfil-success");
    errEl.hidden = true; okEl.hidden = true;

    const res = await api(`/admins/${state.adminId}`, { method: "PATCH", body: JSON.stringify(payload) });
    if (!res) return;

    if (!res.ok) {
      const data = await res.json();
      errEl.textContent = data.error || "Error";
      errEl.hidden = false;
      return;
    }

    state.admin = { ...state.admin, ...payload };
    okEl.hidden = false;
    await loadAdminData();
  });

  /* ─── Hero anim (live access feed) ──────── */
  (function initHeroAnim() {
    const feed = document.getElementById('hero-feed');
    if (!feed) return;

    const COLORS   = ['#FF542F','#4A9EFF','#a78bfa','#34d399'];
    const ACCESOS  = ['E. Principal','Acc. Norte','Caseta Veh.','E. Lateral','Acc. Sur'];
    const NOMBRES  = [
      'García L., Marco','Rodríguez P., Ana','Martínez C., Luis',
      'Hernández R., Sofía','López T., Juan','González V., María',
      'Sánchez F., Carlos','Ramírez D., Elena','Torres M., José',
      'Flores J., Laura','Pérez C., Diego','Vargas M., Paula',
    ];
    const ESTADOS  = ['APROBADO','APROBADO','APROBADO','PENDIENTE','REVISIÓN'];

    let running = true, spawnId = null;

    function pick(arr) { return arr[Math.floor(Math.random() * arr.length)]; }

    function collapseCard(card, onDone) {
      card.style.animation = 'none';
      card.classList.add('leaving');
      setTimeout(onDone, 400);
    }

    function spawnCard() {
      const name   = pick(NOMBRES);
      const color  = pick(COLORS);
      const acceso = pick(ACCESOS);
      const estado = pick(ESTADOS);
      const init2  = name.replace(/[,. ]+/g,'').slice(0,2).toUpperCase();
      const bcls   = estado==='APROBADO'?'badge--aprobado':estado==='PENDIENTE'?'badge--pendiente':'badge--revision';
      const card   = document.createElement('div');
      card.className = 'hero-card';
      card.innerHTML = `
        <div class="hero-card-avatar" style="background:${color}20;border-color:${color}55;color:${color}">${init2}</div>
        <div class="hero-card-info">
          <div class="hero-card-name">${esc(name)}</div>
          <div class="hero-card-meta">${esc(acceso)} · ahora</div>
        </div>
        <span class="badge ${bcls}">${estado}</span>`;
      feed.insertBefore(card, feed.firstChild);
      if (feed.children.length > 3) {
        const oldest = feed.lastElementChild;
        collapseCard(oldest, () => oldest.remove());
      }
      setTimeout(() => collapseCard(card, () => card.remove()), 6000);
    }

    function animCount(el, target, ms) {
      if (!el) return;
      const start = performance.now();
      function frame(now) {
        const t = Math.min((now - start) / ms, 1);
        el.textContent = Math.round((1 - Math.pow(1-t, 3)) * target);
        if (t < 1) requestAnimationFrame(frame);
      }
      requestAnimationFrame(frame);
    }

    function start() {
      if (spawnId) return;
      for (let i = 0; i < 2; i++) spawnCard();
      spawnId = setInterval(() => { if (running) spawnCard(); }, 2200);
      animCount(document.getElementById('has-visitas'),   247, 1400);
      animCount(document.getElementById('has-aprobadas'), 183, 1400);
      animCount(document.getElementById('has-pendientes'), 12, 1000);
    }

    function stop() {
      clearInterval(spawnId); spawnId = null; running = false;
    }

    start();

    const loginScreen = document.getElementById('screen-login');
    if (loginScreen) {
      new MutationObserver(() => {
        if (loginScreen.hidden) { stop(); }
        else { running = true; start(); }
      }).observe(loginScreen, { attributes: true, attributeFilter: ['hidden'] });
    }
  })();

  /* ─── Onboarding first-run ───────────────── */
  let obStep = 1;

  // Preview en el cliente del código que el backend va a generar a partir del
  // nombre — el valor real (con sufijo anti-colisión si aplica) lo decide
  // siempre el backend al guardar; esto es solo para que el admin lo vea
  // en vivo mientras escribe.
  function previsualizarCodigo(nombre) {
    const plano = (nombre || '').trim().toUpperCase()
      .replace(/[ÁÀÄ]/g, 'A').replace(/[ÉÈË]/g, 'E').replace(/[ÍÌÏ]/g, 'I')
      .replace(/[ÓÒÖ]/g, 'O').replace(/[ÚÙÜ]/g, 'U').replace(/Ñ/g, 'N');
    const codigo = plano.replace(/[^A-Z0-9]+/g, '-').replace(/^-+|-+$/g, '').slice(0, 30).replace(/-+$/, '');
    return codigo || 'CENTRO';
  }

  async function showOnboarding() {
    obStep = 1;
    document.getElementById('onboarding-overlay').hidden = false;
    setObStep(1);
    // precargar datos actuales del tenant
    const res = await api(`/tenants/${state.tenantId || 1}`);
    if (res && res.ok) {
      const d = await res.json();
      const nombreEl = document.getElementById('ob-inst-nombre');
      if (nombreEl) nombreEl.value = d.nombre || '';
      const previewEl = document.getElementById('ob-inst-codigo-preview');
      if (previewEl) previewEl.textContent = d.codigo || previsualizarCodigo(d.nombre);
    }
  }

  document.getElementById('ob-inst-nombre')?.addEventListener('input', e => {
    document.getElementById('ob-inst-codigo-preview').textContent = previsualizarCodigo(e.target.value);
  });

  function setObStep(n) {
    [1,2,3].forEach(i => {
      document.getElementById(`ob-step-${i}`)?.classList.toggle('active', i===n);
      const dot = document.getElementById(`ob-dot-${i}`);
      if (dot) {
        dot.classList.toggle('active', i===n);
        dot.classList.toggle('done',   i<n);
      }
    });
    document.getElementById('ob-line-1')?.classList.toggle('done', n>1);
    document.getElementById('ob-line-2')?.classList.toggle('done', n>2);
    obStep = n;
  }

  document.getElementById('ob-inst-form')?.addEventListener('submit', async e => {
    e.preventDefault();
    const errEl = document.getElementById('ob-inst-error');
    errEl.hidden = true;
    const body = {
      nombre: document.getElementById('ob-inst-nombre').value.trim(),
    };
    const res = await api(`/tenants/${state.tenantId || 1}`, { method: 'PATCH', body: JSON.stringify(body) });
    if (!res) return;
    if (!res.ok) {
      const d = await res.json();
      errEl.textContent = d.error || 'Error al guardar';
      errEl.hidden = false;
      return;
    }
    setObStep(2);
  });

  // Activar el kiosko reusa el wizard normal de "nuevo kiosko" (código →
  // datos → configuración) — se oculta el overlay de onboarding mientras
  // está abierto para no encimar dos pantallas completas, y se retoma al
  // terminar (o al cancelar, para no dejar al admin varado sin ver nada).
  document.getElementById('ob-kiosko-activar')?.addEventListener('click', () => {
    document.getElementById('onboarding-overlay').hidden = true;
    openNuevoKioskoWizard(() => {
      document.getElementById('onboarding-overlay').hidden = false;
      setObStep(3);
    }, () => {
      document.getElementById('onboarding-overlay').hidden = false;
    });
  });

  document.getElementById('ob-kiosko-saltar')?.addEventListener('click', () => {
    setObStep(3);
  });

  document.getElementById('ob-vig-crear')?.addEventListener('click', async () => {
    const errEl = document.getElementById('ob-vig-error');
    errEl.hidden = true;
    const payload = {
      nombre:           document.getElementById('ob-vig-nombre').value.trim(),
      apellido_paterno: '',
      correo:           document.getElementById('ob-vig-correo').value.trim(),
      password:         document.getElementById('ob-vig-password').value,
      rol:              'vigilante',
    };
    if (!payload.correo || !payload.password) {
      errEl.textContent = 'Correo y contraseña son obligatorios';
      errEl.hidden = false;
      return;
    }
    const res = await api('/auth/sign-in', { method: 'POST', body: JSON.stringify(payload) });
    if (!res) return;
    if (!res.ok) {
      const d = await res.json();
      errEl.textContent = d.error || 'Error al crear vigilante';
      errEl.hidden = false;
      return;
    }
    document.getElementById('onboarding-overlay').hidden = true;
    mostrarToast('Vigilante creado. ¡Todo listo!', 'ok');
    navTo('dashboard');
  });

  document.getElementById('ob-vig-saltar')?.addEventListener('click', () => {
    document.getElementById('onboarding-overlay').hidden = true;
    navTo('dashboard');
  });

  /* ─── Destinos ───────────────────────────── */

  async function loadDestinosSection() {
    await loadDestinos();
  }

  async function loadDestinos() {
    const rowsEl  = document.getElementById('dest-rows');
    const emptyEl = document.getElementById('dest-empty');
    const loadEl  = document.getElementById('dest-loading');
    if (!rowsEl) return;

    rowsEl.innerHTML = '';
    emptyEl.hidden = true;
    loadEl.hidden = false;

    const res = await api('/destinos/');
    loadEl.hidden = true;
    if (!res || !res.ok) { mostrarToast('Error al cargar destinos', 'err'); return; }

    const items = await res.json();
    if (!items.length) { emptyEl.hidden = false; return; }

    // Agrupadas por calle: un fraccionamiento con decenas de casas es
    // ilegible como lista plana.
    const porCalle = new Map();
    for (const d of items) {
      const calle = d.calle || 'Sin calle';
      if (!porCalle.has(calle)) porCalle.set(calle, []);
      porCalle.get(calle).push(d);
    }

    rowsEl.innerHTML = [...porCalle.entries()].map(([calle, destinos]) => `
      <div class="dest-grupo">
        <div class="dest-grupo-titulo">${esc(calle)}</div>
        ${destinos.map(d => `
          <div class="equipo-row" id="dest-row-${d.id}">
            <div class="equipo-info">
              <div class="equipo-name">${esc(d.tipo === 'edificio' ? 'Edificio' : 'Casa')} ${esc(d.numero || '')}</div>
              ${d.titular ? `<div class="equipo-sub">${esc(d.titular)}</div>` : ''}
            </div>
            <button class="btn-ghost" style="color:var(--red)" data-del-dest="${d.id}" title="Eliminar destino">
              <svg width="14" height="14" viewBox="0 0 18 18" fill="none" stroke="currentColor" stroke-width="1.7"><line x1="4" y1="5" x2="14" y2="5"/><path d="M6 5V3.5h6V5"/><path d="M5 5l.7 9a1 1 0 0 0 1 .9h4.6a1 1 0 0 0 1-.9L13 5"/></svg>
            </button>
          </div>`).join('')}
      </div>`).join('');

    rowsEl.querySelectorAll('[data-del-dest]').forEach(btn => {
      btn.addEventListener('click', () => deleteDestino(+btn.dataset.delDest));
    });
  }

  async function deleteDestino(id) {
    if (!confirm('¿Eliminar este destino?')) return;
    const res = await api(`/destinos/${id}`, { method: 'DELETE' });
    if (res && res.ok) {
      document.getElementById(`dest-row-${id}`)?.remove();
      if (!document.getElementById('dest-rows').children.length)
        document.getElementById('dest-empty').hidden = false;
    } else {
      mostrarToast('No se pudo eliminar el destino', 'err');
    }
  }

  document.getElementById('btn-nuevo-destino')?.addEventListener('click', () => {
    document.getElementById('modal-destino').hidden = false;
  });
  document.getElementById('dest-cancel')?.addEventListener('click', () => {
    document.getElementById('modal-destino').hidden = true;
  });

  function parsearNumeros(texto) {
    return texto.split(',').map(n => n.trim()).filter(n => n.length > 0);
  }

  document.getElementById('dest-numeros')?.addEventListener('input', e => {
    const n = parsearNumeros(e.target.value).length;
    document.getElementById('dest-numeros-preview').textContent =
      n > 0 ? `Se crearán ${n} destino${n !== 1 ? 's' : ''}.` : 'Separa cada número con una coma.';
  });

  document.getElementById('destino-form')?.addEventListener('submit', async e => {
    e.preventDefault();
    const calle   = document.getElementById('dest-calle').value.trim();
    const tipo    = document.getElementById('dest-tipo').value;
    const numeros = parsearNumeros(document.getElementById('dest-numeros').value);
    const errEl   = document.getElementById('dest-form-error');
    errEl.hidden  = true;

    if (!numeros.length) {
      errEl.textContent = 'Escribe al menos un número';
      errEl.hidden = false;
      return;
    }

    const res = await api('/destinos/lote', { method: 'POST', body: JSON.stringify({ calle, tipo, numeros }) });
    if (!res) return;
    if (!res.ok) {
      const d = await res.json();
      errEl.textContent = d.error || 'Error al crear destinos';
      errEl.hidden = false; return;
    }
    document.getElementById('modal-destino').hidden = true;
    document.getElementById('destino-form').reset();
    document.getElementById('dest-numeros-preview').textContent = 'Separa cada número con una coma.';
    loadDestinos();
  });

  /* ─── Centro habitacional: configuración ─────────────────── */

  async function loadInstalacionConfig() {
    const tenantId = state.tenantId || 1;
    const res = await api(`/tenants/${tenantId}`);
    if (!res || !res.ok) return;
    const d = await res.json();
    const set = (id, val) => { const el = document.getElementById(id); if (el) el.value = val || ''; };
    set('inst-nombre',     d.nombre);
    set('inst-direccion',  d.direccion);
    set('inst-descripcion', d.descripcion);
    const codigoEl = document.getElementById('inst-codigo');
    if (codigoEl) codigoEl.textContent = d.codigo || '—';
  }

  document.getElementById('inst-config-form')?.addEventListener('submit', async e => {
    e.preventDefault();
    const tenantId = state.tenantId || 1;
    const body = {
      nombre:      document.getElementById('inst-nombre')?.value.trim(),
      direccion:   document.getElementById('inst-direccion')?.value.trim(),
      descripcion: document.getElementById('inst-descripcion')?.value.trim(),
    };
    const res = await api(`/tenants/${tenantId}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
    if (res && res.ok) mostrarToast('Centro habitacional actualizado', 'ok');
    else mostrarToast('Error al guardar', 'err');
  });

  /* ─── Residentes pendientes (modelo viejo Residente + Membresia de la app Kigo) ─── */

  async function loadResidentesPendientesBadge() {
    try {
      const [resRes, resMem] = await Promise.all([
        api('/residentes/pendientes'),
        api('/membresias/pendientes'),
      ]);
      let n = 0;
      if (resRes && resRes.ok) {
        const d = await resRes.json();
        n += (Array.isArray(d) ? d : (d.residentes || [])).length;
      }
      if (resMem && resMem.ok) {
        const d = await resMem.json();
        n += (Array.isArray(d) ? d : (d.membresias || [])).length;
      }
      const badge = document.getElementById('tab-badge-res-sol');
      if (badge) { badge.textContent = n; badge.hidden = n === 0; }
    } catch (e) {
      console.warn('loadResidentesPendientesBadge error:', e);
    }
  }

  async function loadResidentesPendientes() {
    const loadEl  = document.getElementById('resp-loading');
    const emptyEl = document.getElementById('resp-empty');
    const rowsEl  = document.getElementById('resp-rows');
    if (!rowsEl) return;

    rowsEl.innerHTML = '';
    if (emptyEl) emptyEl.hidden = true;
    if (loadEl)  loadEl.hidden = false;

    let resResidentes = null, resMembresias = null;
    try {
      [resResidentes, resMembresias] = await Promise.all([
        api('/residentes/pendientes'),
        api('/membresias/pendientes'),
      ]);
    } catch (e) {
      console.error('Error fetching pendientes:', e);
    }
    if (loadEl) loadEl.hidden = true;

    let residentes = [];
    if (resResidentes && resResidentes.ok) {
      try {
        const d = await resResidentes.json();
        residentes = Array.isArray(d) ? d : (d.residentes || []);
      } catch (e) { console.error(e); }
    }

    let membresias = [];
    if (resMembresias && resMembresias.ok) {
      try {
        const d = await resMembresias.json();
        membresias = Array.isArray(d) ? d : (d.membresias || []);
      } catch (e) { console.error(e); }
    }

    if (!residentes.length && !membresias.length) {
      if (emptyEl) emptyEl.hidden = false;
      return;
    }
    if (emptyEl) emptyEl.hidden = true;

    const filasResidentes = residentes.map(r => {
      const fecha = new Date(r.created_at).toLocaleDateString('es-MX', { day:'2-digit', month:'short', hour:'2-digit', minute:'2-digit' });
      const foto  = r.foto_cara_url
        ? `<img src="${esc(r.foto_cara_url)}" style="width:48px;height:48px;border-radius:50%;object-fit:cover;margin-right:12px" alt="foto">`
        : `<div style="width:48px;height:48px;border-radius:50%;background:var(--surface-2);display:flex;align-items:center;justify-content:center;margin-right:12px;font-size:20px">👤</div>`;
      return `
        <div class="equipo-row" style="align-items:center">
          ${foto}
          <div class="equipo-info" style="flex:1">
            <div class="equipo-name">${esc(r.nombre)} ${esc(r.apellido_paterno)} ${esc(r.apellido_materno)}</div>
            <div class="equipo-sub">${esc(r.casa_destino)}${r.telefono ? ' · ' + esc(r.telefono) : ''} · Solicitado: ${fecha}</div>
          </div>
          <div style="display:flex;gap:8px">
            <button class="btn-primary" data-aprobar-res="${r.id}">Aprobar</button>
            <button class="btn-ghost" data-rechazar-res="${r.id}" style="color:var(--danger,#e55)">Rechazar</button>
          </div>
        </div>`;
    }).join('');

    const filasMembresias = membresias.map(m => `
        <div class="equipo-row" style="align-items:center">
          <div style="width:48px;height:48px;border-radius:50%;background:var(--surface-2);display:flex;align-items:center;justify-content:center;margin-right:12px;font-size:20px">👤</div>
          <div class="equipo-info" style="flex:1">
            <div class="equipo-name">${esc(m.nombre || 'Sin nombre')}</div>
            <div class="equipo-sub">${esc(m.casa_destino)}${m.telefono ? ' · ' + esc(m.telefono) : ''} · App Kigo</div>
          </div>
          <div style="display:flex;gap:8px">
            <button class="btn-primary" data-aprobar-mem="${m.id}">Aprobar</button>
            <button class="btn-ghost" data-rechazar-mem="${m.id}" style="color:var(--danger,#e55)">Rechazar</button>
          </div>
        </div>`).join('');

    rowsEl.innerHTML = filasMembresias + filasResidentes;

    rowsEl.querySelectorAll('[data-aprobar-res]').forEach(btn => {
      btn.addEventListener('click', async () => {
        const id = btn.dataset.aprobarRes;
        const res = await api(`/residentes/${id}/aprobar`, { method: 'POST' });
        if (res && res.ok) { mostrarToast('Residente aprobado', 'ok'); loadResidentesPendientes(); }
        else mostrarToast('Error al aprobar', 'err');
      });
    });

    rowsEl.querySelectorAll('[data-rechazar-res]').forEach(btn => {
      btn.addEventListener('click', async () => {
        const id = btn.dataset.rechazarRes;
        if (!confirm('¿Rechazar esta solicitud?')) return;
        const res = await api(`/residentes/${id}/rechazar`, { method: 'POST' });
        if (res && res.ok) { mostrarToast('Solicitud rechazada', 'ok'); loadResidentesPendientes(); }
        else mostrarToast('Error al rechazar', 'err');
      });
    });

    rowsEl.querySelectorAll('[data-aprobar-mem]').forEach(btn => {
      btn.addEventListener('click', async () => {
        const id = btn.dataset.aprobarMem;
        const res = await api(`/membresias/${id}/aprobar`, { method: 'POST' });
        if (res && res.ok) { mostrarToast('Solicitud aprobada', 'ok'); loadResidentesPendientes(); }
        else mostrarToast('Error al aprobar', 'err');
      });
    });

    rowsEl.querySelectorAll('[data-rechazar-mem]').forEach(btn => {
      btn.addEventListener('click', async () => {
        const id = btn.dataset.rechazarMem;
        if (!confirm('¿Rechazar esta solicitud?')) return;
        const res = await api(`/membresias/${id}/rechazar`, { method: 'POST' });
        if (res && res.ok) { mostrarToast('Solicitud rechazada', 'ok'); loadResidentesPendientes(); }
        else mostrarToast('Error al rechazar', 'err');
      });
    });
  }


  /* ─── Init ───────────────────────────────── */
  function init() {
    const token = getToken();
    if (!token) { showLogin(); applyI18n(); return; }

    const claims = decodeJWT(token);
    if (!claims || (claims.exp && claims.exp * 1000 < Date.now())) {
      clearToken(); showLogin(); applyI18n(); return;
    }

    state.adminId  = claims.admin_id;
    state.tenantId = claims.tenant_id;
    state.rol      = claims.rol || "admin";
    bootstrapApp();
  }

  function esc(str) {
    return String(str || "")
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  applyI18n();
  init();
})();
