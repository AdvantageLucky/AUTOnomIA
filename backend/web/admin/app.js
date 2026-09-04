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
      casa_destino: "Destino",
      placa: "Placa",
      no_placa: "Sin placa",
      autorizado_por: "Autorizado por",
      sin_resolver: "Sin resolver",
      autorizador_admin: "Admin",
      autorizador_residente: "Residente",
      autorizador_agente: "Agente IA",
      autorizador_sistema: "Sistema (sin respuesta)",
      autorizador_propio: "Acceso propio",
      visits: n => `${n} entrada${n !== 1 ? "s" : ""} registrada${n !== 1 ? "s" : ""}`,
      hello: name => `Hola, ${name}`,
      nav_inicio: "Inicio",
      nav_solicitudes: "Solicitudes",
      nav_residentes: "Residentes",
      nav_kioskos: "Kioskos",
      nav_instalacion: "Centro",
      tab_activos: "Activos",
      tab_solicitudes: "Solicitudes",
      tab_enrolamientos: "Enrolamientos",
      enrolamientos_sub: "Personas con acceso frecuente por rostro/QR que un residente dio de alta -- no son residentes, entran sin invitación cada vez.",
      cargando_enrolamientos: "Cargando enrolamientos…",
      sin_enrolamientos: "Sin enrolamientos",
      sin_enrolamientos_detalle: "Cuando un residente le dé acceso frecuente por rostro a alguien, aparecerá aquí.",
      enrolado_por_label: "Enrolado por",
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
      approbar: "Aprobar",
      rechazar: "Rechazar",
      sin_solicitudes: "Sin solicitudes pendientes",
      sin_solicitudes_text: "Cuando alguien solicite acceso, aparecerá aquí.",
            confirmar_button: "Confirmar",
      confirmar_pregunta: "¿Confirmar?",
      stream_conectado: "Stream conectado",
      stream_desconectado: "Stream desconectado",
      asistencia_urgente_sse: "Asistencia urgente solicitada en el kiosko",
      nuevo_visitante: "Nuevo visitante",
      alerta_revision_manual: "Alerta: Requiere revisión manual:",
      nueva_solicitud_toast: "Nueva solicitud:",
            google_login_fallido: "Falló el inicio de sesión con Google",
      error_conexion: "Error de conexión",
            tema_claro_corto: "Claro",
      tema_oscuro_corto: "Oscuro",
            periodo_label: "Período:",
      ultimo_periodo: "Último período",
      total_visitas_pill: "Total visitas",
      total_registradas_pill: "Total registradas",
      analisis_ia_header: "Análisis de Inteligencia Artificial",
      resumen_automatico_sin_ia: "Resumen automático · IA no disponible",
      actividad_acumulada_reciente: "Actividad acumulada reciente",
      resumen_dinamico_intro: (total, aprob, rech, rev) => `Se han registrado **${total} accesos** en el sistema (${aprob} aprobados, ${rech} rechazados, ${rev} pendientes de resolución).`,
      resumen_dinamico_con_rechazos: "Se identificaron entradas rechazadas que sugieren atención por parte de vigilancia o administración.",
      resumen_dinamico_normal: "El flujo de accesos opera con normalidad y con alta tasa de aprobación.",
      historial_no_disponible: "No se pudo cargar el historial.",
            sin_identificador_historial: "Sin identificador para buscar historial.",
      primera_visita_registrada: "Primera visita registrada.",
            visitante_sin_nombre: "Visitante sin nombre",
      evidencia_documento: "Documento",
      evidencia_rostro: "Rostro",
      evidencia_placa: "Placa",
      evidencia_sin_fotos: "Esta entrada no tiene fotos registradas.",
      ver_completa: "Ver completa",
            kio_nunca_conectado: "Nunca conectado",
      kio_en_linea: "En línea",
      kio_desconectado_hace: "Desconectado hace",
      con_analisis_ia: "Con análisis de IA",
      revisada_por_ia: "Revisada por IA",
            configurar_kiosko_title: "Configurar kiosko",
            ingresa_codigo_formato: "Ingresa el código con formato XXXX-XXXX",
      codigo_invalido_o_usado: "Código inválido o ya utilizado",
      codigo_no_activo_o_expiro: "El código no está activo o ya expiró",
      error_crear_kiosko: "Error al crear kiosko",
      kiosko_creado_sin_vincular: "Kiosko creado pero no se pudo vincular al dispositivo",
      kiosko_configurado_listo: "Kiosko configurado y listo",
      kiosko_activado_toast: "Kiosko activado. Configúralo cuando quieras desde Kioskos.",
            error_generico: "Error",
      kiosko_actualizado_toast: "Kiosko actualizado",
      nombre_kiosko_obligatorio: "El nombre del kiosko es obligatorio",
      error_actualizar_info_kiosko: "Error al actualizar información del kiosko",
            pipeline_rostro_title: "Foto de Rostro",
      pipeline_rostro_desc: "Captura facial de verificación y reconocimiento",
      pipeline_destino_title: "Selección de Destino",
      pipeline_destino_desc: "Búsqueda y selección de calle, edificio o casa",
      pipeline_placa_title: "Captura de Placa Vehicular",
      pipeline_placa_desc: "Escaneo de matrícula (obligatorio en accesos vehiculares)",
      pipeline_ine_title: "Escaneo de INE / Identificación",
      pipeline_ine_desc: "Escaneo de credencial con OCR (opcional según hardware)",
      pipeline_motivo_title: "Motivo de la visita",
      pipeline_motivo_desc: "Chips de un toque (Paquete, Servicio, Visita, Proveedor, Otro). Un invitado con pase QR no lo ve -- ya lo capturó quien lo invitó.",
      no_aplica_kiosko_peatonal: "No aplica a kioskos peatonales",
      no_disponible_kiosko_peatonal: "No disponible en kiosko peatonal",
      arrastrar_para_reordenar: "Arrastrar para reordenar",
      desactivado_no_aplica_peatonal: "Desactivado (no aplica a kioskos peatonales)",
      mover_arriba: "Mover arriba",
      mover_abajo: "Mover abajo",
      eliminar_destino_title: "Eliminar destino",
      tiene_contacto_referencia_title: "Tiene contacto de referencia",
            no_pudo_cargar_config_kiosko: "No se pudo cargar la configuración del kiosko",
      configuracion_label: "Configuración",
      configuracion_de_kiosko: "Configuración de kiosko",
      error_guardar_configuracion: "Error al guardar configuración",
      kiosko_config_guardados_ok: "Kiosko y configuración guardados correctamente",
            rol_admin_corto: "Admin",
      rol_vigilante_corto: "Vigilante",
      eliminar_vigilante_title: "Eliminar vigilante",
      confirmar_eliminar_vigilante: "¿Eliminar este vigilante?",
      no_pudo_eliminar_vigilante: "No se pudo eliminar el vigilante",
      error_crear_vigilante: "Error al crear vigilante",
      vigilante_creado_todo_listo: "Vigilante creado. ¡Todo listo!",
      vigilante_creado_correctamente: "Vigilante creado correctamente",
            hero_ahora: "ahora",
            error_al_guardar: "Error al guardar",
      correo_pass_obligatorios: "Correo y contraseña son obligatorios",
            tipo_destino_casa: "Casa",
      tipo_destino_departamento: "Depto.",
      tipo_destino_edificio: "Edificio",
      tipo_destino_oficina: "Oficina",
      tipo_destino_local: "Local",
      tipo_destino_bodega: "Bodega",
      tipo_destino_lote: "Lote",
            error_cargar_destinos: "Error al cargar destinos",
      sin_calle: "Sin calle",
      no_pudo_guardar_contacto: "No se pudo guardar el contacto",
      confirmar_eliminar_destino: "¿Eliminar este destino?",
      confirmar_eliminar_destino_texto: "Los residentes ya enlazados a esta casa no se eliminan, pero el destino dejará de estar disponible para nuevos registros.",
      no_pudo_eliminar_destino: "No se pudo eliminar el destino",
      ingresa_nombre_calle_bloque: "Ingresa el nombre de la calle o bloque",
      agrega_numero_identificador: "Agrega al menos un número o identificador",
      error_crear_destinos: "Error al crear destinos",
      destinos_creados_ok: "Destinos creados correctamente",
            centro_actualizado_toast: "Centro habitacional actualizado",
      copiado_exclamacion: "¡Copiado!",
      codigo_copiado_portapapeles: "Código copiado al portapapeles",
            sin_calle_registrada: "Sin calle registrada",
      sin_tipo: "Sin tipo",
      residentes_label: "Residentes",
      invitados_frecuentes_label: "Invitados frecuentes",
      sin_destino: "Sin destino",
            sin_nombre: "Sin nombre",
      residente_activo_label: "Residente activo",
      invitado_frecuente_badge: "Invitado frecuente",
      sin_casa: "Sin casa",
      alta_label: "Alta",
      ver_detalle_label: "Ver detalle",
            filtrando_por: "Filtrando por:",
            confirmar_revocar_n: n => `¿Revocar a ${n} residente${n !== 1 ? 's' : ''}?`,
      revocar_acceso_texto: "Ya no podrán entrar por PIN ni reconocimiento facial. Esto no borra su cuenta de Kigo, solo su acceso a este centro.",
      revocar_button: "Revocar",
      no_pudo_revocar_reintentar: "No se pudo revocar. Intenta de nuevo.",
      nav_ayuda: "Ayuda",
      ayuda_title: "Ayuda",
      asistencias_urgentes_sub: "Solicitudes de asistencia urgente desde los kioskos",
      ayuda_filtro_pendientes: "Pendientes",
      ayuda_filtro_todas: "Todas",
      ayuda_cargando: "Cargando asistencias…",
      ayuda_sin_solicitudes: "Sin solicitudes de ayuda",
      ayuda_sin_solicitudes_sub: "Cuando un visitante pida ayuda urgente desde un kiosko, aparecerá aquí.",
      ayuda_sin_motivo: "Sin motivo especificado",
      ayuda_marcar_resuelta: "Marcar resuelta",
      ayuda_estado_pendiente: "Pendiente",
      ayuda_estado_resuelta: "Resuelta",
      ayuda_resuelta_hace: h => `Resuelta hace ${h}`,
      ayuda_motivo_label: "Motivo",
      ayuda_guardar_motivo: "Guardar motivo",
      resetear_confianza_btn: "Restablecer confianza",
      resetear_confianza_titulo: "¿Restablecer la confianza con esta persona?",
      resetear_confianza_texto: "Se olvida todo su historial anterior para el cálculo de confianza -- su próxima visita se evalúa desde cero, como si fuera la primera vez. Esto no borra el historial, solo deja de contar para el análisis.",
      no_pudo_resetear_confianza: "No se pudo restablecer la confianza. Intenta de nuevo.",
      confianza_reseteada_ok: "Confianza restablecida",
      nav_seguridad: "Seguridad",
      seguridad_title: "Seguridad",
      seguridad_sub: "Intentos de acceso fallidos (PIN incorrecto, QR inválido) con foto",
      seguridad_filtro_todos: "Todos",
      seguridad_filtro_pin: "PIN incorrecto",
      seguridad_filtro_qr: "QR inválido",
      seguridad_cargando: "Cargando eventos…",
      seguridad_sin_eventos: "Sin eventos de seguridad",
      seguridad_sin_eventos_sub: "Los intentos fallidos de PIN o QR en los kioskos aparecerán aquí, con foto.",
      seguridad_tipo_pin: "PIN incorrecto",
      seguridad_tipo_qr: "QR inválido",
      seguridad_sin_foto: "Sin foto",
      seguridad_evento_sse: "Intento de acceso fallido en un kiosko",
      // __NEW_I18N_ES_MARKER__
      // --- fix modal residente: claves faltantes ---
      activo_badge: "Activo",
      app_kigo_qr_desc: "Invitaciones y QR de acceso propio",
      app_kigo_qr_label: "App Kigo / QR",
      aprobar_solicitud_button: "Aprobar solicitud",
      configurado_label: "Configurado",
      destino_casa_label: "Destino / Casa",
      documento_identidad_ine_label: "Documento de identidad (INE)",
      documento_ine_alt: "Documento INE",
      enrolado_label: "Enrolado",
      ine_de_label: "INE de",
      metodos_acceso_identidad_label: "Métodos de acceso e identidad",
      miembro_desde_label: "Miembro desde",
      pendiente_aprobacion_label: "Pendiente de aprobación",
      pin_de_acceso_desc: "PIN numérico para entrar sin la app",
      pin_de_acceso_label: "PIN de acceso",
      reconocimiento_facial_ia_desc: "Reconocimiento 1:N en el kiosko",
      reconocimiento_facial_ia_label: "Reconocimiento facial (IA)",
      revocar_acceso_button: "Revocar acceso",
      rostro_de_label: "Rostro de",
      sin_casa_asignada: "Sin casa asignada",
      sin_pin_label: "Sin PIN",
      sin_rostro_label: "Sin rostro",
      solicitado_el_label: "Solicitado el",
      solicitud_pendiente_badge: "Solicitud pendiente",
      ver_entradas_residente_button: "Ver entradas",
      // --- i18n dashboard: segunda pasada (completado) ---
      abre_la_app_en_el_dispositivo_del_kiosko_activacion: "Abre la app en el dispositivo del kiosko — mostrará un código de activación. Escríbelo aquí.",
      ajusta_los_parametros_basicos: "Ajusta los parámetros básicos. Puedes cambiarlos después en la sección Kioskos → Configuración.",
      analisis_de_ia_tab: "Análisis de IA",
      apariencia_y_bienvenida: "Apariencia y Bienvenida",
      aprobacion_automatica_ia_autopass: "Aprobación automática por IA (AutoPass)",
      aprobadas_stat_lower: "aprobadas",
      arrastra_las_tarjetas: "arrastra las tarjetas",
      atras_flecha: "← Atrás",
      auto_pass_con_ia: "Auto-pass con IA",
      ayer_option: "Ayer",
      cada_entrada_recibe_un_score: "Cada entrada recibe un score de confianza de 0 a 100 según su historial, la evidencia capturada y las anomalías detectadas.",
      calle_bloque: "Calle / Bloque",
      captura_biometrica_al_validar_qr: "Captura biométrica al validar el QR para bitácora",
      cargando_destinos: "Cargando destinos…",
      cargando_equipo: "Cargando equipo…",
      cargando_kioskos: "Cargando kioskos…",
      cargando_residentes: "Cargando residentes…",
      cargando_solicitudes: "Cargando solicitudes…",
      codigo_de_vinculacion_para_residentes: "Código de vinculación para residentes",
      codigo_verificado_define_los_datos: "Código verificado. Define los datos de este punto de acceso.",
      comparte_este_codigo_con_los_residentes: "Comparte este código con los residentes para que puedan registrarse y vincular su casa desde la app ",
      con_autopass_encendido: "Con AutoPass encendido, se aprueba sola a partir de este porcentaje. Más alto = más estricto. Recomendado 80.",
      con_invitacion_qr: "Con invitación QR",
      crea_una_cuenta_de_vigilante: "Crea una cuenta de vigilante para monitorear solicitudes. Puedes hacerlo después desde la sección Kioskos → Equipo.",
      cuando_un_habitante_solicite_unirse: "Cuando un habitante solicite unirse desde la app, aparecerá aquí para tu aprobación.",
      da_de_alta_varios_destinos: "Da de alta varios destinos de una calle a la vez. El tipo se aplica a lo que agregues a continuacion, asi que puedes mezclar casas y departamentos en el mismo alta.",
      dato_de_referencia_que_tu_capturas: "Dato de referencia que tú capturas — no está verificado. Nunca se usa para notificar automáticamente, solo para que sepas a quién llamar.",
      define_como_se_llama_tu_comunidad: "Define cómo se llama tu comunidad o edificio. Esto aparecerá en la app del residente.",
      define_que_pasos_son_obligatorios_y: "Define qué pasos son obligatorios y ",
      documento_curp_ine: "Documento (CURP/INE)",
      el_visitante_completara_los_pasos: "El visitante completará los pasos de arriba hacia abajo. Los pasos desactivados se omitirán por completo. Un invitado con pase QR nunca ve el paso de Motivo -- quien lo invitó ya lo capturó al crear la invitación.",
      el_visitante_ve_un_sello_verificado: "El visitante ve un sello \"Verificado por IA\" con el nivel de confianza; el vigilante puede tocarlo, meter su PIN de operador y ver el detalle completo (factores, recomendaciones)",
      en_vivo_label: "En vivo",
      exigir_escaneo_de_credencial_fisica: "Exigir escaneo de credencial física aunque el pase QR sea válido",
      flujo_sin_invitacion_secuencia: "Flujo Sin Invitación (Secuencia de Pasos)",
      general_y_pantalla: "General y Pantalla",
      historial_de_reportes_ia_title: "Historial de reportes IA",
      hola_saludo: "Hola",
      horario_de_operacion: "Horario de Operación",
      hoy_option: "Hoy",
      ultimos_30_dias: "Últimos 30 días",
      regenerar_pin_button: "Regenerar",
      regenerar_pin_confirmar_titulo: "¿Regenerar PIN?",
      regenerar_pin_confirmar_texto: "El PIN anterior deja de funcionar de inmediato. Vas a necesitar comunicarle el nuevo código al residente.",
      regenerar_pin_ok_toast: "PIN regenerado",
      regenerar_pin_error_toast: "No se pudo regenerar el PIN",
      ine_identificacion_obligatoria: "INE / Identificación obligatoria",
      las_casas_o_edificios_se_agregan_despues: "Las casas o edificios se agregan después, desde Instalación — para arrancar solo necesitas un kiosko activo. Abre la app en el dispositivo, mostrará un código, y actívalo aquí.",
      lo_hare_despues: "Lo haré después →",
      mostrar_analisis_de_ia_en_kiosko: "Mostrar análisis de IA en el kiosko",
      nota_dos_puntos: "Nota: ",
      nuevo_destino_btn: "Nuevo destino",
      nuevo_kiosko_btn: "Nuevo kiosko",
      numero_vigilante_admin_boton_llamar_global: "Número del vigilante/admin para el botón \"Llamar al administrador\" de todos los kioskos de este centro -- funciona aunque el kiosko no tenga internet",
      numero_vigilante_admin_boton_llamar_kiosko: "Número del vigilante/admin para el botón \"Llamar al administrador\" del kiosko -- funciona aunque el kiosko no tenga internet.",
      numeros_o_identificadores: "Números o Identificadores ",
      opcional_paren: "(opcional)",
      para_elegir_el_orden_exacto: " para elegir el orden exacto en que aparecerán en la pantalla del kiosko.",
      pase_qr_invitacion_tab: "Pase QR (Invitación)",
      pendientes_stat_lower: "pendientes",
      que_evidencia_se_usa_para_ligar: "Qué evidencia se usa para ligar una visita con su historial (recurrencia, anomalías) y para el score -- no si se pide capturarla, eso está en las otras pestañas. Apaga una si el dato de prueba se repite entre personas distintas (mismo vehículo, mismo rostro o INE de prueba en una demo) y el análisis lo leería como \"el mismo visitante recurrente\" sin serlo.",
      que_tanto_debe_parecer_la_cara: "Qué tanto se debe parecer la cara para que el kiosko dé por buena la identidad. Más alto = más estricto, más rechazos legítimos. Recomendado 85.",
      resumen_y_analisis_de_actividad: "Resumen y Análisis de Actividad",
      saltar_por_ahora: "Saltar por ahora →",
      score_de_confianza_y_autopass: "Score de Confianza y AutoPass",
      se_agregan_con_el_tipo_elegido: "(se agregan con el tipo elegido arriba)",
      siguiente_flecha: "Siguiente →",
      sin_invitacion_tab: "Sin Invitación",
      solo_marcadas_por_ia: "Solo marcadas por IA",
      tiempos_y_pantalla_de_exito: "Tiempos y Pantalla de Éxito",
      tipo_destino_otro: "Otro",
      tipo_label_generic: "Tipo",
      title_panel_admin: "AUTOnomIA · Panel de administración",
      todas_las_entradas_procesadas: "Todas las entradas han sido procesadas. Se actualiza cada 15 segundos.",
      ubicacion_referencia: "Ubicación / Referencia",
      ver_en_residentes: "Ver en Residentes",
      ver_historial: "Ver historial ›",
      verificaciones_en_pase_qr_pin: "Verificaciones en Pase QR / PIN",
      visitas_hoy_stat_lower: "visitas hoy",
      volver_a_kioskos: "Volver a Kioskos",
      tipo_destino_local_comercial: "Local Comercial",
      tipo_destino_lote_terreno: "Lote / Terreno",
      accesos_pendientes_de_aprobacion: "Accesos pendientes de aprobación",
      activa_tu_primer_kiosko: "Activa tu primer kiosko",
      activa_tu_primer_kiosko_o_punto_de_acceso_para_emp: "Activa tu primer kiosko o punto de acceso para empezar a recibir visitantes.",
      activar_kiosko: "Activar kiosko",
      actualiza_el_nombre_tipo_o_ubicacion_de_este_punto: "Actualiza el nombre, tipo o ubicación de este punto de acceso.",
      actualizado: "Actualizado: ",
      agrega_a_tu_equipo: "Agrega a tu equipo",
      agrupar_por_calle: "Agrupar por calle",
      agrupar_por_destino: "Agrupar por destino",
      agrupar_por_rol: "Agrupar por rol",
      agrupar_por_tipo_de_destino: "Agrupar por tipo de destino",
      anadir: "Añadir",
      apellido_paterno_opcional: "Apellido paterno (opcional)",
      aprobar_accesos_recurrentes_seguros_sin_intervenci: "Aprobar accesos recurrentes seguros sin intervención manual",
      aprobar_automaticamente_visitantes_de_confianza: "Aprobar automáticamente visitantes de confianza",
      aprobar_o_rechazar_accesos_en_espera: "Aprobar o rechazar accesos en espera",
      cerrar: "Cerrar",
      cerrar_sesion: "Cerrar sesión",
      change_pass_optional: "Cambiar contraseña (opcional)",
      codigo_del_kiosko: "Código del kiosko",
      confianza_minima_para_aprobar_sola: "Confianza mínima para aprobar sola (%)",
      configura_tu_centro_habitacional: "Configura tu centro habitacional",
      configuracion_guardada: "Configuración guardada.",
      confirmacion_de_placa_vehicular: "Confirmación de placa vehicular",
      contacto_de_referencia_sin_verificar: "Contacto de referencia (sin verificar)",
      contacto_del_destino: "Contacto del destino",
      copiar: "Copiar",
      crea_el_primer_destino_para_que_los_visitantes_pue: "Crea el primer destino para que los visitantes puedan indicar a dónde van.",
      crea_el_primer_vigilante_para_que_pueda_monitorear: "Crea el primer vigilante para que pueda monitorear solicitudes en tiempo real.",
      crear_destinos: "Crear destinos",
      crear_kiosko: "Crear kiosko",
      crear_vigilante: "Crear vigilante",
      cualquier_fecha: "Cualquier fecha",
      cuando_apruebes_una_solicitud_la_persona_aparecera: "Cuando apruebes una solicitud, la persona aparecerá aquí.",
      datos_principales_y_tipo_de_acceso_de_este_punto_d: "Datos principales y tipo de acceso de este punto de control.",
      define_si_admite_peatones_o_vehiculos: "Define si admite peatones o vehículos",
      departamento: "Departamento",
      descripcion: "Descripción",
      detalle_de_entrada: "Detalle de entrada",
      detalle_del_residente: "Detalle del residente",
      direccion: "Dirección",
      editar: "Editar",
      editar_kiosko: "Editar kiosko",
      el_vigilante_solo_puede_ver_y_gestionar_solicitude: "El vigilante solo puede ver y gestionar solicitudes en tiempo real.",
      elige_un_acceso_del_menu_de_arriba_para_ver_y_edit: "Elige un acceso del menú de arriba para ver y editar su configuración.",
      entradas_hoy: "Entradas hoy",
      entradas_recientes: "Entradas recientes",
      espanol: "Español",
      exigencia_del_reconocimiento_facial: "Exigencia del reconocimiento facial (%)",
      filtros_por_tipo_residente_invitado_o_sin_app: "Filtros por tipo: residente, invitado o sin app",
      foto_de_rostro_de_confirmacion: "Foto de rostro de confirmación",
      guardar: "Guardar",
      guardar_configuracion: "Guardar configuración",
      guardar_y_cerrar: "Guardar y cerrar",
      horario_de_cierre: "Horario de cierre",
      horario_de_inicio: "Horario de inicio",
      idioma_de_la_interfaz: "Idioma de la interfaz",
      idioma_en_que_se_muestran_los_textos_del_kiosko: "Idioma en que se muestran los textos del kiosko",
      informacion_del_centro_habitacional: "Información del centro habitacional",
      informacion_del_kiosko: "Información del kiosko",
      ingles: "Inglés",
      iniciar_sesion: "Iniciar sesión",
      kiosko_activo_desde_esta_hora: "Kiosko activo desde esta hora",
      kiosko_activo_hasta_esta_hora: "Kiosko activo hasta esta hora",
      mensaje_de_bienvenida: "Mensaje de bienvenida",
      mensaje_de_bienvenida_2: "Mensaje de bienvenida ",
      mi_perfil: "Mi perfil",
      miembros_del_centro_habitacional: "Miembros del centro habitacional",
      mis_kioskos: "Mis kioskos",
      modo_visual: "Modo visual",
      new_password: "Nueva contraseña",
      no_has_agregado_ningun_numero: "No has agregado ningún número",
      no_hay_reportes_en_este_rango: "No hay reportes en este rango.",
      nombre_del_acceso: "Nombre del acceso",
      nombre_del_kiosko: "Nombre del kiosko",
      nombre_opcional: "Nombre (opcional)",
      nuevo_vigilante: "Nuevo vigilante",
      nuevos_destinos: "Nuevos destinos",
      omitir: "Omitir",
      orden_de_ejecucion: "Orden de ejecución:",
      paleta_de_colores_que_veran_los_visitantes_en_el_k: "Paleta de colores que verán los visitantes en el kiosko",
      parametros_y_reglas_de_acceso: "Parámetros y reglas de acceso",
      pass_optional_hint: "Déjalo en blanco si solo deseas actualizar tus datos personales.",
      peatonal: "Peatonal",
      puntos_de_acceso_y_su_configuracion: "Puntos de acceso y su configuración",
      que_cuenta_para_el_analisis: "Qué cuenta para el análisis",
      registro_de_matricula_si_el_invitado_ingresa_en_ve: "Registro de matrícula si el invitado ingresa en vehículo",
      reglas_de_seguridad_cuando_una_persona_llega_con_i: "Reglas de seguridad cuando una persona llega con invitación generada desde la app.",
      residentes_con_telefono_verificado: "Residentes con teléfono verificado",
      residentes_lo_usan_para_unirse: ". Los residentes lo usan para unirse desde la app.",
      revocar_seleccionados: "Revocar seleccionados",
      segundos_de_inactividad_antes_de_cancelar_un_regis: "Segundos de inactividad antes de cancelar un registro incompleto",
      segundos_que_dura_la_pantalla_de_bienvenidaapertur: "Segundos que dura la pantalla de bienvenida/apertura antes de volver al inicio",
      selecciona_un_kiosko: "Selecciona un kiosko",
      sin_actividad_de_accesos_reciente_para_analizar: "Sin actividad de accesos reciente para analizar.",
      sin_agrupar: "Sin agrupar",
      sin_destinos_registrados: "Sin destinos registrados",
      sin_entradas_registradas: "Sin entradas registradas",
      sin_invitacion_sin_app: "Sin invitación (sin app)",
      sin_kioskos_registrados: "Sin kioskos registrados",
      sin_residentes_activos: "Sin residentes activos",
      sin_vigilantes_registrados: "Sin vigilantes registrados",
      solicitudes_pendientes: "Solicitudes pendientes",
      telefono: "Teléfono",
      telefono_de_contacto: "Teléfono de contacto",
      tema_que_veran_los_visitantes: "Tema que verán los visitantes",
      tema_visual: "Tema visual",
      texto_inicial_en_pantalla_principal: "Texto inicial en pantalla principal",
      tiempo_de_autoregreso_en_exito_seg: "Tiempo de autoregreso en éxito (seg)",
      tiempo_de_espera_maximo_seg: "Tiempo de espera máximo (seg)",
      tiempos: "Tiempos",
      tipo_de_kiosko: "Tipo de kiosko",
      tu_codigo_publico_sera: "Tu código público será: ",
      ubicacion: "Ubicación ",
      vehicular: "Vehicular",
      ver_bitacora_completa: "Ver bitácora completa",
      verificar_codigo: "Verificar código",
      visibilidad_en_el_kiosko: "Visibilidad en el kiosko",
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
      casa_destino: "Destination",
      placa: "License plate",
      no_placa: "No plate",
      autorizado_por: "Authorized by",
      sin_resolver: "Unresolved",
      autorizador_admin: "Admin",
      autorizador_residente: "Resident",
      autorizador_agente: "AI agent",
      autorizador_sistema: "System (no response)",
      autorizador_propio: "Self check-in",
      visits: n => `${n} entr${n !== 1 ? "ies" : "y"} recorded`,
      hello: name => `Hello, ${name}`,
      nav_inicio: "Home",
      nav_solicitudes: "Requests",
      nav_residentes: "Residents",
      nav_kioskos: "Kiosks",
      nav_instalacion: "Complex",
      tab_activos: "Active",
      tab_solicitudes: "Requests",
      tab_enrolamientos: "Enrolled guests",
      enrolamientos_sub: "People with frequent face/QR access that a resident set up -- not residents themselves, they get in without an invitation each time.",
      cargando_enrolamientos: "Loading enrolled guests…",
      sin_enrolamientos: "No enrolled guests",
      sin_enrolamientos_detalle: "When a resident gives someone frequent face access, they'll show up here.",
      enrolado_por_label: "Enrolled by",
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
      approbar: "Approve",
      rechazar: "Reject",
      sin_solicitudes: "No pending requests",
      sin_solicitudes_text: "When someone requests access, they'll appear here.",
            confirmar_button: "Confirm",
      confirmar_pregunta: "Confirm?",
      stream_conectado: "Stream connected",
      stream_desconectado: "Stream disconnected",
      asistencia_urgente_sse: "Urgent assistance requested at the kiosk",
      nuevo_visitante: "New visitor",
      alerta_revision_manual: "Alert: Requires manual review:",
      nueva_solicitud_toast: "New request:",
            google_login_fallido: "Google sign-in failed",
      error_conexion: "Connection error",
            tema_claro_corto: "Light",
      tema_oscuro_corto: "Dark",
            periodo_label: "Period:",
      ultimo_periodo: "Latest period",
      total_visitas_pill: "Total visits",
      total_registradas_pill: "Total recorded",
      analisis_ia_header: "Artificial Intelligence Analysis",
      resumen_automatico_sin_ia: "Automatic summary · AI unavailable",
      actividad_acumulada_reciente: "Recent cumulative activity",
      resumen_dinamico_intro: (total, aprob, rech, rev) => `**${total} accesses** have been recorded in the system (${aprob} approved, ${rech} rejected, ${rev} pending resolution).`,
      resumen_dinamico_con_rechazos: "Rejected entries were identified that suggest attention from security or administration.",
      resumen_dinamico_normal: "Access flow is operating normally with a high approval rate.",
      historial_no_disponible: "Could not load the history.",
            sin_identificador_historial: "No identifier to search history.",
      primera_visita_registrada: "First visit recorded.",
            visitante_sin_nombre: "Unnamed visitor",
      evidencia_documento: "Document",
      evidencia_rostro: "Face",
      evidencia_placa: "License plate",
      evidencia_sin_fotos: "This entry has no photos on record.",
      ver_completa: "View full size",
            kio_nunca_conectado: "Never connected",
      kio_en_linea: "Online",
      kio_desconectado_hace: "Disconnected",
      con_analisis_ia: "With AI analysis",
      revisada_por_ia: "Reviewed by AI",
            configurar_kiosko_title: "Configure kiosk",
            ingresa_codigo_formato: "Enter the code in XXXX-XXXX format",
      codigo_invalido_o_usado: "Invalid or already used code",
      codigo_no_activo_o_expiro: "The code is not active or has expired",
      error_crear_kiosko: "Error creating kiosk",
      kiosko_creado_sin_vincular: "Kiosk created but could not be linked to the device",
      kiosko_configurado_listo: "Kiosk configured and ready",
      kiosko_activado_toast: "Kiosk activated. Configure it anytime from Kiosks.",
            error_generico: "Error",
      kiosko_actualizado_toast: "Kiosk updated",
      nombre_kiosko_obligatorio: "The kiosk name is required",
      error_actualizar_info_kiosko: "Error updating kiosk information",
            pipeline_rostro_title: "Face Photo",
      pipeline_rostro_desc: "Facial capture for verification and recognition",
      pipeline_destino_title: "Destination Selection",
      pipeline_destino_desc: "Search and selection of street, building, or house",
      pipeline_placa_title: "Vehicle License Plate Capture",
      pipeline_placa_desc: "License plate scan (required for vehicle access)",
      pipeline_ine_title: "ID / Identification Scan",
      pipeline_ine_desc: "ID scan with OCR (optional depending on hardware)",
      pipeline_motivo_title: "Reason for visit",
      pipeline_motivo_desc: "One-tap chips (Package, Service, Visit, Vendor, Other). A guest with a QR pass doesn't see this -- whoever invited them already captured it.",
      no_aplica_kiosko_peatonal: "Does not apply to pedestrian kiosks",
      no_disponible_kiosko_peatonal: "Not available on pedestrian kiosk",
      arrastrar_para_reordenar: "Drag to reorder",
      desactivado_no_aplica_peatonal: "Disabled (does not apply to pedestrian kiosks)",
      mover_arriba: "Move up",
      mover_abajo: "Move down",
      eliminar_destino_title: "Delete destination",
      tiene_contacto_referencia_title: "Has a reference contact",
            no_pudo_cargar_config_kiosko: "Could not load kiosk configuration",
      configuracion_label: "Settings",
      configuracion_de_kiosko: "Kiosk settings",
      error_guardar_configuracion: "Error saving configuration",
      kiosko_config_guardados_ok: "Kiosk and configuration saved successfully",
            rol_admin_corto: "Admin",
      rol_vigilante_corto: "Security guard",
      eliminar_vigilante_title: "Delete guard",
      confirmar_eliminar_vigilante: "Delete this guard?",
      no_pudo_eliminar_vigilante: "Could not delete the guard",
      error_crear_vigilante: "Error creating guard",
      vigilante_creado_todo_listo: "Guard created. All set!",
      vigilante_creado_correctamente: "Guard created successfully",
            hero_ahora: "now",
            error_al_guardar: "Error saving",
      correo_pass_obligatorios: "Email and password are required",
            tipo_destino_casa: "House",
      tipo_destino_departamento: "Apt.",
      tipo_destino_edificio: "Building",
      tipo_destino_oficina: "Office",
      tipo_destino_local: "Unit",
      tipo_destino_bodega: "Warehouse",
      tipo_destino_lote: "Lot",
            error_cargar_destinos: "Error loading destinations",
      sin_calle: "No street",
      no_pudo_guardar_contacto: "Could not save the contact",
      confirmar_eliminar_destino: "Delete this destination?",
      confirmar_eliminar_destino_texto: "Residents already linked to this house won't be deleted, but the destination will no longer be available for new registrations.",
      no_pudo_eliminar_destino: "Could not delete the destination",
      ingresa_nombre_calle_bloque: "Enter the street or block name",
      agrega_numero_identificador: "Add at least one number or identifier",
      error_crear_destinos: "Error creating destinations",
      destinos_creados_ok: "Destinations created successfully",
            centro_actualizado_toast: "Residential center updated",
      copiado_exclamacion: "Copied!",
      codigo_copiado_portapapeles: "Code copied to clipboard",
            sin_calle_registrada: "No street on record",
      sin_tipo: "No type",
      residentes_label: "Residents",
      invitados_frecuentes_label: "Frequent guests",
      sin_destino: "No destination",
            sin_nombre: "No name",
      residente_activo_label: "Active resident",
      invitado_frecuente_badge: "Frequent guest",
      sin_casa: "No house",
      alta_label: "Joined",
      ver_detalle_label: "View details",
            filtrando_por: "Filtering by:",
            confirmar_revocar_n: n => `Revoke access for ${n} resident${n !== 1 ? 's' : ''}?`,
      revocar_acceso_texto: "They will no longer be able to enter by PIN or facial recognition. This does not delete their Kigo account, only their access to this center.",
      revocar_button: "Revoke",
      no_pudo_revocar_reintentar: "Could not revoke access. Try again.",
      nav_ayuda: "Help",
      ayuda_title: "Help",
      asistencias_urgentes_sub: "Urgent assistance requests from the kiosks",
      ayuda_filtro_pendientes: "Pending",
      ayuda_filtro_todas: "All",
      ayuda_cargando: "Loading assistance requests…",
      ayuda_sin_solicitudes: "No assistance requests",
      ayuda_sin_solicitudes_sub: "When a visitor asks for urgent help from a kiosk, it will show up here.",
      ayuda_sin_motivo: "No reason given",
      ayuda_marcar_resuelta: "Mark resolved",
      ayuda_estado_pendiente: "Pending",
      ayuda_estado_resuelta: "Resolved",
      ayuda_resuelta_hace: h => `Resolved ${h} ago`,
      ayuda_motivo_label: "Reason",
      ayuda_guardar_motivo: "Save reason",
      resetear_confianza_btn: "Reset trust",
      resetear_confianza_titulo: "Reset trust with this person?",
      resetear_confianza_texto: "Forgets their entire prior history for the trust calculation -- their next visit is evaluated from scratch, as if it were the first time. This does not delete the history, it just stops counting for the analysis.",
      no_pudo_resetear_confianza: "Could not reset trust. Try again.",
      confianza_reseteada_ok: "Trust reset",
      // __NEW_I18N_EN_MARKER__
      // --- fix modal residente: claves faltantes ---
      activo_badge: "Active",
      app_kigo_qr_desc: "Invitations and own access QR",
      app_kigo_qr_label: "Kigo App / QR",
      aprobar_solicitud_button: "Approve request",
      configurado_label: "Set",
      destino_casa_label: "Destination / House",
      documento_identidad_ine_label: "ID document (INE)",
      documento_ine_alt: "ID document",
      enrolado_label: "Enrolled",
      ine_de_label: "ID of",
      metodos_acceso_identidad_label: "Access & identity methods",
      miembro_desde_label: "Member since",
      pendiente_aprobacion_label: "Pending approval",
      pin_de_acceso_desc: "Numeric PIN to enter without the app",
      pin_de_acceso_label: "Access PIN",
      reconocimiento_facial_ia_desc: "1:N recognition at the kiosk",
      reconocimiento_facial_ia_label: "Facial recognition (AI)",
      revocar_acceso_button: "Revoke access",
      rostro_de_label: "Face of",
      sin_casa_asignada: "No house assigned",
      sin_pin_label: "No PIN",
      sin_rostro_label: "No face",
      solicitado_el_label: "Requested on",
      solicitud_pendiente_badge: "Pending request",
      ver_entradas_residente_button: "View entries",
      // --- i18n dashboard: segunda pasada (completado) ---
      abre_la_app_en_el_dispositivo_del_kiosko_activacion: "Open the app on the kiosk device — it will show an activation code. Type it here.",
      ajusta_los_parametros_basicos: "Adjust the basic settings. You can change them later from the Kiosks → Settings section.",
      analisis_de_ia_tab: "AI Analysis",
      apariencia_y_bienvenida: "Appearance & Welcome",
      aprobacion_automatica_ia_autopass: "Automatic AI approval (AutoPass)",
      aprobadas_stat_lower: "approved",
      arrastra_las_tarjetas: "drag the cards",
      atras_flecha: "← Back",
      auto_pass_con_ia: "Auto-pass with AI",
      ayer_option: "Yesterday",
      cada_entrada_recibe_un_score: "Each entry receives a confidence score from 0 to 100 based on its history, the captured evidence, and detected anomalies.",
      calle_bloque: "Street / Block",
      captura_biometrica_al_validar_qr: "Capture biometrics when validating the QR for the log",
      cargando_destinos: "Loading destinations…",
      cargando_equipo: "Loading team…",
      cargando_kioskos: "Loading kiosks…",
      cargando_residentes: "Loading residents…",
      cargando_solicitudes: "Loading requests…",
      codigo_de_vinculacion_para_residentes: "Linking code for residents",
      codigo_verificado_define_los_datos: "Code verified. Set the details for this access point.",
      comparte_este_codigo_con_los_residentes: "Share this code with residents so they can register and link their house from the ",
      con_autopass_encendido: "With AutoPass on, it self-approves from this percentage onward. Higher = stricter. Recommended 80.",
      con_invitacion_qr: "With QR invitation",
      crea_una_cuenta_de_vigilante: "Create a guard account to monitor requests. You can do this later from the Kiosks → Team section.",
      cuando_un_habitante_solicite_unirse: "When a resident requests to join from the app, they'll appear here for your approval.",
      da_de_alta_varios_destinos: "Add multiple destinations on the same street at once. The type applies to everything you add next, so you can mix houses and apartments in the same batch.",
      dato_de_referencia_que_tu_capturas: "Reference info that you enter — unverified. Never used to notify automatically, only so you know who to call.",
      define_como_se_llama_tu_comunidad: "Set the name of your community or building. This will appear in the resident app.",
      define_que_pasos_son_obligatorios_y: "Define which steps are required and ",
      documento_curp_ine: "Document (CURP/INE)",
      el_visitante_completara_los_pasos: "The visitor will complete the steps from top to bottom. Disabled steps are skipped entirely. A guest with a QR pass never sees the Reason step -- whoever invited them already captured it when creating the invitation.",
      el_visitante_ve_un_sello_verificado: "The visitor sees a \"Verified by AI\" badge with the confidence level; the guard can tap it, enter their operator PIN, and see the full detail (factors, recommendations)",
      en_vivo_label: "Live",
      exigir_escaneo_de_credencial_fisica: "Require physical ID scan even if the QR pass is valid",
      flujo_sin_invitacion_secuencia: "No-Invitation Flow (Step Sequence)",
      general_y_pantalla: "General & Display",
      historial_de_reportes_ia_title: "AI report history",
      hola_saludo: "Hi",
      horario_de_operacion: "Operating Hours",
      hoy_option: "Today",
      ultimos_30_dias: "Last 30 days",
      regenerar_pin_button: "Regenerate",
      regenerar_pin_confirmar_titulo: "Regenerate PIN?",
      regenerar_pin_confirmar_texto: "The old PIN stops working immediately. You'll need to tell the resident their new code.",
      regenerar_pin_ok_toast: "PIN regenerated",
      regenerar_pin_error_toast: "Could not regenerate the PIN",
      ine_identificacion_obligatoria: "ID / INE required",
      las_casas_o_edificios_se_agregan_despues: "Houses or buildings are added later, from Facility — to get started you only need one active kiosk. Open the app on the device, it will show a code, and activate it here.",
      lo_hare_despues: "I'll do it later →",
      mostrar_analisis_de_ia_en_kiosko: "Show AI analysis on the kiosk",
      nota_dos_puntos: "Note: ",
      nuevo_destino_btn: "New destination",
      nuevo_kiosko_btn: "New kiosk",
      numero_vigilante_admin_boton_llamar_global: "Guard/admin phone number for the \"Call administrator\" button across all kiosks in this center -- works even if the kiosk has no internet",
      numero_vigilante_admin_boton_llamar_kiosko: "Guard/admin phone number for the kiosk's \"Call administrator\" button -- works even if the kiosk has no internet.",
      numeros_o_identificadores: "Numbers or Identifiers ",
      opcional_paren: "(optional)",
      para_elegir_el_orden_exacto: " to choose the exact order they'll appear on the kiosk screen.",
      pase_qr_invitacion_tab: "QR Pass (Invitation)",
      pendientes_stat_lower: "pending",
      que_evidencia_se_usa_para_ligar: "Which evidence is used to link a visit to its history (recurrence, anomalies) and for the score -- not whether it's requested for capture, that's on the other tabs. Turn one off if the test data repeats across different people (same vehicle, same test face or ID in a demo) and the analysis would read it as \"the same recurring visitor\" without it being one.",
      que_tanto_debe_parecer_la_cara: "How closely the face must match for the kiosk to accept the identity. Higher = stricter, more legitimate rejections. Recommended 85.",
      resumen_y_analisis_de_actividad: "Activity Summary and Analysis",
      saltar_por_ahora: "Skip for now →",
      score_de_confianza_y_autopass: "Confidence Score & AutoPass",
      se_agregan_con_el_tipo_elegido: "(added using the type selected above)",
      siguiente_flecha: "Next →",
      sin_invitacion_tab: "No Invitation",
      solo_marcadas_por_ia: "Only flagged by AI",
      tiempos_y_pantalla_de_exito: "Timings & Success Screen",
      tipo_destino_otro: "Other",
      tipo_label_generic: "Type",
      title_panel_admin: "AUTOnomIA · Admin Panel",
      todas_las_entradas_procesadas: "All entries have been processed. Updates every 15 seconds.",
      ubicacion_referencia: "Location / Reference",
      ver_en_residentes: "View in Residents",
      ver_historial: "View history ›",
      verificaciones_en_pase_qr_pin: "Checks on QR Pass / PIN",
      visitas_hoy_stat_lower: "visits today",
      volver_a_kioskos: "Back to Kiosks",
      tipo_destino_local_comercial: "Commercial space",
      tipo_destino_lote_terreno: "Lot / Land",
      accesos_pendientes_de_aprobacion: "Accesses pending approval",
      activa_tu_primer_kiosko: "Activate your first kiosk",
      activa_tu_primer_kiosko_o_punto_de_acceso_para_emp: "Activate your first kiosk or access point to start receiving visitors.",
      activar_kiosko: "Activate kiosk",
      actualiza_el_nombre_tipo_o_ubicacion_de_este_punto: "Update the name, type, or location of this access point.",
      actualizado: "Updated: ",
      agrega_a_tu_equipo: "Add to your team",
      agrupar_por_calle: "Group by street",
      agrupar_por_destino: "Group by destination",
      agrupar_por_rol: "Group by role",
      agrupar_por_tipo_de_destino: "Group by destination type",
      anadir: "Add",
      apellido_paterno_opcional: "Last name (optional)",
      aprobar_accesos_recurrentes_seguros_sin_intervenci: "Approve recurring, safe accesses without manual intervention",
      aprobar_automaticamente_visitantes_de_confianza: "Automatically approve trusted visitors",
      aprobar_o_rechazar_accesos_en_espera: "Approve or reject pending accesses",
      cerrar: "Close",
      cerrar_sesion: "Log out",
      change_pass_optional: "Change password (optional)",
      codigo_del_kiosko: "Kiosk code",
      confianza_minima_para_aprobar_sola: "Minimum confidence to auto-approve (%)",
      configura_tu_centro_habitacional: "Set up your residential center",
      configuracion_guardada: "Configuration saved.",
      confirmacion_de_placa_vehicular: "License plate confirmation",
      contacto_de_referencia_sin_verificar: "Reference contact (unverified)",
      contacto_del_destino: "Destination contact",
      copiar: "Copy",
      crea_el_primer_destino_para_que_los_visitantes_pue: "Create the first destination so visitors can indicate where they're going.",
      crea_el_primer_vigilante_para_que_pueda_monitorear: "Create the first guard so they can monitor requests in real time.",
      crear_destinos: "Create destinations",
      crear_kiosko: "Create kiosk",
      crear_vigilante: "Create guard",
      cualquier_fecha: "Any date",
      cuando_apruebes_una_solicitud_la_persona_aparecera: "Once you approve a request, the person will appear here.",
      datos_principales_y_tipo_de_acceso_de_este_punto_d: "Main details and access type for this control point.",
      define_si_admite_peatones_o_vehiculos: "Defines whether it admits pedestrians or vehicles",
      departamento: "Department",
      descripcion: "Description",
      detalle_de_entrada: "Entry detail",
      detalle_del_residente: "Resident detail",
      direccion: "Address",
      editar: "Edit",
      editar_kiosko: "Edit kiosk",
      el_vigilante_solo_puede_ver_y_gestionar_solicitude: "The guard can only view and manage requests in real time.",
      elige_un_acceso_del_menu_de_arriba_para_ver_y_edit: "Choose an access point from the menu above to view and edit its configuration.",
      entradas_hoy: "Entries today",
      entradas_recientes: "Recent entries",
      espanol: "Spanish",
      exigencia_del_reconocimiento_facial: "Facial recognition strictness (%)",
      filtros_por_tipo_residente_invitado_o_sin_app: "Filters by type: resident, guest, or without app",
      foto_de_rostro_de_confirmacion: "Confirmation face photo",
      guardar: "Save",
      guardar_configuracion: "Save configuration",
      guardar_y_cerrar: "Save and close",
      horario_de_cierre: "Closing time",
      horario_de_inicio: "Opening time",
      idioma_de_la_interfaz: "Interface language",
      idioma_en_que_se_muestran_los_textos_del_kiosko: "Language the kiosk's texts are displayed in",
      informacion_del_centro_habitacional: "Residential center information",
      informacion_del_kiosko: "Kiosk information",
      ingles: "English",
      iniciar_sesion: "Log in",
      kiosko_activo_desde_esta_hora: "Kiosk active from this time",
      kiosko_activo_hasta_esta_hora: "Kiosk active until this time",
      mensaje_de_bienvenida: "Welcome message",
      mensaje_de_bienvenida_2: "Welcome message ",
      mi_perfil: "My profile",
      miembros_del_centro_habitacional: "Residential center members",
      mis_kioskos: "My kiosks",
      modo_visual: "Visual mode",
      new_password: "New password",
      no_has_agregado_ningun_numero: "You haven't added any number",
      no_hay_reportes_en_este_rango: "No reports in this range.",
      nombre_del_acceso: "Access name",
      nombre_del_kiosko: "Kiosk name",
      nombre_opcional: "Name (optional)",
      nuevo_vigilante: "New guard",
      nuevos_destinos: "New destinations",
      omitir: "Skip",
      orden_de_ejecucion: "Execution order:",
      paleta_de_colores_que_veran_los_visitantes_en_el_k: "Color palette visitors will see on the kiosk",
      parametros_y_reglas_de_acceso: "Access parameters and rules",
      pass_optional_hint: "Leave it blank if you only want to update your personal data.",
      peatonal: "Pedestrian",
      puntos_de_acceso_y_su_configuracion: "Access points and their configuration",
      que_cuenta_para_el_analisis: "What counts for the analysis",
      registro_de_matricula_si_el_invitado_ingresa_en_ve: "License plate record if the guest arrives by vehicle",
      reglas_de_seguridad_cuando_una_persona_llega_con_i: "Security rules for when someone arrives with an invitation generated from the app.",
      residentes_con_telefono_verificado: "Residents with verified phone",
      residentes_lo_usan_para_unirse: ". Residents use it to join from the app.",
      revocar_seleccionados: "Revoke selected",
      segundos_de_inactividad_antes_de_cancelar_un_regis: "Seconds of inactivity before canceling an incomplete registration",
      segundos_que_dura_la_pantalla_de_bienvenidaapertur: "Seconds the welcome/opening screen lasts before returning to the start",
      selecciona_un_kiosko: "Select a kiosk",
      sin_actividad_de_accesos_reciente_para_analizar: "No recent access activity to analyze.",
      sin_agrupar: "No grouping",
      sin_destinos_registrados: "No destinations registered",
      sin_entradas_registradas: "No entries registered",
      sin_invitacion_sin_app: "No invitation (no app)",
      sin_kioskos_registrados: "No kiosks registered",
      sin_residentes_activos: "No active residents",
      sin_vigilantes_registrados: "No guards registered",
      solicitudes_pendientes: "Pending requests",
      telefono: "Phone",
      telefono_de_contacto: "Contact phone",
      tema_que_veran_los_visitantes: "Theme visitors will see",
      tema_visual: "Visual theme",
      texto_inicial_en_pantalla_principal: "Initial text on main screen",
      tiempo_de_autoregreso_en_exito_seg: "Auto-return time on success (sec)",
      tiempo_de_espera_maximo_seg: "Maximum wait time (sec)",
      tiempos: "Timings",
      tipo_de_kiosko: "Kiosk type",
      tu_codigo_publico_sera: "Your public code will be: ",
      ubicacion: "Location ",
      vehicular: "Vehicular",
      ver_bitacora_completa: "View full log",
      verificar_codigo: "Verify code",
      visibilidad_en_el_kiosko: "Visibility on the kiosk",
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
    admin:     ["dashboard","solicitudes","visitas","detalle","residentes","kioskos","ayuda","seguridad","configuracion","instalacion","perfil"],
    vigilante: ["solicitudes","ayuda","seguridad","perfil"],
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
    badgesAmbientalesPollingId: null,
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

  // Reemplaza confirm() nativo para acciones destructivas -- se puede
  // explicar la consecuencia con más detalle que un diálogo genérico del
  // navegador, y se ve consistente con el resto del dashboard.
  function confirmarAccion({ titulo, texto, textoBoton = t("confirmar_button") }) {
    return new Promise(resolve => {
      const modal = document.getElementById("modal-confirmar");
      if (!modal) { resolve(window.confirm(texto || titulo)); return; }

      document.getElementById("confirmar-titulo").textContent = titulo || t("confirmar_pregunta");
      document.getElementById("confirmar-texto").textContent = texto || "";
      const btnAceptar = document.getElementById("confirmar-aceptar");
      const btnCancelar = document.getElementById("confirmar-cancelar");
      btnAceptar.textContent = textoBoton;

      const cerrar = (resultado) => {
        modal.hidden = true;
        btnAceptar.removeEventListener("click", onAceptar);
        btnCancelar.removeEventListener("click", onCancelar);
        resolve(resultado);
      };
      const onAceptar = () => cerrar(true);
      const onCancelar = () => cerrar(false);
      btnAceptar.addEventListener("click", onAceptar);
      btnCancelar.addEventListener("click", onCancelar);

      modal.hidden = false;
    });
  }

  function initSSE(token) {
    if (state.sseSource) { state.sseSource.close(); state.sseSource = null; }
    const url = `${API_BASE}/kioskos/solicitudes/stream?token=${encodeURIComponent(token)}`;
    const es = new EventSource(url);
    state.sseSource = es;

    const dot = document.getElementById("sse-dot");

    es.onopen = () => { if (dot) { dot.className = "sse-dot sse-dot--on"; dot.title = t("stream_conectado"); } };
    es.onerror = () => { if (dot) { dot.className = "sse-dot"; dot.title = t("stream_desconectado"); } };

    es.onmessage = e => {
      try {
        const v = JSON.parse(e.data);
        // El Hub es global (no filtra por tenant) -- todo mensaje trae
        // tenant_id (visitas y asistencia_urgente por igual) y se descarta
        // aquí si no es el del admin conectado. Antes solo se filtraba el
        // evento de asistencia urgente; una visita de OTRO fraccionamiento
        // sí llegaba a este dashboard (nombre, foto, resumen de IA incluidos).
        if (String(v.tenant_id) !== String(state.tenantId)) return;
        if (v.tipo === "asistencia_urgente") {
          mostrarToast(`🆘 ${t("asistencia_urgente_sse")}`, "urgente");
          // El toast se autodestruye a los 5s -- sin esto, si el admin no
          // lo alcanzaba a ver (o no tenía el dashboard abierto), la
          // solicitud no dejaba ningún rastro consultable después.
          loadAyudaBadge();
          if (currentNavScreen === "ayuda") loadAyuda();
          return;
        }
        if (v.tipo === "evento_seguridad") {
          mostrarToast(`⚠️ ${t("seguridad_evento_sse")}`, "urgente");
          loadSeguridadBadge();
          if (currentNavScreen === "seguridad") loadSeguridad();
          return;
        }
        const nombre = v.titular || t("nuevo_visitante");
        if (v.estado === "REVISION") {
          mostrarToast(`${t("alerta_revision_manual")} ${nombre}`, "revision");
          loadSolicitudes();
          loadAlertasIABadge();
        } else if (v.estado === "PENDIENTE") {
          mostrarToast(`${t("nueva_solicitud_toast")} ${nombre}`);
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

  function fmtTime(iso) {
    const d = new Date(iso);
    return d.toLocaleTimeString(lang === "en" ? "en-US" : "es-MX", { hour: "2-digit", minute: "2-digit" });
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
    document.querySelectorAll(".nav-btn, .mobile-nav-btn").forEach(b => b.classList.remove("active"));

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
    if (screen === "ayuda")         loadAyuda();
    if (screen === "seguridad")     loadSeguridad();
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
        errEl.textContent = data.error || t("error_generico");
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
      if (!res.ok) { errEl.textContent = data.error || t("google_login_fallido"); errEl.hidden = false; return; }
      setToken(data.access_token);
      const claims = decodeJWT(data.access_token);
      state.adminId  = claims?.admin_id;
      state.tenantId = claims?.tenant_id;
      await bootstrapApp();
    } catch { errEl.textContent = t("error_conexion"); errEl.hidden = false; }
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
    loadKioskosOfflineBadge();
    loadAyudaBadge();
    loadSeguridadBadge();
    startBadgesAmbientalesPolling();
    // state.rol viene del JWT y a veces no trae el rol real (visto con
    // login por Google) -- state.admin.rol viene de /admins/:id, directo
    // de la BD, así que es la fuente confiable para decidir si es
    // vigilante. No se toca de dónde sale state.rol en sí (se usa en más
    // lugares) -- solo se refuerza este chequeo puntual con la fuente que
    // sí es correcta, para que un vigilante nunca vea el wizard de
    // onboarding de un centro que no le corresponde crear.
    if (state.rol !== 'vigilante' && state.admin?.rol !== 'vigilante' && !state.tenant?.nombre) {
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
    stopBadgesAmbientalesPolling();
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
    if (lbl)    lbl.textContent = dark ? t("tema_claro_corto") : t("tema_oscuro_corto");
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
        tab === 'res-activos'        ? loadResidentesActivos :
        tab === 'res-solicitudes'    ? loadResidentesPendientes :
        tab === 'res-enrolamientos'  ? loadEnrolamientos : null
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
        periodoEl.textContent = (inicio && fin) ? `${t('periodo_label')} ${fmtDate(inicio)} – ${fmtDate(fin)}` : t('ultimo_periodo');
      }

      if (chipsEl) {
        chipsEl.innerHTML = `
          <div class="stat-pill"><span class="stat-pill-num">${total}</span> ${t('total_visitas_pill')}</div>
          <div class="stat-pill stat-pill--green"><span class="stat-pill-num">${aprob}</span> ${t('aprobado')}</div>
          ${rech > 0 ? `<div class="stat-pill stat-pill--red"><span class="stat-pill-num">${rech}</span> ${t('rechazado')}</div>` : ''}
          ${rev > 0 ? `<div class="stat-pill stat-pill--yellow"><span class="stat-pill-num">${rev}</span> ${t('revision')}</div>` : ''}
        `;
      }

      if (textoEl) {
        const etiqueta = generadoPorIA
          ? `<div style="display:flex;align-items:center;gap:6px;margin-bottom:8px;font-size:11px;font-weight:700;color:var(--primary);text-transform:uppercase;letter-spacing:.04em">✨ ${t('analisis_ia_header')}</div>`
          : `<div style="display:flex;align-items:center;gap:6px;margin-bottom:8px;font-size:11px;font-weight:700;color:var(--text-3);text-transform:uppercase;letter-spacing:.04em">${t('resumen_automatico_sin_ia')}</div>`;
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

      if (periodoEl) periodoEl.textContent = t('actividad_acumulada_reciente');
      if (chipsEl) {
        chipsEl.innerHTML = `
          <div class="stat-pill"><span class="stat-pill-num">${total}</span> ${t('total_registradas_pill')}</div>
          <div class="stat-pill stat-pill--green"><span class="stat-pill-num">${aprob}</span> ${t('aprobado')} (${tasaAprob}%)</div>
          ${rech > 0 ? `<div class="stat-pill stat-pill--red"><span class="stat-pill-num">${rech}</span> ${t('rechazado')}</div>` : ''}
          ${rev > 0 ? `<div class="stat-pill stat-pill--yellow"><span class="stat-pill-num">${rev}</span> ${t('revision')}</div>` : ''}
        `;
      }

      let textoDinamico = `${t('resumen_dinamico_intro')(total, aprob, rech, rev)} `;
      textoDinamico += rech > 0 ? t('resumen_dinamico_con_rechazos') : t('resumen_dinamico_normal');

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
      if (emptyEl) { emptyEl.hidden = false; emptyEl.querySelector(".empty-text").textContent = t("historial_no_disponible"); }
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
    const titular = v.titular || v.placa || (v.tipo_visitante === "RESIDENTE" ? tvLabel : t("visitante_sin_nombre"));
    return `<div class="row-item" style="grid-template-columns:minmax(0,2fr) auto minmax(0,1fr) 80px;gap:12px;align-items:center;animation-delay:${i*40}ms;cursor:pointer" data-id="${v.id}">
      <div style="min-width:0">
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

  function rolAdminLabel(rol) { return { admin: t("rol_admin_corto"), vigilante: t("rol_vigilante_corto") }[rol]; }

  function autorizadorLabel(v) {
    if (!v.autorizado_por_tipo) {
      // Entradas viejas de residente por PIN/rostro creadas antes de que
      // esas rutas empezaran a guardar AutorizadorPropio -- sin esto se ve
      // "Sin resolver" junto a un badge "APROBADO", contradictorio.
      if (v.tipo_visitante === "RESIDENTE") return t("autorizador_propio");
      return t("sin_resolver");
    }
    const map = {
      ADMIN: t("autorizador_admin"),
      RESIDENTE: t("autorizador_residente"),
      AGENTE: t("autorizador_agente"),
      SISTEMA: t("autorizador_sistema"),
      PROPIO: t("autorizador_propio"),
    };
    const tipo = map[v.autorizado_por_tipo] || v.autorizado_por_tipo;
    if (!v.autorizado_por_nombre) return tipo;
    const detalle = [rolAdminLabel(v.autorizado_por_rol) || null, v.autorizado_por_correo]
      .filter(Boolean).map(esc).join(" · ");
    return `${tipo} — ${esc(v.autorizado_por_nombre)}${detalle ? ` (${detalle})` : ""}`;
  }

  // calidad_ine viene del kiosko (EvidenciaCalidadServicio): "nitida" o
  // "media" -- nunca "borrosa", esa se rechaza antes de llegar al backend.
  const CALIDAD_INE_LABEL = { nitida: "Nítida", media: "Media" };
  function calidadIneField(v) {
    if (!v.calidad_ine) return "";
    const label = CALIDAD_INE_LABEL[v.calidad_ine] || v.calidad_ine;
    return `<div><div class="campo-label">Calidad de INE</div><div class="campo-value">${esc(label)}</div></div>`;
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
    // Antes incluía v.estadisticas, pero ese campo lo llena
    // EstadisticasPorPersona para CUALQUIER visita con persona_id (incluye
    // el auto-checkin de residente por PIN/rostro, que nunca pasa por el
    // analizador) -- terminaba marcando casi todas las filas con IA sin
    // haberla tenido. Solo resumen_ia/score_ia vienen del analizador real.
    const tieneIA = !!(v.resumen_ia || v.score_ia);
    const badgeIA = tieneIA ? `<span class="badge badge--intervenida" style="font-size:9.5px;padding:1px 6px;margin-left:6px;vertical-align:1px" title="${t('con_analisis_ia')}">IA</span>` : '';
    return `<div class="row-item vis-row-grid--list" style="animation-delay:${i*30}ms" data-id="${v.id}">
      <div style="min-width:0"><div class="row-name">${esc(v.titular)}${badgeIA}</div><div class="row-sub">${esc(v.casa_destino || "")}</div></div>
      <div><span class="badge ${tvBadge}">${esc(tvLabel)}</span></div>
      <div class="row-sub">${acceso ? esc(acceso.nombre) : `#${v.kiosko_id}`}</div>
      <div><span class="badge ${ESTADO_BADGE[v.estado] || ""}">${estadoLabel(v.estado)}</span></div>
      <div class="row-date">${fmtDateShort(v.created_at)}<div class="row-sub">${fmtTime(v.created_at)}</div></div>
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
      { url: v.foto_documento_url, label: t("evidencia_documento") },
      { url: v.foto_rostro_url,    label: t("evidencia_rostro") },
      { url: v.foto_placa_url,     label: t("evidencia_placa") },
    ].filter(f => !!f.url);

    if (!fotos.length) {
      return `<div class="evidencia-grid"><div class="evidencia-vacia">${t("evidencia_sin_fotos")}</div></div>`;
    }

    const lupa = `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="11" cy="11" r="7"/><line x1="21" y1="21" x2="16.65" y2="16.65"/><line x1="11" y1="8" x2="11" y2="14"/><line x1="8" y1="11" x2="14" y2="11"/></svg>`;

    return `<div class="evidencia-grid">${fotos.map(f => `
      <div class="evidencia-card" tabindex="0" role="button" data-foto="${esc(f.url)}" data-foto-label="${esc(f.label)}">
        <div class="evidencia-marco">
          <img class="evidencia-img" src="${esc(f.url)}" alt="${esc(f.label)}" loading="lazy">
          <span class="evidencia-zoom">${lupa}</span>
        </div>
        <div class="evidencia-pie"><span>${esc(f.label)}</span><span>${t("ver_completa")}</span></div>
      </div>`).join("")}</div>`;
  }

  // Delegado en document: la evidencia se re-renderiza en varios sitios
  // (detalle y modal de solicitud) y así no hay que recablear listeners.
  document.addEventListener("click", (e) => {
    const card = e.target.closest?.(".evidencia-card");
    if (card) abrirLightbox(card.dataset.foto, card.dataset.fotoLabel);

    const filtroVisitas = e.target.closest?.(".campo-link[data-filtro-visitas]");
    if (filtroVisitas) {
      const q = filtroVisitas.dataset.filtroVisitas;
      const fQ = document.getElementById("vis-quick-search");
      if (fQ) fQ.value = q;
      const fTipo = document.getElementById("vis-filter-tipo");
      if (fTipo) fTipo.value = "";
      const fEstado = document.getElementById("vis-filter-estado");
      if (fEstado) fEstado.value = "";
      const fFecha = document.getElementById("vis-filter-fecha");
      if (fFecha) fFecha.value = "";
      navTo("visitas");
      return;
    }

    const verDestino = e.target.closest?.(".campo-link[data-ver-destino]");
    if (verDestino) verResidentesDeDestino(verDestino.dataset.verDestino);
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
              ${s.generado_por_ia === false ? `<div style="font-size:12px;color:var(--text-3);margin-top:4px">Análisis automático (asistente de IA no disponible)</div>` : ''}
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
            ${v.intervenida ? `<span class="badge badge--intervenida">${t("revisada_por_ia")}</span>` : ""}
          </div>
          <div class="detalle-nombre">${esc(v.titular)}</div>
          <div class="row-sub" style="margin-top:4px">${acceso ? esc(acceso.nombre) : `Kiosko #${v.kiosko_id}`} · ${fmtDate(v.created_at)}</div>
          <div class="detalle-campos">
            <div><div class="campo-label">CURP</div><div class="campo-value campo-mono">${
              v.curp ? `<span class="campo-link" data-filtro-visitas="${esc(v.curp)}">${esc(v.curp)}</span>`
              : (v.persona_curp ? `<span class="campo-link" data-filtro-visitas="${esc(v.persona_curp)}">${esc(v.persona_curp)}</span> <span style="color:var(--text-3);font-weight:400;font-family:inherit">(del perfil)</span>` : "—")
            }</div></div>
            <div><div class="campo-label">${t("casa_destino")}</div><div class="campo-value">${v.casa_destino ? `<span class="campo-link" data-ver-destino="${esc(v.casa_destino)}">${esc(v.casa_destino)}</span>` : "—"}</div></div>
            <div><div class="campo-label">${t("placa")}</div><div class="campo-value">${v.placa ? `<span class="campo-link" data-filtro-visitas="${esc(v.placa)}">${esc(v.placa)}</span>` : t("no_placa")}</div></div>
            <div><div class="campo-label">Motivo</div><div class="campo-value">${v.motivo ? esc(v.motivo) : "—"}</div></div>
            <div><div class="campo-label">${t("autorizado_por")}</div><div class="campo-value">${autorizadorLabel(v)}</div></div>
            ${v.telefono ? `<div><div class="campo-label">Teléfono</div><div class="campo-value" style="display:flex;align-items:center;gap:6px;flex-wrap:wrap">
              <span class="campo-mono">${esc(v.telefono)}</span>
              <a href="tel:${esc(v.telefono)}" class="btn-contact">Llamar</a>
              <a href="https://wa.me/${esc(v.telefono.replace(/\D/g, ""))}" target="_blank" rel="noopener" class="btn-contact">WhatsApp</a>
            </div></div>` : ""}
            ${calidadIneField(v)}
          </div>
        </div>
      </div>
      ${renderEvidencia(v)}
      ${renderSeccionIA(v)}
      <div class="expediente-section">
        <div class="expediente-header">
          <span class="expediente-title">Historial de esta persona</span>
          <span class="expediente-count" id="exp-count"></span>
          ${v.persona_id ? `<button type="button" class="btn-cancel" id="btn-resetear-confianza" data-persona-id="${v.persona_id}" style="margin-left:auto;padding:4px 10px;font-size:12px">${t("resetear_confianza_btn")}</button>` : ""}
        </div>
        <div class="expediente-timeline" id="exp-timeline">
          <div class="loading-state" style="padding:20px"><div class="spinner"></div></div>
        </div>
      </div>`;

    cargarExpediente(v);
    document.getElementById("btn-resetear-confianza")?.addEventListener("click", () => resetearConfianza(v.persona_id, v.id));
  }

  async function resetearConfianza(personaId, visitaActualId) {
    const ok = await confirmarAccion({
      titulo: t("resetear_confianza_titulo"),
      texto: t("resetear_confianza_texto"),
      textoBoton: t("resetear_confianza_btn"),
    });
    if (!ok) return;
    const res = await api(`/visitas/personas/${personaId}/resetear-historial`, { method: "POST" });
    if (!res || !res.ok) {
      mostrarToast(t("no_pudo_resetear_confianza"), "err");
      return;
    }
    mostrarToast(t("confianza_reseteada_ok"), "ok");
    const v = await (await api(`/visitas/${visitaActualId}`)).json();
    cargarExpediente(v);
  }

  async function cargarExpediente(visitaActual) {
    const timeline = document.getElementById("exp-timeline");
    if (!timeline) return;

    const curp = visitaActual.curp?.trim();
    let mismaPersona = [];

    if (visitaActual.persona_id) {
      // Correlación fuerte (PersonaID) -- la misma que usa el análisis de
      // IA, más precisa que cruzar solo por CURP exacto o por nombre.
      const res = await api(`/visitas/personas/${visitaActual.persona_id}/historial`);
      if (!res || !res.ok) {
        timeline.innerHTML = renderExpEmpty(t("historial_no_disponible"));
        return;
      }
      const data = await res.json();
      mismaPersona = (data.visitas || []).sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
    } else if (curp) {
      /* /visitas/buscar devuelve VisitaResponse completo (con curp, fotos, etc.) */
      const res = await api(`/visitas/buscar?curp=${encodeURIComponent(curp)}`);
      if (!res || !res.ok) {
        timeline.innerHTML = renderExpEmpty(t("historial_no_disponible"));
        return;
      }
      const data = await res.json();
      mismaPersona = (data.visitas || []).sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
    } else {
      /* fallback: busca por nombre en la lista paginada */
      const nombre = visitaActual.nombre?.trim();
      if (!nombre) {
        timeline.innerHTML = renderExpEmpty(t("sin_identificador_historial"));
        return;
      }
      const res = await api(`/visitas/?q=${encodeURIComponent(nombre)}&page_size=100`);
      if (!res || !res.ok) {
        timeline.innerHTML = renderExpEmpty(t("historial_no_disponible"));
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
      timeline.innerHTML = renderExpEmpty(t("primera_visita_registrada"));
      return;
    }

    timeline.innerHTML = mismaPersona.map((v, i) => {
      const esCurrent = String(v.id) === String(visitaActual.id);
      const acceso = state.accesosById.get(v.kiosko_id);
      const accNombre = acceso ? esc(acceso.nombre) : `Kiosko #${v.kiosko_id}`;
      const autorizador = v.autorizado_por_nombre ? `Autorizó: ${autorizadorLabel(v)}` : null;
      const meta = [accNombre, v.casa_destino ? esc(v.casa_destino) : null, autorizador].filter(Boolean).join(" · ");
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

  // Los badges de Residentes, Bitácora (alertas IA) y Kioskos solo se
  // refrescaban al entrar a esa pantalla o al completar una acción ahí
  // mismo -- si el cambio pasaba en otra pestaña, otra sesión de admin, o
  // simplemente el tiempo avanzaba mientras el usuario veía otra pantalla,
  // se quedaban pegados en el último número que vieron (ver aprobación de
  // residente que ya no aparecía en ningún lado, pero el badge seguía en
  // 1). A diferencia de Solicitudes, que sí tiene su propio polling, estos
  // tres no tenían ninguno: corren siempre desde el login, sin importar
  // qué pantalla esté abierta.
  function startBadgesAmbientalesPolling() {
    stopBadgesAmbientalesPolling();
    state.badgesAmbientalesPollingId = setInterval(() => {
      loadResidentesPendientesBadge();
      loadAlertasIABadge();
      loadKioskosOfflineBadge();
      loadAyudaBadge();
      loadSeguridadBadge();
    }, 20000);
  }

  function stopBadgesAmbientalesPolling() {
    if (state.badgesAmbientalesPollingId) {
      clearInterval(state.badgesAmbientalesPollingId);
      state.badgesAmbientalesPollingId = null;
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

  // Cuántos kioskos están desconectados ahora mismo -- mismo criterio que
  // el punto por kiosko en la lista (estadoConexionKiosko), pero resumido
  // en un numerito en el tab "Kioskos" para que se note sin tener que
  // entrar a la lista y leer cada tarjeta.
  async function loadKioskosOfflineBadge(listaYaCargada) {
    let list = listaYaCargada;
    if (!list) {
      const res = await api("/kioskos/");
      if (!res || !res.ok) return;
      try {
        const d = await res.json();
        list = Array.isArray(d) ? d : (d.kioskos || []);
      } catch (e) { console.error(e); return; }
    }
    const offline = list.filter(a => estadoConexionKiosko(a.ultimo_ping).clase !== 'online').length;
    const text = offline > 99 ? "99+" : String(offline);
    const hidden = offline <= 0;
    const badge = document.getElementById("nav-badge-kioskos-offline");
    if (badge) { badge.textContent = text; badge.hidden = hidden; }
    const badgeMob = document.getElementById("nav-badge-kioskos-offline-mob");
    if (badgeMob) { badgeMob.textContent = text; badgeMob.hidden = hidden; }
  }

  /* ─── Ayuda (asistencias urgentes) ──────────────────── */
  // Antes el botón de "llamar al vigilante" del kiosko era 100% efímero: un
  // toast de 5s (ver el "asistencia_urgente" dentro de initSSE) y un correo,
  // sin ningún registro consultable después. Ahora el backend las persiste
  // (GET/PATCH /asistencias-urgentes/) y esta pestaña es el listado real.
  state.ayudaFiltro = "pendiente";

  async function loadAyudaBadge() {
    const res = await api("/asistencias-urgentes/?estado=pendiente");
    if (!res || !res.ok) return;
    let total = 0;
    try {
      const d = await res.json();
      total = d.total || 0;
    } catch (e) { console.error(e); return; }
    const text = total > 99 ? "99+" : String(total);
    const hidden = total <= 0;
    const badge = document.getElementById("nav-badge-ayuda");
    if (badge) { badge.textContent = text; badge.hidden = hidden; }
    const badgeMob = document.getElementById("nav-badge-ayuda-mob");
    if (badgeMob) { badgeMob.textContent = text; badgeMob.hidden = hidden; }
  }

  function showAyudaState(s) {
    ["loading", "empty", "error"].forEach(x => {
      const el = document.getElementById(`ayuda-${x}`);
      if (el) el.hidden = x !== s;
    });
    const rows = document.getElementById("ayuda-rows");
    if (rows) rows.hidden = s !== "rows";
  }

  async function loadAyuda() {
    showAyudaState("loading");
    const query = state.ayudaFiltro === "pendiente" ? "?estado=pendiente" : "";
    const res = await api(`/asistencias-urgentes/${query}`);
    if (!res || !res.ok) { showAyudaState("error"); return; }

    let asistencias = [];
    try {
      const d = await res.json();
      asistencias = d.asistencias || [];
    } catch (e) { console.error(e); showAyudaState("error"); return; }

    loadAyudaBadge();

    if (asistencias.length === 0) { showAyudaState("empty"); return; }

    // Cache en memoria para que abrirAyudaDetalle no tenga que volver a
    // pedirle al backend el mismo registro que ya está en pantalla.
    state.ayudaCache = new Map(asistencias.map(a => [String(a.id), a]));

    const container = document.getElementById("ayuda-rows");
    if (!container) return;
    container.innerHTML = asistencias.map((a, i) => renderAyudaRow(a, i)).join("");
    container.querySelectorAll("[data-resolver-ayuda]").forEach(btn => {
      btn.addEventListener("click", (e) => {
        e.stopPropagation();
        resolverAyuda(btn.dataset.resolverAyuda);
      });
    });
    container.querySelectorAll("[data-ayuda-detalle]").forEach(card => {
      card.addEventListener("click", () => abrirAyudaDetalle(card.dataset.ayudaDetalle));
      card.addEventListener("keydown", (e) => {
        if (e.key === "Enter" || e.key === " ") { e.preventDefault(); abrirAyudaDetalle(card.dataset.ayudaDetalle); }
      });
    });
    showAyudaState("rows");
  }

  function renderAyudaRow(a, i) {
    const pendiente = a.estado === "pendiente";
    const badgeClase = pendiente ? "badge--pendiente" : "badge--aprobado";
    const badgeTexto = pendiente ? t("ayuda_estado_pendiente") : t("ayuda_estado_resuelta");
    const sub = pendiente
      ? fmtElapsed(a.created_at)
      : (a.resuelta_at ? STRINGS[lang].ayuda_resuelta_hace(fmtElapsed(a.resuelta_at)) : "");
    return `<div class="sol-card" style="animation-delay:${i * 40}ms" data-ayuda-detalle="${a.id}" role="button" tabindex="0">
      <div class="sol-card-left">
        <div class="feed-dot"></div>
        <div>
          <div class="row-name">${esc(a.kiosko_nombre || `Kiosko #${a.kiosko_id}`)} <span class="badge ${badgeClase}">${badgeTexto}</span></div>
          <div class="row-sub">${esc(a.motivo && a.motivo.trim() ? a.motivo : t("ayuda_sin_motivo"))} · ${fmtDate(a.created_at)}${sub && !pendiente ? ` · ${sub}` : ""}</div>
        </div>
      </div>
      ${pendiente ? `<div class="sol-card-actions"><button class="btn-aprobar" data-resolver-ayuda="${a.id}">${t("ayuda_marcar_resuelta")}</button></div>` : ""}
    </div>`;
  }

  async function resolverAyuda(id) {
    const res = await api(`/asistencias-urgentes/${id}/resolver`, { method: "PATCH" });
    if (!res || !res.ok) return;
    loadAyuda();
  }

  // Abre el detalle de una asistencia con un textarea editable de motivo --
  // sin esto, un motivo vacío (lo más común: el kiosko lo manda opcional)
  // se quedaba vacío para siempre, sin forma de que el admin lo anotara al
  // atenderla.
  function abrirAyudaDetalle(id) {
    const a = state.ayudaCache?.get(String(id));
    const modal = document.getElementById("modal-ayuda");
    if (!modal || !a) return;

    const pendiente = a.estado === "pendiente";
    const badgeClase = pendiente ? "badge--pendiente" : "badge--aprobado";
    const badgeTexto = pendiente ? t("ayuda_estado_pendiente") : t("ayuda_estado_resuelta");

    modal.innerHTML = `<div class="modal-box">
      <div style="display:flex;align-items:flex-start;justify-content:space-between;gap:12px;margin-bottom:4px">
        <div>
          <div class="badge ${badgeClase}" style="margin-bottom:8px;display:inline-block">${badgeTexto}</div>
          <div class="modal-title">${esc(a.kiosko_nombre || `Kiosko #${a.kiosko_id}`)}</div>
          <div class="modal-sub" style="margin-bottom:0">${fmtDate(a.created_at)}</div>
        </div>
        <button type="button" class="btn-cancel" data-cerrar-ayuda style="padding:4px 10px;font-size:16px;border-radius:6px;cursor:pointer">&#10005;</button>
      </div>

      <div style="margin-top:16px">
        <div class="campo-label" style="margin-bottom:6px">${t("ayuda_motivo_label")}</div>
        <textarea id="ayuda-motivo-input" rows="3" style="width:100%;box-sizing:border-box;background:var(--surface-2);border:1px solid var(--border);border-radius:var(--radius-sm);color:var(--text);padding:10px 12px;font:inherit;resize:vertical" placeholder="${t("ayuda_sin_motivo")}">${esc(a.motivo || "")}</textarea>
      </div>

      <div class="modal-actions">
        ${pendiente ? `<button type="button" class="btn-aprobar" data-ayuda-resolver="${a.id}">${t("ayuda_marcar_resuelta")}</button>` : ""}
        <button type="button" class="btn-cancel" data-ayuda-guardar="${a.id}">${t("ayuda_guardar_motivo")}</button>
      </div>
    </div>`;

    modal.hidden = false;
    modal.querySelectorAll("[data-cerrar-ayuda]").forEach(btn => {
      btn.addEventListener("click", () => { modal.hidden = true; });
    });
    modal.querySelector("[data-ayuda-guardar]")?.addEventListener("click", async () => {
      const motivo = document.getElementById("ayuda-motivo-input")?.value || "";
      const res = await api(`/asistencias-urgentes/${a.id}/motivo`, {
        method: "PATCH",
        body: JSON.stringify({ motivo }),
      });
      if (!res || !res.ok) return;
      modal.hidden = true;
      loadAyuda();
    });
    modal.querySelector("[data-ayuda-resolver]")?.addEventListener("click", async () => {
      modal.hidden = true;
      await resolverAyuda(a.id);
    });
  }

  document.getElementById("modal-ayuda")?.addEventListener("click", (e) => {
    if (e.target.id === "modal-ayuda") e.target.hidden = true;
  });

  document.querySelectorAll('#screen-ayuda .tab-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('#screen-ayuda .tab-btn').forEach(b => b.classList.toggle('active', b === btn));
      state.ayudaFiltro = btn.dataset.ayudaFiltro;
      loadAyuda();
    });
  });

  /* ─── Seguridad (intentos fallidos de PIN/QR con foto) ──────────────── */
  state.seguridadFiltro = "";

  async function loadSeguridadBadge() {
    const res = await api("/eventos-seguridad/");
    if (!res || !res.ok) return;
    let total = 0;
    try {
      const d = await res.json();
      total = d.total || 0;
    } catch (e) { console.error(e); return; }
    const text = total > 99 ? "99+" : String(total);
    const hidden = total <= 0;
    const badge = document.getElementById("nav-badge-seguridad");
    if (badge) { badge.textContent = text; badge.hidden = hidden; }
    const badgeMob = document.getElementById("nav-badge-seguridad-mob");
    if (badgeMob) { badgeMob.textContent = text; badgeMob.hidden = hidden; }
  }

  function showSeguridadState(s) {
    ["loading", "empty", "error"].forEach(x => {
      const el = document.getElementById(`seguridad-${x}`);
      if (el) el.hidden = x !== s;
    });
    const rows = document.getElementById("seguridad-rows");
    if (rows) rows.hidden = s !== "rows";
  }

  const SEGURIDAD_TIPO_LABEL = {
    pin_incorrecto: () => t("seguridad_tipo_pin"),
    qr_invalido: () => t("seguridad_tipo_qr"),
  };

  async function loadSeguridad() {
    showSeguridadState("loading");
    const query = state.seguridadFiltro ? `?tipo=${encodeURIComponent(state.seguridadFiltro)}` : "";
    const res = await api(`/eventos-seguridad/${query}`);
    if (!res || !res.ok) { showSeguridadState("error"); return; }

    let eventos = [];
    try {
      const d = await res.json();
      eventos = d.eventos || [];
    } catch (e) { console.error(e); showSeguridadState("error"); return; }

    loadSeguridadBadge();

    if (eventos.length === 0) { showSeguridadState("empty"); return; }

    const container = document.getElementById("seguridad-rows");
    if (!container) return;
    container.innerHTML = eventos.map((e, i) => renderSeguridadRow(e, i)).join("");
    showSeguridadState("rows");
  }

  function renderSeguridadRow(e, i) {
    const tipoLabel = (SEGURIDAD_TIPO_LABEL[e.tipo] || (() => e.tipo))();
    const foto = e.foto_url
      ? `<div class="evidencia-card" style="max-width:180px" tabindex="0" role="button" data-foto="${esc(e.foto_url)}" data-foto-label="${esc(tipoLabel)}">
          <div class="evidencia-marco"><img class="evidencia-img" src="${esc(e.foto_url)}" alt="${esc(tipoLabel)}" loading="lazy"></div>
          <div class="evidencia-pie"><span>${t("ver_completa")}</span></div>
        </div>`
      : `<div class="empty-text" style="font-size:12px">${t("seguridad_sin_foto")}</div>`;
    return `<div class="sol-card" style="animation-delay:${i * 40}ms;align-items:center">
      <div class="sol-card-left">
        <div class="feed-dot"></div>
        <div>
          <div class="row-name">${esc(e.kiosko_nombre || `Kiosko #${e.kiosko_id}`)} <span class="badge badge--rechazado">${esc(tipoLabel)}</span></div>
          <div class="row-sub">${e.detalle ? esc(e.detalle) + " · " : ""}${fmtDate(e.created_at)}</div>
        </div>
      </div>
      ${foto}
    </div>`;
  }

  document.querySelectorAll('#screen-seguridad .tab-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('#screen-seguridad .tab-btn').forEach(b => b.classList.toggle('active', b === btn));
      state.seguridadFiltro = btn.dataset.seguridadFiltro;
      loadSeguridad();
    });
  });

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
            ${v.intervenida ? `<span class="badge badge--intervenida">${t("revisada_por_ia")}</span>` : ""}
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
    if (!ultimoPing) return { clase: 'nunca', texto: t('kio_nunca_conectado') };
    const ms = Date.now() - new Date(ultimoPing).getTime();
    if (ms < KIO_PING_MARGEN_MS) return { clase: 'online', texto: t('kio_en_linea') };
    const mins = Math.floor(ms / 60000);
    if (mins < 60) return { clase: 'offline', texto: `${t('kio_desconectado_hace')} ${mins}m` };
    const hrs = Math.floor(mins / 60);
    return { clase: 'offline', texto: `${t('kio_desconectado_hace')} ${hrs}h` };
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
    loadKioskosOfflineBadge(list);

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
          <button class="btn-cancel" data-cfg-acceso="${a.id}" style="font-size:12.5px;padding:6px 14px;border-radius:8px;font-weight:600;display:inline-flex;align-items:center;gap:6px" title="${t('configurar_kiosko_title')}">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6z"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>
            ${t('tab_config')}
          </button>
          <button class="btn-ghost" data-del-acceso="${a.id}" style="color:var(--red)" title="${t('delete')}">
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
      errEl.textContent = t('ingresa_codigo_formato');
      errEl.hidden = false;
      return;
    }
    const res = await api(`/device/validar?user_code=${encodeURIComponent(code)}`);
    if (!res) return;
    if (!res.ok) {
      errEl.textContent = t('codigo_invalido_o_usado');
      errEl.hidden = false;
      return;
    }
    const d = await res.json();
    if (!d.valid) {
      errEl.textContent = t('codigo_no_activo_o_expiro');
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
      errEl.textContent = d.error || t('error_crear_kiosko');
      errEl.hidden = false;
      return;
    }
    const kiosko = await resKiosko.json();
    state.accesosById.set(kiosko.id, kiosko);

    const resAprobar = await api(`/device/${encodeURIComponent(nkPendingCode)}/aprobar`, {
      method: 'POST', body: JSON.stringify({ kiosko_id: kiosko.id, clave_kiosko: kiosko.clave_kiosko || '' }),
    });
    if (!resAprobar || !resAprobar.ok) {
      errEl.textContent = t('kiosko_creado_sin_vincular');
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
    mostrarToast(t('kiosko_configurado_listo'), 'ok');
  }

  document.getElementById('nk-cfg-guardar')?.addEventListener('click', nkGuardarConfig);
  document.getElementById('nk-cfg-saltar')?.addEventListener('click', () => {
    cerrarNuevoKioskoWizard();
    mostrarToast(t('kiosko_activado_toast'), 'ok');
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
      errEl.textContent = data.error || t("error_generico");
      errEl.hidden = false;
      return;
    }
    document.getElementById("modal-acceso").hidden = true;
    await loadAccesos();
    mostrarToast(t("kiosko_actualizado_toast"), "ok");
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
      titleKey: "pipeline_rostro_title",
      descKey: "pipeline_rostro_desc",
      defaultChecked: true,
    },
    DESTINO: {
      id: "DESTINO",
      icon: `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"></path><polyline points="9 22 9 12 15 12 15 22"></polyline></svg>`,
      titleKey: "pipeline_destino_title",
      descKey: "pipeline_destino_desc",
      defaultChecked: true,
    },
    PLACA: {
      id: "PLACA",
      icon: `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="10" width="20" height="10" rx="2" ry="2"/><path d="M4 10l2-4h12l2 4"/><circle cx="7" cy="16.5" r="1.5"/><circle cx="17" cy="16.5" r="1.5"/></svg>`,
      titleKey: "pipeline_placa_title",
      descKey: "pipeline_placa_desc",
      defaultChecked: false,
    },
    INE: {
      id: "INE",
      icon: `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="6" width="18" height="12" rx="2" ry="2"/><circle cx="8" cy="12" r="2"/><path d="M14 10h4m-4 4h4"/></svg>`,
      titleKey: "pipeline_ine_title",
      descKey: "pipeline_ine_desc",
      defaultChecked: false,
    },
    MOTIVO: {
      id: "MOTIVO",
      icon: `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg>`,
      titleKey: "pipeline_motivo_title",
      descKey: "pipeline_motivo_desc",
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

    const orderedIds = [...new Set([...rawPasos, "ROSTRO", "DESTINO", "PLACA", "INE", "MOTIVO"])];

    const checkedMap = {
      ROSTRO: cfg.foto_rostro_visitante !== undefined ? !!cfg.foto_rostro_visitante : true,
      DESTINO: true,
      PLACA: esPeatonal ? false : (cfg.foto_placa_visitante !== undefined ? !!cfg.foto_placa_visitante : true),
      INE: !!cfg.foto_ine_visitante,
      MOTIVO: !!cfg.motivo_obligatorio_visitante,
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
        item.title = t("no_aplica_kiosko_peatonal");
      }

      item.innerHTML = `
        <div class="pipeline-handle" title="${isPlacaPeatonal ? t('no_disponible_kiosko_peatonal') : t('arrastrar_para_reordenar')}">⠿</div>
        <div class="pipeline-order-badge">—</div>
        <div class="pipeline-icon">${def.icon}</div>
        <div class="pipeline-info">
          <div class="pipeline-title">${t(def.titleKey)}</div>
          <div class="pipeline-desc">${isPlacaPeatonal ? t("desactivado_no_aplica_peatonal") : t(def.descKey)}</div>
        </div>
        <div class="pipeline-actions">
          <div class="pipeline-move-btns" style="${isPlacaPeatonal ? 'opacity:0.3;pointer-events:none' : ''}">
            <button type="button" class="pipeline-btn-move btn-move-up" title="${t('mover_arriba')}" ${isPlacaPeatonal ? 'disabled' : ''}>▲</button>
            <button type="button" class="pipeline-btn-move btn-move-down" title="${t('mover_abajo')}" ${isPlacaPeatonal ? 'disabled' : ''}>▼</button>
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
      mostrarToast(t("no_pudo_cargar_config_kiosko"), "err");
      return;
    }

    const cfg = await res.json();
    cfgAccesoId = accesoId;

    const headerTitle = document.getElementById("cfg-header-title");
    const headerSub = document.getElementById("cfg-header-sub");
    if (headerTitle) headerTitle.textContent = acceso?.nombre ? `${t("configuracion_label")}: ${acceso.nombre}` : t("configuracion_de_kiosko");
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
    document.getElementById("cfg-score-ia-kiosko").checked  = cfg.mostrar_score_ia_kiosko !== false;
    document.getElementById("cfg-score-ia-placa").checked     = cfg.usar_placa_en_score_ia !== false;
    document.getElementById("cfg-score-ia-documento").checked = cfg.usar_documento_en_score_ia !== false;
    document.getElementById("cfg-score-ia-rostro").checked    = cfg.usar_rostro_en_score_ia !== false;

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
      motivo_obligatorio_visitante: activeSteps.includes("MOTIVO"),
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
      errEl.textContent = t("nombre_kiosko_obligatorio");
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
      errEl.textContent = data.error || t("error_actualizar_info_kiosko");
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
    let fotoRostro = false, fotoPlaca = false, fotoIne = false, motivoObligatorio = false;

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
          if (stepId === "MOTIVO") motivoObligatorio = true;
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
      motivo_obligatorio_visitante: motivoObligatorio,
      mostrar_score_ia_kiosko:      document.getElementById("cfg-score-ia-kiosko").checked,
      usar_placa_en_score_ia:       document.getElementById("cfg-score-ia-placa").checked,
      usar_documento_en_score_ia:   document.getElementById("cfg-score-ia-documento").checked,
      usar_rostro_en_score_ia:      document.getElementById("cfg-score-ia-rostro").checked,
    };

    const res = await api(`/kioskos/${cfgAccesoId}/config`, {
      method: "PATCH",
      body: JSON.stringify(payload),
    });

    if (!res) return;
    if (!res.ok) {
      const data = await res.json();
      errEl.textContent = data.error || t("error_guardar_configuracion");
      errEl.hidden = false;
      return;
    }
    okEl.hidden = false;
    mostrarToast(t("kiosko_config_guardados_ok"), "ok");
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
      const nombre = [nombreRaw, apeRaw].filter(Boolean).join(" ") || correoRaw || t("rol_vigilante_corto");
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
          <button class="btn-ghost" style="color:var(--red)" data-del-vigilante="${idRaw}" title="${t('eliminar_vigilante_title')}">
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
    if (!confirm(t("confirmar_eliminar_vigilante"))) return;
    const res = await api(`/admins/${id}`, { method: "DELETE" });
    if (res && res.ok) loadEquipo();
    else mostrarToast(t("no_pudo_eliminar_vigilante"), "err");
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
      errEl.textContent = data.error || t("error_crear_vigilante");
      errEl.hidden = false;
      return;
    }

    document.getElementById("modal-vigilante").hidden = true;
    mostrarToast(t("vigilante_creado_correctamente"));
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
      errEl.textContent = data.error || t("error_generico");
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
          <div class="hero-card-meta">${esc(acceso)} · ${t('hero_ahora')}</div>
        </div>
        <span class="badge ${bcls}">${estadoLabel(estado === 'REVISIÓN' ? 'REVISION' : estado)}</span>`;
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
      const telefonoEl = document.getElementById('ob-inst-telefono');
      if (telefonoEl) telefonoEl.value = d.telefono_contacto || '';
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
      telefono_contacto: document.getElementById('ob-inst-telefono')?.value.trim() || '',
    };
    const res = await api(`/tenants/${state.tenantId || 1}`, { method: 'PATCH', body: JSON.stringify(body) });
    if (!res) return;
    if (!res.ok) {
      const d = await res.json();
      errEl.textContent = d.error || t('error_al_guardar');
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
      errEl.textContent = t('correo_pass_obligatorios');
      errEl.hidden = false;
      return;
    }
    const res = await api('/auth/sign-in', { method: 'POST', body: JSON.stringify(payload) });
    if (!res) return;
    if (!res.ok) {
      const d = await res.json();
      errEl.textContent = d.error || t('error_crear_vigilante');
      errEl.hidden = false;
      return;
    }
    document.getElementById('onboarding-overlay').hidden = true;
    mostrarToast(t('vigilante_creado_todo_listo'), 'ok');
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
    if (!tipo) return t('tipo_destino_casa');
    switch (tipo.toLowerCase()) {
      case 'casa': return t('tipo_destino_casa');
      case 'departamento': return t('tipo_destino_departamento');
      case 'edificio': return t('tipo_destino_edificio');
      case 'oficina': return t('tipo_destino_oficina');
      case 'local': return t('tipo_destino_local');
      case 'bodega': return t('tipo_destino_bodega');
      case 'lote': return t('tipo_destino_lote');
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
    if (!res || !res.ok) { mostrarToast(t('error_cargar_destinos'), 'err'); return; }

    const items = await res.json();
    if (!items.length) { emptyEl.hidden = false; return; }

    destinosCache = new Map(items.map(d => [d.id, d]));

    // Agrupadas por calle y, dentro de cada calle, por tipo -- una calle
    // real mezcla casas, deptos, locales, etc., y verlos todos revueltos
    // hacía más lento encontrar uno en calles grandes.
    const porCalle = new Map();
    for (const d of items) {
      const calle = d.calle || t('sin_calle');
      if (!porCalle.has(calle)) porCalle.set(calle, new Map());
      const porTipo = porCalle.get(calle);
      const tipo = d.tipo || 'casa';
      if (!porTipo.has(tipo)) porTipo.set(tipo, []);
      porTipo.get(tipo).push(d);
    }

    // Ícono por tipo -- edificio/departamento/oficina/bodega comparten la
    // silueta de edificio, casa/lote la de casa, así se distinguen de un
    // vistazo en la vista de tarjetas sin tener que leer la etiqueta.
    const iconoEdificio = `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="4" y="2" width="16" height="20" rx="1"/><line x1="9" y1="7" x2="9" y2="7.01"/><line x1="15" y1="7" x2="15" y2="7.01"/><line x1="9" y1="12" x2="9" y2="12.01"/><line x1="15" y1="12" x2="15" y2="12.01"/><line x1="9" y1="17" x2="15" y2="17"/></svg>`;
    const iconoCasa = `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>`;
    // Calle: vista de arriba de una vialidad (dos guarniciones + línea
    // central punteada) en vez de las líneas en perspectiva de antes, que
    // a 16px se veían como un garabato sin forma clara.
    const iconoCalle = `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="2" y1="7" x2="22" y2="7"/><line x1="2" y1="17" x2="22" y2="17"/><line x1="4" y1="12" x2="8" y2="12"/><line x1="12" y1="12" x2="16" y2="12"/><line x1="20" y1="12" x2="22" y2="12"/></svg>`;
    const esEdificioLike = tipo => ['edificio', 'departamento', 'oficina', 'bodega', 'local'].includes((tipo || '').toLowerCase());

    rowsEl.innerHTML = [...porCalle.entries()].map(([calle, porTipo]) => {
      const totalCalle = [...porTipo.values()].reduce((acc, arr) => acc + arr.length, 0);
      return `
      <div style="margin-bottom:24px">
        <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:12px">
          <div style="font-size:13px;font-weight:700;color:var(--text-2);text-transform:uppercase;letter-spacing:0.04em;display:flex;align-items:center;gap:8px">
            ${iconoCalle}
            ${esc(calle)}
          </div>
          <span class="badge badge--neutral" style="font-size:11.5px">${totalCalle} ${totalCalle === 1 ? 'destino' : 'destinos'}</span>
        </div>
        ${[...porTipo.entries()].map(([tipo, destinos]) => `
          <div style="margin-bottom:14px">
            ${porTipo.size > 1 ? `<div style="font-size:11px;font-weight:600;color:var(--text-3);text-transform:uppercase;letter-spacing:0.05em;margin-bottom:8px">${formatTipoDestino(tipo)}${destinos.length > 1 ? 's' : ''} · ${destinos.length}</div>` : ''}
            <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(180px,1fr));gap:12px">
              ${destinos.map(d => {
                const n = d.residentes_activos || 0;
                return `
                <div id="dest-row-${d.id}" class="dest-card" data-dest-id="${d.id}" style="position:relative;background:var(--surface-2);border:1px solid var(--border);border-radius:12px;padding:14px;cursor:pointer;transition:border-color .15s,transform .15s">
                  <button type="button" class="btn-ghost" style="position:absolute;top:8px;right:8px;color:var(--text-3);padding:4px;display:flex" data-del-dest="${d.id}" title="${t('eliminar_destino_title')}">
                    <svg width="13" height="13" viewBox="0 0 18 18" fill="none" stroke="currentColor" stroke-width="2"><line x1="4" y1="5" x2="14" y2="5"/><path d="M6 5V3.5h6V5"/><path d="M5 5l.7 9a1 1 0 0 0 1 .9h4.6a1 1 0 0 0 1-.9L13 5"/></svg>
                  </button>
                  <div style="color:var(--text-3);margin-bottom:8px">${esEdificioLike(d.tipo) ? iconoEdificio : iconoCasa}</div>
                  <div style="font-size:14px;font-weight:700;color:var(--text)">${formatTipoDestino(d.tipo)} ${esc(d.numero || '')}</div>
                  ${d.titular ? `<div style="font-size:11.5px;color:var(--text-3);margin-top:2px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${esc(d.titular)}</div>` : ''}
                  <div style="display:flex;align-items:center;gap:5px;margin-top:12px;padding-top:10px;border-top:1px solid var(--border)">
                    <svg width="13" height="13" viewBox="0 0 18 18" fill="none" stroke="currentColor" stroke-width="1.7" style="color:${n > 0 ? 'var(--brand)' : 'var(--text-3)'}"><circle cx="9" cy="6" r="3.5"/><path d="M2 16c0-3.9 3.1-7 7-7s7 3.1 7 7"/></svg>
                    <span style="font-size:13px;font-weight:700;color:${n > 0 ? 'var(--text)' : 'var(--text-3)'}">${n}</span>
                    <span style="font-size:11.5px;color:var(--text-3)">residente${n !== 1 ? 's' : ''}</span>
                    ${d.contacto_telefono ? `<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color:var(--text-3);margin-left:auto" title="${t('tiene_contacto_referencia_title')}"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72c.127.96.361 1.903.7 2.81a2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0 1 22 16.92z"/></svg>` : ''}
                  </div>
                </div>`;
              }).join('')}
            </div>
          </div>`).join('')}
      </div>`;
    }).join('');

    rowsEl.querySelectorAll('.dest-card').forEach(card => {
      card.addEventListener('mouseenter', () => { card.style.borderColor = 'var(--brand)'; });
      card.addEventListener('mouseleave', () => { card.style.borderColor = 'var(--border)'; });
      card.addEventListener('click', (e) => {
        if (e.target.closest('[data-del-dest]')) return;
        abrirDetalleDestino(+card.dataset.destId);
      });
    });

    rowsEl.querySelectorAll('[data-del-dest]').forEach(btn => {
      btn.addEventListener('click', (e) => { e.stopPropagation(); deleteDestino(+btn.dataset.delDest); });
    });
  }

  // -- Detalle de destino -----------------------------------------------
  // Antes, picarle a una tarjeta te mandaba directo a Residentes filtrado.
  // Eso no dejaba lugar para ver/editar el contacto de referencia ni los
  // teléfonos ya verificados de esa casa sin salir de la vista de Destinos
  // -- este modal es la parada intermedia con ambas cosas, y desde ahí sí
  // se puede navegar a Residentes si se quiere el listado completo.
  let destinosCache = new Map();
  let contactoDestinoIdActual = null;

  async function abrirDetalleDestino(id) {
    const d = destinosCache.get(id);
    if (!d) return;

    document.getElementById('dd-titulo').textContent = `${formatTipoDestino(d.tipo)} ${d.numero || ''} · ${d.calle || ''}`.trim();
    document.getElementById('dd-titular').textContent = d.titular ? `Titular: ${d.titular}` : '';
    document.getElementById('modal-destino-detalle').dataset.destId = id;
    document.getElementById('modal-destino-detalle').dataset.destNombre = d.nombre;
    renderContactoEnDetalle(d);

    const residentesEl = document.getElementById('dd-residentes-rows');
    residentesEl.innerHTML = `<div style="font-size:12.5px;color:var(--text-3)">Cargando...</div>`;
    document.getElementById('modal-destino-detalle').hidden = false;

    const res = await api('/membresias/');
    if (!res || !res.ok) { residentesEl.innerHTML = `<div style="font-size:12.5px;color:var(--text-3)">No se pudo cargar</div>`; return; }
    const data = await res.json();
    const todos = Array.isArray(data) ? data : (data.membresias || []);
    const deEsteDestino = todos.filter(m => m.casa_destino === d.nombre);

    residentesEl.innerHTML = deEsteDestino.length
      ? deEsteDestino.map(m => {
          const nombreCompleto = `${m.nombre || ''} ${m.apellido_paterno || ''}`.trim() || 'Sin nombre';
          return `
          <div style="display:flex;align-items:center;justify-content:space-between;padding:8px 0;border-bottom:1px solid var(--border);font-size:13px">
            <span style="color:var(--text)">${esc(nombreCompleto)}</span>
            <span class="mono-value" style="color:var(--text-2);font-size:12.5px">${esc(m.telefono || '—')}</span>
          </div>`;
        }).join('')
      : `<div style="font-size:12.5px;color:var(--text-3)">Nadie enrolado con teléfono verificado en este destino.</div>`;
  }

  function renderContactoEnDetalle(d) {
    const el = document.getElementById('dd-contacto-valor');
    el.innerHTML = d.contacto_telefono || d.contacto_nombre
      ? `${d.contacto_nombre ? esc(d.contacto_nombre) + ' · ' : ''}${esc(d.contacto_telefono || '')}`
      : `<span style="color:var(--text-3)">Sin contacto capturado</span>`;
  }

  document.getElementById('dd-cerrar')?.addEventListener('click', () => {
    document.getElementById('modal-destino-detalle').hidden = true;
  });

  document.getElementById('dd-ver-residentes')?.addEventListener('click', () => {
    const nombre = document.getElementById('modal-destino-detalle').dataset.destNombre;
    document.getElementById('modal-destino-detalle').hidden = true;
    verResidentesDeDestino(nombre);
  });

  document.getElementById('dd-editar-contacto')?.addEventListener('click', () => {
    const id = +document.getElementById('modal-destino-detalle').dataset.destId;
    const d = destinosCache.get(id);
    if (!d) return;
    contactoDestinoIdActual = id;
    document.getElementById('cd-nombre').value = d.contacto_nombre || '';
    document.getElementById('cd-telefono').value = d.contacto_telefono || '';
    document.getElementById('modal-contacto-destino').hidden = false;
  });

  document.getElementById('cd-cancel')?.addEventListener('click', () => {
    document.getElementById('modal-contacto-destino').hidden = true;
  });

  document.getElementById('contacto-destino-form')?.addEventListener('submit', async (e) => {
    e.preventDefault();
    if (!contactoDestinoIdActual) return;
    const res = await api(`/destinos/${contactoDestinoIdActual}/contacto`, {
      method: 'PATCH',
      body: JSON.stringify({
        contacto_nombre: document.getElementById('cd-nombre').value.trim(),
        contacto_telefono: document.getElementById('cd-telefono').value.trim(),
      }),
    });
    if (!res || !res.ok) {
      mostrarToast(t('no_pudo_guardar_contacto'), 'err');
      return;
    }
    const actualizado = await res.json();
    destinosCache.set(actualizado.id, actualizado);
    document.getElementById('modal-contacto-destino').hidden = true;
    renderContactoEnDetalle(actualizado);
    // Refleja el ícono de "tiene contacto" en la tarjeta sin recargar todo.
    const card = document.getElementById(`dest-row-${actualizado.id}`);
    if (card) loadDestinos();
  });

  async function deleteDestino(id) {
    const ok = await confirmarAccion({
      titulo: t('confirmar_eliminar_destino'),
      texto: t('confirmar_eliminar_destino_texto'),
      textoBoton: t('delete'),
    });
    if (!ok) return;
    const res = await api(`/destinos/${id}`, { method: 'DELETE' });
    if (res && res.ok) {
      document.getElementById(`dest-row-${id}`)?.remove();
      if (!document.getElementById('dest-rows').children.length)
        document.getElementById('dest-empty').hidden = false;
    } else {
      mostrarToast(t('no_pudo_eliminar_destino'), 'err');
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
      errEl.textContent = t('ingresa_nombre_calle_bloque');
      errEl.hidden = false;
      return;
    }

    if (!destinos.length) {
      errEl.textContent = t('agrega_numero_identificador');
      errEl.hidden = false;
      return;
    }

    const res = await api('/destinos/lote', {
      method: 'POST',
      body: JSON.stringify({ calle, destinos })
    });

    if (!res || !res.ok) {
      const d = await res.json();
      errEl.textContent = d.error || t('error_crear_destinos');
      errEl.hidden = false;
      return;
    }
    document.getElementById('modal-destino').hidden = true;
    document.getElementById('destino-form').reset();
    destinosChips = [];
    renderChips();
    mostrarToast(t('destinos_creados_ok'), 'ok');
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
    set('inst-telefono-contacto', d.telefono_contacto);
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
      telefono_contacto: document.getElementById('inst-telefono-contacto')?.value.trim(),
    };
    const res = await api(`/tenants/${tenantId}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
    if (res && res.ok) mostrarToast(t('centro_actualizado_toast'), 'ok');
    else mostrarToast(t('error_al_guardar'), 'err');
  });

  document.getElementById('btn-copiar-codigo')?.addEventListener('click', () => {
    const code = document.getElementById('inst-codigo')?.textContent?.trim();
    if (code && code !== '—') {
      navigator.clipboard?.writeText(code);
      const txt = document.getElementById('btn-copiar-codigo-texto');
      if (txt) {
        const orig = txt.textContent;
        txt.textContent = t('copiado_exclamacion');
        setTimeout(() => { txt.textContent = orig; }, 2000);
      }
      mostrarToast(t('codigo_copiado_portapapeles'), 'ok');
    }
  });

  /* ─── Residentes (Persona + Membresia) ─── */

  let residentesActivosCache = [];
  let residentesSeleccion = new Set();
  let residentesFiltroDestino = null;
  let enrolamientosCache = [];

  function residentesAgruparPor() {
    return document.getElementById('resa-agrupar')?.value || 'destino';
  }

  function residentesClaveGrupo(m, criterio) {
    if (criterio === 'calle') return m.destino_calle || t('sin_calle_registrada');
    if (criterio === 'tipo') return ({ casa: t('tipo_destino_casa'), edificio: t('tipo_destino_edificio') })[m.destino_tipo] || t('sin_tipo');
    if (criterio === 'rol') return ({ residente: t('residentes_label'), invitado_frecuente: t('invitados_frecuentes_label') })[m.rol] || t('residentes_label');
    if (criterio === 'ninguno') return null;
    return m.casa_destino || t('sin_destino');
  }

  function actualizarToolbarSeleccion() {
    const count = document.getElementById('resa-sel-count');
    const btn = document.getElementById('resa-revocar-btn');
    const n = residentesSeleccion.size;
    if (count) { count.hidden = n === 0; count.textContent = `${n} seleccionado${n !== 1 ? 's' : ''}`; }
    if (btn) btn.hidden = n === 0;
  }

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
    residentesSeleccion = new Set();
    actualizarToolbarSeleccion();

    if (!activos.length) {
      if (emptyEl) emptyEl.hidden = false;
      return;
    }
    if (emptyEl) emptyEl.hidden = true;

    renderResidentesActivos();
  }

  function residenteRowHtml(m) {
    const nombreCompleto = `${m.nombre || ''} ${m.apellido_paterno || ''} ${m.apellido_materno || ''}`.trim() || t('sin_nombre');
    const inicial = (m.nombre || 'R')[0].toUpperCase();
    const avatarHtml = m.foto_cara_url
      ? `<div class="res-avatar"><img src="${esc(m.foto_cara_url)}" alt="${esc(nombreCompleto)}" onerror="this.parentElement.innerHTML='${inicial}'"></div>`
      : `<div class="res-avatar">${inicial}</div>`;

    const contacto = m.telefono ? `${esc(m.telefono)}` : (m.curp ? `CURP: ${esc(m.curp)}` : t('residente_activo_label'));
    const fechaAlta = m.created_at ? fmtDateShort(m.created_at) : '—';
    const checked = residentesSeleccion.has(m.id) ? 'checked' : '';
    // Un invitado frecuente (Rol=invitado_frecuente) lo da de alta un
    // residente por su cuenta, sin pasar por la aprobación del admin --
    // sin este badge, se veía en esta lista exactamente igual que un
    // residente real dado de alta y aprobado por el propio centro.
    const badgeInvitadoFrecuente = m.rol === 'invitado_frecuente'
      ? `<span class="badge badge--revision" style="font-size:10px;padding:2px 8px;margin-left:6px;vertical-align:1px">${t('invitado_frecuente_badge')}</span>`
      : '';

    return `
      <div class="res-row" data-res-id="${m.id}">
        <input type="checkbox" class="res-check" data-check-id="${m.id}" ${checked} style="width:16px;height:16px;cursor:pointer;flex-shrink:0">
        ${avatarHtml}
        <div class="res-info-main">
          <div class="res-name">${esc(nombreCompleto)}${badgeInvitadoFrecuente}</div>
          <div class="res-sub">${contacto}</div>
        </div>
        <div class="res-dest-col">
          <span class="badge badge--aprobado" style="font-size:12px;padding:4px 10px;font-weight:600">
             ${esc(m.casa_destino || t('sin_casa'))}
          </span>
        </div>
        <div class="res-date-col">
          <div style="font-size:10.5px;color:var(--text-3);text-transform:uppercase;letter-spacing:0.04em">${t('alta_label')}</div>
          <div style="font-size:12.5px;color:var(--text-2);font-weight:500">${fechaAlta}</div>
        </div>
        <div class="res-action-col">
          <button type="button" class="btn-cancel" style="padding:6px 12px;font-size:12px;border-radius:8px;font-weight:600;display:inline-flex;align-items:center;gap:4px">
            ${t('ver_detalle_label')}
            <svg width="12" height="12" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="2"><path d="M6 3l5 5-5 5"/></svg>
          </button>
        </div>
      </div>`;
  }

  // Agrupa la lista ya cargada según el criterio elegido en el toolbar
  // (destino/calle/tipo) -- todo desde caché, sin volver a pedir al backend.
  function renderResidentesActivos() {
    const rowsEl = document.getElementById('resa-rows');
    if (!rowsEl) return;

    const chipEl = document.getElementById('resa-filtro-chip');
    if (chipEl) {
      chipEl.hidden = !residentesFiltroDestino;
      chipEl.querySelector('span').textContent = `${t('filtrando_por')} ${residentesFiltroDestino || ''}`;
    }

    const base = residentesFiltroDestino
      ? residentesActivosCache.filter(m => m.casa_destino === residentesFiltroDestino)
      : residentesActivosCache;

    const criterio = residentesAgruparPor();
    if (criterio === 'ninguno') {
      rowsEl.innerHTML = base.map(residenteRowHtml).join('');
    } else {
      const grupos = new Map();
      base.forEach(m => {
        const clave = residentesClaveGrupo(m, criterio);
        if (!grupos.has(clave)) grupos.set(clave, []);
        grupos.get(clave).push(m);
      });
      const claves = [...grupos.keys()].sort((a, b) => a.localeCompare(b));
      rowsEl.innerHTML = claves.map(clave => `
        <div class="res-group-header" style="font-size:12px;font-weight:700;color:var(--text-2);text-transform:uppercase;letter-spacing:0.04em;margin:18px 0 8px;padding-bottom:6px;border-bottom:1px solid var(--border)">
          ${esc(clave)} <span style="font-weight:400;color:var(--text-3)">(${grupos.get(clave).length})</span>
        </div>
        ${grupos.get(clave).map(residenteRowHtml).join('')}
      `).join('');
    }

    rowsEl.querySelectorAll('.res-check').forEach(chk => {
      chk.addEventListener('click', e => e.stopPropagation());
      chk.addEventListener('change', () => {
        const id = Number(chk.dataset.checkId);
        if (chk.checked) residentesSeleccion.add(id); else residentesSeleccion.delete(id);
        actualizarToolbarSeleccion();
      });
    });

    rowsEl.querySelectorAll('[data-res-id]').forEach(el => {
      el.addEventListener('click', () => {
        const id = Number(el.dataset.resId);
        const m = residentesActivosCache.find(x => x.id === id);
        if (m) showResidenteModal(m);
      });
    });
  }

  document.getElementById('resa-agrupar')?.addEventListener('change', renderResidentesActivos);

  document.getElementById('resa-filtro-quitar')?.addEventListener('click', () => {
    residentesFiltroDestino = null;
    renderResidentesActivos();
  });

  // Entrada desde "Destino" en el detalle de una visita -- ver residentes
  // enlazados a esa casa/edificio, ya agrupados/filtrados a solo esa clave.
  function verResidentesDeDestino(casaDestino) {
    residentesFiltroDestino = casaDestino;
    navTo('residentes'); // dispara loadResidentesActivos() (ver navTo, caso "residentes")
  }

  document.getElementById('resa-revocar-btn')?.addEventListener('click', async () => {
    const ids = [...residentesSeleccion];
    if (!ids.length) return;
    const ok = await confirmarAccion({
      titulo: STRINGS[lang].confirmar_revocar_n(ids.length),
      texto: t('revocar_acceso_texto'),
      textoBoton: t('revocar_button'),
    });
    if (!ok) return;

    const res = await api('/membresias/revocar', { method: 'POST', body: JSON.stringify({ ids }) });
    if (!res || !res.ok) {
      mostrarToast(t('no_pudo_revocar_reintentar'), 'err');
      return;
    }
    await loadResidentesActivos();
  });

  let residentesPendientesCache = [];

  // ─── Enrolamientos: invitados frecuentes (Rol=invitado_frecuente) de
  // CUALQUIER casa del centro -- distinto de "Activos" (que junta residentes
  // e invitados frecuentes mezclados, agrupables por destino). Reusa el
  // mismo endpoint /membresias/ y el mismo modal de detalle/revocar que
  // Activos -- lo único propio de esta pestaña es el filtro por rol y el
  // campo "enrolado por".
  async function loadEnrolamientos() {
    const loadEl  = document.getElementById('rese-loading');
    const emptyEl = document.getElementById('rese-empty');
    const rowsEl  = document.getElementById('rese-rows');
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

    let todas = [];
    try {
      const d = await res.json();
      todas = Array.isArray(d) ? d : (d.membresias || []);
    } catch (e) { console.error(e); }

    enrolamientosCache = todas.filter(m => m.rol === 'invitado_frecuente');

    if (!enrolamientosCache.length) {
      if (emptyEl) emptyEl.hidden = false;
      return;
    }
    if (emptyEl) emptyEl.hidden = true;

    rowsEl.innerHTML = enrolamientosCache.map(enrolamientoRowHtml).join('');
    rowsEl.querySelectorAll('[data-enrolamiento-id]').forEach(el => {
      el.addEventListener('click', () => {
        const id = Number(el.dataset.enrolamientoId);
        const m = enrolamientosCache.find(x => x.id === id);
        if (m) showResidenteModal(m);
      });
    });
  }

  function enrolamientoRowHtml(m) {
    const nombreCompleto = `${m.nombre || ''} ${m.apellido_paterno || ''} ${m.apellido_materno || ''}`.trim() || t('sin_nombre');
    const inicial = (m.nombre || 'I')[0].toUpperCase();
    const avatarHtml = m.foto_cara_url
      ? `<div class="res-avatar"><img src="${esc(m.foto_cara_url)}" alt="${esc(nombreCompleto)}" onerror="this.parentElement.innerHTML='${inicial}'"></div>`
      : `<div class="res-avatar">${inicial}</div>`;
    const contacto = m.telefono ? esc(m.telefono) : t('residente_activo_label');
    const fechaAlta = m.created_at ? fmtDateShort(m.created_at) : '—';

    return `
      <div class="res-row" data-enrolamiento-id="${m.id}" style="cursor:pointer">
        ${avatarHtml}
        <div class="res-info-main">
          <div class="res-name">${esc(nombreCompleto)}</div>
          <div class="res-sub">${contacto}</div>
        </div>
        <div class="res-dest-col">
          <span class="badge badge--aprobado" style="font-size:12px;padding:4px 10px;font-weight:600">
             ${esc(m.casa_destino || t('sin_casa'))}
          </span>
        </div>
        <div class="res-dest-col">
          <div style="font-size:10.5px;color:var(--text-3);text-transform:uppercase;letter-spacing:0.04em">${t('enrolado_por_label')}</div>
          <div style="font-size:12.5px;color:var(--text-2);font-weight:500">${m.enrolado_por_nombre ? esc(m.enrolado_por_nombre) : '—'}</div>
        </div>
        <div class="res-date-col">
          <div style="font-size:10.5px;color:var(--text-3);text-transform:uppercase;letter-spacing:0.04em">${t('alta_label')}</div>
          <div style="font-size:12.5px;color:var(--text-2);font-weight:500">${fechaAlta}</div>
        </div>
        <div class="res-action-col">
          <button type="button" class="btn-cancel" style="padding:6px 12px;font-size:12px;border-radius:8px;font-weight:600;display:inline-flex;align-items:center;gap:4px">
            ${t('ver_detalle_label')}
            <svg width="12" height="12" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="2"><path d="M6 3l5 5-5 5"/></svg>
          </button>
        </div>
      </div>`;
  }

  function showResidenteModal(m) {
    const modal = document.getElementById('modal-residente-detalle');
    const body = document.getElementById('res-modal-body');
    if (!modal || !body) return;

    const esPendiente = (m.status === 'pendiente');
    const nombreCompleto = `${m.nombre || ''} ${m.apellido_paterno || ''} ${m.apellido_materno || ''}`.trim() || t('sin_nombre');
    const inicial = (m.nombre || 'R')[0].toUpperCase();
    // data-foto + .evidencia-card, no onclick inline: app.js entero corre
    // dentro del IIFE de arranque y abrirLightbox nunca se expuso a
    // window, así que un onclick="abrirLightbox(...)" en un string HTML
    // fallaba en silencio (ReferenceError en consola, invisible en la UI)
    // -- el listener delegado en document ya existe para .evidencia-card,
    // se reusa tal cual en vez de duplicar el mecanismo.
    const avatarHtml = m.foto_cara_url
      ? `<div class="res-avatar res-avatar--lg evidencia-card" tabindex="0" role="button" style="cursor:pointer" data-foto="${esc(m.foto_cara_url)}" data-foto-label="${t('rostro_de_label')} ${esc(nombreCompleto)}"><img src="${esc(m.foto_cara_url)}" alt="${esc(nombreCompleto)}" onerror="this.parentElement.innerHTML='${inicial}'"></div>`
      : `<div class="res-avatar res-avatar--lg">${inicial}</div>`;

    const tieneRostro = m.tiene_rostro;
    const tienePin = m.tiene_pin;

    body.innerHTML = `
      <div class="res-modal-header">
        ${avatarHtml}
        <div>
          <div style="font-size:18px;font-weight:700;color:var(--text);margin-bottom:4px">${esc(nombreCompleto)}</div>
          <div style="display:flex;gap:8px;align-items:center;flex-wrap:wrap">
            <span class="badge ${esPendiente ? 'badge--pendiente' : 'badge--aprobado'}">${esc(m.casa_destino || t('sin_casa_asignada'))}</span>
            <span class="badge" style="text-transform:capitalize">${esc(m.rol || t('autorizador_residente'))}</span>
            <span class="badge ${esPendiente ? 'badge--pendiente' : 'badge--green'}">${esPendiente ? t('solicitud_pendiente_badge') : t('activo_badge')}</span>
          </div>
        </div>
      </div>

      <div class="${m.foto_ine_url ? 'res-modal-cols' : ''}">
        <div>
          <div class="res-modal-grid">
            <div class="res-modal-field">
              <div class="res-modal-field-label">${t('telefono')}</div>
              <div class="res-modal-field-value">${m.telefono ? esc(m.telefono) : '—'}</div>
            </div>
            <div class="res-modal-field">
              <div class="res-modal-field-label">CURP</div>
              <div class="res-modal-field-value mono-value" style="font-size:12px">${m.curp ? esc(m.curp) : '—'}</div>
            </div>
            <div class="res-modal-field">
              <div class="res-modal-field-label">${t('destino_casa_label')}</div>
              <div class="res-modal-field-value">${esc(m.casa_destino || '—')}</div>
            </div>
            <div class="res-modal-field">
              <div class="res-modal-field-label">${esPendiente ? t('solicitado_el_label') : t('miembro_desde_label')}</div>
              <div class="res-modal-field-value">${m.created_at ? fmtDateShort(m.created_at) : '—'}</div>
            </div>
            ${m.rol === 'invitado_frecuente' ? `
            <div class="res-modal-field">
              <div class="res-modal-field-label">${t('enrolado_por_label')}</div>
              <div class="res-modal-field-value">${m.enrolado_por_nombre ? esc(m.enrolado_por_nombre) : '—'}</div>
            </div>` : ''}
          </div>
        </div>

        ${m.foto_ine_url ? `
          <div>
            <div style="font-size:11px;font-weight:700;color:var(--text-2);text-transform:uppercase;letter-spacing:0.08em;margin-bottom:8px">
              ${t('documento_identidad_ine_label')}
            </div>
            <div class="evidencia-card" tabindex="0" role="button" style="display:block;width:100%" data-foto="${esc(m.foto_ine_url)}" data-foto-label="${t('ine_de_label')} ${esc(nombreCompleto)}">
              <img src="${esc(m.foto_ine_url)}" alt="${t('documento_ine_alt')}" style="display:block;width:100%;height:130px;object-fit:cover">
            </div>
          </div>
        ` : ''}
      </div>

      <div style="margin-top:20px">
        <div style="font-size:11px;font-weight:700;color:var(--text-2);text-transform:uppercase;letter-spacing:0.08em;margin-bottom:10px">
          ${t('metodos_acceso_identidad_label')}
        </div>

        <!-- A todo el ancho del modal, no en media columna: ícono+título+
             descripción+badge es contenido inherentemente ancho, apretarlo
             en una columna angosta es lo que causaba el badge encimado
             sobre el texto. flex-wrap deja 2-3 tarjetas por fila según
             quepan, en vez de una columna angosta o un grid que fuerza 2. -->
        <div style="display:flex;flex-wrap:wrap;gap:8px">
            <div style="flex:1 1 220px;display:flex;align-items:center;justify-content:space-between;gap:10px;padding:10px 14px;background:var(--surface-2);border-radius:8px;border:1px solid var(--border)">
              <div style="display:flex;align-items:center;gap:10px;min-width:0">
                <span style="font-size:18px">👤</span>
                <div>
                  <div style="font-size:13.5px;font-weight:600;color:var(--text)">${t('reconocimiento_facial_ia_label')}</div>
                  <div style="font-size:11.5px;color:var(--text-3)">${t('reconocimiento_facial_ia_desc')}</div>
                </div>
              </div>
              <span class="badge ${tieneRostro ? 'badge--aprobado' : 'badge--rechazado'}" style="flex-shrink:0">
                ${tieneRostro ? t('enrolado_label') : t('sin_rostro_label')}
              </span>
            </div>

            <div style="flex:1 1 220px;display:flex;align-items:center;justify-content:space-between;gap:10px;padding:10px 14px;background:var(--surface-2);border-radius:8px;border:1px solid var(--border)">
              <div style="display:flex;align-items:center;gap:10px;min-width:0">
                <span style="font-size:18px">🔢</span>
                <div>
                  <div style="font-size:13.5px;font-weight:600;color:var(--text)">${t('pin_de_acceso_label')}</div>
                  <div style="font-size:11.5px;color:var(--text-3)">${t('pin_de_acceso_desc')}</div>
                </div>
              </div>
              <div style="display:flex;align-items:center;gap:8px;flex-shrink:0">
                <span class="badge ${tienePin ? 'badge--aprobado' : 'badge--rechazado'}" id="res-modal-pin-badge">
                  ${tienePin ? t('configurado_label') : t('sin_pin_label')}
                </span>
                ${!esPendiente ? `<button type="button" class="btn-ghost" id="res-modal-regenerar-pin-btn" style="padding:4px 8px;font-size:11.5px">${t('regenerar_pin_button')}</button>` : ''}
              </div>
            </div>

            <div style="flex:1 1 220px;display:flex;align-items:center;justify-content:space-between;gap:10px;padding:10px 14px;background:var(--surface-2);border-radius:8px;border:1px solid var(--border)">
              <div style="display:flex;align-items:center;gap:10px;min-width:0">
                <span style="font-size:18px">📱</span>
                <div>
                  <div style="font-size:13.5px;font-weight:600;color:var(--text)">${t('app_kigo_qr_label')}</div>
                  <div style="font-size:11.5px;color:var(--text-3)">${t('app_kigo_qr_desc')}</div>
                </div>
              </div>
              <span class="badge ${esPendiente ? 'badge--pendiente' : 'badge--aprobado'}" style="flex-shrink:0">
                ${esPendiente ? t('pendiente_aprobacion_label') : t('activo_badge')}
              </span>
            </div>
          </div>
        </div>

      <div class="modal-actions" style="justify-content:space-between;display:flex;gap:10px;align-items:center;flex-wrap:wrap">
        ${esPendiente ? `
          <div style="display:flex;gap:8px">
            <button type="button" class="btn-primary" id="res-modal-aprobar-btn" style="padding:8px 16px;font-weight:600">${t('aprobar_solicitud_button')}</button>
            <button type="button" class="btn-ghost" id="res-modal-rechazar-btn" style="color:var(--danger,#e55);padding:8px 12px">${t('rechazar')}</button>
          </div>
        ` : `
          <div style="display:flex;gap:8px;flex-wrap:wrap">
            <button type="button" class="btn-cancel" id="res-modal-ver-visitas">
              <svg width="14" height="14" viewBox="0 0 18 18" fill="none" stroke="currentColor" stroke-width="1.8" style="vertical-align:middle;margin-right:4px"><circle cx="4" cy="4.5" r="1.7"/><line x1="8" y1="4.5" x2="16" y2="4.5"/><circle cx="4" cy="9" r="1.7"/><line x1="8" y1="9" x2="16" y2="9"/><circle cx="4" cy="13.5" r="1.7"/><line x1="8" y1="13.5" x2="16" y2="13.5"/></svg>
              ${t('ver_entradas_residente_button')}
            </button>
            <button type="button" class="btn-ghost" id="res-modal-revocar-btn" style="color:var(--danger,#e55)">${t('revocar_acceso_button')}</button>
          </div>
        `}
        <button type="button" class="btn-cancel" id="res-modal-cerrar-btn">${t('cerrar')}</button>
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

    document.getElementById('res-modal-revocar-btn')?.addEventListener('click', async () => {
      const nombreCompleto = `${m.nombre || ''} ${m.apellido_paterno || ''}`.trim() || 'este residente';
      const ok = await confirmarAccion({
        titulo: `¿Revocar a ${nombreCompleto}?`,
        texto: 'Ya no podrá entrar por PIN ni reconocimiento facial. Esto no borra su cuenta de Kigo, solo su acceso a este centro.',
        textoBoton: 'Revocar',
      });
      if (!ok) return;
      const res = await api('/membresias/revocar', { method: 'POST', body: JSON.stringify({ ids: [m.id] }) });
      if (res && res.ok) {
        modal.hidden = true;
        mostrarToast('Acceso revocado', 'ok');
        // El modal es el mismo para "Activos" y "Enrolamientos" -- se
        // refrescan las dos listas en vez de adivinar cuál lo abrió, para
        // que ninguna se quede mostrando la fila ya revocada.
        await Promise.all([loadResidentesActivos(), loadEnrolamientos()]);
      } else {
        mostrarToast('No se pudo revocar', 'err');
      }
    });

    document.getElementById('res-modal-regenerar-pin-btn')?.addEventListener('click', async () => {
      const ok = await confirmarAccion({
        titulo: t('regenerar_pin_confirmar_titulo'),
        texto: t('regenerar_pin_confirmar_texto'),
        textoBoton: t('regenerar_pin_button'),
      });
      if (!ok) return;
      const res = await api(`/membresias/${m.id}/regenerar-pin`, { method: 'POST' });
      if (res && res.ok) {
        const data = await res.json();
        const badge = document.getElementById('res-modal-pin-badge');
        // Se queda visible en el badge (no en un toast de 5s) porque el
        // admin necesita tiempo para copiarlo o dictarlo al residente.
        if (badge) badge.textContent = data.pin_codigo;
        mostrarToast(t('regenerar_pin_ok_toast'), 'ok');
      } else {
        mostrarToast(t('regenerar_pin_error_toast'), 'err');
      }
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
          <div style="width:18px"></div>
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
