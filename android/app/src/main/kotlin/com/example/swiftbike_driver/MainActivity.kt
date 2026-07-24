package com.example.swiftbike_driver

import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val overlayChannel = "swiftbike_driver/overlay"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        registerChannel(flutterEngine)

        // flutter_overlay_window creates a second, cached FlutterEngine for
        // the chat head. A MethodChannel attached only above cannot receive
        // calls made by that engine, which is why the overlay's View button
        // could not foreground this activity. Register the same handler on
        // that cached engine once the plugin has created it.
        registerOverlayEngineChannel(attempt = 0)
    }

    private fun registerChannel(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, overlayChannel)
            .setMethodCallHandler { call, result ->

            when (call.method) {

                "openOverlayPermissionSettings" -> {
                    val intent = Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:$packageName")
                    )
                    startActivity(intent)
                    result.success(null)
                }

                "openMainApp" -> {
                    // Reuse the existing activity/task so the driver returns
                    // to the live trip request screen instead of launching a
                    // second copy of the app from the overlay service.
                    val intent = Intent(this@MainActivity, MainActivity::class.java).apply {
                        addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                    }
                    startActivity(intent)
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun registerOverlayEngineChannel(attempt: Int) {
        val overlayEngine = FlutterEngineCache.getInstance().get("myCachedEngine")
        if (overlayEngine != null) {
            registerChannel(overlayEngine)
            return
        }

        // The plugin normally creates this during activity attachment. Retry
        // briefly to cover plugin-registration order on cold app starts.
        if (attempt < 8) {
            Handler(Looper.getMainLooper()).postDelayed(
                { registerOverlayEngineChannel(attempt + 1) },
                250L,
            )
        }
    }
}
