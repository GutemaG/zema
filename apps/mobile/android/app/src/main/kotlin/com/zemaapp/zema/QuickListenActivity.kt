package com.zemaapp.zema

import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class QuickListenActivity : FlutterActivity() {
    private var widget: WidgetChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
            )
        }
        super.onCreate(savedInstanceState)
    }

    override fun getDartEntrypointFunctionName(): String = "listenMain"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        widget = WidgetChannel(applicationContext, messenger)
        MethodChannel(messenger, NAME).setMethodCallHandler { call, result ->
            when (call.method) {
                "openApp" -> {
                    val args = call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()
                    openApp(LaunchChannel.matchIntent(this, args))
                    result.success(null)
                }
                "close" -> {
                    finish()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        widget?.dispose()
        widget = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private fun openApp(intent: Intent) {
        val keyguard = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && keyguard.isKeyguardLocked) {
            keyguard.requestDismissKeyguard(
                this,
                object : KeyguardManager.KeyguardDismissCallback() {
                    override fun onDismissSucceeded() {
                        startActivity(intent)
                        finish()
                    }
                },
            )
        } else {
            startActivity(intent)
            finish()
        }
    }

    companion object {
        private const val NAME = "zema/quick_listen"

        fun intent(context: Context): Intent =
            Intent(context, QuickListenActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
    }
}
