import 'package:flutter_test/flutter_test.dart';
import 'package:kigo_kiosco/core/services/coincidencia_facial_local.dart';

void main() {
  test('regresa null si no hay residentes', () {
    final resultado = mejorCoincidenciaLocal([], [1.0, 0.0, 0.0]);
    expect(resultado, isNull);
  });

  test('regresa el residente con mayor similitud si supera el umbral', () {
    final residentes = [
      {'nombre': 'Ana', 'apellido_paterno': 'Ruiz', 'casa_destino': 'Casa 1', 'embedding': [1.0, 0.0, 0.0]},
      {'nombre': 'Luis', 'apellido_paterno': 'Gomez', 'casa_destino': 'Casa 2', 'embedding': [0.0, 1.0, 0.0]},
    ];
    final vivo = [0.99, 0.01, 0.0];

    final resultado = mejorCoincidenciaLocal(residentes, vivo, umbral: 0.9);
    expect(resultado, isNotNull);
    expect(resultado!['nombre'], 'Ana');
  });

  test('regresa null si el mejor score no supera el umbral', () {
    final residentes = [
      {'nombre': 'Ana', 'apellido_paterno': 'Ruiz', 'casa_destino': 'Casa 1', 'embedding': [1.0, 0.0, 0.0]},
    ];
    final vivo = [0.0, 1.0, 0.0]; // ortogonal, similitud coseno 0

    final resultado = mejorCoincidenciaLocal(residentes, vivo, umbral: 0.85);
    expect(resultado, isNull);
  });

  test('ignora residentes sin embedding (lista vacia)', () {
    final residentes = [
      {'nombre': 'SinFoto', 'apellido_paterno': 'X', 'casa_destino': 'Casa 3', 'embedding': <double>[]},
    ];
    final resultado = mejorCoincidenciaLocal(residentes, [1.0, 0.0, 0.0]);
    expect(resultado, isNull);
  });
}
