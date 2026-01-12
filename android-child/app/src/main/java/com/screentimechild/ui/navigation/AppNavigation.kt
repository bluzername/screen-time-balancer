package com.screentimechild.ui.navigation

import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.screentimechild.ui.auth.AuthScreen
import com.screentimechild.ui.auth.AuthViewModel
import com.screentimechild.ui.dashboard.DashboardScreen
import com.screentimechild.ui.setup.SetupScreen

sealed class Screen(val route: String) {
    object Auth : Screen("auth")
    object Setup : Screen("setup")
    object Dashboard : Screen("dashboard")
}

@Composable
fun AppNavigation() {
    val navController = rememberNavController()
    val authViewModel: AuthViewModel = hiltViewModel()
    val isAuthenticated by authViewModel.isAuthenticated.collectAsState()
    val hasFamily by authViewModel.hasFamily.collectAsState()

    val startDestination = when {
        !isAuthenticated -> Screen.Auth.route
        !hasFamily -> Screen.Setup.route
        else -> Screen.Dashboard.route
    }

    NavHost(
        navController = navController,
        startDestination = startDestination
    ) {
        composable(Screen.Auth.route) {
            AuthScreen(
                viewModel = authViewModel,
                onAuthSuccess = {
                    if (authViewModel.hasFamily.value) {
                        navController.navigate(Screen.Dashboard.route) {
                            popUpTo(Screen.Auth.route) { inclusive = true }
                        }
                    } else {
                        navController.navigate(Screen.Setup.route) {
                            popUpTo(Screen.Auth.route) { inclusive = true }
                        }
                    }
                }
            )
        }

        composable(Screen.Setup.route) {
            SetupScreen(
                onSetupComplete = {
                    navController.navigate(Screen.Dashboard.route) {
                        popUpTo(Screen.Setup.route) { inclusive = true }
                    }
                }
            )
        }

        composable(Screen.Dashboard.route) {
            DashboardScreen(
                onSignOut = {
                    authViewModel.signOut()
                    navController.navigate(Screen.Auth.route) {
                        popUpTo(Screen.Dashboard.route) { inclusive = true }
                    }
                }
            )
        }
    }
}
