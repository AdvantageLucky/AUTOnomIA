/* OCR LOCAL DE PLACAS VEHICULARES (MLKit, mismo motor que la INE) */

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Resultado del OCR de una placa. [texto] es null cuando no se reconoció
/// ningún patrón de placa en la imagen: la vista debe ofrecer captura manual.
class PlacaDetectada {
  final String? texto;
  final String pathFoto;

  const PlacaDetectada({required this.pathFoto, this.texto});

  bool get fueLeida => texto != null;
}

/// Formato de placa descrito como máscara posicional: 'A' es letra y '9' es
/// dígito. Se usa en vez de un RegExp suelto porque además de validar hay que
/// corregir el OCR posición por posición, igual que hace `_reconstruirCurp`
/// con la CURP de la INE.
class _FormatoPlaca {
  final String mascara;
  const _FormatoPlaca(this.mascara);

  int get longitud => mascara.length;

  bool aceptaLetraEn(int i) => mascara[i] == 'A';
}

/// Lee la placa de una foto usando el reconocedor de texto de MLKit on-device.
///
/// A diferencia de la INE, la placa se fotografía en exteriores: sol directo,
/// lluvia, mica sucia, ángulo. El OCR falla mucho más seguido, así que este
/// servicio nunca es la única vía — el flujo siempre deja corregir a mano.
class PlacaDetectorServicio {
  /// Formatos de placa mexicana de auto particular, en orden de frecuencia.
  static const List<_FormatoPlaca> _formatos = [
    _FormatoPlaca('AAA999A'), // formato vigente
    _FormatoPlaca('AAA9999'),
    _FormatoPlaca('999AAA'),
    _FormatoPlaca('AA99999'), // carga y algunos estados
  ];

  /// Confusiones clásicas del OCR en placas. Se aplican solo donde la máscara
  /// dice qué se esperaba, nunca a ciegas sobre todo el texto.
  static const Map<String, String> _aDigito = {
    'O': '0', 'D': '0', 'I': '1', 'L': '1', 'Z': '2',
    'S': '5', 'G': '6', 'T': '7', 'B': '8',
  };
  static const Map<String, String> _aLetra = {
    '0': 'O', '1': 'I', '2': 'Z', '5': 'S', '6': 'G', '8': 'B',
  };

  /// Texto impreso en las placas que el OCR devuelve junto al número.
  static const Set<String> _ruido = {
    'MEXICO', 'MEX', 'ESTADOS', 'UNIDOS', 'MEXICANOS',
    'PUEBLA', 'TLAXCALA', 'VERACRUZ', 'HIDALGO', 'MORELOS',
    'GUERRERO', 'OAXACA', 'QUERETARO', 'JALISCO', 'GUANAJUATO',
    'PARTICULAR', 'FRONTERIZO', 'DEMO', 'MX',
  };

  Future<PlacaDetectada> analizarPlaca(String pathImagen) async {
    final inputImage = InputImage.fromFilePath(pathImagen);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      final List<String> lineas = [];
      for (final TextBlock block in recognizedText.blocks) {
        for (final TextLine line in block.lines) {
          final limpia = _limpiarLinea(line.text);
          if (limpia.isNotEmpty && !_esRuido(limpia)) lineas.add(limpia);
        }
      }

      return PlacaDetectada(
        pathFoto: pathImagen,
        texto: _extraerPlaca(lineas),
      );
    } catch (e) {
      debugPrint('Error en OCR de placa: $e');
      return PlacaDetectada(pathFoto: pathImagen);
    } finally {
      textRecognizer.close();
    }
  }

  /// Normaliza lo que el usuario teclea a mano para que coincida con lo que
  /// guarda el backend (mayúsculas, sin guiones ni espacios).
  static String normalizar(String entrada) {
    return entrada.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  /// true si el texto tiene forma de placa. Se usa para validar la captura
  /// manual sin bloquear formatos raros (placas de otros estados, motos,
  /// vehículos extranjeros): basta con que sea alfanumérico de 5 a 8 caracteres.
  static bool pareceValida(String texto) {
    final t = normalizar(texto);
    return t.length >= 5 && t.length <= 8;
  }

  // ---------------------------------------------------------------------------
  // Limpieza
  // ---------------------------------------------------------------------------
  String _limpiarLinea(String raw) {
    return raw
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _esRuido(String linea) {
    final palabras = linea.split(' ').where((p) => p.isNotEmpty);
    return palabras.isNotEmpty && palabras.every(_ruido.contains);
  }

  // ---------------------------------------------------------------------------
  // Extracción
  // ---------------------------------------------------------------------------
  String? _extraerPlaca(List<String> lineas) {
    if (lineas.isEmpty) return null;

    // Se colapsan los espacios porque el OCR suele partir "ABC 123 D" en tokens
    // sueltos; también se prueba la concatenación de todas las líneas por si la
    // placa quedó dividida en dos renglones.
    final candidatos = <String>[
      ...lineas.map((l) => l.replaceAll(' ', '')),
      lineas.join().replaceAll(' ', ''),
    ];

    for (final formato in _formatos) {
      for (final candidato in candidatos) {
        final placa = _buscarEnToken(candidato, formato);
        if (placa != null) return placa;
      }
    }

    return null;
  }

  String? _buscarEnToken(String token, _FormatoPlaca formato) {
    for (int i = 0; i + formato.longitud <= token.length; i++) {
      final ventana = token.substring(i, i + formato.longitud);
      final corregida = _corregirSegunMascara(ventana, formato);
      if (corregida != null) return corregida;
    }
    return null;
  }

  /// Fuerza cada carácter al tipo que la máscara espera en esa posición. Si un
  /// carácter no calza ni siquiera tras la corrección, la ventana se descarta:
  /// así "MEXICO1" no se convierte en una placa inventada.
  String? _corregirSegunMascara(String ventana, _FormatoPlaca formato) {
    final buf = StringBuffer();

    for (int i = 0; i < ventana.length; i++) {
      final c = ventana[i];
      final esLetra = RegExp(r'[A-Z]').hasMatch(c);

      if (formato.aceptaLetraEn(i)) {
        final letra = esLetra ? c : _aLetra[c];
        if (letra == null) return null;
        buf.write(letra);
      } else {
        final digito = esLetra ? _aDigito[c] : c;
        if (digito == null) return null;
        buf.write(digito);
      }
    }

    return buf.toString();
  }
}
