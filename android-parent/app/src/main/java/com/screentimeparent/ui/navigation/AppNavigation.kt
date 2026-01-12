package com.screentimeparent.ui.navigation

import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.screentimeparent.ui.auth.AuthScreen
import com.screentimeparent.ui.auth.AuthViewModel
import com.screentimeparent.ui.dashboard.DashboardScreen

sealed class Screen(val route: String) {
    object Auth : Screen("auth")
    object Dashboard : Screen("dashboard")
    object Family : Screen("family")
    object Rules : Screen("rules")
    object Apps : Screen("apps")
}

@Composable
fun AppNavigation() {
    val navController = rememberNavController()
    val authViewModel: AuthViewModel = hiltViewModel()
    val isAuthenticated by authViewModel.isAuthenticated.collectAsState()

    val startDestination = if (isAuthenticated) Screen.Dashboard.route else Screen.Auth.route

    NavHost(
        navController = navController,
        startDestination = startDestination
    ) {
        composable(Screen.Auth.route) {
            AuthScreen(
                viewModel = authViewModel,
                onAuthSuccess = {
                    navController.navigate(Screen.Dashboard.route) {
                        popUpTo(Screen.Auth.route) { inclusive = true }
                    }
                }
            )
        }

        composable(Screen.Dashboard.route) {
            DashboardScreen(
                onNavigateToFamily = { navController.navigate(Screen.Family.route) },
                onNavigateToRules = { navController.navigate(Screen.Rules.route) },
                onNavigateToApps = { navController.navigate(Screen.Apps.route) },
                onSignOut = {
                    authViewModel.signOut()
                    navController.navigate(Screen.Auth.route) {
                        popUpTo(Screen.Dashboard.route) { inclusive = true }
                    }
                }
            )
        }

        composable(Screen.Family.route) {
            // FamilyScreen - to be implemented
        }

        composable(Screen.Rules.route) {
            // RulesScreen - to be implemented
        }

        composable(Screen.Apps.route) {
            // AppsScreen - to be implemented
        }
    }
}
