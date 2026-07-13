/* AUTO-nomIA · Panel de administración
 * Vanilla JS, sin build step. Consume la API real en /api/v1 (ver internal/router/router.go).
 */
(() => {
  const API_BASE = "/api/v1";
  const TOKEN_KEY = "autonomia_admin_token";

  const MESES = [
    "ene",
    "feb",
    "mar",
    "abr",
    "may",
    "jun",
    "jul",
    "ago",
    "sep",
    "oct",
    "nov",
    "dic",
  ];

  const TIPO_COLOR = {
    INE: "#FB6514",
    PASAPORTE: "#2D6CDF",
    LICENCIA: "#0E9F6E",
  };
  const TIPO_LABEL = {
    INE: "INE",
    PASAPORTE: "Pasaporte",
    LICENCIA: "Licencia",
  };

  const state = {
    adminId: null,
    admin: null,
    accesosById: new Map(),
    visPage: 1,
    visPageSize: 20,
    visTotal: 0,
    editingAccesoId: null,
    deletingAccesoId: null,
  };

  // ---------- token / fetch helpers ----------

  function getToken() {
    return localStorage.getItem(TOKEN_KEY);
  }
  function setToken(t) {
    localStorage.setItem(TOKEN_KEY, t);
  }
  function clearToken() {
    localStorage.removeItem(TOKEN_KEY);
  }

  function decodeJWT(token) {
    try {
      const payload = token.split(".")[1];
      const json = atob(payload.replace(/-/g, "+").replace(/_/g, "/"));
      return JSON.parse(json);
    } catch {
      return null;
    }
  }

  async function api(path, opts = {}) {
    const headers = Object.assign(
      { "Content-Type": "application/json" },
      opts.headers || {},
    );
    const token = getToken();
    if (token) headers.Authorization = "Bearer " + token;

    const res = await fetch(
      API_BASE + path,
      Object.assign({}, opts, { headers }),
    );

    if (res.status === 401) {
      clearToken();
      showLogin("Tu sesión expiró. Inicia sesión de nuevo.");
      throw new Error("No autorizado");
    }

    let body = null;
    try {
      body = await res.json();
    } catch {
      /* sin cuerpo */
    }

    if (!res.ok) {
      throw new Error((body && body.error) || "Error " + res.status);
    }
    return body;
  }

  // ---------- formato ----------

  function initials(nombre) {
    return (nombre || "")
      .split(" ")
      .filter(Boolean)
      .slice(0, 2)
      .map((w) => w[0])
      .join("")
      .toUpperCase();
  }

  function formatFecha(iso) {
    if (!iso) return "—";
    const d = new Date(iso);
    if (isNaN(d.getTime())) return "—";
    const dia = String(d.getDate()).padStart(2, "0");
    const mes = MESES[d.getMonth()];
    const horas = String(d.getHours()).padStart(2, "0");
    const min = String(d.getMinutes()).padStart(2, "0");
    return `${dia} ${mes} ${d.getFullYear()} · ${horas}:${min}`;
  }

  function accesoInfo(accesoId) {
    return state.accesosById.get(accesoId) || { nombre: "—", ubicacion: "" };
  }

  // ---------- navegación ----------

  function showLogin(message) {
    document.getElementById("app-shell").hidden = true;
    document.getElementById("screen-login").hidden = false;
    const errEl = document.getElementById("login-error");
    if (message) {
      errEl.textContent = message;
      errEl.hidden = false;
    } else {
      errEl.hidden = true;
    }
  }

  function showApp() {
    document.getElementById("screen-login").hidden = true;
    document.getElementById("app-shell").hidden = false;
  }

  const SCREEN_LOADERS = {
    dashboard: loadDashboard,
    visitantes: () => loadVisitantes(1),
    historial: loadHistorialIdle,
    accesos: loadAccesos,
    perfil: loadPerfil,
  };

  function goTo(screen, extra) {
    document.querySelectorAll(".screen").forEach((el) => {
      el.hidden = true;
    });
    document.querySelectorAll(".nav-btn").forEach((el) => {
      el.classList.toggle(
        "active",
        el.dataset.nav === screen ||
          (screen === "detalle" && el.dataset.nav === "visitantes"),
      );
    });
    const target = document.getElementById("screen-" + screen);
    if (target) target.hidden = false;

    if (screen === "detalle" && extra) {
      loadDetalle(extra);
    } else if (SCREEN_LOADERS[screen]) {
      SCREEN_LOADERS[screen]();
    }
  }

  document.querySelectorAll("[data-nav]").forEach((el) => {
    el.addEventListener("click", () => goTo(el.dataset.nav));
  });

  // ---------- fila de visitante (equivalente a VisitanteRow.dc.html) ----------

  function visitanteRowEl(v, variant) {
    const tipoColor = TIPO_COLOR[v.tipo_documento] || "#9A958C";
    const tipoLabel = TIPO_LABEL[v.tipo_documento] || v.tipo_documento;
    const acc = accesoInfo(v.acceso_id);
    const fecha = formatFecha(v.created_at);

    const el = document.createElement("div");
    el.addEventListener("click", () => goTo("detalle", v.id));

    if (variant === "compact") {
      el.className = "vis-row-compact";
      el.innerHTML = `
        <div class="avatar">${initials(v.nombre)}</div>
        <div class="vis-row-compact-info">
          <div class="vis-person-name">${escapeHtml(v.nombre)}</div>
          <div class="vis-row-compact-sub">${escapeHtml(acc.nombre)} · ${fecha}</div>
        </div>
        <div class="vis-chevron">›</div>`;
      return el;
    }

    if (variant === "list") {
      // listado principal (ListarVisitantes): la API no manda curp ni clave_lector aqui a
      // proposito, solo se ven en el detalle (goTo("detalle", v.id) abajo)
      el.className = "vis-row vis-row-grid--list";
      el.innerHTML = `
        <div class="vis-person">
          <div class="avatar">${initials(v.nombre)}</div>
          <div class="vis-person-name">${escapeHtml(v.nombre)}</div>
        </div>
        <div><span class="tipo-badge"><span class="tipo-dot" style="background:${tipoColor}"></span>${tipoLabel}</span></div>
        <div class="vis-acceso"><span class="vis-acceso-dot"></span><span class="vis-acceso-name">${escapeHtml(acc.nombre)}</span></div>
        <div class="vis-fecha">${fecha}</div>
        <div class="vis-chevron">›</div>`;
      return el;
    }

    el.className = "vis-row vis-row-grid";
    el.innerHTML = `
      <div class="vis-person">
        <div class="avatar">${initials(v.nombre)}</div>
        <div>
          <div class="vis-person-name">${escapeHtml(v.nombre)}</div>
          <div class="vis-person-clave">${escapeHtml(v.clave_lector)}</div>
        </div>
      </div>
      <div><span class="tipo-badge"><span class="tipo-dot" style="background:${tipoColor}"></span>${tipoLabel}</span></div>
      <div class="vis-curp">${escapeHtml(v.curp)}</div>
      <div class="vis-acceso"><span class="vis-acceso-dot"></span><span class="vis-acceso-name">${escapeHtml(acc.nombre)}</span></div>
      <div class="vis-fecha">${fecha}</div>
      <div class="vis-chevron">›</div>`;
    return el;
  }

  function escapeHtml(s) {
    const div = document.createElement("div");
    div.textContent = s == null ? "" : String(s);
    return div.innerHTML;
  }

  function skeletonRows(container, count) {
    container.innerHTML = "";
    for (let i = 0; i < count; i++) {
      const row = document.createElement("div");
      row.className = "skel-row";
      row.innerHTML = `
        <div style="display:flex;align-items:center;gap:12px;"><div class="skel-avatar"></div><div style="flex:1;"><div class="skel-block" style="height:11px;width:60%;border-radius:5px;"></div><div class="skel-block" style="height:9px;width:35%;border-radius:5px;margin-top:7px;"></div></div></div>
        <div class="skel-block" style="height:22px;width:78px;border-radius:20px;"></div>
        <div class="skel-block" style="height:11px;width:88%;border-radius:5px;"></div>
        <div class="skel-block" style="height:11px;width:70%;border-radius:5px;"></div>
        <div class="skel-block" style="height:11px;width:60%;border-radius:5px;"></div>
        <div></div>`;
      container.appendChild(row);
    }
  }

  // ---------- accesos (cache compartida) ----------

  async function refreshAccesosCache() {
    const accesos = await api("/accesos/");
    state.accesosById = new Map((accesos || []).map((a) => [a.id, a]));
    return accesos || [];
  }

  // ---------- DASHBOARD ----------

  async function loadDashboard() {
    document.getElementById("dash-greeting").textContent =
      "Hola" + (state.admin ? ", " + state.admin.nombre : "") + " 👋";

    const rowsEl = document.getElementById("dash-recent-rows");
    rowsEl.innerHTML = "";
    skeletonRows(rowsEl, 5);

    try {
      const [accesos, pagina] = await Promise.all([
        refreshAccesosCache(),
        api(`/visitantes/?page=1&page_size=100`),
      ]);

      document.getElementById("stat-accesos").textContent = accesos.length;
      document.getElementById("stat-total").textContent = pagina.total;

      const ahora = new Date();
      const inicioHoy = new Date(
        ahora.getFullYear(),
        ahora.getMonth(),
        ahora.getDate(),
      );
      const hace7Dias = new Date(ahora.getTime() - 7 * 24 * 60 * 60 * 1000);
      const visitas = pagina.visitantes || [];
      const hoy = visitas.filter(
        (v) => new Date(v.created_at) >= inicioHoy,
      ).length;
      const semana = visitas.filter(
        (v) => new Date(v.created_at) >= hace7Dias,
      ).length;
      document.getElementById("stat-hoy").textContent = hoy;
      document.getElementById("stat-semana").textContent = semana;

      rowsEl.innerHTML = "";
      visitas
        .slice(0, 5)
        .forEach((v) => rowsEl.appendChild(visitanteRowEl(v, "compact")));
      if (visitas.length === 0) {
        rowsEl.innerHTML =
          '<div style="padding:24px;text-align:center;color:#9A958C;font-size:13.5px;">Sin visitas registradas todavía.</div>';
      }
    } catch (e) {
      rowsEl.innerHTML = `<div style="padding:24px;text-align:center;color:#D14343;font-size:13.5px;">${escapeHtml(e.message)}</div>`;
    }
  }

  // ---------- VISITANTES (listado paginado) ----------

  function setVisitantesViewState(viewState) {
    document.getElementById("vis-loading").hidden = viewState !== "loading";
    document.getElementById("vis-rows").hidden = viewState !== "data";
    document.getElementById("vis-empty").hidden = viewState !== "empty";
    document.getElementById("vis-error").hidden = viewState !== "error";
    document.getElementById("vis-pagination").hidden = viewState !== "data";
  }

  async function loadVisitantes(page) {
    state.visPage = page;
    setVisitantesViewState("loading");
    skeletonRows(document.getElementById("vis-loading"), 8);

    try {
      if (state.accesosById.size === 0) await refreshAccesosCache();
      const params = new URLSearchParams({
        page: String(page),
        page_size: String(state.visPageSize),
      });
      const q = document.getElementById("vis-quick-search").value.trim();
      if (q) params.set("q", q);
      const tipo = document.getElementById("vis-filter-tipo").value;
      if (tipo) params.set("tipo_documento", tipo);

      const pagina = await api(`/visitantes/?${params.toString()}`);
      state.visTotal = pagina.total;

      document.getElementById("vis-subtitle").textContent =
        `${pagina.total} registros en la bitácora`;

      const rowsEl = document.getElementById("vis-rows");
      rowsEl.innerHTML = "";

      if (!pagina.visitantes || pagina.visitantes.length === 0) {
        setVisitantesViewState("empty");
        return;
      }

      pagina.visitantes.forEach((v) =>
        rowsEl.appendChild(visitanteRowEl(v, "list")),
      );
      setVisitantesViewState("data");

      const totalPages = Math.max(
        1,
        Math.ceil(pagina.total / state.visPageSize),
      );
      document.getElementById("vis-page-label").textContent =
        `Mostrando ${pagina.visitantes.length} de ${pagina.total} registros`;
      document.getElementById("vis-page-current").textContent =
        `Página ${page} de ${totalPages}`;
      document.getElementById("vis-prev").disabled = page <= 1;
      document.getElementById("vis-next").disabled = page >= totalPages;
    } catch (e) {
      setVisitantesViewState("error");
    }
  }

  document.getElementById("vis-prev").addEventListener("click", () => {
    if (state.visPage > 1) loadVisitantes(state.visPage - 1);
  });
  document.getElementById("vis-next").addEventListener("click", () => {
    const totalPages = Math.max(
      1,
      Math.ceil(state.visTotal / state.visPageSize),
    );
    if (state.visPage < totalPages) loadVisitantes(state.visPage + 1);
  });
  document
    .getElementById("vis-retry")
    .addEventListener("click", () => loadVisitantes(state.visPage));

  let visSearchDebounce = null;
  document.getElementById("vis-quick-search").addEventListener("input", () => {
    clearTimeout(visSearchDebounce);
    visSearchDebounce = setTimeout(() => loadVisitantes(1), 350);
  });
  document.getElementById("vis-filter-tipo").addEventListener("change", () => {
    loadVisitantes(1);
  });

  // ---------- DETALLE ----------

  const DETALLE_OTRAS_VISITAS_MAX = 4;

  async function loadDetalle(id) {
    const body = document.getElementById("detalle-body");
    body.innerHTML =
      '<div class="loading-state"><div class="spinner"></div></div>';

    try {
      if (state.accesosById.size === 0) await refreshAccesosCache();
      const v = await api(`/visitantes/${id}`);
      const acc = accesoInfo(v.acceso_id);
      const tipoColor = TIPO_COLOR[v.tipo_documento] || "#9A958C";
      const tipoLabel = TIPO_LABEL[v.tipo_documento] || v.tipo_documento;

      const hist = await api(
        `/visitantes/buscar?curp=${encodeURIComponent(v.curp)}`,
      );
      const otras = hist.visitas.filter((x) => x.id !== v.id);
      const preview = otras.slice(0, DETALLE_OTRAS_VISITAS_MAX);
      const restantes = otras.length - preview.length;

      const verHistorial = () => {
        document.getElementById("curp-input").value = v.curp;
        goTo("historial");
        buscarHistorial(v.curp);
      };

      body.innerHTML = `
        <div style="display:grid;grid-template-columns:300px 1fr;gap:20px;align-items:start;">
          <div class="panel panel--padded" style="text-align:center;border-radius:16px;">
            <div class="avatar avatar--lg" style="margin:0 auto 16px;">${initials(v.nombre)}</div>
            <div style="font-size:19px;font-weight:700;letter-spacing:-.2px;">${escapeHtml(v.nombre)}</div>
            <div style="margin-top:10px;"><span class="tipo-badge"><span class="tipo-dot" style="background:${tipoColor}"></span>${tipoLabel}</span></div>
            <button class="btn-primary btn-block" id="btn-ver-historial" style="margin-top:22px;">Ver historial completo</button>
          </div>
          <div>
            <div class="panel" style="border-radius:16px;padding:8px 26px;">
              ${detalleRow("Tipo de documento", tipoLabel)}
              ${detalleRow("Clave de lector", v.clave_lector, true)}
              ${detalleRow("CURP", v.curp, true)}
              ${detalleRow("Acceso de entrada", acc.nombre, false, acc.ubicacion)}
              ${detalleRow("Fecha y hora", formatFecha(v.created_at), false, null, otras.length === 0)}
            </div>
            ${
              otras.length > 0
                ? `<div class="panel" style="border-radius:16px;margin-top:16px;">
                <div style="padding:14px 20px;font-size:11px;font-weight:600;letter-spacing:.5px;color:#9A958C;border-bottom:1px solid #F1EFEA;">
                  OTRAS VISITAS DE ESTA PERSONA (${otras.length})
                </div>
                <div id="detalle-otras-visitas"></div>
                ${
                  restantes > 0
                    ? `<button class="btn-outline" id="btn-ver-todas-visitas" style="margin:14px 20px 18px;">Ver las ${otras.length} visitas →</button>`
                    : ""
                }
              </div>`
                : ""
            }
          </div>
        </div>`;

      if (preview.length > 0) {
        const cont = document.getElementById("detalle-otras-visitas");
        preview.forEach((ov) =>
          cont.appendChild(visitanteRowEl(ov, "compact")),
        );
      }

      document
        .getElementById("btn-ver-historial")
        .addEventListener("click", verHistorial);
      const btnTodas = document.getElementById("btn-ver-todas-visitas");
      if (btnTodas) btnTodas.addEventListener("click", verHistorial);
    } catch (e) {
      body.innerHTML = `<div class="empty-state"><div class="empty-title">No se pudo cargar el detalle</div><div class="empty-text">${escapeHtml(e.message)}</div></div>`;
    }
  }

  function detalleRow(label, value, mono, sub, last) {
    return `
      <div style="display:flex;align-items:center;justify-content:space-between;padding:18px 0;${last ? "" : "border-bottom:1px solid #F1EFEA;"}">
        <div style="font-size:13px;font-weight:600;color:#3A362F;">${label}</div>
        <div style="text-align:right;">
          <div style="font-size:14px;color:#1C1A17;font-weight:500;${mono ? "font-family:'IBM Plex Mono';letter-spacing:.5px;" : ""}">${escapeHtml(value)}</div>
          ${sub ? `<div style="font-size:12px;color:#9A958C;margin-top:2px;">${escapeHtml(sub)}</div>` : ""}
        </div>
      </div>`;
  }

  // ---------- HISTORIAL ----------

  function loadHistorialIdle() {
    document.getElementById("curp-input").value = "";
    setHistState("idle");
  }

  function setHistState(s) {
    ["idle", "loading", "results", "empty"].forEach((name) => {
      document.getElementById("hist-" + name).hidden = name !== s;
    });
  }

  async function buscarHistorial(rawCurp) {
    const curp = (rawCurp || "").trim().toUpperCase();
    const hintEl = document.getElementById("curp-hint");

    if (curp.length !== 18) {
      hintEl.textContent = "La CURP debe tener exactamente 18 caracteres.";
      hintEl.classList.add("invalid");
      return;
    }
    hintEl.textContent = "18 caracteres exactos.";
    hintEl.classList.remove("invalid");

    setHistState("loading");
    try {
      if (state.accesosById.size === 0) await refreshAccesosCache();
      const res = await api(
        `/visitantes/buscar?curp=${encodeURIComponent(curp)}`,
      );

      if (!res.visitas || res.visitas.length === 0) {
        setHistState("empty");
        return;
      }

      document.getElementById("hist-total").textContent = res.total_visitas;
      document.getElementById("hist-title").textContent =
        `${res.total_visitas} visita${res.total_visitas === 1 ? "" : "s"} registrada${res.total_visitas === 1 ? "" : "s"}`;
      document.getElementById("hist-curp-label").textContent = res.curp;

      const rowsEl = document.getElementById("hist-rows");
      rowsEl.innerHTML = "";
      res.visitas.forEach((v) => rowsEl.appendChild(visitanteRowEl(v, "full")));

      setHistState("results");
    } catch (e) {
      setHistState("empty");
    }
  }

  document.getElementById("curp-search-btn").addEventListener("click", () => {
    buscarHistorial(document.getElementById("curp-input").value);
  });
  document.getElementById("curp-input").addEventListener("keydown", (e) => {
    if (e.key === "Enter") buscarHistorial(e.target.value);
  });

  // ---------- ACCESOS ----------

  async function loadAccesos() {
    const listEl = document.getElementById("accesos-list");
    listEl.innerHTML =
      '<div class="loading-state"><div class="spinner"></div></div>';
    try {
      const accesos = await refreshAccesosCache();
      listEl.innerHTML = "";
      if (accesos.length === 0) {
        listEl.innerHTML =
          '<div class="empty-state"><div class="empty-title">No tienes accesos configurados</div><div class="empty-text">Crea tu primera entrada con "Nuevo acceso".</div></div>';
        return;
      }
      accesos.forEach((a) => listEl.appendChild(accesoCardEl(a)));
    } catch (e) {
      listEl.innerHTML = `<div class="empty-state"><div class="empty-title">No se pudieron cargar los accesos</div><div class="empty-text">${escapeHtml(e.message)}</div></div>`;
    }
  }

  function accesoCardEl(a) {
    const el = document.createElement("div");
    el.className = "acceso-card";
    el.innerHTML = `
      <div class="acceso-icon"><svg width="20" height="20" viewBox="0 0 18 18" fill="none" stroke="#C2410C" stroke-width="1.6"><rect x="2.5" y="3" width="13" height="12" rx="1.4"/><line x1="9" y1="3" x2="9" y2="15"/></svg></div>
      <div class="acceso-info">
        <div class="acceso-nombre">${escapeHtml(a.nombre)}</div>
        <div class="acceso-ubicacion"><span class="acceso-ubicacion-dot"></span>${escapeHtml(a.ubicacion || "Sin ubicación")}</div>
      </div>
      <span class="acceso-id-badge">ID: ${a.id}</span>
      <button class="btn-edit">Editar</button>
      <button class="btn-icon-outline" title="Eliminar"><svg width="16" height="16" viewBox="0 0 18 18" fill="none" stroke="currentColor" stroke-width="1.6"><line x1="4" y1="5" x2="14" y2="5"/><path d="M6 5V3.5h6V5"/><path d="M5 5l.7 9a1 1 0 0 0 1 .9h4.6a1 1 0 0 0 1-.9L13 5"/></svg></button>`;
    el.querySelector(".btn-edit").addEventListener("click", () =>
      openAccesoModal(a),
    );
    el.querySelector(".btn-icon-outline").addEventListener("click", () =>
      openDeleteModal(a),
    );
    return el;
  }

  function openAccesoModal(acceso) {
    state.editingAccesoId = acceso ? acceso.id : null;
    document.getElementById("modal-acceso-title").textContent = acceso
      ? "Editar acceso"
      : "Nuevo acceso";
    document.getElementById("acceso-nombre").value = acceso
      ? acceso.nombre
      : "";
    document.getElementById("acceso-ubicacion").value = acceso
      ? acceso.ubicacion || ""
      : "";
    document.getElementById("acceso-clave-hint").hidden = !!acceso;
    document.getElementById("acceso-form-error").hidden = true;
    document.getElementById("acceso-form-view").hidden = false;
    document.getElementById("acceso-reveal-view").hidden = true;
    document.getElementById("modal-acceso").hidden = false;
  }

  function closeModals() {
    document.getElementById("modal-acceso").hidden = true;
    document.getElementById("modal-delete").hidden = true;
  }

  document
    .getElementById("btn-nuevo-acceso")
    .addEventListener("click", () => openAccesoModal(null));
  document
    .getElementById("acceso-cancel")
    .addEventListener("click", closeModals);
  document
    .getElementById("acceso-reveal-done")
    .addEventListener("click", () => {
      closeModals();
      loadAccesos();
    });
  document.getElementById("modal-acceso").addEventListener("click", (e) => {
    if (e.target.id === "modal-acceso") closeModals();
  });

  document
    .getElementById("acceso-form")
    .addEventListener("submit", async (e) => {
      e.preventDefault();
      const errEl = document.getElementById("acceso-form-error");
      errEl.hidden = true;

      const payload = {
        nombre: document.getElementById("acceso-nombre").value.trim(),
        ubicacion: document.getElementById("acceso-ubicacion").value.trim(),
      };

      try {
        if (state.editingAccesoId) {
          await api(`/accesos/${state.editingAccesoId}`, {
            method: "PATCH",
            body: JSON.stringify(payload),
          });
          closeModals();
          loadAccesos();
        } else {
          const creado = await api("/accesos/", {
            method: "POST",
            body: JSON.stringify(payload),
          });
          document.getElementById("reveal-acceso-id").textContent = creado.id;
          document.getElementById("reveal-clave").textContent =
            creado.clave_kiosko;
          document.getElementById("acceso-form-view").hidden = true;
          document.getElementById("acceso-reveal-view").hidden = false;
        }
      } catch (e2) {
        errEl.textContent = e2.message;
        errEl.hidden = false;
      }
    });

  function openDeleteModal(acceso) {
    state.deletingAccesoId = acceso.id;
    document.getElementById("modal-delete-title").textContent =
      `¿Eliminar "${acceso.nombre}"?`;
    document.getElementById("modal-delete").hidden = false;
  }

  document
    .getElementById("delete-cancel")
    .addEventListener("click", closeModals);
  document.getElementById("modal-delete").addEventListener("click", (e) => {
    if (e.target.id === "modal-delete") closeModals();
  });
  document
    .getElementById("delete-confirm")
    .addEventListener("click", async () => {
      try {
        await api(`/accesos/${state.deletingAccesoId}`, { method: "DELETE" });
        closeModals();
        loadAccesos();
      } catch (e) {
        closeModals();
        alert("No se pudo eliminar: " + e.message);
      }
    });

  // ---------- PERFIL ----------

  async function loadPerfil() {
    try {
      const a = await api(`/admins/${state.adminId}`);
      state.admin = a;
      document.getElementById("perfil-avatar").textContent = initials(
        a.nombre + " " + a.apellido_paterno,
      );
      document.getElementById("perfil-nombre-completo").textContent =
        `${a.nombre} ${a.apellido_paterno} ${a.apellido_materno}`.trim() ||
        a.correo;
      document.getElementById("perfil-nombre").value = a.nombre || "";
      document.getElementById("perfil-paterno").value =
        a.apellido_paterno || "";
      document.getElementById("perfil-materno").value =
        a.apellido_materno || "";
      document.getElementById("perfil-correo").value = a.correo || "";
      document.getElementById("perfil-password").value = "";
      document.getElementById("perfil-error").hidden = true;
      document.getElementById("perfil-success").hidden = true;
      updateSidebarUser();
    } catch (e) {
      document.getElementById("perfil-error").textContent = e.message;
      document.getElementById("perfil-error").hidden = false;
    }
  }

  document
    .getElementById("perfil-form")
    .addEventListener("submit", async (e) => {
      e.preventDefault();
      const errEl = document.getElementById("perfil-error");
      const okEl = document.getElementById("perfil-success");
      errEl.hidden = true;
      okEl.hidden = true;

      const payload = {
        nombre: document.getElementById("perfil-nombre").value.trim(),
        apellido_paterno: document
          .getElementById("perfil-paterno")
          .value.trim(),
        apellido_materno: document
          .getElementById("perfil-materno")
          .value.trim(),
        correo: document.getElementById("perfil-correo").value.trim(),
        password: document.getElementById("perfil-password").value,
      };

      try {
        const updated = await api(`/admins/${state.adminId}`, {
          method: "PATCH",
          body: JSON.stringify(payload),
        });
        state.admin = updated;
        okEl.hidden = false;
        updateSidebarUser();
      } catch (e2) {
        errEl.textContent = e2.message;
        errEl.hidden = false;
      }
    });

  function updateSidebarUser() {
    if (!state.admin) return;
    const nombreCompleto =
      `${state.admin.nombre} ${state.admin.apellido_paterno}`.trim() ||
      state.admin.correo;
    document.getElementById("sidebar-user-name").textContent = nombreCompleto;
    document.getElementById("sidebar-avatar").textContent =
      initials(nombreCompleto) || "··";
  }

  // ---------- login / signup / logout ----------

  let loginMode = "login"; // 'login' | 'signup'

  function setLoginMode(mode) {
    loginMode = mode;
    const isSignup = mode === "signup";
    document.getElementById("login-title").textContent = isSignup
      ? "Crear cuenta"
      : "Panel de administración";
    document.getElementById("login-lead").textContent = isSignup
      ? "Crea tu cuenta de administrador para empezar a configurar tu comunidad."
      : "Inicia sesión para supervisar los accesos de tu comunidad.";
    document.getElementById("login-submit").textContent = isSignup
      ? "Crear cuenta"
      : "Entrar";
    document.getElementById("login-toggle-text").textContent = isSignup
      ? "¿Ya tienes cuenta?"
      : "¿No tienes cuenta?";
    document.getElementById("login-toggle-mode").textContent = isSignup
      ? "Inicia sesión"
      : "Crear cuenta de administrador";
    document.getElementById("login-password").placeholder = isSignup
      ? "Mínimo 8 caracteres"
      : "••••••••";
    document.getElementById("login-error").hidden = true;
  }

  document.getElementById("login-toggle-mode").addEventListener("click", () => {
    setLoginMode(loginMode === "login" ? "signup" : "login");
  });

  document
    .getElementById("login-form")
    .addEventListener("submit", async (e) => {
      e.preventDefault();
      const errEl = document.getElementById("login-error");
      errEl.hidden = true;
      const submitBtn = document.getElementById("login-submit");
      submitBtn.disabled = true;

      const correo = document.getElementById("login-correo").value.trim();
      const password = document.getElementById("login-password").value;
      const path = loginMode === "signup" ? "/auth/sign-in" : "/auth/login";

      try {
        const res = await fetch(API_BASE + path, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ correo, password }),
        });
        const body = await res.json();
        if (!res.ok)
          throw new Error(body.error || "No se pudo completar la operación");

        setToken(body.access_token);
        await bootstrapApp();
      } catch (err) {
        errEl.textContent = err.message;
        errEl.hidden = false;
      } finally {
        submitBtn.disabled = false;
      }
    });

  document.getElementById("btn-logout").addEventListener("click", () => {
    clearToken();
    state.admin = null;
    state.adminId = null;
    setLoginMode("login");
    showLogin();
  });

  // ---------- bootstrap ----------

  async function bootstrapApp() {
    const token = getToken();
    if (!token) {
      showLogin();
      return;
    }

    const claims = decodeJWT(token);
    if (!claims || !claims.admin_id) {
      clearToken();
      showLogin();
      return;
    }

    state.adminId = claims.admin_id;
    showApp();

    try {
      state.admin = await api(`/admins/${state.adminId}`);
      updateSidebarUser();
    } catch {
      return; // si el token ya expiro, api() ya nos regreso al login
    }

    goTo("dashboard");
  }

  bootstrapApp();
})();
