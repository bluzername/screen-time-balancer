package com.screentimechild.ui.auth

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.screentimechild.data.models.UserProfile
import com.screentimechild.data.repository.AuthRepository
import com.screentimechild.data.repository.FamilyRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class AuthUiState(
    val isLoading: Boolean = false,
    val error: String? = null,
    val isSignUpMode: Boolean = false,
    val email: String = "",
    val password: String = "",
    val fullName: String = "",
    val confirmPassword: String = ""
)

@HiltViewModel
class AuthViewModel @Inject constructor(
    private val authRepository: AuthRepository,
    private val familyRepository: FamilyRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(AuthUiState())
    val uiState: StateFlow<AuthUiState> = _uiState.asStateFlow()

    private val _isAuthenticated = MutableStateFlow(authRepository.isAuthenticated())
    val isAuthenticated: StateFlow<Boolean> = _isAuthenticated.asStateFlow()

    private val _hasFamily = MutableStateFlow(false)
    val hasFamily: StateFlow<Boolean> = _hasFamily.asStateFlow()

    private val _currentUser = MutableStateFlow<UserProfile?>(null)
    val currentUser: StateFlow<UserProfile?> = _currentUser.asStateFlow()

    init {
        checkAuthState()
    }

    private fun checkAuthState() {
        viewModelScope.launch {
            _isAuthenticated.value = authRepository.isAuthenticated()
            if (_isAuthenticated.value) {
                _currentUser.value = authRepository.getCurrentUser()
                _hasFamily.value = familyRepository.getCurrentFamily() != null
            }
        }
    }

    fun updateEmail(email: String) {
        _uiState.value = _uiState.value.copy(email = email)
    }

    fun updatePassword(password: String) {
        _uiState.value = _uiState.value.copy(password = password)
    }

    fun updateFullName(fullName: String) {
        _uiState.value = _uiState.value.copy(fullName = fullName)
    }

    fun updateConfirmPassword(confirmPassword: String) {
        _uiState.value = _uiState.value.copy(confirmPassword = confirmPassword)
    }

    fun toggleSignUpMode() {
        _uiState.value = _uiState.value.copy(
            isSignUpMode = !_uiState.value.isSignUpMode,
            error = null
        )
    }

    fun clearError() {
        _uiState.value = _uiState.value.copy(error = null)
    }

    fun signIn(onSuccess: () -> Unit) {
        val state = _uiState.value
        if (state.email.isBlank() || state.password.isBlank()) {
            _uiState.value = state.copy(error = "Please fill in all fields")
            return
        }

        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)

            authRepository.signIn(state.email, state.password)
                .onSuccess { profile ->
                    _currentUser.value = profile
                    _isAuthenticated.value = true
                    _hasFamily.value = familyRepository.getCurrentFamily() != null
                    _uiState.value = _uiState.value.copy(isLoading = false)
                    onSuccess()
                }
                .onFailure { exception ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        error = exception.message ?: "Sign in failed"
                    )
                }
        }
    }

    fun signUp(onSuccess: () -> Unit) {
        val state = _uiState.value
        if (state.email.isBlank() || state.password.isBlank() || state.fullName.isBlank()) {
            _uiState.value = state.copy(error = "Please fill in all fields")
            return
        }

        if (state.password != state.confirmPassword) {
            _uiState.value = state.copy(error = "Passwords do not match")
            return
        }

        if (state.password.length < 6) {
            _uiState.value = state.copy(error = "Password must be at least 6 characters")
            return
        }

        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)

            authRepository.signUp(state.email, state.password, state.fullName)
                .onSuccess { profile ->
                    _currentUser.value = profile
                    _isAuthenticated.value = true
                    _hasFamily.value = false
                    _uiState.value = _uiState.value.copy(isLoading = false)
                    onSuccess()
                }
                .onFailure { exception ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        error = exception.message ?: "Sign up failed"
                    )
                }
        }
    }

    fun signOut() {
        viewModelScope.launch {
            authRepository.signOut()
            _isAuthenticated.value = false
            _hasFamily.value = false
            _currentUser.value = null
            _uiState.value = AuthUiState()
        }
    }
}
