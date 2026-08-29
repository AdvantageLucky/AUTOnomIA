import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kigo_user/models/membresia_model.dart';
import 'package:kigo_user/utils/constants.dart';
import 'package:kigo_user/viewmodels/auth_viewmodel.dart';

MembresiaActual _m(int tenantId, String status, {String nombre = 'Centro'}) =>
    MembresiaActual(
      id: tenantId,
      tenantId: tenantId,
      centroNombre: nombre,
      casaDestino: 'CASA 1',
      status: status,
      pin: '12345',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('sin membresias: centroActivo nulo, membresiaEstado ninguna', () async {
    final auth = AuthViewModel();
    await auth.waitUntilReady();
    auth.debugSetMembresias([]);

    expect(auth.centroActivo, isNull);
    expect(auth.membresiasActivas, isEmpty);
    expect(auth.membresiaEstado, MembresiaEstado.ninguna);
  });

  test('una activa: se vuelve el centro activo automaticamente', () async {
    final auth = AuthViewModel();
    await auth.waitUntilReady();
    auth.debugSetMembresias([_m(7, 'activo')]);

    expect(auth.centroActivo?.tenantId, 7);
    expect(auth.membresiaEstado, MembresiaEstado.activa);
  });

  test('activa + pendiente: la activa gana como centro activo, ambas en membresias', () async {
    final auth = AuthViewModel();
    await auth.waitUntilReady();
    auth.debugSetMembresias([_m(7, 'activo'), _m(9, 'pendiente')]);

    expect(auth.centroActivo?.tenantId, 7);
    expect(auth.membresias.length, 2);
    expect(auth.membresiasActivas.length, 1);
    expect(auth.membresiaEstado, MembresiaEstado.activa);
  });

  test('solo pendiente: membresiaEstado pendiente, sin centro activo', () async {
    final auth = AuthViewModel();
    await auth.waitUntilReady();
    auth.debugSetMembresias([_m(9, 'pendiente')]);

    expect(auth.centroActivo, isNull);
    expect(auth.membresiaEstado, MembresiaEstado.pendiente);
  });

  test('solo rechazada: membresiaEstado rechazada', () async {
    final auth = AuthViewModel();
    await auth.waitUntilReady();
    auth.debugSetMembresias([_m(9, 'rechazado')]);

    expect(auth.membresiaEstado, MembresiaEstado.rechazada);
  });

  test('setCentroActivo cambia la seleccion y persiste', () async {
    final auth = AuthViewModel();
    await auth.waitUntilReady();
    auth.debugSetMembresias([_m(7, 'activo'), _m(8, 'activo')]);

    await auth.setCentroActivo(8);

    expect(auth.centroActivo?.tenantId, 8);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(AppConstants.prefsCentroActivoId), 8);
  });

  test('setCentroActivo rechaza un tenantId que no esta activo', () async {
    final auth = AuthViewModel();
    await auth.waitUntilReady();
    auth.debugSetMembresias([_m(7, 'activo'), _m(9, 'pendiente')]);

    await auth.setCentroActivo(9);

    expect(auth.centroActivo?.tenantId, 7, reason: 'no debio cambiar: 9 no esta activo');
  });

  test('centroActivoId que ya no esta activo cae al fallback (primera activa)', () async {
    final auth = AuthViewModel();
    await auth.waitUntilReady();
    // 999 simula un id persistido de una membresia que ya no es valida (se
    // dio de baja, o nunca existio) -- debugSetMembresias reproduce
    // exactamente la resolucion de fallback que hace _cargarMembresias.
    auth.debugSetMembresias([_m(7, 'activo')], centroActivoId: 999);

    expect(auth.centroActivo?.tenantId, 7);
  });
}
