# El kiosko solo usa reconocimiento de texto latino (TextRecognizerOptions por
# defecto). El plugin google_mlkit_text_recognition referencia ademas los
# reconocedores chino, devanagari, japones y coreano, cuyos artefactos no se
# incluyen en el build. R8 falla al no encontrarlos, asi que se silencian.
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions

# vosk_flutter_service usa JNA (Java Native Access) para llamar a la librería
# nativa de Vosk -- sin estas reglas, R8 puede eliminar las clases que JNA
# necesita por reflexión en el build de release.
-keep class com.sun.jna.* { *; }
-keepclassmembers class * extends com.sun.jna.* { public *; }

# JNA trae soporte opcional para AWT (Java de escritorio) que nunca se
# ejecuta en Android -- esas clases no existen en el SDK de Android, R8 las
# marca como "missing" al analizar el bytecode aunque el código real nunca
# las llame. Regla sugerida por el propio R8 (missing_rules.txt).
-dontwarn java.awt.Component
-dontwarn java.awt.GraphicsEnvironment
-dontwarn java.awt.HeadlessException
-dontwarn java.awt.Window
