# La app solo usa reconocimiento de texto en latín (google_mlkit_text_recognition
# con TextRecognitionScript.latin) — R8 igual encuentra referencias a los
# reconocedores de otros scripts (chino/japonés/coreano/devanagari) porque el
# paquete los declara todos, aunque nunca se agregan como dependencia real.
# Sin esto, `flutter build apk --release` falla en minifyReleaseWithR8.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Sin estas reglas, R8 en el build de release minifica/renombra clases
# internas de ML Kit que sus modulos Dynamite de Play Services resuelven
# por reflexion en tiempo de ejecucion -- produce un NullPointerException
# ("getClass() on a null object reference") dentro de codigo ofuscado de
# com.google.android.gms.internal.mlkit_vision_* en TODOS los dispositivos
# que corren el APK release, no solo en uno (en debug no aparece porque
# ahi no hay minificacion).
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_** { *; }
-keep class com.google.android.gms.internal.mlkit_common_** { *; }
-keep class com.google.android.gms.vision.** { *; }
-dontwarn com.google.mlkit.**
