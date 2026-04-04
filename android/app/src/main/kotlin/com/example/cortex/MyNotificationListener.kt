package com.example.cortex

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

class MyNotificationListener : NotificationListenerService() {
  companion object {
    @Volatile
    var onNotificationPostedCallback: ((Map<String, Any?>) -> Unit)? = null
  }

  override fun onNotificationPosted(sbn: StatusBarNotification) {
    val packageName = sbn.packageName ?: return
    if (packageName == applicationContext.packageName) {
      return
    }

    val extras = sbn.notification.extras
    val title = extras?.getCharSequence("android.title")?.toString()?.trim().orEmpty()
    val text = extras?.getCharSequence("android.text")?.toString()?.trim().orEmpty()

    if (title.isEmpty() && text.isEmpty()) {
      return
    }

    val appName = try {
      val appInfo = packageManager.getApplicationInfo(packageName, 0)
      packageManager.getApplicationLabel(appInfo).toString()
    } catch (_: Exception) {
      packageName
    }

    val payload = mapOf(
      "appPackage" to packageName,
      "appName" to appName,
      "title" to title,
      "text" to text,
      "postedAt" to sbn.postTime,
    )

    onNotificationPostedCallback?.invoke(payload)
  }
}
