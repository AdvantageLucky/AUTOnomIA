import 'package:flutter/foundation.dart';

/// Canal para que una pantalla le pida a la mascota-asistente
/// (`BotonAsistente`) que narre un texto, sin llamar directo a
/// `TextToSpeakServicio`. No decide si el asistente está libre para
/// hablar ahora mismo -- esa decisión (no interrumpir una interacción del
/// usuario en curso) vive en `BotonAsistente`, que es quien conoce su
/// propio estado.
class AsistenteController extends ChangeNotifier {
  String? _textoPendiente;

  String? get textoPendiente => _textoPendiente;

  void decir(String texto) {
    _textoPendiente = texto;
    notifyListeners();
  }
}
