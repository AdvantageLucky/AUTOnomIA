// El kiosko se quedaba sin la pastilla de bienvenida al volver de un cierre.
//
// La cadena era: el sistema mata el proceso en segundo plano -> al volver es
// un arranque en frio -> obtenerConfig() falla porque el wifi todavia no
// reasocia -> KioskoConfigNotifier se quedaba en KioskoConfig.defaults, donde
// mensajeBienvenida es cadena vacia -> el escaner QR lee vacio como "no hay
// pastilla que mostrar". Y no se recuperaba solo: el SSE del backend solo
// emite cuando el admin guarda cambios, no manda el estado al conectarse.
//
// Estas pruebas fijan el respaldo en disco que rompe esa cadena.
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kigo_kiosco/core/models/kiosko_config.dart';
import 'package:kigo_kiosco/features/registro/services/kiosko_servicio.dart';

const _canal = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

/// Almacen en memoria detras del canal del plugin. Devuelve el mapa para que
/// la prueba pueda sembrarlo y leer lo que el servicio escribio.
Map<String, String> _almacenFalso() {
  final datos = <String, String>{};
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_canal, (llamada) async {
    final args = (llamada.arguments as Map?)?.cast<String, dynamic>() ?? {};
    final key = args['key'] as String?;
    switch (llamada.method) {
      case 'read':
        return datos[key];
      case 'write':
        datos[key!] = args['value'] as String;
        return null;
      case 'delete':
        datos.remove(key);
        return null;
      case 'readAll':
        return datos;
      default:
        return null;
    }
  });
  addTearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_canal, null);
  });
  return datos;
}

String _configJson(String mensaje) => jsonEncode({
      'tipo': 'PEATONAL',
      'mensaje_bienvenida': mensaje,
      'telefono_contacto': '5566778899',
      'umbral_facial_pct': 90,
      'idioma': 'es',
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // El agujero por el que se colaba el bug: los defaults dejan operar al
  // kiosko, pero no traen mensaje, y vacio es exactamente lo que el escaner
  // interpreta como "no dibujes la pastilla".
  test('los defaults no traen mensaje de bienvenida', () {
    expect(KioskoConfig.defaults.mensajeBienvenida, isEmpty);
  });

  test('sin respaldo previo devuelve null, no una config inventada', () async {
    _almacenFalso();
    expect(await KioskoServicio().configRespaldo(), isNull);
  });

  test('el respaldo conserva el mensaje del arranque anterior', () async {
    _almacenFalso()['kiosko_config_respaldo'] =
        _configJson('BIENVENIDO A FEPRO 2026');

    final cfg = await KioskoServicio().configRespaldo();

    expect(cfg, isNotNull);
    expect(cfg!.mensajeBienvenida, 'BIENVENIDO A FEPRO 2026');
    // Y no solo el mensaje: el resto de la config del kiosko tambien vuelve,
    // en vez de caer a valores que no son de este fraccionamiento.
    expect(cfg.telefonoContacto, '5566778899');
    expect(cfg.umbralFacialPct, 90);
  });

  // Un respaldo corrupto (escritura a medias, storage reciclado) no puede
  // tumbar el arranque: se ignora y el kiosko sigue con los defaults.
  test('un respaldo ilegible se ignora en vez de reventar', () async {
    _almacenFalso()['kiosko_config_respaldo'] = 'esto no es json';
    expect(await KioskoServicio().configRespaldo(), isNull);
  });
}
