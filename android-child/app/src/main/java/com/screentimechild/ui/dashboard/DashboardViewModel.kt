package com.screentimechild.ui.dashboard

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.screentimechild.data.repository.UsageRepository
import com.screentimechild.enforcement.EnforcementEngine
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class DashboardUiState(
    val isLoading: Boolean = true,
    val isLocked: Boolean = true,
    val educationalMinutes: Int = 0,
    val requiredEducationalMinutes: Int = 30,
    val recreationalMinutesUsed: Int = 0,
    val recreationalMinutesAvailable: Int? = null
)

@HiltViewModel
class DashboardViewModel @Inject constructor(
    private val usageRepository: UsageRepository,
    private val enforcementEngine: EnforcementEngine
) : ViewModel() {

    private val _uiState = MutableStateFlow(DashboardUiState())
    val uiState: StateFlow<DashboardUiState> = _uiState.asStateFlow()

    init {
        observeEnforcementState()
        refresh()
    }

    private fun observeEnforcementState() {
        viewModelScope.launch {
            enforcementEngine.enforcementState.collect { state ->
                _uiState.value = _uiState.value.copy(
                    isLocked = state.isLocked,
                    educationalMinutes = state.educationalMinutes,
                    requiredEducationalMinutes = state.requiredEducationalMinutes,
                    recreationalMinutesUsed = state.recreationalMinutesUsed,
                    recreationalMinutesAvailable = state.recreationalMinutesAvailable,
                    isLoading = false
                )
            }
        }
    }

    fun refresh() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true)

            enforcementEngine.refreshRules()
            enforcementEngine.refreshState()

            val earnedTime = usageRepository.getTodayEarnedTime()
            _uiState.value = _uiState.value.copy(
                isLoading = false,
                educationalMinutes = earnedTime?.educationalMinutes ?: 0,
                recreationalMinutesUsed = earnedTime?.recreationalMinutesUsed ?: 0,
                isLocked = !(earnedTime?.requirementMet ?: false)
            )
        }
    }
}
