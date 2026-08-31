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

# vosk_flutter usa JNA (Java Native Access) para llamar a la librería nativa
# de Vosk -- sin estas reglas, R8 puede eliminar las clases que JNA necesita
# por reflexión en el build de release.
-keep class com.sun.jna.* { *; }
-keepclassmembers class * extends com.sun.jna.* { public *; }
