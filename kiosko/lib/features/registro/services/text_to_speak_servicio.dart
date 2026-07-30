import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';

class TextToSpeakServicio {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  Future<void> _initTts() async {
    if (_isInitialized) return;

    await _flutterTts.setLanguage("es-MX");
    await _flutterTts.setPitch(1.0);
    
    // 1. Un toque más rápido (0.53 - 0.55) le quita lo robótico al español
    await _flutterTts.setSpeechRate(0.53); 
    await _flutterTts.setVolume(1.0);

    // 2. Forzar motor de Google en Android para usar voces neuronales de alta calidad
    if (Platform.isAndroid) {
      await _flutterTts.setEngine("com.google.android.tts");
    }

    // Esperar a que termine de hablar antes de desbloquear el flujo si es necesario
    await _flutterTts.awaitSpeakCompletion(true);
    _isInitialized = true;
  }

  Future<void> speak(String text) async {
    await _initTts();
    // 3. Detener cualquier audio previo inmediatamente para que la app responda al instante
    await _flutterTts.stop(); 
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}