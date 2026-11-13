package com.zemaapp.zema

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class DetectionChannel(private val context: Context, messenger: BinaryMessenger) {
    private val methods = MethodChannel(messenger, NAME)
    private val events = EventChannel(messenger, "$NAME/events")
    private var stopListening: (() -> Unit)? = null

    init {
        methods.setMethodCallHandler { call, result ->
            when (call.method) {
                "hasAccess" -> result.success(hasAccess())
                "openAccessSettings" -> {
                    openAccessSettings()
                    result.success(null)
                }
                "enabled" -> result.success(PlaybackHub.enabled(context))
                "setEnabled" -> {
                    PlaybackHub.setEnabled(context, call.arguments == true)
                    result.success(null)
                }
                "sources" -> result.success(PlaybackHub.sources(context).toList())
                "setSources" -> {
                    val sources = (call.arguments as? List<*>)?.filterIsInstance<String>()?.toSet()
                    if (sources == null) {
                        result.error("bad_arguments", "A list of package names is needed", null)
                    } else {
                        PlaybackHub.setSources(context, sources)
                        result.success(null)
                    }
                }
                "batteryUnrestricted" -> result.success(batteryUnrestricted())
                "allowBattery" -> {
                    allowBattery()
                    result.success(null)
                }
                "manufacturer" -> result.success(Build.MANUFACTURER ?: "")
                "openPhoneSettings" -> {
                    openPhoneSettings()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        events.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
                stopListening?.invoke()
                stopListening = PlaybackHub.listen { sink.success(it) }
            }

            override fun onCancel(arguments: Any?) {
                stopListening?.invoke()
                stopListening = null
            }
        })
    }

    fun dispose() {
        methods.setMethodCallHandler(null)
        events.setStreamHandler(null)
        stopListening?.invoke()
        stopListening = null
    }

    private fun hasAccess(): Boolean {
        val enabled = Settings.Secure.getString(context.contentResolver, "enabled_notification_listeners")
            ?: return false
        val me = MediaWatchService.component(context)
        return enabled.split(':').any { it == me.flattenToString() || it == me.flattenToShortString() }
    }

    private fun openAccessSettings() {
        val detail = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Intent(Settings.ACTION_NOTIFICATION_LISTENER_DETAIL_SETTINGS).putExtra(
                Settings.EXTRA_NOTIFICATION_LISTENER_COMPONENT_NAME,
                MediaWatchService.component(context).flattenToString(),
            )
        } else {
            null
        }
        val all = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        for (intent in listOfNotNull(detail, all)) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            if (runCatching { context.startActivity(intent) }.isSuccess) return
        }
    }

    private fun batteryUnrestricted(): Boolean {
        val power = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        return power.isIgnoringBatteryOptimizations(context.packageName)
    }

    private fun allowBattery() {
        start(
            Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, Uri.parse("package:${context.packageName}")),
            Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS),
            appDetails(),
        )
    }

    private fun openPhoneSettings() {
        val brand = PHONE_SETTINGS.filterKeys { Build.MANUFACTURER.lowercase().contains(it) }.values.flatten()
        start(*brand.map { Intent().setComponent(ComponentName.unflattenFromString(it)) }.toTypedArray(), appDetails())
    }

    private fun appDetails() =
        Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:${context.packageName}"))

    private fun start(vararg intents: Intent) {
        for (intent in intents) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            if (runCatching { context.startActivity(intent) }.isSuccess) return
        }
    }

    companion object {
        private const val NAME = "zema/detection"
        private val PHONE_SETTINGS = mapOf(
            "xiaomi" to listOf("com.miui.securitycenter/com.miui.permcenter.autostart.AutoStartManagementActivity"),
            "redmi" to listOf("com.miui.securitycenter/com.miui.permcenter.autostart.AutoStartManagementActivity"),
            "poco" to listOf("com.miui.securitycenter/com.miui.permcenter.autostart.AutoStartManagementActivity"),
            "samsung" to listOf("com.samsung.android.lool/com.samsung.android.sm.battery.ui.BatteryActivity"),
            "huawei" to listOf(
                "com.huawei.systemmanager/.startupmgr.ui.StartupNormalAppListActivity",
                "com.huawei.systemmanager/.optimize.process.ProtectActivity",
            ),
            "oppo" to listOf(
                "com.coloros.safecenter/.permission.startup.StartupAppListActivity",
                "com.coloros.safecenter/.startupapp.StartupAppListActivity",
                "com.oppo.safe/.permission.startup.StartupAppListActivity",
            ),
            "realme" to listOf("com.coloros.safecenter/.startupapp.StartupAppListActivity"),
            "vivo" to listOf(
                "com.vivo.permissionmanager/.activity.BgStartUpManagerActivity",
                "com.iqoo.secure/.ui.phoneoptimize.AddWhiteListActivity",
            ),
            "oneplus" to listOf("com.oneplus.security/.chainlaunch.view.ChainLaunchAppListActivity"),
            "tecno" to listOf("com.transsion.phonemaster/com.cyin.himgr.autostart.AutoStartActivity"),
            "infinix" to listOf("com.transsion.phonemaster/com.cyin.himgr.autostart.AutoStartActivity"),
            "itel" to listOf("com.transsion.phonemaster/com.cyin.himgr.autostart.AutoStartActivity"),
        )
    }
}
