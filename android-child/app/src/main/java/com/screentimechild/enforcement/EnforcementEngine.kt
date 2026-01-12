package com.screentimechild.enforcement

import android.content.Context
import android.content.Intent
import com.screentimechild.data.models.AppCategory
import com.screentimechild.data.models.EnforcementState
import com.screentimechild.data.repository.FamilyRepository
import com.screentimechild.data.repository.UsageRepository
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.time.Instant
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class EnforcementEngine @Inject constructor(
    @ApplicationContext private val context: Context,
    private val familyRepository: FamilyRepository,
    private val usageRepository: UsageRepository
) {
    private val scope = CoroutineScope(Dispatchers.IO)

    private val _enforcementState = MutableStateFlow(
        EnforcementState(
            isLocked = true,
            educationalMinutes = 0,
            requiredEducationalMinutes = 30,
            recreationalMinutesUsed = 0,
            recreationalMinutesAvailable = null,
            currentApp = null,
            currentAppCategory = null
        )
    )
    val enforcementState: StateFlow<EnforcementState> = _enforcementState.asStateFlow()

    private var appCategories: Map<String, AppCategory> = emptyMap()
    private var blockedApps: Set<String> = emptySet()

    private var currentSessionStart: Instant? = null
    private var currentPackage: String? = null
    private var currentAppName: String? = null
    private var currentCategory: AppCategory? = null
    private var deviceId: String? = null

    // System apps and launchers that should never be blocked
    private val systemPackages = setOf(
        "com.android.launcher",
        "com.android.launcher3",
        "com.google.android.apps.nexuslauncher",
        "com.sec.android.app.launcher",
        "com.huawei.android.launcher",
        "com.miui.home",
        "com.android.settings",
        "com.android.systemui",
        "com.android.phone",
        "com.android.dialer",
        "com.android.contacts",
        "com.android.mms",
        "com.screentimechild" // This app itself
    )

    fun setDeviceId(id: String) {
        deviceId = id
    }

    suspend fun refreshRules() {
        appCategories = familyRepository.getAppCategories()
        blockedApps = familyRepository.getBlockedApps()
        refreshState()
    }

    suspend fun refreshState() {
        val earnedTime = usageRepository.getTodayEarnedTime()
        val rules = familyRepository.getActiveRules()
        val requiredMinutes = rules.maxOfOrNull { it.requiredEducationalMinutes } ?: 30
        val maxRecreational = rules.firstOrNull()?.maxRecreationalMinutes

        _enforcementState.value = _enforcementState.value.copy(
            isLocked = !(earnedTime?.requirementMet ?: false),
            educationalMinutes = earnedTime?.educationalMinutes ?: 0,
            requiredEducationalMinutes = requiredMinutes,
            recreationalMinutesUsed = earnedTime?.recreationalMinutesUsed ?: 0,
            recreationalMinutesAvailable = maxRecreational
        )
    }

    fun onAppLaunched(packageName: String, appName: String): Boolean {
        // Never block system apps
        if (isSystemApp(packageName)) {
            return false
        }

        val category = getAppCategory(packageName)

        _enforcementState.value = _enforcementState.value.copy(
            currentApp = packageName,
            currentAppCategory = category
        )

        // End previous session if exists
        endCurrentSession()

        // Start new session
        currentSessionStart = Instant.now()
        currentPackage = packageName
        currentAppName = appName
        currentCategory = category

        // Check if app should be blocked
        val shouldBlock = shouldBlockApp(packageName, category)

        if (shouldBlock) {
            showBlockingOverlay()
        }

        return shouldBlock
    }

    fun onAppClosed(packageName: String) {
        if (packageName == currentPackage) {
            endCurrentSession()
        }
    }

    private fun endCurrentSession() {
        val start = currentSessionStart ?: return
        val pkg = currentPackage ?: return
        val name = currentAppName ?: return
        val category = currentCategory ?: return
        val device = deviceId ?: return

        val end = Instant.now()
        val durationSeconds = (end.epochSecond - start.epochSecond).toInt()

        // Only record sessions longer than 5 seconds
        if (durationSeconds > 5) {
            scope.launch {
                usageRepository.recordSession(
                    deviceId = device,
                    packageName = pkg,
                    appName = name,
                    category = category,
                    startTime = start,
                    endTime = end
                )
                refreshState()
            }
        }

        currentSessionStart = null
        currentPackage = null
        currentAppName = null
        currentCategory = null
    }

    private fun getAppCategory(packageName: String): AppCategory {
        return appCategories[packageName] ?: AppCategory.UNCATEGORIZED
    }

    private fun shouldBlockApp(packageName: String, category: AppCategory): Boolean {
        // Always blocked apps
        if (blockedApps.contains(packageName)) {
            return true
        }

        // Educational and utility apps are never blocked
        if (category == AppCategory.EDUCATIONAL || category == AppCategory.UTILITY) {
            return false
        }

        // Recreational apps are blocked if requirement not met
        if (category == AppCategory.RECREATIONAL) {
            return _enforcementState.value.isLocked
        }

        // Uncategorized apps are treated as recreational by default
        return _enforcementState.value.isLocked
    }

    private fun isSystemApp(packageName: String): Boolean {
        return systemPackages.any { packageName.startsWith(it) }
    }

    private fun showBlockingOverlay() {
        val intent = Intent(context, BlockingOverlayActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("educational_minutes", _enforcementState.value.educationalMinutes)
            putExtra("required_minutes", _enforcementState.value.requiredEducationalMinutes)
        }
        context.startActivity(intent)
    }
}
