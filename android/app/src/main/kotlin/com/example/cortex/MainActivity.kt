package com.example.cortex

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val channel = "com.example.cortex/installed_apps"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"getInstalledApps" -> {
						try {
							val launcherIntent = Intent(Intent.ACTION_MAIN, null).apply {
								addCategory(Intent.CATEGORY_LAUNCHER)
							}
							val apps = packageManager
								.queryIntentActivities(launcherIntent, 0)
								.map {
									mapOf(
										"name" to it.loadLabel(packageManager).toString(),
										"package" to it.activityInfo.packageName
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
	}
}
