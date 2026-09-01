import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/ine_ocr_model.dart';

/// OCR de INE, on-device — portado de kiosko/lib/features/registro/services/
/// detector_servicio.dart (misma lógica de extracción de CURP/nombre,
/// probada en el kiosko). Aquí solo cambia el tipo de retorno: no depende
/// del modelo de registro del kiosko.
class DetectorIneServicio {
  Future<IneOcrResult> analizarIne(String pathImagen) async {
    final inputImage = InputImage.fromFilePath(pathImagen);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      List<String> lineas = [];
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          final limpia = _limpiarLinea(line.text);
          if (limpia.isNotEmpty) lineas.add(limpia);
        }
      }

      final textoPlano = lineas.join(' ');
      final curp = _extraerCurp(textoPlano, lineas);
      final estructurado = _extraerNombreEstructurado(lineas);

      return IneOcrResult(
        pathFotoIne: pathImagen,
        curp: curp,
        nombreCompleto: estructurado.nombreCompleto,
        apellidoPaterno: estructurado.apellidoPaterno,
        apellidoMaterno: estructurado.apellidoMaterno,
        nombre: estructurado.nombre,
      );
    } catch (e) {
      debugPrint('Error en OCR: $e');
      return IneOcrResult(pathFotoIne: pathImagen);
    } finally {
      textRecognizer.close();
    }
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

  String _colapsar(String s) => s.replaceAll(' ', '');

  // ---------------------------------------------------------------------------
  // CURP: 18 chars — 4 letras | 6 dígitos | H/M | 5 letras | 2 alfanum
  // ---------------------------------------------------------------------------
  String? _extraerCurp(String textoPlano, List<String> lineas) {
    // Patrón tolerante: acepta O/0 e I/1 en cualquier posición
    final patron = RegExp(r'[A-Z0-9]{4}[0-9OI]{6}[HM][A-Z]{5}[A-Z0-9]{2}');

    // 1. Buscar en texto plano
    for (final m in patron.allMatches(textoPlano)) {
      final c = _reconstruirCurp(m.group(0)!);
      if (c != null) return c;
    }

    // 2. Línea a línea, colapsando espacios
    for (final linea in lineas) {
      final token = _colapsar(linea);
      for (int k = 0; k + 18 <= token.length; k++) {
        final c = _reconstruirCurp(token.substring(k, k + 18));
        if (c != null) return c;
      }
    }

    // 3. Buscar cerca de la etiqueta "CURP"
    for (int i = 0; i < lineas.length; i++) {
      if (!lineas[i].contains('CURP')) continue;
      for (int j = 0; j <= 3; j++) {
        final idx = i + j;
        if (idx >= lineas.length) break;
        final token = _colapsar(lineas[idx]);
        for (int k = 0; k + 18 <= token.length; k++) {
          final c = _reconstruirCurp(token.substring(k, k + 18));
          if (c != null) return c;
        }
      }
    }

    return null;
  }

  String? _reconstruirCurp(String token) {
    if (token.length < 18) return null;
    final buf = StringBuffer();
    for (int i = 0; i < 18; i++) {
      final c = token[i];
      if (i >= 4 && i <= 9) {
        buf.write(c == 'O' ? '0' : c == 'I' ? '1' : c);
      } else if (i == 10) {
        if (c != 'H' && c != 'M') return null;
        buf.write(c);
      } else {
        buf.write(c == '0' ? 'O' : c == '1' ? 'I' : c);
      }
    }
    final r = buf.toString();
    return RegExp(r'^[A-Z]{4}\d{6}[HM][A-Z]{5}[A-Z0-9]{2}$').hasMatch(r) ? r : null;
  }

  // ---------------------------------------------------------------------------
  // Nombre: busca cerca de "NOMBRE" / "APELLIDOS" / "APELLIDO PATERNO"
  // ---------------------------------------------------------------------------
  ({String? nombreCompleto, String? apellidoPaterno, String? apellidoMaterno, String? nombre})
      _extraerNombreEstructurado(List<String> lineas) {
    final filtros = {
      'DOMICILIO', 'CALLE', 'AVENIDA', 'AV', 'COL', 'COLONIA',
      'MUNICIPIO', 'ESTADO', 'CP', 'NUM', 'NUMERO', 'INTERIOR',
      'EXTERIOR', 'SECCION', 'VIGENCIA', 'CURP', 'CLAVE', 'FOLIO',
      'MEXICO', 'ELECTOR', 'REGISTRO', 'FEDERAL', 'EMISION',
    };

    final curpRx  = RegExp(r'[A-Z0-9]{4}\d{6}[HM][A-Z]{5}[A-Z0-9]{2}');
    final claveRx = RegExp(r'[A-Z]{6}\d{6}[HM]\d{5}');

    bool esValida(String linea) {
      if (curpRx.hasMatch(linea) || claveRx.hasMatch(linea)) return false;
      if (RegExp(r'\d').hasMatch(linea)) return false;
      final palabras = linea.split(' ').where((p) => p.isNotEmpty).toSet();
      if (palabras.any((p) => filtros.contains(p))) return false;
      if (linea.length < 3) return false;
      return true;
    }

    final etiquetas = ['NOMBRE', 'APELLIDOS', 'APELLIDO PATERNO', 'APELLIDO'];

    for (final etiqueta in etiquetas) {
      for (int i = 0; i < lineas.length; i++) {
        if (!lineas[i].contains(etiqueta)) continue;

        final sinEtiqueta = lineas[i]
            .replaceAll(RegExp(r'\bAPELLIDO(S)?\s*(PATERNO|MATERNO)?\b'), '')
            .replaceAll(RegExp(r'\bNOMBRES?\b'), '')
            .trim();
        if (sinEtiqueta.length > 3 && esValida(sinEtiqueta)) {
          // Todo en la misma línea que la etiqueta: no hay separación
          // fiable de apellido paterno/materno/nombre, solo referencia.
          return (nombreCompleto: sinEtiqueta, apellidoPaterno: null, apellidoMaterno: null, nombre: null);
        }

        final validas = <String>[];
        for (int j = 1; j <= 4; j++) {
          if (i + j >= lineas.length) break;
          final linea = lineas[i + j];
          if (!esValida(linea)) break;
          validas.add(linea);
        }
        if (validas.isEmpty) continue;

        final completo = validas.join(' ');
        // El INE moderno imprime exactamente 3 líneas en este orden bajo
        // "NOMBRE": apellido paterno, apellido materno, nombre(s). Con
        // menos o más líneas no se puede asumir esa posición con
        // confianza -- se deja solo la referencia sin separar.
        if (etiqueta == 'NOMBRE' && validas.length == 3) {
          return (
            nombreCompleto: completo,
            apellidoPaterno: validas[0],
            apellidoMaterno: validas[1],
            nombre: validas[2],
          );
        }
        return (nombreCompleto: completo, apellidoPaterno: null, apellidoMaterno: null, nombre: null);
      }
    }

    return (nombreCompleto: null, apellidoPaterno: null, apellidoMaterno: null, nombre: null);
  }
}
