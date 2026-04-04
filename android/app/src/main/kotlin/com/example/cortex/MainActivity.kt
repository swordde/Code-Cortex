package com.example.cortex

import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val installedAppsChannel = "com.example.cortex/installed_apps"
	private val notificationListenerChannel = "com.example.cortex/notification_listener"
	private val notificationEventsChannel = "com.example.cortex/notification_events"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, installedAppsChannel)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"getInstalledApps" -> {
						try {
							val appsByPackage = linkedMapOf<String, String>()

							val launcherIntent = Intent(Intent.ACTION_MAIN).apply {
								addCategory(Intent.CATEGORY_LAUNCHER)
							}
							val launchable = packageManager.queryIntentActivities(launcherIntent, 0)
							for (resolveInfo in launchable) {
								val packageName = resolveInfo.activityInfo?.packageName ?: continue
								if (packageName == applicationContext.packageName) continue
								val label = resolveInfo.loadLabel(packageManager)?.toString().orEmpty()
								if (label.isNotBlank()) {
									appsByPackage[packageName] = label
								}
							}

							val installed = packageManager.getInstalledApplications(0)
							for (appInfo in installed) {
								if (appInfo.packageName == applicationContext.packageName) continue
								if (appInfo.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM != 0) continue
								val hasLauncher = packageManager.getLaunchIntentForPackage(appInfo.packageName) != null
								if (!hasLauncher && appInfo.packageName !in setOf("com.whatsapp", "com.whatsapp.w4b")) {
									continue
								}
								val label = packageManager.getApplicationLabel(appInfo).toString()
								if (label.isNotBlank()) {
									appsByPackage[appInfo.packageName] = label
								}
							}

							fun addKnownPackage(packageName: String, fallbackName: String) {
								try {
									val appInfo = packageManager.getApplicationInfo(packageName, 0)
									val label = packageManager.getApplicationLabel(appInfo).toString().ifBlank { fallbackName }
									appsByPackage[packageName] = label
								} catch (_: PackageManager.NameNotFoundException) {
								}
							}

							addKnownPackage("com.whatsapp", "WhatsApp")
							addKnownPackage("com.whatsapp.w4b", "WhatsApp Business")

							val apps = appsByPackage
								.map { (packageName, name) ->
									mapOf(
										"name" to name,
										"package" to packageName
									)
								}
								.sortedBy { (it["name"] ?: "").toString().lowercase() }

							result.success(apps)
						} catch (error: Exception) {
							result.error(
								"INSTALLED_APPS_ERROR",
								error.message,
								null
							)
						}
					}

					else -> result.notImplemented()
				}
			}

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, notificationListenerChannel)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"isNotificationAccessEnabled" -> {
						result.success(isNotificationAccessEnabled())
					}

					"openNotificationAccessSettings" -> {
						try {
							startActivity(
								Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS).apply {
									addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
								}
							)
							result.success(true)
						} catch (error: Exception) {
							result.error("NOTIFICATION_SETTINGS_ERROR", error.message, null)
						}
					}

					else -> result.notImplemented()
				}
			}

		EventChannel(flutterEngine.dartExecutor.binaryMessenger, notificationEventsChannel)
			.setStreamHandler(object : EventChannel.StreamHandler {
				override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
					MyNotificationListener.onNotificationPostedCallback = { payload ->
						runOnUiThread {
							events?.success(payload)
						}
					}
				}

				override fun onCancel(arguments: Any?) {
					MyNotificationListener.onNotificationPostedCallback = null
				}
			})
	}

	private fun isNotificationAccessEnabled(): Boolean {
		val enabled = Settings.Secure.getString(
			contentResolver,
			"enabled_notification_listeners"
		) ?: return false
		val expected = ComponentName(this, MyNotificationListener::class.java).flattenToString()
		return enabled.split(":").any { it.equals(expected, ignoreCase = true) }
	}
}
