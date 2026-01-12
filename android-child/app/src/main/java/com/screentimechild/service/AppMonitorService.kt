package com.screentimechild.service

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.content.pm.PackageManager
import android.view.accessibility.AccessibilityEvent
import com.screentimechild.enforcement.EnforcementEngine
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import javax.inject.Inject

@AndroidEntryPoint
class AppMonitorService : AccessibilityService() {

    @Inject
    lateinit var enforcementEngine: EnforcementEngine

    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private var currentPackage: String? = null

    override fun onServiceConnected() {
        super.onServiceConnected()

        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                    AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                    AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
            notificationTimeout = 100
        }
        serviceInfo = info

        // Initial rules refresh
        serviceScope.launch {
            enforcementEngine.refreshRules()
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                val packageName = event.packageName?.toString() ?: return

                // Skip if same package (already tracking)
                if (packageName == currentPackage) return

                // Skip system UI events
                if (packageName == "com.android.systemui") return

                val appName = getAppName(packageName)

                // Notify engine of app change
                val shouldBlock = enforcementEngine.onAppLaunched(packageName, appName)

                // Update current tracking
                if (currentPackage != null && currentPackage != packageName) {
                    enforcementEngine.onAppClosed(currentPackage!!)
                }
                currentPackage = packageName
            }
        }
    }

    override fun onInterrupt() {
        // Service interrupted
    }

    override fun onDestroy() {
        super.onDestroy()
        serviceScope.cancel()
        currentPackage?.let { enforcementEngine.onAppClosed(it) }
    }

    private fun getAppName(packageName: String): String {
        return try {
            val appInfo = packageManager.getApplicationInfo(packageName, 0)
            packageManager.getApplicationLabel(appInfo).toString()
        } catch (e: PackageManager.NameNotFoundException) {
            packageName
        }
    }

    companion object {
        fun isServiceEnabled(context: android.content.Context): Boolean {
            val accessibilityManager = context.getSystemService(
                android.content.Context.ACCESSIBILITY_SERVICE
            ) as android.view.accessibility.AccessibilityManager

            val enabledServices = android.provider.Settings.Secure.getString(
                context.contentResolver,
                android.provider.Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            ) ?: return false

            val colonSplitter = android.text.TextUtils.SimpleStringSplitter(':')
            colonSplitter.setString(enabledServices)

            val serviceName = "${context.packageName}/${AppMonitorService::class.java.canonicalName}"

            while (colonSplitter.hasNext()) {
                val componentNameString = colonSplitter.next()
                if (componentNameString.equals(serviceName, ignoreCase = true)) {
                    return true
                }
            }
            return false
        }
    }
}
