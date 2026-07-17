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
      nav_general: "General",
      nav_dashboard: "Inicio",
      nav_visitas: "Visitas",
      nav_historial: "Buscar CURP",
      nav_config: "Configuración",
      nav_accesos: "Accesos",
      nav_perfil: "Perfil",
      role_admin: "Administrador",
      loading: "Cargando…",
      dash_sub: "Resumen de tu comunidad",
      stat_today: "Visitas de hoy",
      stat_today_hint: "En la última página cargada",
      stat_week: "Últimos 7 días",
      stat_week_hint: "Sobre la última página cargada",
      stat_total: "Total registros",
      stat_total_hint: "Visitantes en bitácora",
      stat_accesos: "Accesos activos",
      stat_accesos_hint: "Entradas configuradas",
      q_curp_title: "Buscar por CURP",
      q_curp_sub: "¿Esta persona ya vino antes?",
      q_visitas_title: "Ver visitas",
      q_visitas_sub: "Bitácora completa y paginada",
      recent_title: "Visitas recientes",
      see_all: "Ver todas ›",
      vis_sub: "Bitácora de registros",
      all_docs: "Todos los documentos",
      pasaporte: "Pasaporte",
      licencia: "Licencia",
      all_states: "Todos los estados",
      pendiente: "Pendiente",
      aprobado: "Aprobado",
      rechazado: "Rechazado",
      search_curp_btn: "Buscar CURP →",
      col_visitor: "VISITANTE",
      col_doc: "DOCUMENTO",
      col_access: "ACCESO",
      col_estado: "ESTADO",
      col_date: "FECHA",
      vis_empty_title: "Sin visitantes registrados",
      vis_empty_text: "Cuando alguien se registre en una de tus entradas, aparecerá aquí automáticamente.",
      load_err_title: "Error al cargar",
      load_err_text: "Revisa tu conexión e inténtalo de nuevo.",
      retry: "Reintentar",
      prev: "‹ Anterior",
      next: "Siguiente ›",
      detail_title: "Detalle de visita",
      hist_sub: "¿Esta persona ya vino? Consulta su historial de visitas.",
      curp_label: "CURP del visitante",
      search_btn: "Buscar",
      curp_hint: "18 caracteres exactos.",
      hist_idle_title: "Consulta el historial de una persona",
      hist_idle_text: "Ingresa una CURP para ver cuántas veces ha ingresado y por qué accesos.",
      searching: "Buscando visitas…",
      hist_empty_title: "Sin visitas con esa CURP",
      hist_empty_text: "Puede ser su primera vez. Verifica que la CURP esté escrita correctamente.",
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
      motivo: "Motivo de visita",
      casa_destino: "Casa / Destino",
      placa: "Placa",
      no_placa: "Sin placa",
      visits: n => `${n} visita${n !== 1 ? "s" : ""} registrada${n !== 1 ? "s" : ""}`,
      hello: name => `Hola, ${name}`,
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
      nav_general: "General",
      nav_dashboard: "Home",
      nav_visitas: "Visits",
      nav_historial: "Search CURP",
      nav_config: "Settings",
      nav_accesos: "Entries",
      nav_perfil: "Profile",
      role_admin: "Administrator",
      loading: "Loading…",
      dash_sub: "Community summary",
      stat_today: "Today's visits",
      stat_today_hint: "From last loaded page",
      stat_week: "Last 7 days",
      stat_week_hint: "From last loaded page",
      stat_total: "Total records",
      stat_total_hint: "Visitors in log",
      stat_accesos: "Active entries",
      stat_accesos_hint: "Configured entry points",
      q_curp_title: "Search by CURP",
      q_curp_sub: "Has this person visited before?",
      q_visitas_title: "View visits",
      q_visitas_sub: "Complete paginated log",
      recent_title: "Recent visits",
      see_all: "See all ›",
      vis_sub: "Visit log",
      all_docs: "All documents",
      pasaporte: "Passport",
      licencia: "Driver's license",
      all_states: "All statuses",
      pendiente: "Pending",
      aprobado: "Approved",
      rechazado: "Rejected",
      search_curp_btn: "Search CURP →",
      col_visitor: "VISITOR",
      col_doc: "DOCUMENT",
      col_access: "ENTRY",
      col_estado: "STATUS",
      col_date: "DATE",
      vis_empty_title: "No visitors registered",
      vis_empty_text: "Once someone registers at one of your entries, they'll appear here.",
      load_err_title: "Failed to load",
      load_err_text: "Check your connection and try again.",
      retry: "Try again",
      prev: "‹ Previous",
      next: "Next ›",
      detail_title: "Visit detail",
      hist_sub: "Has this person visited? Check their visit history.",
      curp_label: "Visitor's CURP",
      search_btn: "Search",
      curp_hint: "Exactly 18 characters.",
      hist_idle_title: "Look up a person's history",
      hist_idle_text: "Enter a CURP to see how many times they've entered and through which entries.",
      searching: "Searching visits…",
      hist_empty_title: "No visits found for this CURP",
      hist_empty_text: "This might be their first time. Verify the CURP is correct.",
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
      motivo: "Reason for visit",
      casa_destino: "House / Destination",
      placa: "License plate",
      no_placa: "No plate",
      visits: n => `${n} visit${n !== 1 ? "s" : ""} recorded`,
      hello: name => `Hello, ${name}`,
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
    setTheme(dark ? "dark" : "light");
  }

  function setTheme(theme) {
    document.documentElement.dataset.theme = theme;
    localStorage.setItem("autonomia_theme", theme);
    document.getElementById("icon-theme-dark").hidden = theme === "dark";
    document.getElementById("icon-theme-light").hidden = theme === "light";
    document.getElementById("label-theme").textContent = theme === "dark" ? t("light_mode") : t("dark_mode");
  }

  document.getElementById("btn-theme").addEventListener("click", () => {
    const current = document.documentElement.dataset.theme;
    setTheme(current === "dark" ? "light" : "dark");
  });

  document.getElementById("btn-lang").addEventListener("click", () => {
    lang = lang === "es" ? "en" : "es";
    localStorage.setItem("autonomia_lang", lang);
    applyI18n();
  });

  initTheme();

  /* ─── State ─────────────────────────────── */
  const MESES_ES = ["ene","feb","mar","abr","may","jun","jul","ago","sep","oct","nov","dic"];
  const MESES_EN = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];

  const TIPO_BADGE = { INE: "badge--ine", PASAPORTE: "badge--pasaporte", LICENCIA: "badge--licencia" };
  const ESTADO_BADGE = { PENDIENTE: "badge--pendiente", APROBADO: "badge--aprobado", RECHAZADO: "badge--rechazado" };

  const state = {
    adminId: null,
    admin: null,
    accesosById: new Map(),
    visPage: 1,
    visPageSize: 20,
    visTotal: 0,
    editingAccesoId: null,
    deletingAccesoId: null,
    visSearchTimeout: null,
  };

  /* ─── Auth helpers ──────────────────────── */
  function getToken()       { return localStorage.getItem(TOKEN_KEY); }
  function setToken(t)      { localStorage.setItem(TOKEN_KEY, t); }
  function clearToken()     { localStorage.removeItem(TOKEN_KEY); }

  function decodeJWT(token) {
    try {
      const p = token.split(".")[1];
      return JSON.parse(atob(p.replace(/-/g, "+").replace(/_/g, "/")));
    } catch { return null; }
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

  /* ─── Navegación ────────────────────────── */
  function showLogin() {
    document.getElementById("screen-login").hidden = false;
    document.getElementById("app-shell").hidden = true;
    clearToken();
  }

  function showApp() {
    document.getElementById("screen-login").hidden = true;
    document.getElementById("app-shell").hidden = false;
    applyI18n();
  }

  function navTo(screen) {
    document.querySelectorAll(".screen").forEach(s => s.classList.remove("active"));
    document.querySelectorAll(".nav-btn").forEach(b => b.classList.remove("active"));

    const screenEl = document.getElementById(`screen-${screen}`);
    if (screenEl) { screenEl.hidden = false; screenEl.classList.add("active"); }

    document.querySelectorAll(`[data-nav="${screen}"]`).forEach(b => b.classList.add("active"));

    if (screen === "dashboard") loadDashboard();
    if (screen === "visitas")   loadVisitas(1);
    if (screen === "accesos")   loadAccesos();
    if (screen === "perfil")    loadPerfil();
  }

  document.addEventListener("click", e => {
    const nav = e.target.closest("[data-nav]");
    if (nav) navTo(nav.dataset.nav);
  });

  /* ─── Login ─────────────────────────────── */
  let loginMode = "login";

  document.getElementById("login-toggle-mode").addEventListener("click", () => {
    loginMode = loginMode === "login" ? "register" : "login";
    const isReg = loginMode === "register";
    document.getElementById("login-submit").textContent = isReg ? (lang === "en" ? "Create account" : "Crear cuenta") : t("login_btn");
  });

  document.getElementById("login-form").addEventListener("submit", async e => {
    e.preventDefault();
    const correo   = document.getElementById("login-correo").value;
    const password = document.getElementById("login-password").value;
    const errEl    = document.getElementById("login-error");
    const btn      = document.getElementById("login-submit");

    btn.disabled = true;
    errEl.hidden = true;

    const endpoint = loginMode === "register" ? "/auth/sign-in" : "/auth/login";
    const method   = "POST";

    try {
      const res = await fetch(API_BASE + endpoint, {
        method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ correo, password }),
      });

      const data = await res.json();
      if (!res.ok) { errEl.textContent = data.error || "Error"; errEl.hidden = false; return; }

      setToken(data.access_token);
      const claims = decodeJWT(data.access_token);
      state.adminId = claims?.admin_id;
      await bootstrapApp();
    } catch { errEl.textContent = "Error de conexión"; errEl.hidden = false; }
    finally  { btn.disabled = false; }
  });

  /* ─── Google Login ──────────────────────── */
  document.getElementById("btn-google-login").addEventListener("click", () => {
    if (typeof google === "undefined" || !google.accounts) {
      alert("Google Identity Services no disponible. Verifica la conexión.");
      return;
    }
    google.accounts.id.initialize({
      client_id: window.__GOOGLE_CLIENT_ID__ || "",
      callback: async ({ credential }) => {
        const errEl = document.getElementById("login-error");
        try {
          const res = await fetch(API_BASE + "/auth/google", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ credential }),
          });
          const data = await res.json();
          if (!res.ok) { errEl.textContent = data.error || "Google login fallido"; errEl.hidden = false; return; }
          setToken(data.access_token);
          const claims = decodeJWT(data.access_token);
          state.adminId = claims?.admin_id;
          await bootstrapApp();
        } catch { errEl.textContent = "Error de conexión"; errEl.hidden = false; }
      },
    });
    google.accounts.id.prompt();
  });

  /* ─── Bootstrap ─────────────────────────── */
  async function bootstrapApp() {
    if (!state.adminId) return;
    await loadAdminData();
    showApp();
    navTo("dashboard");
  }

  async function loadAdminData() {
    const res = await api(`/admins/${state.adminId}`);
    if (!res || !res.ok) return;
    state.admin = await res.json();

    const nombre = [state.admin.nombre, state.admin.apellido_paterno].filter(Boolean).join(" ") || state.admin.correo;
    const initials = (state.admin.nombre?.[0] || "") + (state.admin.apellido_paterno?.[0] || "");

    document.getElementById("sidebar-user-name").textContent = nombre;
    document.getElementById("sidebar-avatar").textContent = initials || "·";
    document.getElementById("perfil-avatar").textContent = initials || "·";
    document.getElementById("perfil-nombre-completo").textContent = nombre;
    document.getElementById("dash-greeting").textContent = STRINGS[lang].hello(state.admin.nombre || nombre);
  }

  /* ─── Logout ─────────────────────────────── */
  document.getElementById("btn-logout").addEventListener("click", () => {
    clearToken();
    state.adminId = null;
    state.admin = null;
    showLogin();
  });

  /* ─── Dashboard ─────────────────────────── */
  async function loadDashboard() {
    const res = await api("/visitas/?page_size=50");
    if (!res || !res.ok) return;
    const data = await res.json();

    const visitas = data.visitas || [];
    const total   = data.total  || 0;

    const hoy = new Date();
    hoy.setHours(0, 0, 0, 0);
    const sieteDias = new Date(hoy); sieteDias.setDate(sieteDias.getDate() - 7);

    const hoyCount    = visitas.filter(v => new Date(v.created_at) >= hoy).length;
    const semanaCount = visitas.filter(v => new Date(v.created_at) >= sieteDias).length;

    animateStat("stat-hoy",    hoyCount);
    animateStat("stat-semana", semanaCount);
    animateStat("stat-total",  total);

    const accRes = await api("/accesos/");
    if (accRes && accRes.ok) {
      const accData = await accRes.json();
      const list = Array.isArray(accData) ? accData : (accData.accesos || []);
      animateStat("stat-accesos", list.length);
      list.forEach(a => state.accesosById.set(a.id, a));
    }

    const container = document.getElementById("dash-recent-rows");
    const recent = visitas.slice(0, 8);
    if (recent.length === 0) {
      container.innerHTML = `<div class="empty-state"><div class="empty-icon"><svg width="22" height="22" viewBox="0 0 18 18" fill="none" stroke="currentColor" stroke-width="1.6"><circle cx="4" cy="4.5" r="1.7"/><line x1="8" y1="4.5" x2="16" y2="4.5"/><circle cx="4" cy="9" r="1.7"/><line x1="8" y1="9" x2="16" y2="9"/><circle cx="4" cy="13.5" r="1.7"/><line x1="8" y1="13.5" x2="16" y2="13.5"/></svg></div><div class="empty-title" data-i18n="vis_empty_title">${t("vis_empty_title")}</div></div>`;
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
    const acceso = state.accesosById.get(v.acceso_id);
    return `<div class="row-item" style="grid-template-columns:2fr 1fr 80px;animation-delay:${i*40}ms" data-id="${v.id}">
      <div>
        <div class="row-name">${esc(v.nombre)}</div>
        <div class="row-sub">${esc(v.casa_destino || "")}</div>
      </div>
      <div class="row-date">${fmtDateShort(v.created_at)}</div>
      <div><span class="badge ${ESTADO_BADGE[v.estado] || ""}">${estadoLabel(v.estado)}</span></div>
    </div>`;
  }

  function estadoLabel(e) {
    const map = { PENDIENTE: t("pendiente"), APROBADO: t("aprobado"), RECHAZADO: t("rechazado") };
    return map[e] || e;
  }

  /* ─── Visitas ────────────────────────────── */
  async function loadVisitas(page) {
    state.visPage = page;
    const tipo   = document.getElementById("vis-filter-tipo").value;
    const estado = document.getElementById("vis-filter-estado").value;
    const q      = document.getElementById("vis-quick-search").value.trim();

    let params = `?page=${page}&page_size=${state.visPageSize}`;
    if (tipo)   params += `&tipo_documento=${tipo}`;
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
    const label = document.getElementById("vis-page-label");
    const cur = document.getElementById("vis-page-current");
    if (totalPages > 1) {
      pag.hidden = false;
      label.textContent = `${state.visTotal} ${lang === "en" ? "records" : "registros"}`;
      cur.textContent = page;
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
    const acceso = state.accesosById.get(v.acceso_id);
    return `<div class="row-item vis-row-grid--list" style="animation-delay:${i*30}ms" data-id="${v.id}">
      <div><div class="row-name">${esc(v.nombre)}</div><div class="row-sub">${esc(v.casa_destino || "")}</div></div>
      <div><span class="badge ${TIPO_BADGE[v.tipo_documento] || ""}">${v.tipo_documento}</span></div>
      <div class="row-sub">${acceso ? esc(acceso.nombre) : `#${v.acceso_id}`}</div>
      <div><span class="badge ${ESTADO_BADGE[v.estado] || ""}">${estadoLabel(v.estado)}</span></div>
      <div class="row-date">${fmtDateShort(v.created_at)}</div>
    </div>`;
  }

  document.getElementById("vis-prev").addEventListener("click", () => loadVisitas(state.visPage - 1));
  document.getElementById("vis-next").addEventListener("click", () => loadVisitas(state.visPage + 1));
  document.getElementById("vis-retry").addEventListener("click", () => loadVisitas(state.visPage));

  ["vis-quick-search","vis-filter-tipo","vis-filter-estado"].forEach(id => {
    document.getElementById(id)?.addEventListener("input", () => {
      clearTimeout(state.visSearchTimeout);
      state.visSearchTimeout = setTimeout(() => loadVisitas(1), 350);
    });
  });

  /* ─── Detalle ───────────────────────────── */
  async function loadDetalle(id) {
    navTo("detalle");
    const body = document.getElementById("detalle-body");
    body.innerHTML = `<div class="loading-state"><div class="spinner"></div></div>`;

    const res = await api(`/visitas/${id}`);
    if (!res || !res.ok) { body.innerHTML = `<div class="empty-state"><div class="empty-title">${t("load_err_title")}</div></div>`; return; }
    const v = await res.json();

    const acceso = state.accesosById.get(v.acceso_id);
    body.innerHTML = `
      <div class="detalle-hero">
        <div class="detalle-fotos">
          <img class="detalle-foto" src="${esc(v.foto_documento_url)}" alt="Documento" loading="lazy">
          <img class="detalle-foto" src="${esc(v.foto_rostro_url)}" alt="Rostro" loading="lazy">
        </div>
        <div class="detalle-info">
          <div style="display:flex;gap:8px;align-items:center;margin-bottom:8px">
            <span class="badge ${TIPO_BADGE[v.tipo_documento] || ""}">${v.tipo_documento}</span>
            <span class="badge ${ESTADO_BADGE[v.estado] || ""}">${estadoLabel(v.estado)}</span>
          </div>
          <div class="detalle-nombre">${esc(v.nombre)}</div>
          <div class="row-sub" style="margin-top:4px">${acceso ? esc(acceso.nombre) : `Acceso #${v.acceso_id}`} · ${fmtDate(v.created_at)}</div>
          <div class="detalle-campos">
            <div><div class="campo-label">CURP</div><div class="campo-value campo-mono">${esc(v.curp)}</div></div>
            <div><div class="campo-label">${t("motivo")}</div><div class="campo-value">${esc(v.motivo_visita || "—")}</div></div>
            <div><div class="campo-label">${t("casa_destino")}</div><div class="campo-value">${esc(v.casa_destino || "—")}</div></div>
            <div><div class="campo-label">${t("placa")}</div><div class="campo-value">${v.placa ? esc(v.placa) : t("no_placa")}</div></div>
            <div><div class="campo-label">Clave lector</div><div class="campo-value campo-mono">${esc(v.clave_lector)}</div></div>
          </div>
        </div>
      </div>`;
  }

  /* ─── Historial ─────────────────────────── */
  document.getElementById("curp-input").addEventListener("input", e => {
    const v = e.target.value.toUpperCase().replace(/[^A-Z0-9]/g, "").slice(0, 18);
    e.target.value = v;
    const hint = document.getElementById("curp-hint");
    hint.textContent = v.length === 18 ? "✓" : `${v.length}/18`;
  });

  document.getElementById("curp-search-btn").addEventListener("click", buscarHistorial);
  document.getElementById("curp-input").addEventListener("keydown", e => { if (e.key === "Enter") buscarHistorial(); });

  async function buscarHistorial() {
    const curp = document.getElementById("curp-input").value.trim();
    if (curp.length !== 18) return;

    showHistState("loading");
    const res = await api(`/visitas/buscar?curp=${encodeURIComponent(curp)}`);
    if (!res || !res.ok) { showHistState("idle"); return; }

    const data = await res.json();
    const visitas = data.visitas || [];

    if (visitas.length === 0) { showHistState("empty"); return; }

    document.getElementById("hist-total").textContent = visitas.length;
    document.getElementById("hist-title-text").textContent = STRINGS[lang].visits(visitas.length);
    document.getElementById("hist-curp-label").textContent = curp;

    document.getElementById("hist-rows").innerHTML = visitas.map((v, i) => renderHistRow(v, i)).join("");
    showHistState("results");
  }

  function showHistState(s) {
    ["idle","loading","results","empty"].forEach(x => {
      const el = document.getElementById(`hist-${x}`);
      if (el) el.hidden = x !== s;
    });
  }

  function renderHistRow(v, i) {
    const acceso = state.accesosById.get(v.acceso_id);
    return `<div class="row-item vis-row-grid" style="animation-delay:${i*30}ms" data-id="${v.id}">
      <div><div class="row-name">${esc(v.nombre)}</div></div>
      <div><span class="badge ${TIPO_BADGE[v.tipo_documento] || ""}">${v.tipo_documento}</span></div>
      <div class="campo-mono" style="font-size:12px">${esc(v.curp)}</div>
      <div class="row-sub">${acceso ? esc(acceso.nombre) : `#${v.acceso_id}`}</div>
      <div><span class="badge ${ESTADO_BADGE[v.estado] || ""}">${estadoLabel(v.estado)}</span></div>
      <div class="row-date">${fmtDateShort(v.created_at)}</div>
    </div>`;
  }

  /* ─── Accesos ────────────────────────────── */
  async function loadAccesos() {
    const res = await api("/accesos/");
    const container = document.getElementById("accesos-list");
    if (!res || !res.ok) { container.innerHTML = `<div class="empty-title">${t("load_err_title")}</div>`; return; }

    const data = await res.json();
    const list = Array.isArray(data) ? data : (data.accesos || []);
    list.forEach(a => state.accesosById.set(a.id, a));

    if (list.length === 0) {
      container.innerHTML = `<div class="empty-state"><div class="empty-title">${t("new_acceso")}</div></div>`;
      return;
    }

    container.innerHTML = list.map(a => `
      <div class="acceso-card">
        <div class="acceso-info">
          <div class="acceso-nombre">${esc(a.nombre)}</div>
          ${a.ubicacion ? `<div class="acceso-ubi">${esc(a.ubicacion)}</div>` : ""}
          <div class="acceso-id">ID ${a.id}</div>
        </div>
        <div class="acceso-actions">
          <button class="btn-ghost" data-edit-acceso="${a.id}">
            <svg width="14" height="14" viewBox="0 0 18 18" fill="none" stroke="currentColor" stroke-width="1.7"><path d="M12 3l3 3-9 9H3v-3z"/></svg>
          </button>
          <button class="btn-ghost" data-del-acceso="${a.id}" style="color:var(--red)">
            <svg width="14" height="14" viewBox="0 0 18 18" fill="none" stroke="currentColor" stroke-width="1.7"><line x1="4" y1="5" x2="14" y2="5"/><path d="M6 5V3.5h6V5"/><path d="M5 5l.7 9a1 1 0 0 0 1 .9h4.6a1 1 0 0 0 1-.9L13 5"/></svg>
          </button>
        </div>
      </div>`).join("");

    container.querySelectorAll("[data-edit-acceso]").forEach(btn => {
      btn.addEventListener("click", () => openAccesoModal(parseInt(btn.dataset.editAcceso)));
    });
    container.querySelectorAll("[data-del-acceso]").forEach(btn => {
      btn.addEventListener("click", () => openDeleteModal(parseInt(btn.dataset.delAcceso)));
    });
  }

  /* modal acceso */
  document.getElementById("btn-nuevo-acceso").addEventListener("click", () => openAccesoModal(null));

  function openAccesoModal(accesoId) {
    state.editingAccesoId = accesoId;
    const titleEl = document.getElementById("modal-acceso-title");
    const hintEl  = document.getElementById("acceso-clave-hint");
    const formView = document.getElementById("acceso-form-view");
    const revView  = document.getElementById("acceso-reveal-view");
    formView.hidden = false;
    revView.hidden  = true;

    if (accesoId) {
      const a = state.accesosById.get(accesoId);
      titleEl.textContent = lang === "en" ? "Edit entry" : "Editar acceso";
      document.getElementById("acceso-nombre").value    = a?.nombre    || "";
      document.getElementById("acceso-ubicacion").value = a?.ubicacion || "";
      hintEl.hidden = true;
    } else {
      titleEl.textContent = t("modal_new_acceso");
      document.getElementById("acceso-nombre").value    = "";
      document.getElementById("acceso-ubicacion").value = "";
      hintEl.hidden = false;
    }
    document.getElementById("acceso-form-error").hidden = true;
    document.getElementById("modal-acceso").hidden = false;
  }

  document.getElementById("acceso-cancel").addEventListener("click", () => { document.getElementById("modal-acceso").hidden = true; });

  document.getElementById("acceso-form").addEventListener("submit", async e => {
    e.preventDefault();
    const nombre    = document.getElementById("acceso-nombre").value;
    const ubicacion = document.getElementById("acceso-ubicacion").value;
    const errEl     = document.getElementById("acceso-form-error");

    const isNew = state.editingAccesoId === null;
    const endpoint = isNew ? "/accesos/" : `/accesos/${state.editingAccesoId}`;
    const method   = isNew ? "POST" : "PATCH";

    const res = await api(endpoint, { method, body: JSON.stringify({ nombre, ubicacion }) });
    if (!res) return;

    if (!res.ok) {
      const data = await res.json();
      errEl.textContent = data.error || "Error";
      errEl.hidden = false;
      return;
    }

    const created = await res.json();
    document.getElementById("modal-acceso").hidden = true;
    await loadAccesos();

    if (isNew) {
      document.getElementById("reveal-acceso-id").textContent = created.id;
      document.getElementById("reveal-clave").textContent     = created.clave_kiosko || "—";
      document.getElementById("acceso-form-view").hidden  = true;
      document.getElementById("acceso-reveal-view").hidden = false;
      document.getElementById("modal-acceso").hidden = false;
    }
  });

  document.getElementById("acceso-reveal-done").addEventListener("click", () => {
    document.getElementById("modal-acceso").hidden = true;
  });

  /* modal delete */
  function openDeleteModal(accesoId) {
    state.deletingAccesoId = accesoId;
    const a = state.accesosById.get(accesoId);
    document.getElementById("modal-delete-title").textContent = `¿${t("delete")} "${a?.nombre || `#${accesoId}`}"?`;
    document.getElementById("modal-delete").hidden = false;
  }

  document.getElementById("delete-cancel").addEventListener("click", () => {
    document.getElementById("modal-delete").hidden = true;
  });

  document.getElementById("delete-confirm").addEventListener("click", async () => {
    const res = await api(`/accesos/${state.deletingAccesoId}`, { method: "DELETE" });
    document.getElementById("modal-delete").hidden = true;
    if (res && res.ok) await loadAccesos();
  });

  /* cerrar modal con Escape */
  document.addEventListener("keydown", e => {
    if (e.key === "Escape") {
      document.querySelectorAll(".modal-overlay").forEach(m => m.hidden = true);
    }
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

  /* ─── Init ───────────────────────────────── */
  function init() {
    const token = getToken();
    if (!token) { showLogin(); applyI18n(); return; }

    const claims = decodeJWT(token);
    if (!claims || (claims.exp && claims.exp * 1000 < Date.now())) {
      clearToken(); showLogin(); applyI18n(); return;
    }

    state.adminId = claims.admin_id;
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
