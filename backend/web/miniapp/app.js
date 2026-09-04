// Mini-app del marketplace de Kigo Parkimovil. Alcance deliberadamente
// mínimo (ver docs/integracion-kigo-marketplace-y-face-enrollment.md y la
// decisión tomada en sesión): kigo.auth.init() solo entrega un userId, sin
// teléfono ni nombre, así que esta página no intenta dar de alta a nadie --
// solo resuelve "¿ya estás vinculado?" y, si no, manda a completar el alta
// en la app AUTOnomIA (que sí sabe pedir teléfono+OTP+rostro).
(function () {
  const app = document.getElementById("app");
  const mensajeEl = document.getElementById("mensaje");
  const spinnerEl = document.getElementById("spinner");
  const botonEl = document.getElementById("boton-accion");

  function mostrar({ mensaje, secundario, error, botonTexto, onBoton }) {
    spinnerEl.hidden = true;
    app.classList.toggle("pantalla--error", !!error);
    mensajeEl.textContent = mensaje;
    mensajeEl.classList.toggle("mensaje--error", !!error);

    if (secundario) {
      let sec = document.getElementById("mensaje-secundario");
      if (!sec) {
        sec = document.createElement("p");
        sec.id = "mensaje-secundario";
        sec.className = "mensaje mensaje--secundario";
        mensajeEl.insertAdjacentElement("afterend", sec);
      }
      sec.textContent = secundario;
    }

    if (botonTexto) {
      botonEl.textContent = botonTexto;
      botonEl.hidden = false;
      botonEl.onclick = onBoton || null;
    } else {
      botonEl.hidden = true;
    }
  }

  async function main() {
    const kigo = window.KigoSDK && window.KigoSDK.kigo;
    if (!kigo) {
      mostrar({
        mensaje: "No se pudo cargar el puente de Kigo.",
        secundario: "Abre esta página desde la app Kigo Parkimovil.",
        error: true,
      });
      return;
    }

    let auth;
    try {
      // El SDK de Kigo espera que la app nativa inyecte window.kigoBridge
      // al abrir esta página en su WebView; si nunca aparece, kigo.auth.init()
      // se queda reintentando hasta 2 minutos (ver vendor/kigo-sdk.umd.js,
      // timeout:12e4) antes de fallar -- eso se ve como "no funciona"
      // (cuelgue largo) más que como un error. Se acota a 10s propios para
      // no dejar al usuario viendo el spinner ese tiempo, y el mensaje
      // distingue "el puente nunca llegó" de otro tipo de falla, para poder
      // diagnosticar con soporte de Kigo si el problema es de registro/
      // configuración de su lado.
      const puenteListoATiempo = () => new Promise((resolve) => {
        setTimeout(() => resolve(typeof window.kigoBridge !== "undefined"), 10000);
      });
      auth = await Promise.race([
        kigo.auth.init(),
        puenteListoATiempo().then((listo) => {
          if (!listo) throw new Error("BRIDGE_NO_DETECTADO");
          throw new Error("BRIDGE_TIMEOUT_LOCAL");
        }),
      ]);
    } catch (err) {
      const sinPuente = err?.message === "BRIDGE_NO_DETECTADO";
      mostrar({
        mensaje: "No se pudo verificar tu sesión de Kigo.",
        secundario: sinPuente
          ? "Kigo Parkimovil no conectó esta página con su app (window.kigoBridge nunca apareció). Repórtalo a soporte de Kigo con este dato."
          : "Abre esta página desde Kigo Parkimovil e inténtalo de nuevo.",
        error: true,
      });
      return;
    }

    if (typeof kigo.ui?.setTitle === "function") {
      kigo.ui.setTitle({ title: "AUTOnomIA" }).catch(() => {});
    }

    let estado;
    try {
      const resp = await fetch(
        `${window.__API_BASE__}/miniapp/estado?kigo_user_id=${encodeURIComponent(auth.userId)}`
      );
      if (!resp.ok) throw new Error("respuesta no OK");
      estado = await resp.json();
    } catch (err) {
      mostrar({
        mensaje: "No se pudo conectar con AUTOnomIA.",
        secundario: "Revisa tu conexión e inténtalo de nuevo.",
        error: true,
      });
      return;
    }

    if (estado.vinculado) {
      mostrar({
        mensaje: "Ya estás registrado en AUTOnomIA.",
        secundario: "Usa la app AUTOnomIA en tu fraccionamiento para tu acceso y tu QR.",
      });
      return;
    }

    mostrar({
      mensaje: "Aún no tienes cuenta en AUTOnomIA.",
      secundario: "Descarga la app para completar tu registro: teléfono, rostro y tu fraccionamiento.",
      botonTexto: "Descargar AUTOnomIA",
      onBoton: () => {
        const url = window.__KIGO_APP_RELEASE_URL__;
        if (!url) {
          // Antes esto no hacía nada visible -- un botón "muerto" es
          // indistinguible de "la mini-app no funciona" para quien la usa.
          mostrar({
            mensaje: "No se pudo abrir la descarga.",
            secundario: "Vuelve a intentarlo en unos minutos.",
            error: true,
          });
          return;
        }
        if (typeof kigo.navigation?.openExternal === "function") {
          kigo.navigation.openExternal({ url }).catch(() => {
            window.open(url, "_blank");
          });
        } else {
          window.open(url, "_blank");
        }
      },
    });
  }

  main();
})();
