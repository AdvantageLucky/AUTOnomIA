import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import 'api_service.dart';

/// Pide permiso de notificaciones, obtiene y mantiene actualizado el token
/// FCM del dispositivo en el backend, y muestra un SnackBar simple cuando
/// llega una notificación con la app abierta (foreground).
///
/// Además, decide a dónde navegar cuando la persona TOCA la notificación
/// (con la app en background o cerrada) -- antes tocar la notificación no
/// hacía nada más que el comportamiento por default del sistema operativo
/// (abrir la app donde sea que se haya quedado), sin llevar a la persona a
/// la solicitud/invitación real que motivó el aviso.
class PushService {
  Future<void> iniciar() async {
    final permiso = await FirebaseMessaging.instance.requestPermission();
    if (permiso.authorizationStatus == AuthorizationStatus.denied) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await _registrar(token);

    FirebaseMessaging.instance.onTokenRefresh.listen(_registrar);

    FirebaseMessaging.onMessage.listen((message) {
      final texto = message.notification?.body ?? message.notification?.title;
      if (texto != null) {
        MyApp.scaffoldMessengerKey.currentState
            ?.showSnackBar(SnackBar(content: Text(texto)));
      }
      // Una notificación casi siempre significa que algo relacionado a
      // solicitudes/invitaciones cambió del lado del servidor -- dispara un
      // refresh en vez de esperar a que la persona toque la pestaña.
      MyApp.notificationTick.value++;
    });

    // App en background, la persona toca la notificación en la bandeja del
    // sistema -- Flutter ya sigue corriendo, solo hace falta navegar.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final tipo = message.data['tipo'];
      if (tipo != null) MyApp.pushNavigationTipo.value = tipo;
      MyApp.notificationTick.value++;
    });

    // App cerrada por completo y la persona la abre tocando la
    // notificación -- este es el "primer mensaje" que la lanzó. Sin esto,
    // `onMessageOpenedApp` nunca se dispara porque Flutter apenas está
    // arrancando cuando ocurre el tap.
    final mensajeInicial = await FirebaseMessaging.instance.getInitialMessage();
    final tipoInicial = mensajeInicial?.data['tipo'];
    if (tipoInicial != null) MyApp.pushNavigationTipo.value = tipoInicial;
  }

  Future<void> _registrar(String token) async {
    try {
      await ApiService().post(
        '/personas/me/device-token',
        {'device_token': token},
        auth: true,
      );
    } catch (_) {
      // Silencioso a propósito: que falle el registro de push no debe
      // romper el login ni el resto de la app.
    }
  }
}
