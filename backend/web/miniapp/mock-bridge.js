// Mock del bridge de Kigo, SOLO para pruebas locales (activado con
// "?mock=1"). El Playground real de Kigo vive en un repo privado de ellos,
// inaccesible para un desarrollador externo de mini-app -- este mock imita
// la misma forma que window.KigoSDK.kigo (ver vendor/kigo-sdk.umd.js) para
// poder probar app.js en un navegador normal.
//
// "?userId=xxx" simula un usuario ya vinculado (respuesta 200 vinculado:true
// del backend) si ese id coincide con uno que hayas dado de alta a mano en
// la BD; cualquier otro id simula "no vinculado".
window.KigoSDK = {
  kigo: {
    async init() {},
    auth: {
      async init() {
        const userId = new URLSearchParams(location.search).get("userId") || "mock-user-1";
        return { sessionId: "mock-session", userId, expiresAt: Date.now() + 3600_000 };
      },
    },
    navigation: {
      async openExternal({ url }) {
        window.open(url, "_blank");
        return { opened: true };
      },
      async close() {
        alert("kigo.navigation.close() -- en la app real esto cerraría la mini-app.");
      },
    },
    ui: {
      async setTitle({ title }) {
        document.title = title;
      },
    },
  },
};
console.log("[mock-bridge] activo -- esto NO es el bridge real de Kigo.");
