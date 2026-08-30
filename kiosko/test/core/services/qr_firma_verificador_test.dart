import 'dart:convert';
import 'dart:typed_data';

import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:flutter_test/flutter_test.dart';
import 'package:kigo_kiosco/core/services/qr_firma_verificador.dart';

void main() {
  test('verificar acepta una firma real hecha con la clave de prueba', () {
    final firma = ed.sign(_privKeyDePrueba, Uint8List.fromList(utf8.encode('42')));
    final firmaHex = _hex(firma);

    expect(QrFirmaVerificador.verificar(42, firmaHex, pubKey: _pubKeyDePrueba), isTrue);
  });

  test('verificar rechaza una firma de otro persona_id', () {
    final firma = ed.sign(_privKeyDePrueba, Uint8List.fromList(utf8.encode('42')));
    final firmaHex = _hex(firma);

    expect(QrFirmaVerificador.verificar(99, firmaHex, pubKey: _pubKeyDePrueba), isFalse);
  });

  test('verificar rechaza un hex mal formado', () {
    expect(QrFirmaVerificador.verificar(42, 'no-es-hex', pubKey: _pubKeyDePrueba), isFalse);
  });

  test('verificar rechaza una firma hecha con otra clave', () {
    final otraKeyPair = ed.generateKey();
    final firma = ed.sign(otraKeyPair.privateKey, Uint8List.fromList(utf8.encode('42')));
    final firmaHex = _hex(firma);

    expect(QrFirmaVerificador.verificar(42, firmaHex, pubKey: _pubKeyDePrueba), isFalse);
  });
}

String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

// Par de prueba fijo — generado una sola vez, no es la clave real de
// producción (esa vive embebida en QrFirmaVerificador y solo la conoce el
// backend del lado privado).
final _keyPairDePrueba = ed.generateKey();
ed.PrivateKey get _privKeyDePrueba => _keyPairDePrueba.privateKey;
ed.PublicKey get _pubKeyDePrueba => _keyPairDePrueba.publicKey;
