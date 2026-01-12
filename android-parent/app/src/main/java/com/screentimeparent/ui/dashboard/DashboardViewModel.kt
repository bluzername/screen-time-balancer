package com.screentimeparent.ui.dashboard

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.screentimeparent.data.models.ChildStatus
import com.screentimeparent.data.models.FamilyOverview
import com.screentimeparent.data.repository.FamilyRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class DashboardUiState(
    val isLoading: Boolean = true,
    val error: String? = null,
    val familyOverview: FamilyOverview? = null,
    val childStatuses: List<ChildStatus> = emptyList(),
    val hasFamily: Boolean = false
)

@HiltViewModel
class DashboardViewModel @Inject constructor(
    private val familyRepository: FamilyRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(DashboardUiState())
    val uiState: StateFlow<DashboardUiState> = _uiState.asStateFlow()

    init {
        loadDashboardData()
    }

    fun loadDashboardData() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)

            try {
                val familyOverview = familyRepository.getCurrentFamilyOverview()
                val childStatuses = if (familyOverview != null) {
                    familyRepository.getChildStatuses(familyOverview.id)
                } else {
                    emptyList()
                }

                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    familyOverview = familyOverview,
                    childStatuses = childStatuses,
                    hasFamily = familyOverview != null
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = e.message ?: "Failed to load dashboard data"
                )
            }
        }
    }

    fun refresh() {
        loadDashboardData()
    }

    fun clearError() {
        _uiState.value = _uiState.value.copy(error = null)
    }
}
