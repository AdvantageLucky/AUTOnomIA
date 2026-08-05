package com.example.kigo_kiosco

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val kioskChannel = "com.example.kigo_kiosco/kiosk_mode"
    private var kioskLockEnabled = true

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
    }
}
