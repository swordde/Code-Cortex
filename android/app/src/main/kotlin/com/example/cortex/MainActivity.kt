package com.example.cortex

import android.content.ComponentName
import android.content.Intent
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
							val apps = packageManager
								.getInstalledApplications(0)
								.filter { appInfo ->
									appInfo.packageName != applicationContext.packageName &&
										packageManager.getLaunchIntentForPackage(appInfo.packageName) != null
								}
								.map { appInfo ->
									mapOf(
										"name" to packageManager.getApplicationLabel(appInfo).toString(),
										"package" to appInfo.packageName
									)
								}
								.distinctBy { it["package"] }
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
