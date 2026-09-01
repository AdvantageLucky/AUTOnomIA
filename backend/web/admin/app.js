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
      forgot_pass_link: "¿Olvidaste tu contraseña?",
      forgot_title: "Recuperar contraseña",
      forgot_sub: "Ingresa tu correo para recibir un código de recuperación.",
      forgot_send_btn: "Enviar código",
      forgot_code_hint: "Ingresa el código que te enviamos y tu nueva contraseña.",
      forgot_new_pass: "Nueva contraseña",
      forgot_confirm_pass: "Confirmar nueva contraseña",
      forgot_submit_btn: "Restablecer contraseña",
      back_to_login: "Volver a Iniciar sesión",
      reg_title: "Crear cuenta",
      reg_sub: "Registra tu centro habitacional y cuenta de administrador.",
      reg_name_label: "Nombre completo",
      reg_send_btn: "Continuar y verificar correo",
      reg_verify_btn: "Verificar y crear cuenta",
      reg_otp_hint: "Te enviamos un código de 6 dígitos para verificar tu correo.",
      otp_code_label: "Código de 6 dígitos",
      resend_code: "Reenviar código",
      change_email: "Cambiar correo",
      already_account: "¿Ya tienes cuenta?",
      hero_title: "Quién entró, cuándo y por dónde.",
      hero_sub: "Auto-registro de visitantes para comunidades cerradas. Supervisa bitácoras, verifica visitas y gestiona tus entradas desde un solo lugar.",
      dark_mode: "Modo oscuro",
      light_mode: "Modo claro",
      preferences: "Preferencias",
      pref_theme: "Apariencia",
      pref_lang: "Idioma",
      nav_general: "General",
      nav_dashboard: "Inicio",
      nav_entradas: "Bitácora",
      nav_config: "Configuración",
      nav_perfil: "Perfil",
      role_admin: "Administrador",
      dash_sub: "Resumen de tu comunidad",
      stat_today: "Accesos hoy",
      stat_attention: "Requieren atención",
      stat_approved: "Aprobadas hoy",
      stat_residents: "Residentes activos",
      stat_week: "Últimos 7 días",
      stat_total: "Total registros",
      stat_pending: "Pendientes",
      q_visitas_title: "Ver bitácora de accesos",
      q_visitas_sub: "Filtros por tipo: residente, con QR o sin app",
      recent_title: "Bitácora reciente",
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
      vis_empty_title: "Sin accesos registrados",
      vis_empty_text: "Cuando alguien ingrese o se registre en un kiosko, aparecerá aquí automáticamente.",
      load_err_title: "Error al cargar",
      load_err_text: "Revisa tu conexión e inténtalo de nuevo.",
      retry: "Reintentar",
      prev: "‹ Anterior",
      next: "Siguiente ›",
      detail_title: "Detalle de acceso",
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
      forgot_pass_link: "Forgot password?",
      forgot_title: "Reset password",
      forgot_sub: "Enter your email to receive a recovery code.",
      forgot_send_btn: "Send code",
      forgot_code_hint: "Enter the code sent to your email and your new password.",
      forgot_new_pass: "New password",
      forgot_confirm_pass: "Confirm new password",
      forgot_submit_btn: "Reset password",
      back_to_login: "Back to Sign in",
      reg_title: "Create account",
      reg_sub: "Register your community and admin account.",
      reg_name_label: "Full name",
      reg_send_btn: "Continue & verify email",
      reg_verify_btn: "Verify & create account",
      reg_otp_hint: "We sent a 6-digit code to verify your email.",
      otp_code_label: "6-digit code",
      resend_code: "Resend code",
      change_email: "Change email",
      already_account: "Already have an account?",
      hero_title: "Who entered, when and where.",
      hero_sub: "Self-registration for gated communities. Monitor logs, verify visits and manage your entries from one place.",
      dark_mode: "Dark mode",
      light_mode: "Light mode",
      preferences: "Preferences",
      pref_theme: "Appearance",
      pref_lang: "Language",
      nav_general: "General",
      nav_dashboard: "Home",
      nav_entradas: "Log",
      nav_config: "Settings",
      nav_perfil: "Profile",
      role_admin: "Administrator",
      loading: "Loading…",
      dash_sub: "Community summary",
      stat_today: "Today's accesses",
      stat_attention: "Require attention",
      stat_approved: "Approved today",
      stat_residents: "Active residents",
      stat_week: "Last 7 days",
      stat_total: "Total records",
      stat_pending: "Pending",
      q_visitas_title: "View access log",
      q_visitas_sub: "Filter by type: resident, QR guest or walk-in",
      recent_title: "Recent accesses",
      see_all: "See all ›",
      vis_sub: "Access log",
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
      col_access: "ACCESS",
      col_estado: "STATUS",
      col_date: "DATE",
      vis_empty_title: "No accesses recorded",
      vis_empty_text: "When someone enters or registers at a kiosk, they'll appear here.",
      load_err_title: "Failed to load",
      load_err_text: "Check your connection and try again.",
      retry: "Try again",
      prev: "‹ Previous",
      next: "Next ›",
      detail_title: "Access detail",
      new_acceso: "New access",
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
    admin:     ["dashboard","solicitudes","visitas","detalle","residentes","kioskos","configuracion","instalacion","perfil"],
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
    detalleAbiertoId: null,
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
    document.querySelectorAll(".nav-btn[data-nav], .mobile-nav-btn[data-nav]").forEach(btn => {
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
          mostrarToast(`Alerta: Requiere revisión manual: ${nombre}`, "revision");
          loadSolicitudes();
          loadAlertasIABadge();
        } else if (v.estado === "PENDIENTE") {
          mostrarToast(`Nueva solicitud: ${nombre}`);
          loadSolicitudes();
        }
        if (String(v.id) === String(state.detalleAbiertoId)) {
          loadDetalle(v.id);
        }
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
    stopKioPolling();
    switchAuthView("login");
  }

  function showApp() {
    document.getElementById("screen-login").hidden = true;
    document.getElementById("app-shell").hidden = false;
    applyI18n();
  }

  /* ─── Router / SPA Navigation History ───── */
  let currentNavScreen = null;

  function navTo(screen, push = true) {
    const rutas = RUTAS_POR_ROL[state.rol] || RUTAS_POR_ROL.admin;
    if (!rutas.includes(screen)) screen = state.rol === "vigilante" ? "solicitudes" : "dashboard";

    if (screen !== "detalle") state.detalleAbiertoId = null;

    document.querySelectorAll(".screen").forEach(s => s.classList.remove("active"));
    document.querySelectorAll(".nav-btn").forEach(b => b.classList.remove("active"));

    const screenEl = document.getElementById(`screen-${screen}`);
    if (screenEl) { screenEl.hidden = false; screenEl.classList.add("active"); }

    document.querySelectorAll(`[data-nav="${screen}"]`).forEach(b => b.classList.add("active"));

    currentNavScreen = screen;
    if (push) {
      if (window.location.hash !== "#" + screen) {
        history.pushState({ type: "screen", screen: screen }, "", "#" + screen);
      } else {
        history.replaceState({ type: "screen", screen: screen }, "", "#" + screen);
      }
    }

    stopSolPolling();
    stopKioPolling();
    if (screen === "dashboard")     loadDashboard();
    if (screen === "visitas")       loadVisitas(1);
    if (screen === "solicitudes")   startSolPolling();
    if (screen === "residentes")    { loadResidentesActivos(); loadResidentesPendientesBadge(); }
    if (screen === "kioskos")       startKioPolling();
    if (screen === "instalacion")   { loadDestinosSection(); }
    if (screen === "configuracion") loadConfigAccesos();
    if (screen === "perfil")        loadPerfil();
  }

  document.addEventListener("click", e => {
    const nav = e.target.closest("[data-nav]");
    if (nav) {
      e.preventDefault();
      navTo(nav.dataset.nav);
    }
  });

  /* ─── Auth Views Navigation ───────────────── */
  let authMode = "login"; // "login" | "register" | "forgot"

  function switchAuthView(mode, push = true) {
    authMode = mode;
    const viewLogin  = document.getElementById("auth-view-login");
    const viewReg    = document.getElementById("auth-view-register");
    const viewForgot = document.getElementById("auth-view-forgot");

    if (viewLogin)  viewLogin.hidden  = mode !== "login";
    if (viewReg)    viewReg.hidden    = mode !== "register";
    if (viewForgot) viewForgot.hidden = mode !== "forgot";

    // Limpiar errores y mensajes
    document.getElementById("login-error")?.setAttribute("hidden", "");
    document.getElementById("login-success")?.setAttribute("hidden", "");
    document.getElementById("reg-error")?.setAttribute("hidden", "");
    document.getElementById("reg-success")?.setAttribute("hidden", "");
    document.getElementById("forgot-error")?.setAttribute("hidden", "");
    document.getElementById("forgot-success")?.setAttribute("hidden", "");

    if (mode === "register") {
      const stepDatos = document.getElementById("reg-step-datos");
      const stepOtp   = document.getElementById("reg-step-otp");
      if (stepDatos) stepDatos.hidden = false;
      if (stepOtp)   stepOtp.hidden   = true;
    } else if (mode === "forgot") {
      const stepSol = document.getElementById("forgot-step-solicitar");
      const stepVer = document.getElementById("forgot-step-verificar");
      if (stepSol) stepSol.hidden = false;
      if (stepVer) stepVer.hidden = true;
    }

    if (push) {
      const targetHash = mode === "login" ? "" : "#auth-" + mode;
      if (window.location.hash !== targetHash) {
        history.pushState({ type: "auth", mode: mode }, "", targetHash || window.location.pathname);
      }
    }

    renderGoogleButton();
  }

  // Interceptar navegación Atrás/Adelante del navegador
  window.addEventListener("popstate", (e) => {
    // 1. Si hay algún modal abierto, cerrarlo primero
    const openModals = Array.from(document.querySelectorAll(".modal-overlay")).filter(m => !m.hidden);
    if (openModals.length > 0) {
      openModals.forEach(m => m.hidden = true);
      return;
    }

    // 2. Si el usuario está dentro de la app
    const appShell = document.getElementById("app-shell");
    if (appShell && !appShell.hidden) {
      if (e.state && e.state.type === "screen" && e.state.screen) {
        navTo(e.state.screen, false);
      } else if (window.location.hash) {
        const hash = window.location.hash.replace(/^#/, "");
        if (hash && !hash.startsWith("auth-")) {
          navTo(hash, false);
        } else {
          navTo(state.rol === "vigilante" ? "solicitudes" : "dashboard", false);
        }
      } else {
        navTo(state.rol === "vigilante" ? "solicitudes" : "dashboard", false);
      }
      return;
    }

    // 3. Si está en la pantalla de autenticación
    const screenLogin = document.getElementById("screen-login");
    if (screenLogin && !screenLogin.hidden) {
      if (e.state && e.state.type === "auth" && e.state.mode) {
        switchAuthView(e.state.mode, false);
      } else if (window.location.hash) {
        const hash = window.location.hash.replace(/^#auth-/, "").replace(/^#/, "");
        if (["login", "register", "forgot"].includes(hash)) {
          switchAuthView(hash, false);
        } else {
          switchAuthView("login", false);
        }
      } else {
        switchAuthView("login", false);
      }
    }
  });

  document.getElementById("go-register-btn")?.addEventListener("click", () => switchAuthView("register"));
  document.getElementById("reg-go-login-btn")?.addEventListener("click", () => switchAuthView("login"));
  document.getElementById("forgot-pass-btn")?.addEventListener("click", () => switchAuthView("forgot"));
  document.getElementById("forgot-back-btn")?.addEventListener("click", () => switchAuthView("login"));

  /* ─── 1. Login (Correo + Contraseña) ──────── */
  document.getElementById("login-form")?.addEventListener("submit", async e => {
    e.preventDefault();
    const correo   = document.getElementById("login-correo").value.trim();
    const password = document.getElementById("login-password").value;
    const errEl    = document.getElementById("login-error");
    const okEl     = document.getElementById("login-success");
    const btn      = document.getElementById("login-submit");

    btn.disabled = true;
    errEl.hidden = true;
    if (okEl) okEl.hidden = true;

    try {
      const res = await fetch(API_BASE + "/auth/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ correo, password }),
      });

      const data = await res.json();
      if (!res.ok) {
        errEl.textContent = data.error || (lang === "en" ? "Invalid credentials" : "Credenciales inválidas");
        errEl.hidden = false;
        return;
      }

      setToken(data.access_token);
      const claims = decodeJWT(data.access_token);
      state.adminId  = claims?.admin_id;
      state.tenantId = claims?.tenant_id;
      await bootstrapApp();
    } catch {
      errEl.textContent = lang === "en" ? "Connection error" : "Error de conexión";
      errEl.hidden = false;
    } finally {
      btn.disabled = false;
    }
  });

  /* ─── 2. Sign-In (Datos + OTP Verificación) ─ */
  let regDatos = null;

  document.getElementById("reg-solicitar-btn")?.addEventListener("click", async () => {
    const correo   = document.getElementById("reg-correo").value.trim();
    const password = document.getElementById("reg-password").value;
    const errEl    = document.getElementById("reg-error");
    const btn      = document.getElementById("reg-solicitar-btn");

    errEl.hidden = true;

    if (!correo) {
      errEl.textContent = lang === "en" ? "Email is required" : "El correo es requerido";
      errEl.hidden = false;
      return;
    }
    if (!password || password.length < 8) {
      errEl.textContent = lang === "en" ? "Password must be at least 8 characters" : "La contraseña debe tener al menos 8 caracteres";
      errEl.hidden = false;
      return;
    }

    regDatos = { correo, password };
    btn.disabled = true;

    try {
      const res = await fetch(API_BASE + "/auth/sign-in/solicitar-otp", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ correo }),
      });

      const data = await res.json();
      if (!res.ok) {
        errEl.textContent = data.error || (lang === "en" ? "Error sending code" : "Error al enviar código");
        errEl.hidden = false;
        return;
      }

      document.getElementById("reg-step-datos").hidden = true;
      document.getElementById("reg-step-otp").hidden = false;
      const hint = document.getElementById("reg-otp-hint");
      if (hint) {
        hint.textContent = (lang === "en" ? "We sent a 6-digit code to " : "Te enviamos un código de 6 dígitos a ") + correo;
      }
      document.getElementById("reg-codigo").value = "";
      document.getElementById("reg-codigo").focus();
    } catch {
      errEl.textContent = lang === "en" ? "Connection error" : "Error de conexión";
      errEl.hidden = false;
    } finally {
      btn.disabled = false;
    }
  });

  document.getElementById("reg-cambiar-correo-btn")?.addEventListener("click", () => {
    document.getElementById("reg-step-datos").hidden = false;
    document.getElementById("reg-step-otp").hidden = true;
    document.getElementById("reg-error").hidden = true;
  });

  document.getElementById("reg-reenviar-btn")?.addEventListener("click", async () => {
    if (!regDatos?.correo) return;
    const errEl = document.getElementById("reg-error");
    const okEl  = document.getElementById("reg-success");
    errEl.hidden = true;
    okEl.hidden  = true;

    try {
      const res = await fetch(API_BASE + "/auth/sign-in/solicitar-otp", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ correo: regDatos.correo }),
      });
      const data = await res.json();
      if (!res.ok) {
        errEl.textContent = data.error || "Error";
        errEl.hidden = false;
      } else {
        okEl.textContent = lang === "en" ? "New code sent to your email." : "Nuevo código enviado a tu correo.";
        okEl.hidden = false;
      }
    } catch {
      errEl.textContent = lang === "en" ? "Connection error" : "Error de conexión";
      errEl.hidden = false;
    }
  });

  document.getElementById("register-form")?.addEventListener("submit", async e => {
    e.preventDefault();
    if (!regDatos) return;

    const codigo = document.getElementById("reg-codigo").value.trim();
    const errEl  = document.getElementById("reg-error");
    const btn    = document.getElementById("reg-verificar-btn");

    errEl.hidden = true;
    if (!codigo) {
      errEl.textContent = lang === "en" ? "Enter the 6-digit code" : "Ingresa el código de 6 dígitos";
      errEl.hidden = false;
      return;
    }

    btn.disabled = true;

    try {
      const res = await fetch(API_BASE + "/auth/sign-in", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          correo: regDatos.correo,
          password: regDatos.password,
          nombre: regDatos.nombre,
          codigo: codigo,
        }),
      });

      const data = await res.json();
      if (!res.ok) {
        errEl.textContent = data.error || (lang === "en" ? "Invalid or expired code" : "Código inválido o vencido");
        errEl.hidden = false;
        return;
      }

      setToken(data.access_token);
      const claims = decodeJWT(data.access_token);
      state.adminId  = claims?.admin_id;
      state.tenantId = claims?.tenant_id;
      await bootstrapApp();
    } catch {
      errEl.textContent = lang === "en" ? "Connection error" : "Error de conexión";
      errEl.hidden = false;
    } finally {
      btn.disabled = false;
    }
  });

  /* ─── 3. Olvidé mi contraseña (Reset con OTP) ─ */
  let forgotCorreo = "";

  document.getElementById("forgot-solicitar-btn")?.addEventListener("click", async () => {
    const correo = document.getElementById("forgot-correo").value.trim();
    const errEl  = document.getElementById("forgot-error");
    const btn    = document.getElementById("forgot-solicitar-btn");

    errEl.hidden = true;
    if (!correo) {
      errEl.textContent = lang === "en" ? "Email is required" : "El correo es requerido";
      errEl.hidden = false;
      return;
    }

    forgotCorreo = correo;
    btn.disabled = true;

    try {
      const res = await fetch(API_BASE + "/auth/recuperar-password/solicitar-otp", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ correo }),
      });

      const data = await res.json();
      if (!res.ok) {
        let msg = data.error || (lang === "en" ? "Error sending code" : "Error al enviar código");
        if (res.status === 404 || msg.includes("no existe")) {
          msg = lang === "en" ? "No account found with this email address." : "No existe ninguna cuenta registrada con este correo.";
        }
        errEl.textContent = msg;
        errEl.hidden = false;
        return;
      }

      document.getElementById("forgot-step-solicitar").hidden = true;
      document.getElementById("forgot-step-verificar").hidden = false;
      document.getElementById("forgot-codigo").value = "";
      document.getElementById("forgot-new-password").value = "";
      document.getElementById("forgot-confirm-password").value = "";
      document.getElementById("forgot-codigo").focus();
    } catch {
      errEl.textContent = lang === "en" ? "Connection error" : "Error de conexión";
      errEl.hidden = false;
    } finally {
      btn.disabled = false;
    }
  });

  document.getElementById("forgot-form")?.addEventListener("submit", async e => {
    e.preventDefault();
    const codigo       = document.getElementById("forgot-codigo").value.trim();
    const newPassword  = document.getElementById("forgot-new-password").value;
    const confirmPass  = document.getElementById("forgot-confirm-password").value;
    const errEl        = document.getElementById("forgot-error");
    const btn          = document.getElementById("forgot-submit-btn");

    errEl.hidden = true;

    if (!codigo) {
      errEl.textContent = lang === "en" ? "Enter the 6-digit code" : "Ingresa el código de 6 dígitos";
      errEl.hidden = false;
      return;
    }
    if (!newPassword || newPassword.length < 8) {
      errEl.textContent = lang === "en" ? "Password must be at least 8 characters" : "La contraseña debe tener al menos 8 caracteres";
      errEl.hidden = false;
      return;
    }
    if (newPassword !== confirmPass) {
      errEl.textContent = lang === "en" ? "Passwords do not match" : "Las contraseñas no coinciden";
      errEl.hidden = false;
      return;
    }

    btn.disabled = true;

    try {
      const res = await fetch(API_BASE + "/auth/recuperar-password/verificar-otp", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          correo: forgotCorreo,
          codigo: codigo,
          new_password: newPassword,
        }),
      });

      const data = await res.json();
      if (!res.ok) {
        errEl.textContent = data.error || (lang === "en" ? "Invalid or expired code" : "Código inválido o vencido");
        errEl.hidden = false;
        return;
      }

      setToken(data.access_token);
      const claims = decodeJWT(data.access_token);
      state.adminId  = claims?.admin_id;
      state.tenantId = claims?.tenant_id;
      await bootstrapApp();
    } catch {
      errEl.textContent = lang === "en" ? "Connection error" : "Error de conexión";
      errEl.hidden = false;
    } finally {
      btn.disabled = false;
    }
  });

  /* ─── Google Login ──────────────────────── */
  let googleInitialized = false;

  async function googleCallback({ credential }) {
    const errEl = document.getElementById(authMode === "register" ? "reg-error" : "login-error");
    const endpoint = authMode === "register" ? "/auth/google/sign-in" : "/auth/google";
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
    if (typeof google === "undefined" || !google.accounts) return;

    const clientId = window.__GOOGLE_CLIENT_ID__ || "";
    if (!clientId) return;

    if (!googleInitialized) {
      google.accounts.id.initialize({ client_id: clientId, callback: googleCallback });
      googleInitialized = true;
    }

    const containerLogin = document.getElementById("google-btn-container");
    if (containerLogin) {
      containerLogin.innerHTML = "";
      const ancho = Math.round(containerLogin.getBoundingClientRect().width) || 320;
      google.accounts.id.renderButton(containerLogin, {
        theme: "outline", size: "large", width: ancho,
        text: "signin_with",
        locale: lang === "en" ? "en" : "es",
      });
    }

    const containerReg = document.getElementById("google-btn-container-reg");
    if (containerReg) {
      containerReg.innerHTML = "";
      const ancho = Math.round(containerReg.getBoundingClientRect().width) || 320;
      google.accounts.id.renderButton(containerReg, {
        theme: "outline", size: "large", width: ancho,
        text: "signup_with",
        locale: lang === "en" ? "en" : "es",
      });
    }
  }

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
    loadAlertasIABadge();
    loadResidentesPendientesBadge();
    if (state.rol !== 'vigilante' && !state.tenant?.nombre) {
      showOnboarding();
    } else {
      const hash = window.location.hash.replace(/^#/, "");
      const rutas = RUTAS_POR_ROL[state.rol] || RUTAS_POR_ROL.admin;
      const target = rutas.includes(hash) ? hash : (state.rol === "vigilante" ? "solicitudes" : "dashboard");
      history.replaceState({ type: "screen", screen: target }, "", "#" + target);
      navTo(target, false);
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
        tab === 'res-activos'     ? loadResidentesActivos :
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
    const [resVisitas, resMembresias] = await Promise.all([
      api("/visitas/?page_size=100"),
      api("/membresias/"),
    ]);

    let visitas = [];
    if (resVisitas && resVisitas.ok) {
      const data = await resVisitas.json();
      visitas = data.visitas || [];
    }

    let residentesCount = 0;
    if (resMembresias && resMembresias.ok) {
      const mData = await resMembresias.json();
      residentesCount = (Array.isArray(mData) ? mData : (mData.membresias || [])).length;
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

    document.querySelectorAll("[data-stat-nav]").forEach(card => {
      card.onclick = () => {
        const dest = card.dataset.statNav;
        if (dest === "hoy") {
          const fFecha = document.getElementById("vis-filter-fecha");
          if (fFecha) fFecha.value = "hoy";
          const fTipo = document.getElementById("vis-filter-tipo");
          if (fTipo) fTipo.value = "";
          const fEstado = document.getElementById("vis-filter-estado");
          if (fEstado) fEstado.value = "";
          const fQ = document.getElementById("vis-quick-search");
          if (fQ) fQ.value = "";
          navTo("visitas");
        } else if (dest === "pendientes") {
          navTo("solicitudes");
        } else if (dest === "aprobadas") {
          const fFecha = document.getElementById("vis-filter-fecha");
          if (fFecha) fFecha.value = "hoy";
          const fEstado = document.getElementById("vis-filter-estado");
          if (fEstado) fEstado.value = "APROBADO";
          const fTipo = document.getElementById("vis-filter-tipo");
          if (fTipo) fTipo.value = "";
          const fQ = document.getElementById("vis-quick-search");
          if (fQ) fQ.value = "";
          navTo("visitas");
        } else if (dest === "residentes") {
          navTo("residentes");
          const tabActivos = document.querySelector('[data-tab="res-activos"]');
          if (tabActivos) tabActivos.click();
        }
      };
    });

    const container = document.getElementById("dash-recent-rows");
    const recent = visitas.slice(0, 10);
    if (recent.length === 0) {
      container.innerHTML = `<div class="empty-state"><div class="empty-icon"><svg width="22" height="22" viewBox="0 0 18 18" fill="none" stroke="currentColor" stroke-width="1.6"><circle cx="4" cy="4.5" r="1.7"/><line x1="8" y1="4.5" x2="16" y2="4.5"/><circle cx="4" cy="9" r="1.7"/><line x1="8" y1="9" x2="16" y2="9"/><circle cx="4" cy="13.5" r="1.7"/><line x1="8" y1="13.5" x2="16" y2="13.5"/></svg></div><div class="empty-title">${t("vis_empty_title")}</div><div class="empty-text">${t("vis_empty_text")}</div></div>`;
      return;
    }
    container.innerHTML = recent.map((v, i) => renderDashRow(v, i)).join("");
    container.querySelectorAll("[data-id]").forEach(row => {
      row.addEventListener("click", () => loadDetalle(row.dataset.id));
    });

    loadReporteIA(visitas);
  }

  async function loadReporteIA(visitas = []) {
    const loadEl   = document.getElementById('dash-reporte-ia-loading');
    const emptyEl  = document.getElementById('dash-reporte-ia-empty');
    const bodyEl   = document.getElementById('dash-reporte-ia-body');
    const chipsEl  = document.getElementById('dash-reporte-ia-stats-chips');
    const periodoEl= document.getElementById('dash-reporte-ia-periodo');
    const textoEl  = document.getElementById('dash-reporte-ia-texto');
    if (!bodyEl) return;

    if (loadEl) loadEl.hidden = false;
    if (emptyEl) emptyEl.hidden = true;
    bodyEl.hidden = true;

    const res = await api('/visitas/reportes');
    if (loadEl) loadEl.hidden = true;

    let reportes = [];
    if (res && res.ok) {
      try {
        const d = await res.json();
        reportes = Array.isArray(d.reportes) ? d.reportes : [];
      } catch (e) { console.error(e); }
    }

    if (reportes.length > 0) {
      const r = reportes[0];
      const inicio = r.periodo_inicio || r.PeriodoInicio;
      const fin = r.periodo_fin || r.PeriodoFin;
      const texto = r.texto || r.Texto || "";
      let raw = null;
      if (r.datos_raw || r.DatosRaw) {
        try {
          raw = typeof (r.datos_raw || r.DatosRaw) === 'string' ? JSON.parse(r.datos_raw || r.DatosRaw) : (r.datos_raw || r.DatosRaw);
        } catch (e) {}
      }

      const total = raw ? (raw.total_visitas ?? raw.TotalVisitas ?? 0) : visitas.length;
      const aprob = raw ? (raw.aprobadas ?? raw.Aprobadas ?? 0) : visitas.filter(v => v.estado === 'APROBADO').length;
      const rech = raw ? (raw.rechazadas ?? raw.Rechazadas ?? 0) : visitas.filter(v => v.estado === 'RECHAZADO').length;
      const rev = raw ? (raw.en_revision ?? raw.EnRevision ?? 0) : visitas.filter(v => v.estado === 'REVISION' || v.estado === 'PENDIENTE').length;

      const generadoPorIA = !!(r.generado_por_ia ?? r.GeneradoPorIA);

      if (periodoEl) {
        periodoEl.textContent = (inicio && fin) ? `Período: ${fmtDate(inicio)} – ${fmtDate(fin)}` : 'Último período';
      }

      if (chipsEl) {
        chipsEl.innerHTML = `
          <div class="stat-pill"><span class="stat-pill-num">${total}</span> Total visitas</div>
          <div class="stat-pill stat-pill--green"><span class="stat-pill-num">${aprob}</span> Aprobadas</div>
          ${rech > 0 ? `<div class="stat-pill stat-pill--red"><span class="stat-pill-num">${rech}</span> Rechazadas</div>` : ''}
          ${rev > 0 ? `<div class="stat-pill stat-pill--yellow"><span class="stat-pill-num">${rev}</span> En revisión</div>` : ''}
        `;
      }

      if (textoEl) {
        const etiqueta = generadoPorIA
          ? `<div style="display:flex;align-items:center;gap:6px;margin-bottom:8px;font-size:11px;font-weight:700;color:var(--primary);text-transform:uppercase;letter-spacing:.04em">✨ Análisis de Inteligencia Artificial</div>`
          : `<div style="display:flex;align-items:center;gap:6px;margin-bottom:8px;font-size:11px;font-weight:700;color:var(--text-3);text-transform:uppercase;letter-spacing:.04em">Resumen automático · IA no disponible</div>`;
        textoEl.innerHTML = etiqueta + (formatMarkdown(esc(texto)) || '');
      }
      bodyEl.hidden = false;
      return;
    }

    // Si no hay reporte periódico aún, generar resumen dinámico si hay visitas
    if (visitas.length > 0) {
      const total = visitas.length;
      const aprob = visitas.filter(v => v.estado === 'APROBADO').length;
      const rech = visitas.filter(v => v.estado === 'RECHAZADO').length;
      const rev = visitas.filter(v => v.estado === 'REVISION' || v.estado === 'PENDIENTE').length;
      const tasaAprob = total > 0 ? Math.round((aprob / total) * 100) : 100;

      if (periodoEl) periodoEl.textContent = "Actividad acumulada reciente";
      if (chipsEl) {
        chipsEl.innerHTML = `
          <div class="stat-pill"><span class="stat-pill-num">${total}</span> Total registradas</div>
          <div class="stat-pill stat-pill--green"><span class="stat-pill-num">${aprob}</span> Aprobadas (${tasaAprob}%)</div>
          ${rech > 0 ? `<div class="stat-pill stat-pill--red"><span class="stat-pill-num">${rech}</span> Rechazadas</div>` : ''}
          ${rev > 0 ? `<div class="stat-pill stat-pill--yellow"><span class="stat-pill-num">${rev}</span> En revisión</div>` : ''}
        `;
      }

      let textoDinamico = `Se han registrado **${total} accesos** en el sistema (${aprob} aprobados, ${rech} rechazados, ${rev} pendientes de resolución). `;
      if (rech > 0) {
        textoDinamico += `Se identificaron entradas rechazadas que sugieren atención por parte de vigilancia o administración.`;
      } else {
        textoDinamico += `El flujo de accesos opera con normalidad y con alta tasa de aprobación.`;
      }

      if (textoEl) textoEl.innerHTML = formatMarkdown(textoDinamico);
      bodyEl.hidden = false;
      return;
    }

    if (emptyEl) emptyEl.hidden = false;
  }

  const stateHistorialReportes = { page: 1, pageSize: 10 };

  async function loadHistorialReportes(page) {
    stateHistorialReportes.page = page;
    const loadEl  = document.getElementById("historial-reportes-loading");
    const emptyEl = document.getElementById("historial-reportes-empty");
    const rowsEl  = document.getElementById("historial-reportes-rows");
    const pagEl   = document.getElementById("historial-reportes-pagination");

    if (loadEl) loadEl.hidden = false;
    if (emptyEl) emptyEl.hidden = true;
    rowsEl.innerHTML = "";
    pagEl.hidden = true;

    const res = await api(`/visitas/reportes?page=${page}&page_size=${stateHistorialReportes.pageSize}`);
    if (loadEl) loadEl.hidden = true;

    if (!res || !res.ok) {
      if (emptyEl) { emptyEl.hidden = false; emptyEl.querySelector(".empty-text").textContent = "No se pudo cargar el historial."; }
      return;
    }

    let data = { reportes: [], total: 0 };
    try { data = await res.json(); } catch (e) { console.error(e); }
    const reportes = data.reportes || [];

    if (!reportes.length) {
      if (emptyEl) emptyEl.hidden = false;
      return;
    }

    rowsEl.innerHTML = reportes.map(r => {
      const inicio = r.periodo_inicio || r.PeriodoInicio;
      const fin = r.periodo_fin || r.PeriodoFin;
      const texto = r.texto || r.Texto || "";
      let raw = null;
      if (r.datos_raw || r.DatosRaw) {
        try {
          raw = typeof (r.datos_raw || r.DatosRaw) === 'string' ? JSON.parse(r.datos_raw || r.DatosRaw) : (r.datos_raw || r.DatosRaw);
        } catch (e) {}
      }

      let chips = '';
      if (raw) {
        const total = raw.total_visitas ?? raw.TotalVisitas ?? 0;
        const aprob = raw.aprobadas ?? raw.Aprobadas ?? 0;
        const rech = raw.rechazadas ?? raw.Rechazadas ?? 0;
        chips = `<div style="display:flex;gap:6px;margin:6px 0;">
          <span class="stat-pill" style="font-size:11px;padding:2px 8px"><span class="stat-pill-num">${total}</span> visitas</span>
          <span class="stat-pill stat-pill--green" style="font-size:11px;padding:2px 8px"><span class="stat-pill-num">${aprob}</span> aprob</span>
          ${rech > 0 ? `<span class="stat-pill stat-pill--red" style="font-size:11px;padding:2px 8px"><span class="stat-pill-num">${rech}</span> rech</span>` : ''}
        </div>`;
      }

      const generadoPorIA = !!(r.generado_por_ia ?? r.GeneradoPorIA);
      const etiqueta = generadoPorIA
        ? `<span style="font-size:10px;font-weight:700;color:var(--primary);text-transform:uppercase;letter-spacing:.04em">✨ IA</span>`
        : `<span style="font-size:10px;font-weight:700;color:var(--text-3);text-transform:uppercase;letter-spacing:.04em">Automático</span>`;

      return `<div class="panel-padded" style="padding:12px 0;border-bottom:1px solid var(--border)">
        <div class="row-sub" style="margin-bottom:6px;display:flex;align-items:center;gap:8px">${(inicio && fin) ? `${fmtDate(inicio)} – ${fmtDate(fin)}` : 'Período'} ${etiqueta}</div>
        ${chips}
        <div style="line-height:1.5; font-size:13px; color:var(--text-2); margin-top:8px;" class="ia-summary-card-content">${formatMarkdown(esc(texto))}</div>
      </div>`;
    }).join("");

    const totalPages = Math.ceil((data.total || 0) / stateHistorialReportes.pageSize);
    if (totalPages > 1) {
      pagEl.hidden = false;
      document.getElementById("historial-reportes-page-label").textContent = `${data.total} reportes`;
      document.getElementById("historial-reportes-page-current").textContent = page;
      document.getElementById("historial-reportes-prev").disabled = page <= 1;
      document.getElementById("historial-reportes-next").disabled = page >= totalPages;
    }
  }

  document.getElementById("btn-ver-historial-reportes")?.addEventListener("click", () => {
    document.getElementById("modal-historial-reportes").hidden = false;
    loadHistorialReportes(1);
  });
  document.getElementById("historial-reportes-close")?.addEventListener("click", () => {
    document.getElementById("modal-historial-reportes").hidden = true;
  });
  document.getElementById("historial-reportes-prev")?.addEventListener("click", () => loadHistorialReportes(stateHistorialReportes.page - 1));
  document.getElementById("historial-reportes-next")?.addEventListener("click", () => loadHistorialReportes(stateHistorialReportes.page + 1));

  function animateStat(id, value) {
    const el = document.getElementById(id);
    if (!el) return;
    const num = Number(value);
    if (isNaN(num)) {
      el.textContent = "0";
      return;
    }
    if (num === 0) {
      el.textContent = "0";
      return;
    }
    el.textContent = "0";
    const duration = 400;
    const start = performance.now();
    const step = ts => {
      const p = Math.min((ts - start) / duration, 1);
      el.textContent = Math.round(p * num);
      if (p < 1) requestAnimationFrame(step);
    };
    requestAnimationFrame(step);
  }

  function renderDashRow(v, i) {
    const tvBadge = TIPO_VIS_BADGE[v.tipo_visitante] || "";
    const tvLabel = tipoVisLabel(v.tipo_visitante);
    const titular = v.titular || v.placa || (v.tipo_visitante === "RESIDENTE" ? "Residente" : "Visitante sin nombre");
    return `<div class="row-item" style="grid-template-columns:2fr auto 1fr 80px;gap:12px;align-items:center;animation-delay:${i*40}ms;cursor:pointer" data-id="${v.id}">
      <div>
        <div class="row-name">${esc(titular)}</div>
        <div class="row-sub">${esc(v.casa_destino || v.placa || "")}</div>
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
    const tipo   = document.getElementById("vis-filter-tipo")?.value || "";
    const estado = document.getElementById("vis-filter-estado")?.value || "";
    const fecha  = document.getElementById("vis-filter-fecha")?.value || "";
    const q      = document.getElementById("vis-quick-search")?.value.trim() || "";
    const soloIntervenida = document.getElementById("vis-filter-intervenida")?.checked || false;

    let params = `?page=${page}&page_size=${state.visPageSize}`;
    if (tipo)   params += `&tipo_visitante=${tipo}`;
    if (estado) params += `&estado=${estado}`;
    if (fecha)  params += `&fecha=${fecha}`;
    if (q)      params += `&q=${encodeURIComponent(q)}`;
    if (soloIntervenida) params += `&intervenida=true`;

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
    const tieneIA = !!(v.resumen_ia || v.estadisticas);
    return `<div class="row-item vis-row-grid--list" style="animation-delay:${i*30}ms" data-id="${v.id}">
      <div><div class="row-name">${esc(v.titular)}${tieneIA ? ' <span title="Con análisis IA" style="opacity:.6">*</span>' : ''}</div><div class="row-sub">${esc(v.casa_destino || "")}</div></div>
      <div><span class="badge ${tvBadge}">${esc(tvLabel)}</span></div>
      <div class="row-sub">${acceso ? esc(acceso.nombre) : `#${v.kiosko_id}`}</div>
      <div><span class="badge ${ESTADO_BADGE[v.estado] || ""}">${estadoLabel(v.estado)}</span></div>
      <div class="row-date">${fmtDateShort(v.created_at)}</div>
    </div>`;
  }

  document.getElementById("vis-prev")?.addEventListener("click",  () => loadVisitas(state.visPage - 1));
  document.getElementById("vis-next")?.addEventListener("click",  () => loadVisitas(state.visPage + 1));
  document.getElementById("vis-retry")?.addEventListener("click", () => loadVisitas(1));

  ["vis-quick-search","vis-filter-fecha","vis-filter-tipo","vis-filter-estado","vis-filter-intervenida"].forEach(id => {
    const el = document.getElementById(id);
    if (!el) return;
    const evt = el.tagName === "INPUT" ? "input" : "change";
    let debounce;
    el.addEventListener(evt, () => {
      clearTimeout(debounce);
      debounce = setTimeout(() => loadVisitas(1), el.tagName === "INPUT" ? 250 : 0);
    });
  });

  /* ─── Detalle de visita + expediente ───── */
  function formatMarkdown(text) {
    if (!text) return '';
    let html = text
      .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
      .replace(/\*(.*?)\*/g, '<em>$1</em>')
      .replace(/- (.*)/g, '<li>$1</li>');
      
    html = html.replace(/(<li>.*<\/li>)/s, '<ul>$1</ul>');
    return html.replace(/\n/g, '<br/>');
  }

  /* ─── Evidencia fotográfica + visor ─────── */

  // Las fotos se muestran completas (contain), no recortadas, y se pueden
  // abrir a tamaño real: en una INE recortada se pierden los datos de los
  // bordes, y en un rostro recortado se pierde justo lo que hay que comparar.
  function renderEvidencia(v) {
    const fotos = [
      { url: v.foto_documento_url, label: "Documento" },
      { url: v.foto_rostro_url,    label: "Rostro" },
      { url: v.foto_placa_url,     label: "Placa" },
    ].filter(f => !!f.url);

    if (!fotos.length) {
      return `<div class="evidencia-grid"><div class="evidencia-vacia">Esta entrada no tiene fotos registradas.</div></div>`;
    }

    const lupa = `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="11" cy="11" r="7"/><line x1="21" y1="21" x2="16.65" y2="16.65"/><line x1="11" y1="8" x2="11" y2="14"/><line x1="8" y1="11" x2="14" y2="11"/></svg>`;

    return `<div class="evidencia-grid">${fotos.map(f => `
      <div class="evidencia-card" tabindex="0" role="button" data-foto="${esc(f.url)}" data-foto-label="${esc(f.label)}">
        <div class="evidencia-marco">
          <img class="evidencia-img" src="${esc(f.url)}" alt="${esc(f.label)}" loading="lazy">
          <span class="evidencia-zoom">${lupa}</span>
        </div>
        <div class="evidencia-pie"><span>${esc(f.label)}</span><span>Ver completa</span></div>
      </div>`).join("")}</div>`;
  }

  // Delegado en document: la evidencia se re-renderiza en varios sitios
  // (detalle y modal de solicitud) y así no hay que recablear listeners.
  document.addEventListener("click", (e) => {
    const card = e.target.closest?.(".evidencia-card");
    if (card) abrirLightbox(card.dataset.foto, card.dataset.fotoLabel);
  });
  document.addEventListener("keydown", (e) => {
    if (e.key !== "Enter" && e.key !== " ") return;
    const card = document.activeElement?.closest?.(".evidencia-card");
    if (card) { e.preventDefault(); abrirLightbox(card.dataset.foto, card.dataset.fotoLabel); }
  });

  function abrirLightbox(src, titulo) {
    const box = document.getElementById("lightbox");
    const img = document.getElementById("lightbox-img");
    const cap = document.getElementById("lightbox-caption");
    if (!box || !img) return;
    img.src = src;
    img.alt = titulo || "";
    if (cap) cap.textContent = titulo || "";
    box.hidden = false;
  }

  function cerrarLightbox() {
    const box = document.getElementById("lightbox");
    if (!box) return;
    box.hidden = true;
    // Se limpia el src para que no siga en memoria una imagen grande que ya
    // nadie está viendo.
    const img = document.getElementById("lightbox-img");
    if (img) img.src = "";
  }

  document.getElementById("lightbox-cerrar")?.addEventListener("click", cerrarLightbox);
  document.getElementById("lightbox")?.addEventListener("click", (e) => {
    // Solo el fondo cierra: un clic sobre la imagen no debe cerrarla.
    if (e.target.id === "lightbox") cerrarLightbox();
  });
  document.addEventListener("keydown", (e) => {
    if (e.key !== "Escape") return;
    const lb = document.getElementById("lightbox");
    if (lb && !lb.hidden) { cerrarLightbox(); return; }
    const sol = document.getElementById("modal-solicitud");
    if (sol && !sol.hidden) sol.hidden = true;
    const resMod = document.getElementById("modal-residente-detalle");
    if (resMod && !resMod.hidden) resMod.hidden = true;
  });

  function renderSeccionIA(v) {
    if (v.score_ia || v.resumen_ia) {
      const s = v.score_ia || {};
      const pct = Number.isFinite(s.confianza_pct) ? s.confianza_pct : null;
      const nivel = s.nivel_confianza || (pct === null ? "" : (pct >= 80 ? "alta" : pct >= 55 ? "media" : "baja"));

      const badges = [];
      if (s.anomalia_matricula) badges.push('<span class="badge badge--pendiente">Placa distinta</span>');
      if (s.horario_inusual)    badges.push('<span class="badge badge--pendiente">Horario inusual</span>');
      if (s.rechazado_previo)   badges.push('<span class="badge badge--rechazado">Rechazo previo</span>');
      if (s.ocr_sospechoso)     badges.push('<span class="badge badge--pendiente">OCR sospechoso</span>');
      if (s.confiable)          badges.push('<span class="badge badge--aprobado">Visitante confiable</span>');

      return `
        <div class="ia-summary-card">
          <div class="ia-summary-header">
             <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="color:var(--brand);margin-right:6px;"><path d="m21.64 3.64-1.28-1.28a1.21 1.21 0 0 0-1.72 0L2.36 18.64a1.21 1.21 0 0 0 0 1.72l1.28 1.28a1.2 1.2 0 0 0 1.72 0L21.64 5.36a1.2 1.2 0 0 0 0-1.72Z"/><path d="m14 7 3 3"/><path d="M5 6v4"/><path d="M19 14v4"/><path d="M10 2v2"/><path d="M7 8H3"/><path d="M21 16h-4"/><path d="M11 3H9"/></svg>
             <span style="font-weight:600;color:var(--text);">Análisis de Inteligencia Artificial</span>
          </div>

          <div class="ia-cuerpo">
            ${pct === null ? "" : renderScoreAnillo(pct, nivel)}
            <div class="ia-texto">
              ${v.resumen_ia ? `<div class="ia-resumen">${formatMarkdown(esc(v.resumen_ia))}</div>` : ''}
              ${badges.length ? `<div class="ia-badges">${badges.join('')}</div>` : ''}
            </div>
          </div>

          ${renderRecomendaciones(s.recomendaciones)}
          ${renderFactores(s.factores)}
        </div>`;
    }

    if (v.estadisticas) {
      const e = v.estadisticas;
      return `
        <div class="ia-summary-card" style="border: 1px solid var(--border); background: var(--bg);">
          <div class="ia-summary-header">
             <span style="font-weight:600;color:var(--text);">Historial del Visitante</span>
          </div>
          <div style="font-size:13px;color:var(--text-3);padding-top:10px;line-height:1.5;">
            <strong>Visitas previas:</strong> ${e.veces_visitado}<br>
            ${e.ultima_visita ? `<strong>Última visita:</strong> ${fmtDateShort(e.ultima_visita)}<br>` : ''}
            ${e.casa_habitual ? `<strong>Casa habitual:</strong> ${esc(e.casa_habitual)}` : ''}
          </div>
        </div>`;
    }

    if (v.estado === 'PENDIENTE') {
      return `
        <div class="ia-summary-card" style="border: 1px dashed var(--border);">
          <div class="ia-summary-header" style="color:var(--text-3);">Analizando mediante IA...</div>
        </div>`;
    }

    return '';
  }

  // El score es lo primero que mira el guardia, así que se pinta como un
  // anillo grande y no como una línea más de texto. El arco se dibuja con
  // stroke-dasharray sobre un círculo de radio 26 (perímetro ~163.4).
  function renderScoreAnillo(pct, nivel) {
    const P = 163.4;
    const avance = Math.max(0, Math.min(100, pct)) / 100 * P;
    const clase = nivel === "alta" ? "score--alta" : nivel === "media" ? "score--media" : "score--baja";
    return `
      <div class="score-anillo ${clase}">
        <svg viewBox="0 0 64 64" width="88" height="88" aria-hidden="true">
          <circle class="score-pista" cx="32" cy="32" r="26" fill="none" stroke-width="7"/>
          <circle class="score-arco" cx="32" cy="32" r="26" fill="none" stroke-width="7"
                  stroke-linecap="round" stroke-dasharray="${avance} ${P}"
                  transform="rotate(-90 32 32)"/>
        </svg>
        <div class="score-centro">
          <div class="score-num">${pct}</div>
          <div class="score-de">/100</div>
        </div>
        <div class="score-nivel">Confianza ${esc(nivel)}</div>
      </div>`;
  }

  // Las recomendaciones no las escribe el LLM: salen de los mismos datos que
  // el score (ver construirRecomendaciones en el backend), así que siempre
  // están y siempre son ciertas aunque el modelo esté apagado.
  function renderRecomendaciones(recs) {
    if (!Array.isArray(recs) || !recs.length) return '';
    return `
      <div class="ia-bloque">
        <div class="ia-bloque-titulo">Cómo proceder</div>
        <ul class="ia-recs">
          ${recs.map(r => `<li>${esc(r)}</li>`).join('')}
        </ul>
      </div>`;
  }

  // Cada factor con su peso: un score que no se puede auditar no le sirve al
  // guardia para decidir, solo le pide que confíe en un número.
  function renderFactores(factores) {
    if (!Array.isArray(factores) || !factores.length) return '';
    const orden = { negativo: 0, faltante: 1, positivo: 2 };
    const items = [...factores].sort((a, b) => (orden[a.tipo] ?? 3) - (orden[b.tipo] ?? 3));
    return `
      <details class="ia-bloque ia-factores">
        <summary class="ia-bloque-titulo">Cómo se calculó (${items.length} factores)</summary>
        <div class="factor-lista">
          ${items.map(f => `
            <div class="factor factor--${esc(f.tipo)}">
              <div class="factor-info">
                <div class="factor-etiqueta">${esc(f.etiqueta)}</div>
                ${f.detalle ? `<div class="factor-detalle">${esc(f.detalle)}</div>` : ''}
              </div>
              <div class="factor-impacto">${f.impacto > 0 ? '+' : ''}${f.impacto}</div>
            </div>`).join('')}
        </div>
      </details>`;
  }

  async function loadDetalle(id) {
    navTo("detalle");
    state.detalleAbiertoId = id;
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
      ${renderEvidencia(v)}
      ${renderSeccionIA(v)}
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

  /* ─── Kioskos (heartbeat) ────────────────── */
  function startKioPolling() {
    loadAccesos();
    state.kioPollingId = setInterval(loadAccesos, 15000);
  }

  function stopKioPolling() {
    if (state.kioPollingId) {
      clearInterval(state.kioPollingId);
      state.kioPollingId = null;
    }
  }

  function updateNavBadge(count) {
    const text = count > 99 ? "99+" : String(count);
    const hidden = count <= 0;
    const badge = document.getElementById("nav-badge-solicitudes");
    if (badge) { badge.textContent = text; badge.hidden = hidden; }
    const badgeMob = document.getElementById("nav-badge-solicitudes-mob");
    if (badgeMob) { badgeMob.textContent = text; badgeMob.hidden = hidden; }
  }

  function updateNavAlert(activo) {
    document.querySelectorAll('[data-nav="solicitudes"]').forEach(btn => {
      btn.classList.toggle("nav-btn--alert", activo);
    });
  }

  async function loadAlertasIABadge() {
    const res = await api("/visitas/?estado=REVISION&intervenida=true&page_size=1");
    if (!res || !res.ok) return;
    let total = 0;
    try {
      const d = await res.json();
      total = d.total || 0;
    } catch (e) { console.error(e); }
    const text = total > 99 ? "99+" : String(total);
    const hidden = total <= 0;
    const badge = document.getElementById("nav-badge-alertas-ia");
    if (badge) {
      badge.textContent = text;
      badge.hidden = hidden;
    }
    const badgeMob = document.getElementById("nav-badge-alertas-ia-mob");
    if (badgeMob) {
      badgeMob.textContent = text;
      badgeMob.hidden = hidden;
    }
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
    loadResidentesPendientesBadge();

    if (visitas.length === 0) {
      showSolState("empty");
      return;
    }

    const container = document.getElementById("sol-rows");
    if (!container) return;
    container.innerHTML = visitas.map((v, i) => renderSolRow(v, i)).join("");

    container.querySelectorAll("[data-aprobar]").forEach(btn => {
      btn.addEventListener("click", (e) => {
        // La tarjeta entera abre el detalle: sin esto, aprobar también lo abriría.
        e.stopPropagation();
        actualizarEstado(btn.dataset.aprobar, "APROBADO");
      });
    });
    container.querySelectorAll("[data-rechazar]").forEach(btn => {
      btn.addEventListener("click", (e) => {
        e.stopPropagation();
        actualizarEstado(btn.dataset.rechazar, "RECHAZADO");
      });
    });
    container.querySelectorAll("[data-sol]").forEach(card => {
      card.addEventListener("click", () => abrirSolicitudDetalle(card.dataset.sol));
      card.addEventListener("keydown", (e) => {
        if (e.key === "Enter" || e.key === " ") { e.preventDefault(); abrirSolicitudDetalle(card.dataset.sol); }
      });
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
    return `<div class="sol-card" style="animation-delay:${i*40}ms" data-sol="${v.id}" role="button" tabindex="0">
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

  // El listado de solicitudes viene de VisitaListItemResponse, que no trae
  // fotos ni CURP, asi que el detalle se pide aparte. Antes solo se podia
  // aprobar o rechazar a ciegas desde la tarjeta.
  async function abrirSolicitudDetalle(id) {
    const modal = document.getElementById("modal-solicitud");
    if (!modal) return;

    modal.innerHTML = `<div class="modal-box modal-box--lg"><div class="loading-state"><div class="spinner"></div></div></div>`;
    modal.hidden = false;

    const res = await api(`/visitas/${id}`);
    if (!res || !res.ok) {
      modal.innerHTML = `<div class="modal-box modal-box--lg">
        <div class="modal-title">${t("load_err_title")}</div>
        <div class="modal-actions"><button type="button" class="btn-cancel" data-cerrar-sol>Cerrar</button></div>
      </div>`;
      cablearCierreSolicitud(modal);
      return;
    }

    const v = await res.json();
    const acceso = state.accesosById.get(v.kiosko_id);
    const tvBadge = TIPO_VIS_BADGE[v.tipo_visitante] || "";

    modal.innerHTML = `<div class="modal-box modal-box--lg">
      <div style="display:flex;align-items:flex-start;justify-content:space-between;gap:12px;margin-bottom:4px">
        <div>
          <div style="display:flex;gap:8px;align-items:center;flex-wrap:wrap;margin-bottom:8px">
            <span class="badge ${tvBadge}">${esc(tipoVisLabel(v.tipo_visitante))}</span>
            <span class="badge ${ESTADO_BADGE[v.estado] || ""}">${estadoLabel(v.estado)}</span>
            ${v.intervenida ? `<span class="badge badge--intervenida">Revisada por IA</span>` : ""}
          </div>
          <div class="modal-title">${esc(v.titular)}</div>
          <div class="modal-sub" style="margin-bottom:0">
            ${acceso ? esc(acceso.nombre) : `Kiosko #${v.kiosko_id}`} · ${fmtDate(v.created_at)}
          </div>
        </div>
        <button type="button" class="btn-cancel" data-cerrar-sol style="padding:4px 10px;font-size:16px;border-radius:6px;cursor:pointer">&#10005;</button>
      </div>

      ${renderEvidencia(v)}

      <div class="sol-modal-campos">
        <div><div class="campo-label">${t("casa_destino")}</div><div class="campo-value">${esc(v.casa_destino || "—")}</div></div>
        <div><div class="campo-label">${t("placa")}</div><div class="campo-value">${v.placa ? esc(v.placa) : t("no_placa")}</div></div>
        <div><div class="campo-label">CURP</div><div class="campo-value campo-mono">${esc(v.curp || "—")}</div></div>
      </div>

      ${renderSeccionIA(v)}

      <div class="modal-actions">
        <button type="button" class="btn-rechazar" data-sol-rechazar="${v.id}">Rechazar</button>
        <button type="button" class="btn-aprobar"  data-sol-aprobar="${v.id}">Aprobar</button>
      </div>
    </div>`;

    cablearCierreSolicitud(modal);

    modal.querySelector("[data-sol-aprobar]")?.addEventListener("click", async () => {
      modal.hidden = true;
      await actualizarEstado(v.id, "APROBADO");
    });
    modal.querySelector("[data-sol-rechazar]")?.addEventListener("click", async () => {
      modal.hidden = true;
      await actualizarEstado(v.id, "RECHAZADO");
    });
  }

  // Solo los botones de cerrar, que se recrean en cada apertura. El clic en el
  // fondo se cablea una sola vez abajo: el overlay es persistente, y hacerlo
  // aqui apilaba un listener nuevo por cada solicitud abierta.
  function cablearCierreSolicitud(modal) {
    modal.querySelectorAll("[data-cerrar-sol]").forEach(btn => {
      btn.addEventListener("click", () => { modal.hidden = true; });
    });
  }

  document.getElementById("modal-solicitud")?.addEventListener("click", (e) => {
    // Solo el fondo cierra: un clic dentro de la caja no debe cerrarla.
    if (e.target.id === "modal-solicitud") e.target.hidden = true;
  });

  async function actualizarEstado(id, estado) {
    const res = await api(`/visitas/${id}/estado`, {
      method: "PATCH",
      body: JSON.stringify({ estado }),
    });
    if (res && res.ok) loadSolicitudes();
  }

  /* ─── Accesos ────────────────────────────── */
  // Heartbeat: el kiosko manda POST /kioskos/:id/ping cada 30s (ver
  // KioskoConfigNotifier en Flutter) mientras tenga sesión. Con 90s de
  // margen (3x el intervalo) se toleran un par de ciclos perdidos por red
  // lenta antes de marcarlo desconectado -- evita falsos "offline" por un
  // solo ping tardío.
  const KIO_PING_MARGEN_MS = 90000;

  function estadoConexionKiosko(ultimoPing) {
    if (!ultimoPing) return { clase: 'nunca', texto: 'Nunca conectado' };
    const ms = Date.now() - new Date(ultimoPing).getTime();
    if (ms < KIO_PING_MARGEN_MS) return { clase: 'online', texto: 'En línea' };
    const mins = Math.floor(ms / 60000);
    if (mins < 60) return { clase: 'offline', texto: `Desconectado hace ${mins}m` };
    const hrs = Math.floor(mins / 60);
    return { clase: 'offline', texto: `Desconectado hace ${hrs}h` };
  }

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
    container.innerHTML = list.map(a => {
      const conn = estadoConexionKiosko(a.ultimo_ping);
      return `
      <div class="acceso-card">
        <div class="acceso-info">
          <div class="acceso-nombre">
            ${esc(a.nombre)}
            <span class="kio-conn kio-conn--${conn.clase}" title="${esc(conn.texto)}">
              <span class="kio-conn-dot"></span>${esc(conn.texto)}
            </span>
          </div>
          ${a.ubicacion ? `<div class="acceso-ubi">${esc(a.ubicacion)}</div>` : ""}
          <div class="acceso-id">${esc(a.tipo || "—")}</div>
        </div>
        <div class="acceso-actions">
          <button class="btn-cancel" data-cfg-acceso="${a.id}" style="font-size:12.5px;padding:6px 14px;border-radius:8px;font-weight:600;display:inline-flex;align-items:center;gap:6px" title="Configurar kiosko">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6z"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>
            Configuración
          </button>
          <button class="btn-ghost" data-del-acceso="${a.id}" style="color:var(--red)" title="Eliminar">
            <svg width="14" height="14" viewBox="0 0 18 18" fill="none" stroke="currentColor" stroke-width="1.7"><line x1="4" y1="5" x2="14" y2="5"/><path d="M6 5V3.5h6V5"/><path d="M5 5l.7 9a1 1 0 0 0 1 .9h4.6a1 1 0 0 0 1-.9L13 5"/></svg>
          </button>
        </div>
      </div>`;
    }).join("");

    container.querySelectorAll("[data-cfg-acceso]").forEach(btn => {
      btn.addEventListener("click", () => openConfigParaAcceso(parseInt(btn.dataset.cfgAcceso)));
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
      telefono_contacto:     document.getElementById('nk-cfg-telefono-contacto').value.trim(),
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
    cfgAccesoId = accesoId;
    navTo("configuracion");
    await loadConfig(accesoId);
  }

  async function loadConfigAccesos() {
    if (cfgAccesoId) {
      await loadConfig(cfgAccesoId);
      return;
    }
    const res = await api("/kioskos/");
    if (!res || !res.ok) return;
    const data = await res.json();
    const list = Array.isArray(data) ? data : (data.kioskos || []);
    list.forEach(a => state.accesosById.set(a.id, a));
    if (list.length > 0) {
      cfgAccesoId = list[0].id;
      await loadConfig(cfgAccesoId);
    } else {
      const wrap = document.getElementById("cfg-form-wrap");
      const idle = document.getElementById("cfg-idle");
      if (wrap) wrap.hidden = true;
      if (idle) idle.hidden = false;
    }
  }

  document.getElementById("cfg-btn-volver")?.addEventListener("click", () => {
    if (window.history.length > 1) {
      window.history.back();
    } else {
      navTo("kioskos");
    }
  });

  const PIPELINE_DEFS = {
    ROSTRO: {
      id: "ROSTRO",
      icon: `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path><circle cx="12" cy="7" r="4"></circle></svg>`,
      title: "Foto de Rostro",
      desc: "Captura facial de verificación y reconocimiento",
      defaultChecked: true,
    },
    DESTINO: {
      id: "DESTINO",
      icon: `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"></path><polyline points="9 22 9 12 15 12 15 22"></polyline></svg>`,
      title: "Selección de Destino",
      desc: "Búsqueda y selección de calle, edificio o casa",
      defaultChecked: true,
    },
    PLACA: {
      id: "PLACA",
      icon: `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="10" width="20" height="10" rx="2" ry="2"/><path d="M4 10l2-4h12l2 4"/><circle cx="7" cy="16.5" r="1.5"/><circle cx="17" cy="16.5" r="1.5"/></svg>`,
      title: "Captura de Placa Vehicular",
      desc: "Escaneo de matrícula (obligatorio en accesos vehiculares)",
      defaultChecked: false,
    },
    INE: {
      id: "INE",
      icon: `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="6" width="18" height="12" rx="2" ry="2"/><circle cx="8" cy="12" r="2"/><path d="M14 10h4m-4 4h4"/></svg>`,
      title: "Escaneo de INE / Identificación",
      desc: "Escaneo de credencial con OCR (opcional según hardware)",
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
      PLACA: esPeatonal ? false : (cfg.foto_placa_visitante !== undefined ? !!cfg.foto_placa_visitante : true),
      INE: !!cfg.foto_ine_visitante,
    };

    orderedIds.forEach((stepId) => {
      const def = PIPELINE_DEFS[stepId];
      if (!def) return;

      const isPlacaPeatonal = esPeatonal && stepId === "PLACA";
      const isPlacaVehicular = !esPeatonal && stepId === "PLACA";
      const isChecked = isPlacaPeatonal ? false : (checkedMap[stepId] ?? def.defaultChecked);

      const item = document.createElement("div");
      item.className = `pipeline-item ${!isChecked ? "disabled" : ""}`;
      item.draggable = !isPlacaPeatonal;
      item.dataset.stepId = stepId;

      if (isPlacaPeatonal) {
        item.style.opacity = "0.38";
        item.style.filter = "grayscale(1)";
        item.title = "No aplica a kioskos peatonales";
      }

      item.innerHTML = `
        <div class="pipeline-handle" title="${isPlacaPeatonal ? 'No disponible en kiosko peatonal' : 'Arrastrar para reordenar'}">⠿</div>
        <div class="pipeline-order-badge">—</div>
        <div class="pipeline-icon">${def.icon}</div>
        <div class="pipeline-info">
          <div class="pipeline-title">${def.title}</div>
          <div class="pipeline-desc">${isPlacaPeatonal ? "Desactivado (no aplica a kioskos peatonales)" : def.desc}</div>
        </div>
        <div class="pipeline-actions">
          <div class="pipeline-move-btns" style="${isPlacaPeatonal ? 'opacity:0.3;pointer-events:none' : ''}">
            <button type="button" class="pipeline-btn-move btn-move-up" title="Mover arriba" ${isPlacaPeatonal ? 'disabled' : ''}>▲</button>
            <button type="button" class="pipeline-btn-move btn-move-down" title="Mover abajo" ${isPlacaPeatonal ? 'disabled' : ''}>▼</button>
          </div>
          <label class="toggle-switch">
            <input type="checkbox" class="pipeline-toggle" ${isChecked ? "checked" : ""} ${(isPlacaVehicular || isPlacaPeatonal) ? "disabled" : ""}>
            <span class="toggle-slider"></span>
          </label>
        </div>
      `;

      const toggle = item.querySelector(".pipeline-toggle");
      if (!isPlacaPeatonal) {
        toggle.addEventListener("change", () => {
          item.classList.toggle("disabled", !toggle.checked);
          updatePipelineBadges();
        });

        item.querySelector(".btn-move-up").addEventListener("click", (e) => {
          e.stopPropagation();
          const prev = item.previousElementSibling;
          if (prev && prev.dataset.stepId !== "PLACA" || !esPeatonal) {
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
      }

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
    if (!accesoId) return;
    const wrap = document.getElementById("cfg-form-wrap");
    const idle = document.getElementById("cfg-idle");

    let acceso = state.accesosById.get(accesoId);
    if (!acceso) {
      const kRes = await api(`/kioskos/`);
      if (kRes && kRes.ok) {
        const kData = await kRes.json();
        const list = Array.isArray(kData) ? kData : (kData.kioskos || []);
        list.forEach(a => state.accesosById.set(a.id, a));
        acceso = state.accesosById.get(accesoId);
      }
    }

    const res = await api(`/kioskos/${accesoId}/config`);
    if (!res || !res.ok) {
      mostrarToast("No se pudo cargar la configuración del kiosko", "err");
      return;
    }

    const cfg = await res.json();
    cfgAccesoId = accesoId;

    const headerTitle = document.getElementById("cfg-header-title");
    const headerSub = document.getElementById("cfg-header-sub");
    if (headerTitle) headerTitle.textContent = acceso?.nombre ? `Configuración: ${acceso.nombre}` : "Configuración de kiosko";
    if (headerSub) headerSub.textContent = acceso?.ubicacion ? acceso.ubicacion : (acceso?.tipo ? `Acceso ${acceso.tipo.toLowerCase()}` : '');

    // Cargar datos principales del kiosko
    const nombreEl = document.getElementById("cfg-nombre");
    const tipoEl = document.getElementById("cfg-tipo");
    const ubiEl = document.getElementById("cfg-ubicacion");
    if (nombreEl) nombreEl.value = acceso?.nombre || "";
    if (tipoEl) tipoEl.value = acceso?.tipo || "PEATONAL";
    if (ubiEl) ubiEl.value = acceso?.ubicacion || "";

    const esPeatonal = (tipoEl ? tipoEl.value : acceso?.tipo) === "PEATONAL";

    document.getElementById("cfg-color").value        = cfg.color_kiosko       || "oscuro";
    document.getElementById("cfg-idioma").value       = cfg.idioma_kiosko      || "es";
    document.getElementById("cfg-mensaje").value      = cfg.mensaje_bienvenida || "";
    document.getElementById("cfg-telefono-contacto").value = cfg.telefono_contacto || "";
    document.getElementById("cfg-ine-invitado").checked     = !!cfg.foto_ine_invitado;
    document.getElementById("cfg-rostro-invitado").checked  = !!cfg.foto_rostro_invitado;
    document.getElementById("cfg-placa-invitado").checked   = esPeatonal ? false : !!cfg.foto_placa_invitado;
    document.getElementById("cfg-tiempo-exito").value = cfg.tiempo_exito_seg ?? 5;
    document.getElementById("cfg-tiempo-espera").value = cfg.tiempo_espera_seg ?? 60;
    document.getElementById("cfg-autopass").checked = !!cfg.auto_pass_habilitado;
    document.getElementById("cfg-umbral-facial").value = cfg.umbral_facial_pct ?? 85;
    document.getElementById("cfg-umbral-autopass").value = cfg.umbral_autopass_pct ?? 80;
    document.getElementById("cfg-horario-inicio").value = cfg.horario_inicio || "00:00";
    document.getElementById("cfg-horario-fin").value    = cfg.horario_fin    || "23:59";

    const rowPlacaInv = document.getElementById("cfg-row-placa-invitado");
    if (rowPlacaInv) rowPlacaInv.style.opacity = esPeatonal ? "0.35" : "1";
    document.getElementById("cfg-placa-invitado").disabled = esPeatonal;

    // Resetear a la primera pestaña (General)
    document.querySelectorAll("[data-cfg-tab]").forEach(btn => {
      btn.classList.toggle("active", btn.dataset.cfgTab === "cfg-tab-general");
    });
    document.querySelectorAll(".cfg-tab-pane").forEach(pane => {
      pane.hidden = pane.id !== "cfg-tab-general";
    });

    // Renderizar pipeline arrastrable
    renderPipeline(cfg, esPeatonal);

    document.getElementById("cfg-error").hidden   = true;
    document.getElementById("cfg-success").hidden = true;
    if (idle) idle.hidden = true;
    wrap.hidden = false;
  }

  // Listener para las pestañas de configuración de kiosko
  document.querySelectorAll("[data-cfg-tab]").forEach(btn => {
    btn.addEventListener("click", () => {
      const targetId = btn.dataset.cfgTab;
      document.querySelectorAll("[data-cfg-tab]").forEach(b => b.classList.remove("active"));
      btn.classList.add("active");
      document.querySelectorAll(".cfg-tab-pane").forEach(pane => {
        pane.hidden = pane.id !== targetId;
      });
    });
  });

  document.getElementById("cfg-tipo")?.addEventListener("change", (e) => {
    const esPeatonal = e.target.value === "PEATONAL";
    const rowPlacaInv = document.getElementById("cfg-row-placa-invitado");
    if (rowPlacaInv) rowPlacaInv.style.opacity = esPeatonal ? "0.35" : "1";
    const placaChk = document.getElementById("cfg-placa-invitado");
    if (placaChk) {
      placaChk.disabled = esPeatonal;
      if (esPeatonal) placaChk.checked = false;
    }

    const activeSteps = [];
    const listEl = document.getElementById("cfg-pipeline-list");
    if (listEl) {
      listEl.querySelectorAll(".pipeline-item").forEach(item => {
        if (item.querySelector(".pipeline-toggle")?.checked) {
          if (item.dataset.stepId !== "PLACA" || !esPeatonal) {
            activeSteps.push(item.dataset.stepId);
          }
        }
      });
    }
    renderPipeline({
      pasos_sin_invitacion: activeSteps,
      foto_rostro_visitante: activeSteps.includes("ROSTRO"),
      foto_placa_visitante: esPeatonal ? false : activeSteps.includes("PLACA"),
      foto_ine_visitante: activeSteps.includes("INE"),
    }, esPeatonal);
  });

  document.getElementById("cfg-save-btn")?.addEventListener("click", async () => {
    if (!cfgAccesoId) return;
    const errEl = document.getElementById("cfg-error");
    const okEl  = document.getElementById("cfg-success");
    errEl.hidden = true;
    okEl.hidden  = true;

    const nombreVal = document.getElementById("cfg-nombre")?.value.trim() || "";
    const tipoVal   = document.getElementById("cfg-tipo")?.value || "PEATONAL";
    const ubiVal    = document.getElementById("cfg-ubicacion")?.value.trim() || "";

    if (!nombreVal) {
      errEl.textContent = "El nombre del kiosko es obligatorio";
      errEl.hidden = false;
      return;
    }

    // 1. Guardar datos principales del kiosko (nombre, tipo, ubicacion)
    const resKiosko = await api(`/kioskos/${cfgAccesoId}`, {
      method: "PATCH",
      body: JSON.stringify({ nombre: nombreVal, tipo: tipoVal, ubicacion: ubiVal }),
    });

    if (!resKiosko || !resKiosko.ok) {
      const data = resKiosko ? await resKiosko.json() : {};
      errEl.textContent = data.error || "Error al actualizar información del kiosko";
      errEl.hidden = false;
      return;
    }

    const kioskoActualizado = await resKiosko.json();
    state.accesosById.set(cfgAccesoId, kioskoActualizado);

    const headerTitle = document.getElementById("cfg-header-title");
    const headerSub = document.getElementById("cfg-header-sub");
    if (headerTitle) headerTitle.textContent = `Configuración de Kiosko: ${kioskoActualizado.nombre}`;
    if (headerSub) headerSub.textContent = kioskoActualizado.ubicacion ? kioskoActualizado.ubicacion : '';

    // 2. Guardar parámetros de configuración
    const esPeatonal = tipoVal === "PEATONAL";
    const listEl = document.getElementById("cfg-pipeline-list");
    const activeSteps = [];
    let fotoRostro = false, fotoPlaca = false, fotoIne = false;

    if (listEl) {
      listEl.querySelectorAll(".pipeline-item").forEach((item) => {
        const stepId = item.dataset.stepId;
        const toggle = item.querySelector(".pipeline-toggle");
        if (toggle && toggle.checked) {
          if (stepId === "PLACA" && esPeatonal) return;
          activeSteps.push(stepId);
          if (stepId === "ROSTRO") fotoRostro = true;
          if (stepId === "PLACA") fotoPlaca = true;
          if (stepId === "INE") fotoIne = true;
        }
      });
    }

    if (esPeatonal) {
      fotoPlaca = false;
    }

    const payload = {
      color_kiosko:             document.getElementById("cfg-color").value,
      idioma_kiosko:            document.getElementById("cfg-idioma").value,
      mensaje_bienvenida:       document.getElementById("cfg-mensaje").value,
      telefono_contacto:        document.getElementById("cfg-telefono-contacto").value.trim(),
      foto_rostro_visitante:    fotoRostro,
      foto_placa_visitante:     esPeatonal ? false : fotoPlaca,
      foto_ine_visitante:       fotoIne,
      pasos_sin_invitacion:     activeSteps,
      foto_ine_invitado:        document.getElementById("cfg-ine-invitado").checked,
      foto_rostro_invitado:     document.getElementById("cfg-rostro-invitado").checked,
      foto_placa_invitado:      esPeatonal ? false : document.getElementById("cfg-placa-invitado").checked,
      tiempo_exito_seg:         parseInt(document.getElementById("cfg-tiempo-exito").value) || 5,
      tiempo_espera_seg:        parseInt(document.getElementById("cfg-tiempo-espera").value) || 60,
      auto_pass_habilitado:     document.getElementById("cfg-autopass").checked,
      // Se acotan aqui tambien, no solo con min/max del input: el backend
      // vuelve a acotarlos, y mandar un valor que va a ignorar dejaria el
      // dashboard mintiendo sobre lo que quedo guardado.
      umbral_facial_pct:        Math.min(99, Math.max(50,
                                  parseInt(document.getElementById("cfg-umbral-facial").value) || 85)),
      umbral_autopass_pct:      Math.min(100, Math.max(50,
                                  parseInt(document.getElementById("cfg-umbral-autopass").value) || 80)),
      horario_inicio:           document.getElementById("cfg-horario-inicio").value,
      horario_fin:              document.getElementById("cfg-horario-fin").value,
    };

    const res = await api(`/kioskos/${cfgAccesoId}/config`, {
      method: "PATCH",
      body: JSON.stringify(payload),
    });

    if (!res) return;
    if (!res.ok) {
      const data = await res.json();
      errEl.textContent = data.error || "Error al guardar configuración";
      errEl.hidden = false;
      return;
    }
    okEl.hidden = false;
    mostrarToast("Kiosko y configuración guardados correctamente", "ok");
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
      const nombreRaw = (v.nombre || v.Nombre || "").trim();
      const apeRaw = (v.apellido_paterno || v.ApellidoPaterno || "").trim();
      const correoRaw = (v.correo || v.Correo || "").trim();
      const idRaw = v.id || v.ID || 0;
      const nombre = [nombreRaw, apeRaw].filter(Boolean).join(" ") || correoRaw || "Vigilante";
      const initials = (nombreRaw ? (nombreRaw[0] + (apeRaw[0] || "")) : (correoRaw ? correoRaw[0] : "V")).toUpperCase();
      return `<div class="acceso-card" style="animation-delay:${i*30}ms">
        <div class="acceso-info" style="display:flex;align-items:center;gap:12px">
          <div class="avatar">${esc(initials) || "V"}</div>
          <div>
            <div class="acceso-nombre">${esc(nombre)}</div>
            ${correoRaw && correoRaw !== nombre ? `<div class="acceso-ubi">${esc(correoRaw)}</div>` : `<div class="acceso-ubi" style="color:var(--text-3)">Vigilante</div>`}
          </div>
        </div>
        <div class="acceso-actions">
          <button class="btn-ghost" style="color:var(--red)" data-del-vigilante="${idRaw}" title="Eliminar vigilante">
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
    document.getElementById("perfil-password").value = "";
    await loadAdminData();
    mostrarToast(lang === "en" ? "Profile updated successfully" : "Perfil actualizado correctamente");
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
      nombre:           '',
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

  function formatTipoDestino(tipo) {
    if (!tipo) return 'Casa';
    switch (tipo.toLowerCase()) {
      case 'casa': return 'Casa';
      case 'departamento': return 'Depto.';
      case 'edificio': return 'Edificio';
      case 'oficina': return 'Oficina';
      case 'local': return 'Local';
      case 'bodega': return 'Bodega';
      case 'lote': return 'Lote';
      default: return tipo.charAt(0).toUpperCase() + tipo.slice(1);
    }
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

    // Agrupadas por calle
    const porCalle = new Map();
    for (const d of items) {
      const calle = d.calle || 'Sin calle';
      if (!porCalle.has(calle)) porCalle.set(calle, []);
      porCalle.get(calle).push(d);
    }

    rowsEl.innerHTML = [...porCalle.entries()].map(([calle, destinos]) => `
      <div style="background:var(--surface-2);border:1px solid var(--border);border-radius:10px;padding:16px;margin-bottom:16px">
        <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:12px;padding-bottom:8px;border-bottom:1px solid var(--border)">
          <div style="font-size:14px;font-weight:700;color:var(--text);display:flex;align-items:center;gap:8px">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="opacity:0.7"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>
            ${esc(calle)}
          </div>
          <span class="badge badge--neutral" style="font-size:11.5px">${destinos.length} ${destinos.length === 1 ? 'destino' : 'destinos'}</span>
        </div>
        <div style="display:flex;flex-wrap:wrap;gap:8px">
          ${destinos.map(d => `
            <div id="dest-row-${d.id}" style="display:inline-flex;align-items:center;gap:8px;padding:6px 12px;background:var(--surface);border:1px solid var(--border);border-radius:8px;font-size:13px">
              <span style="font-weight:600;color:var(--text)">${formatTipoDestino(d.tipo)} ${esc(d.numero || '')}</span>
              ${d.titular ? `<span style="font-size:11px;color:var(--text-3)">· ${esc(d.titular)}</span>` : ''}
              <button type="button" class="btn-ghost" style="color:var(--red);padding:2px 4px;margin-left:4px;display:flex;align-items:center" data-del-dest="${d.id}" title="Eliminar destino">
                <svg width="13" height="13" viewBox="0 0 18 18" fill="none" stroke="currentColor" stroke-width="2"><line x1="4" y1="5" x2="14" y2="5"/><path d="M6 5V3.5h6V5"/><path d="M5 5l.7 9a1 1 0 0 0 1 .9h4.6a1 1 0 0 0 1-.9L13 5"/></svg>
              </button>
            </div>`).join('')}
        </div>
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
    document.getElementById('destino-form').reset();
    destinosChips = [];
    renderChips();
    document.getElementById('dest-form-error').hidden = true;
    document.getElementById('modal-destino').hidden = false;
    setTimeout(() => document.getElementById('dest-calle')?.focus(), 50);
  });
  document.getElementById('dest-cancel')?.addEventListener('click', () => {
    document.getElementById('modal-destino').hidden = true;
  });

  /* --- UI Chips Destinos --- */
  let destinosChips = [];
  const inputAdd = document.getElementById('dest-numero-input');
  const btnAdd = document.getElementById('dest-numero-add');
  const chipsContainer = document.getElementById('dest-chips-container');
  
  function renderChips() {
    if (!chipsContainer) return;
    if (destinosChips.length === 0) {
      chipsContainer.innerHTML = '<div class="empty-text" style="margin:0;font-size:12.5px" id="dest-chips-empty">No has agregado ningún identificador</div>';
      return;
    }
    chipsContainer.innerHTML = destinosChips.map((chip, idx) => `
      <div style="display:inline-flex; align-items:center; background:var(--brand); color:white; padding:4px 10px; border-radius:14px; font-size:12px; font-weight:600;">
        <span>${esc(formatTipoDestino(chip.tipo))} ${esc(chip.numero)}</span>
        <button type="button" class="dest-chip-remove" data-idx="${idx}" style="background:none; border:none; color:white; margin-left:6px; cursor:pointer; padding:0; display:flex; align-items:center;">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"><path d="M18 6L6 18M6 6l12 12"/></svg>
        </button>
      </div>
    `).join("");
    
    chipsContainer.querySelectorAll('.dest-chip-remove').forEach(btn => {
      btn.addEventListener('click', (e) => {
        e.preventDefault();
        e.stopPropagation();
        const i = parseInt(btn.dataset.idx);
        destinosChips.splice(i, 1);
        renderChips();
      });
    });
  }
  
  // Cada chip se queda con el tipo que estaba elegido al agregarlo, no con el
  // que quede seleccionado al enviar. Asi una misma calle puede llevar n casas
  // y m departamentos en un solo alta: antes el <select> aplicaba a todo el
  // lote y habia que mandar el formulario una vez por tipo.
  function addChip() {
    if (!inputAdd) return;
    const val = inputAdd.value.trim();
    if (!val) return;
    const tipo = document.getElementById('dest-tipo').value;
    const nuevos = val.split(',').map(n => n.trim()).filter(n =>
      n.length > 0 && !destinosChips.some(c => c.tipo === tipo && c.numero === n));
    if (nuevos.length > 0) {
      destinosChips.push(...nuevos.map(numero => ({ tipo, numero })));
      renderChips();
    }
    inputAdd.value = '';
    inputAdd.focus();
  }

  btnAdd?.addEventListener('click', (e) => {
    e.preventDefault();
    addChip();
  });

  inputAdd?.addEventListener('keydown', e => {
    if (e.key === 'Enter') {
      e.preventDefault();
      addChip();
    }
  });

  document.getElementById('destino-form')?.addEventListener('submit', async e => {
    e.preventDefault();
    const calle   = document.getElementById('dest-calle').value.trim();
    const errEl   = document.getElementById('dest-form-error');
    errEl.hidden  = true;

    // Si quedó texto pendiente en el input sin presionar 'Añadir', agregarlo
    if (inputAdd && inputAdd.value.trim()) addChip();

    const destinos = [...destinosChips];

    if (!calle) {
      errEl.textContent = 'Ingresa el nombre de la calle o bloque';
      errEl.hidden = false;
      return;
    }

    if (!destinos.length) {
      errEl.textContent = 'Agrega al menos un número o identificador';
      errEl.hidden = false;
      return;
    }

    const res = await api('/destinos/lote', {
      method: 'POST',
      body: JSON.stringify({ calle, destinos })
    });

    if (!res || !res.ok) {
      const d = await res.json();
      errEl.textContent = d.error || 'Error al crear destinos';
      errEl.hidden = false;
      return;
    }
    document.getElementById('modal-destino').hidden = true;
    document.getElementById('destino-form').reset();
    destinosChips = [];
    renderChips();
    mostrarToast('Destinos creados correctamente', 'ok');
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

  document.getElementById('btn-copiar-codigo')?.addEventListener('click', () => {
    const code = document.getElementById('inst-codigo')?.textContent?.trim();
    if (code && code !== '—') {
      navigator.clipboard?.writeText(code);
      const txt = document.getElementById('btn-copiar-codigo-texto');
      if (txt) {
        const orig = txt.textContent;
        txt.textContent = '¡Copiado!';
        setTimeout(() => { txt.textContent = orig; }, 2000);
      }
      mostrarToast('Código copiado al portapapeles', 'ok');
    }
  });

  /* ─── Residentes (Persona + Membresia) ─── */

  let residentesActivosCache = [];

  async function loadResidentesActivos() {
    const loadEl  = document.getElementById('resa-loading');
    const emptyEl = document.getElementById('resa-empty');
    const rowsEl  = document.getElementById('resa-rows');
    if (!rowsEl) return;

    rowsEl.innerHTML = '';
    if (emptyEl) emptyEl.hidden = true;
    if (loadEl)  loadEl.hidden = false;

    const res = await api('/membresias/');
    if (loadEl) loadEl.hidden = true;

    if (!res || !res.ok) {
      rowsEl.innerHTML = `<div class="empty-state"><div class="empty-title">${t("load_err_title")}</div></div>`;
      return;
    }

    let activos = [];
    try {
      const d = await res.json();
      activos = Array.isArray(d) ? d : (d.membresias || []);
    } catch (e) { console.error(e); }

    residentesActivosCache = activos;

    if (!activos.length) {
      if (emptyEl) emptyEl.hidden = false;
      return;
    }
    if (emptyEl) emptyEl.hidden = true;

    rowsEl.innerHTML = activos.map(m => {
      const nombreCompleto = `${m.nombre || ''} ${m.apellido_paterno || ''} ${m.apellido_materno || ''}`.trim() || 'Sin nombre';
      const inicial = (m.nombre || 'R')[0].toUpperCase();
      const avatarHtml = m.foto_cara_url
        ? `<div class="res-avatar"><img src="${esc(m.foto_cara_url)}" alt="${esc(nombreCompleto)}" onerror="this.parentElement.innerHTML='${inicial}'"></div>`
        : `<div class="res-avatar">${inicial}</div>`;

      const contacto = m.telefono ? `${esc(m.telefono)}` : (m.curp ? `CURP: ${esc(m.curp)}` : 'Residente activo');
      const fechaAlta = m.created_at ? fmtDateShort(m.created_at) : '—';

      return `
        <div class="res-row" data-res-id="${m.id}">
          ${avatarHtml}
          <div class="res-info-main">
            <div class="res-name">${esc(nombreCompleto)}</div>
            <div class="res-sub">${contacto}</div>
          </div>
          <div class="res-dest-col">
            <span class="badge badge--aprobado" style="font-size:12px;padding:4px 10px;font-weight:600">
               ${esc(m.casa_destino || 'Sin casa')}
            </span>
          </div>
          <div class="res-date-col">
            <div style="font-size:10.5px;color:var(--text-3);text-transform:uppercase;letter-spacing:0.04em">Alta</div>
            <div style="font-size:12.5px;color:var(--text-2);font-weight:500">${fechaAlta}</div>
          </div>
          <div class="res-action-col">
            <button type="button" class="btn-cancel" style="padding:6px 12px;font-size:12px;border-radius:8px;font-weight:600;display:inline-flex;align-items:center;gap:4px">
              Ver detalle
              <svg width="12" height="12" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="2"><path d="M6 3l5 5-5 5"/></svg>
            </button>
          </div>
        </div>`;
    }).join('');

    rowsEl.querySelectorAll('[data-res-id]').forEach(el => {
      el.addEventListener('click', () => {
        const id = Number(el.dataset.resId);
        const m = residentesActivosCache.find(x => x.id === id);
        if (m) showResidenteModal(m);
      });
    });
  }

  let residentesPendientesCache = [];

  function showResidenteModal(m) {
    const modal = document.getElementById('modal-residente-detalle');
    const body = document.getElementById('res-modal-body');
    if (!modal || !body) return;

    const esPendiente = (m.status === 'pendiente');
    const nombreCompleto = `${m.nombre || ''} ${m.apellido_paterno || ''} ${m.apellido_materno || ''}`.trim() || 'Sin nombre';
    const inicial = (m.nombre || 'R')[0].toUpperCase();
    // data-foto + .evidencia-card, no onclick inline: app.js entero corre
    // dentro del IIFE de arranque y abrirLightbox nunca se expuso a
    // window, así que un onclick="abrirLightbox(...)" en un string HTML
    // fallaba en silencio (ReferenceError en consola, invisible en la UI)
    // -- el listener delegado en document ya existe para .evidencia-card,
    // se reusa tal cual en vez de duplicar el mecanismo.
    const avatarHtml = m.foto_cara_url
      ? `<div class="res-avatar res-avatar--lg evidencia-card" tabindex="0" role="button" style="cursor:pointer" data-foto="${esc(m.foto_cara_url)}" data-foto-label="Rostro de ${esc(nombreCompleto)}"><img src="${esc(m.foto_cara_url)}" alt="${esc(nombreCompleto)}" onerror="this.parentElement.innerHTML='${inicial}'"></div>`
      : `<div class="res-avatar res-avatar--lg">${inicial}</div>`;

    const tieneRostro = m.tiene_rostro;
    const tienePin = m.tiene_pin;

    body.innerHTML = `
      <div class="res-modal-header">
        ${avatarHtml}
        <div>
          <div style="font-size:18px;font-weight:700;color:var(--text);margin-bottom:4px">${esc(nombreCompleto)}</div>
          <div style="display:flex;gap:8px;align-items:center;flex-wrap:wrap">
            <span class="badge ${esPendiente ? 'badge--pendiente' : 'badge--aprobado'}">${esc(m.casa_destino || 'Sin casa asignada')}</span>
            <span class="badge" style="text-transform:capitalize">${esc(m.rol || 'Residente')}</span>
            <span class="badge ${esPendiente ? 'badge--pendiente' : 'badge--green'}">${esPendiente ? 'Solicitud pendiente' : 'Activo'}</span>
          </div>
        </div>
      </div>

      <div class="res-modal-cols">
        <div>
          <div class="res-modal-grid">
            <div class="res-modal-field">
              <div class="res-modal-field-label">Teléfono</div>
              <div class="res-modal-field-value">${m.telefono ? esc(m.telefono) : '—'}</div>
            </div>
            <div class="res-modal-field">
              <div class="res-modal-field-label">CURP</div>
              <div class="res-modal-field-value mono-value" style="font-size:12px">${m.curp ? esc(m.curp) : '—'}</div>
            </div>
            <div class="res-modal-field">
              <div class="res-modal-field-label">Destino / Casa</div>
              <div class="res-modal-field-value">${esc(m.casa_destino || '—')}</div>
            </div>
            <div class="res-modal-field">
              <div class="res-modal-field-label">${esPendiente ? 'Solicitado el' : 'Miembro desde'}</div>
              <div class="res-modal-field-value">${m.created_at ? fmtDateShort(m.created_at) : '—'}</div>
            </div>
          </div>

          ${m.foto_ine_url ? `
            <div style="font-size:11px;font-weight:700;color:var(--text-2);text-transform:uppercase;letter-spacing:0.08em;margin-bottom:8px">
              Documento de Identidad (INE)
            </div>
            <div>
              <div class="evidencia-card" tabindex="0" role="button" style="display:block;width:100%;max-width:280px" data-foto="${esc(m.foto_ine_url)}" data-foto-label="INE de ${esc(nombreCompleto)}">
                <img src="${esc(m.foto_ine_url)}" alt="Documento INE" style="display:block;width:100%;height:160px;object-fit:cover">
              </div>
            </div>
          ` : ''}
        </div>

        <div>
          <div style="font-size:11px;font-weight:700;color:var(--text-2);text-transform:uppercase;letter-spacing:0.08em;margin-bottom:10px">
            Métodos de acceso e identidad
          </div>

          <div style="display:flex;flex-direction:column;gap:8px">
            <div style="display:flex;align-items:center;justify-content:space-between;padding:10px 14px;background:var(--surface-2);border-radius:8px;border:1px solid var(--border)">
              <div style="display:flex;align-items:center;gap:10px;min-width:0">
                <span style="font-size:18px">👤</span>
                <div>
                  <div style="font-size:13.5px;font-weight:600;color:var(--text)">Reconocimiento Facial IA</div>
                  <div style="font-size:11.5px;color:var(--text-3)">Validación biométrica instantánea en kioskos</div>
                </div>
              </div>
              <span class="badge ${tieneRostro ? 'badge--aprobado' : 'badge--rechazado'}">
                ${tieneRostro ? 'Enrolado' : 'Sin rostro'}
              </span>
            </div>

            <div style="display:flex;align-items:center;justify-content:space-between;padding:10px 14px;background:var(--surface-2);border-radius:8px;border:1px solid var(--border)">
              <div style="display:flex;align-items:center;gap:10px;min-width:0">
                <span style="font-size:18px">🔢</span>
                <div>
                  <div style="font-size:13.5px;font-weight:600;color:var(--text)">PIN de acceso</div>
                  <div style="font-size:11.5px;color:var(--text-3)">Código numérico para teclado en caseta</div>
                </div>
              </div>
              <span class="badge ${tienePin ? 'badge--aprobado' : 'badge--rechazado'}">
                ${tienePin ? 'Configurado' : 'Sin PIN'}
              </span>
            </div>

            <div style="display:flex;align-items:center;justify-content:space-between;padding:10px 14px;background:var(--surface-2);border-radius:8px;border:1px solid var(--border)">
              <div style="display:flex;align-items:center;gap:10px;min-width:0">
                <span style="font-size:18px">📱</span>
                <div>
                  <div style="font-size:13.5px;font-weight:600;color:var(--text)">App Kigo (QR Dinámico)</div>
                  <div style="font-size:11.5px;color:var(--text-3)">Acceso con escáner de código QR móvil</div>
                </div>
              </div>
              <span class="badge ${esPendiente ? 'badge--pendiente' : 'badge--aprobado'}">
                ${esPendiente ? 'Pendiente aprobación' : 'Activo'}
              </span>
            </div>
          </div>
        </div>
      </div>

      <div class="modal-actions" style="justify-content:space-between;display:flex;gap:10px;align-items:center;flex-wrap:wrap">
        ${esPendiente ? `
          <div style="display:flex;gap:8px">
            <button type="button" class="btn-primary" id="res-modal-aprobar-btn" style="padding:8px 16px;font-weight:600">Aprobar solicitud</button>
            <button type="button" class="btn-ghost" id="res-modal-rechazar-btn" style="color:var(--danger,#e55);padding:8px 12px">Rechazar</button>
          </div>
        ` : `
          <button type="button" class="btn-cancel" id="res-modal-ver-visitas">
            <svg width="14" height="14" viewBox="0 0 18 18" fill="none" stroke="currentColor" stroke-width="1.8" style="vertical-align:middle;margin-right:4px"><circle cx="4" cy="4.5" r="1.7"/><line x1="8" y1="4.5" x2="16" y2="4.5"/><circle cx="4" cy="9" r="1.7"/><line x1="8" y1="9" x2="16" y2="9"/><circle cx="4" cy="13.5" r="1.7"/><line x1="8" y1="13.5" x2="16" y2="13.5"/></svg>
            Ver entradas de este residente
          </button>
        `}
        <button type="button" class="btn-cancel" id="res-modal-cerrar-btn">Cerrar</button>
      </div>
    `;

    document.getElementById('res-modal-aprobar-btn')?.addEventListener('click', async () => {
      const res = await api(`/membresias/${m.id}/aprobar`, { method: 'POST' });
      if (res && res.ok) {
        modal.hidden = true;
        mostrarToast('Solicitud aprobada', 'ok');
        await loadResidentesPendientes();
        loadResidentesPendientesBadge();
        loadResidentesActivos();
      } else {
        mostrarToast('Error al aprobar', 'err');
      }
    });

    document.getElementById('res-modal-rechazar-btn')?.addEventListener('click', async () => {
      if (!confirm('¿Rechazar esta solicitud?')) return;
      const res = await api(`/membresias/${m.id}/rechazar`, { method: 'POST' });
      if (res && res.ok) {
        modal.hidden = true;
        mostrarToast('Solicitud rechazada', 'ok');
        await loadResidentesPendientes();
        loadResidentesPendientesBadge();
      } else {
        mostrarToast('Error al rechazar', 'err');
      }
    });

    document.getElementById('res-modal-ver-visitas')?.addEventListener('click', () => {
      modal.hidden = true;
      const fQ = document.getElementById('vis-quick-search');
      if (fQ) fQ.value = m.nombre || '';
      const fTipo = document.getElementById('vis-filter-tipo');
      if (fTipo) fTipo.value = 'RESIDENTE';
      const fFecha = document.getElementById('vis-filter-fecha');
      if (fFecha) fFecha.value = '';
      const fEstado = document.getElementById('vis-filter-estado');
      if (fEstado) fEstado.value = '';
      navTo('visitas');
    });

    document.getElementById('res-modal-cerrar-btn')?.addEventListener('click', () => {
      modal.hidden = true;
    });

    modal.hidden = false;
  }

  document.getElementById('res-modal-close')?.addEventListener('click', () => {
    const m = document.getElementById('modal-residente-detalle');
    if (m) m.hidden = true;
  });

  document.getElementById('modal-residente-detalle')?.addEventListener('click', e => {
    if (e.target.id === 'modal-residente-detalle') {
      e.target.hidden = true;
    }
  });

  async function loadResidentesPendientesBadge() {
    try {
      const resMem = await api('/membresias/pendientes');
      let n = 0;
      if (resMem && resMem.ok) {
        const d = await resMem.json();
        n = (Array.isArray(d) ? d : (d.membresias || [])).length;
      }
      const text = n > 99 ? '99+' : String(n);
      const isHidden = (n <= 0);

      const badge = document.getElementById('tab-badge-res-sol');
      if (badge) { badge.textContent = text; badge.hidden = isHidden; }
      const badgeMob = document.getElementById('tab-badge-res-sol-mob');
      if (badgeMob) { badgeMob.textContent = text; badgeMob.hidden = isHidden; }
      const badgeTab = document.getElementById('tab-badge-res-sol-tab');
      if (badgeTab) { badgeTab.textContent = text; badgeTab.hidden = isHidden; }
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

    let resMembresias = null;
    try {
      resMembresias = await api('/membresias/pendientes');
    } catch (e) {
      console.error('Error fetching pendientes:', e);
    }
    if (loadEl) loadEl.hidden = true;

    let membresias = [];
    if (resMembresias && resMembresias.ok) {
      try {
        const d = await resMembresias.json();
        membresias = Array.isArray(d) ? d : (d.membresias || []);
      } catch (e) { console.error(e); }
    }

    residentesPendientesCache = membresias;
    loadResidentesPendientesBadge();

    if (!membresias.length) {
      if (emptyEl) emptyEl.hidden = false;
      return;
    }
    if (emptyEl) emptyEl.hidden = true;

    rowsEl.innerHTML = membresias.map(m => {
      const nombreCompleto = `${m.nombre || ''} ${m.apellido_paterno || ''} ${m.apellido_materno || ''}`.trim() || 'Sin nombre';
      const inicial = (m.nombre || 'R')[0].toUpperCase();
      const avatarHtml = m.foto_cara_url
        ? `<div class="res-avatar"><img src="${esc(m.foto_cara_url)}" alt="${esc(nombreCompleto)}" onerror="this.parentElement.innerHTML='${inicial}'"></div>`
        : `<div class="res-avatar">${inicial}</div>`;

      const contacto = m.telefono ? `${esc(m.telefono)}` : (m.curp ? `CURP: ${esc(m.curp)}` : 'Solicitud pendiente');
      const fechaSolicitud = m.created_at ? fmtDateShort(m.created_at) : '—';

      return `
        <div class="res-row" data-res-pending-id="${m.id}" style="cursor:pointer">
          ${avatarHtml}
          <div class="res-info-main">
            <div class="res-name">${esc(nombreCompleto)}</div>
            <div class="res-sub">${contacto} · App Kigo</div>
          </div>
          <div class="res-dest-col">
            <span class="badge badge--pendiente" style="font-size:12px;padding:4px 10px;font-weight:600">
               ${esc(m.casa_destino || 'Sin casa')}
            </span>
          </div>
          <div class="res-date-col">
            <div style="font-size:10.5px;color:var(--text-3);text-transform:uppercase;letter-spacing:0.04em">Solicitado</div>
            <div style="font-size:12.5px;color:var(--text-2);font-weight:500">${fechaSolicitud}</div>
          </div>
          <div class="res-action-col" style="display:flex;gap:8px;align-items:center">
            <button type="button" class="btn-primary" data-aprobar-mem="${m.id}" style="padding:6px 12px;font-size:12px;font-weight:600">Aprobar</button>
            <button type="button" class="btn-ghost" data-rechazar-mem="${m.id}" style="color:var(--danger,#e55);padding:6px 10px;font-size:12px">Rechazar</button>
            <button type="button" class="btn-cancel" data-ver-mem="${m.id}" style="padding:6px 10px;font-size:12px;border-radius:8px;font-weight:600;display:inline-flex;align-items:center;gap:4px">
              Ver
              <svg width="12" height="12" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="2"><path d="M6 3l5 5-5 5"/></svg>
            </button>
          </div>
        </div>`;
    }).join('');

    rowsEl.querySelectorAll('[data-res-pending-id]').forEach(el => {
      el.addEventListener('click', () => {
        const id = Number(el.dataset.resPendingId);
        const m = residentesPendientesCache.find(x => x.id === id);
        if (m) showResidenteModal(m);
      });
    });

    rowsEl.querySelectorAll('[data-ver-mem]').forEach(btn => {
      btn.addEventListener('click', (e) => {
        e.stopPropagation();
        const id = Number(btn.dataset.verMem);
        const m = residentesPendientesCache.find(x => x.id === id);
        if (m) showResidenteModal(m);
      });
    });

    rowsEl.querySelectorAll('[data-aprobar-mem]').forEach(btn => {
      btn.addEventListener('click', async (e) => {
        e.stopPropagation();
        const id = btn.dataset.aprobarMem;
        const res = await api(`/membresias/${id}/aprobar`, { method: 'POST' });
        if (res && res.ok) {
          mostrarToast('Solicitud aprobada', 'ok');
          await loadResidentesPendientes();
          loadResidentesPendientesBadge();
          loadResidentesActivos();
        } else {
          mostrarToast('Error al aprobar', 'err');
        }
      });
    });

    rowsEl.querySelectorAll('[data-rechazar-mem]').forEach(btn => {
      btn.addEventListener('click', async (e) => {
        e.stopPropagation();
        const id = btn.dataset.rechazarMem;
        if (!confirm('¿Rechazar esta solicitud?')) return;
        const res = await api(`/membresias/${id}/rechazar`, { method: 'POST' });
        if (res && res.ok) {
          mostrarToast('Solicitud rechazada', 'ok');
          await loadResidentesPendientes();
          loadResidentesPendientesBadge();
        } else {
          mostrarToast('Error al rechazar', 'err');
        }
      });
    });
  }


  /* ─── Init ───────────────────────────────── */
  function init() {
    const token = getToken();
    if (!token) {
      const hash = window.location.hash.replace(/^#auth-/, "").replace(/^#/, "");
      showLogin();
      if (["register", "forgot"].includes(hash)) {
        switchAuthView(hash, false);
      }
      applyI18n();
      return;
    }

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
