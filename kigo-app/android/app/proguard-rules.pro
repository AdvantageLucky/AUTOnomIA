# La app solo usa reconocimiento de texto en latín (google_mlkit_text_recognition
# con TextRecognitionScript.latin) — R8 igual encuentra referencias a los
# reconocedores de otros scripts (chino/japonés/coreano/devanagari) porque el
# paquete los declara todos, aunque nunca se agregan como dependencia real.
# Sin esto, `flutter build apk --release` falla en minifyReleaseWithR8.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
