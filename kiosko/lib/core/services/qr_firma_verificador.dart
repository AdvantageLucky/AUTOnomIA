import 'dart:convert';
import 'dart:typed_data';

import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;

/// Verifica offline la firma Ed25519 del QR personal (persona_id:firma)
/// contra la clave pública del sistema, embebida en el build del kiosko.
/// La clave pública NO permite forjar firmas nuevas — solo confirmar que
/// una firma vino del backend (ver spec 2026-08-29-qr-ed25519-design.md).
class QrFirmaVerificador {
  /// Clave pública Ed25519 real de producción, derivada del seed
  /// configurado como QR_ED25519_PRIVATE_KEY en el backend (homelab).
  static const List<int> _pubKeyBytes = <int>[
    78, 150, 118, 178, 22, 97, 147, 253, 78, 254, 223, 73, 46, 128, 84, 173,
    110, 80, 54, 252, 92, 73, 98, 117, 169, 100, 31, 123, 210, 89, 124, 161,
  ];

  static bool verificar(int personaId, String firmaHex, {ed.PublicKey? pubKey}) {
    final Uint8List firma;
    try {
      firma = _decodeHex(firmaHex);
    } catch (_) {
      return false;
    }
    if (firma.length != ed.SignatureSize) return false;

    final mensaje = Uint8List.fromList(utf8.encode(personaId.toString()));
    final clave = pubKey ?? ed.PublicKey(_pubKeyBytes);
    try {
      return ed.verify(clave, mensaje, firma);
    } catch (_) {
      return false;
    }
  }

  static Uint8List _decodeHex(String hex) {
    if (hex.length.isOdd) throw const FormatException('hex de longitud impar');
    final out = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      out[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  }
}
