package com.screentimechild.ui.setup

import android.app.AppOpsManager
import android.content.Context
import android.os.Build
import android.os.Process
import android.provider.Settings
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.screentimechild.data.repository.FamilyRepository
import com.screentimechild.service.AppMonitorService
import com.screentimechild.service.MonitoringForegroundService
import com.screentimechild.service.SyncWorker
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class SetupUiState(
    val isLoading: Boolean = false,
    val inviteCode: String = "",
    val joinError: String? = null,
    val hasJoinedFamily: Boolean = false,
    val hasUsageStatsPermission: Boolean = false,
    val hasAccessibilityPermission: Boolean = false,
    val hasOverlayPermission: Boolean = false
)

@HiltViewModel
class SetupViewModel @Inject constructor(
    private val familyRepository: FamilyRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(SetupUiState())
    val uiState: StateFlow<SetupUiState> = _uiState.asStateFlow()

    init {
        checkFamilyMembership()
    }

    private fun checkFamilyMembership() {
        viewModelScope.launch {
            val family = familyRepository.getCurrentFamily()
            _uiState.value = _uiState.value.copy(hasJoinedFamily = family != null)
        }
    }

    fun updateInviteCode(code: String) {
        _uiState.value = _uiState.value.copy(
            inviteCode = code.uppercase().filter { it.isLetterOrDigit() }.take(6),
            joinError = null
        )
    }

    fun joinFamily() {
        val code = _uiState.value.inviteCode
        if (code.length < 6) {
            _uiState.value = _uiState.value.copy(joinError = "Invite code must be 6 characters")
            return
        }

        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, joinError = null)

            familyRepository.joinFamily(code)
                .onSuccess {
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        hasJoinedFamily = true
                    )
                }
                .onFailure { exception ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        joinError = exception.message ?: "Failed to join family"
                    )
                }
        }
    }

    fun checkPermissions(context: Context) {
        _uiState.value = _uiState.value.copy(
            hasUsageStatsPermission = hasUsageStatsPermission(context),
            hasAccessibilityPermission = AppMonitorService.isServiceEnabled(context),
            hasOverlayPermission = Settings.canDrawOverlays(context)
        )
    }

    private fun hasUsageStatsPermission(context: Context): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    fun completeSetup(context: Context) {
        viewModelScope.launch {
            // Register device
            val deviceId = Settings.Secure.getString(
                context.contentResolver,
                Settings.Secure.ANDROID_ID
            )
            val deviceName = Build.MODEL

            familyRepository.registerDevice(deviceName, deviceId)

            // Start monitoring services
            MonitoringForegroundService.start(context)
            SyncWorker.schedule(context)
        }
    }
}
