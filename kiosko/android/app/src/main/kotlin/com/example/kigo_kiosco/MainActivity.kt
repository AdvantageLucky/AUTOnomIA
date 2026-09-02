package com.example.kigo_kiosco

import com.common.pos.api.util.PosUtil
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val kioskChannel = "com.example.kigo_kiosco/kiosk_mode"
    private var kioskLockEnabled = true

    // LED RGBW del hardware Telpo F10 (F10SDK/doc/Telpo F10SDK Manual.docx,
    // sección LED). PosUtil.controlLedBright(tipo, brillo): tipo 0=rojo,
    // 1=verde, 2=azul, 3=blanco; brillo 0-255. controlLedBright(4, 1) apaga
    // todos los canales. No requiere inicialización previa.
    private val ledChannel = "com.example.kigo_kiosco/led"

    // Se re-arma en cada resume (pantalla encendida, vuelta de segundo plano, etc.)
    // para que el pineo se auto-repare si el sistema lo soltó.
    override fun onResume() {
        super.onResume()
        if (kioskLockEnabled) {
            try {
                startLockTask()
            } catch (_: Exception) {
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, kioskChannel)
            .setMethodCallHandler { call, result ->
                if (call.method == "exitKioskMode") {
                    kioskLockEnabled = false
                    try {
                        stopLockTask()
                    } catch (_: Exception) {
                    }
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ledChannel)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "setColor" -> {
                            // Cada canal (0=R, 1=G, 2=B, 3=W) es un slider independiente
                            // y aditivo, no un selector de color exclusivo -- verificado
                            // contra F10SDK/demo/.../LedActivity.java. Sin apagar primero,
                            // un canal que quedó encendido de un color anterior (ej.
                            // blanco=W durante el escaneo) se mezcla con el nuevo y el LED
                            // muestra un color que nadie pidió; closeAllControl() (tipo 4)
                            // es la única forma de resetearlos todos.
                            //
                            // "amarillo" no es un canal del hardware -- no hay ámbar
                            // dedicado en un LED RGBW. Se logra prendiendo rojo+verde a
                            // la vez, apoyándose en que los canales son aditivos.
                            val canales = when (call.argument<String>("color")) {
                                "rojo" -> listOf(0)
                                "verde" -> listOf(1)
                                "azul" -> listOf(2)
                                "blanco" -> listOf(3)
                                "amarillo" -> listOf(0, 1)
                                else -> null
                            }
                            if (canales == null) {
                                result.error("ARGUMENTO_INVALIDO", "color debe ser 'rojo', 'verde', 'azul', 'blanco' o 'amarillo'", null)
                            } else {
                                val brillo = call.argument<Int>("brillo") ?: 255
                                PosUtil.controlLedBright(4, 1)
                                for (canal in canales) PosUtil.controlLedBright(canal, brillo)
                                result.success(null)
                            }
                        }
                        "apagar" -> {
                            PosUtil.controlLedBright(4, 1)
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    // El F10SDK no está presente en todo hardware (ej. emulador,
                    // otro modelo Telpo) — un fallo aquí no debe tronar la
                    // pantalla de resultado, solo no prender la luz.
                    result.error("LED_ERROR", e.message, null)
                }
            }
    }
}
