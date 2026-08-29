import 'package:flutter_test/flutter_test.dart';
import 'package:kigo_user/viewmodels/companeros_casa_viewmodel.dart';

void main() {
  test('estado inicial: sin companeros, sin error, no cargando', () {
    final vm = CompanerosCasaViewModel();

    expect(vm.companeros, isEmpty);
    expect(vm.casaDestino, isEmpty);
    expect(vm.isLoading, isFalse);
    expect(vm.error, isNull);
  });

  test('cargar() contra un tenant inexistente deja error y no cargando', () async {
    final vm = CompanerosCasaViewModel();

    // Sin backend real disponible en el entorno de test, ApiService()
    // termina lanzando ApiException o una excepción de red — en cualquier
    // caso el ViewModel debe quedar en un estado consistente: no atorado
    // en isLoading, con un mensaje de error no vacío.
    await vm.cargar(999999);

    expect(vm.isLoading, isFalse);
    expect(vm.error, isNotNull);
  });
}
