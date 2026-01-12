package com.screentimechild.ui.setup

import android.content.Context
import android.content.Intent
import android.provider.Settings
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SetupScreen(
    viewModel: SetupViewModel = hiltViewModel(),
    onSetupComplete: () -> Unit
) {
    val uiState by viewModel.uiState.collectAsState()
    val context = LocalContext.current

    // Check permissions when screen loads
    LaunchedEffect(Unit) {
        viewModel.checkPermissions(context)
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Setup") }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(16.dp)
                .verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            if (!uiState.hasJoinedFamily) {
                // Step 1: Join Family
                Card(
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp)
                    ) {
                        Text(
                            text = "Step 1: Join Family",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold
                        )

                        Spacer(modifier = Modifier.height(8.dp))

                        Text(
                            text = "Enter the invite code from your parent's app",
                            style = MaterialTheme.typography.bodyMedium
                        )

                        Spacer(modifier = Modifier.height(16.dp))

                        OutlinedTextField(
                            value = uiState.inviteCode,
                            onValueChange = viewModel::updateInviteCode,
                            label = { Text("Invite Code") },
                            singleLine = true,
                            modifier = Modifier.fillMaxWidth()
                        )

                        uiState.joinError?.let { error ->
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                text = error,
                                color = MaterialTheme.colorScheme.error,
                                style = MaterialTheme.typography.bodySmall
                            )
                        }

                        Spacer(modifier = Modifier.height(16.dp))

                        Button(
                            onClick = { viewModel.joinFamily() },
                            modifier = Modifier.fillMaxWidth(),
                            enabled = !uiState.isLoading && uiState.inviteCode.length >= 6
                        ) {
                            if (uiState.isLoading) {
                                CircularProgressIndicator(
                                    modifier = Modifier.size(20.dp),
                                    color = MaterialTheme.colorScheme.onPrimary
                                )
                            } else {
                                Text("Join Family")
                            }
                        }
                    }
                }
            } else {
                // Step 2: Grant Permissions
                Text(
                    text = "Family Joined!",
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.primary
                )

                Spacer(modifier = Modifier.height(8.dp))

                Text(
                    text = "Now grant the required permissions for screen time monitoring:",
                    style = MaterialTheme.typography.bodyMedium
                )

                Spacer(modifier = Modifier.height(16.dp))

                // Usage Stats Permission
                PermissionCard(
                    title = "Usage Access",
                    description = "Required to track app usage time",
                    isGranted = uiState.hasUsageStatsPermission,
                    onRequest = {
                        context.startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                    }
                )

                // Accessibility Service Permission
                PermissionCard(
                    title = "Accessibility Service",
                    description = "Required to monitor app launches",
                    isGranted = uiState.hasAccessibilityPermission,
                    onRequest = {
                        context.startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                    }
                )

                // Overlay Permission
                PermissionCard(
                    title = "Display Over Other Apps",
                    description = "Required to show blocking screen",
                    isGranted = uiState.hasOverlayPermission,
                    onRequest = {
                        context.startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION))
                    }
                )

                Spacer(modifier = Modifier.height(16.dp))

                Button(
                    onClick = { viewModel.checkPermissions(context) },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("Check Permissions")
                }

                Spacer(modifier = Modifier.height(8.dp))

                val allPermissionsGranted = uiState.hasUsageStatsPermission &&
                        uiState.hasAccessibilityPermission &&
                        uiState.hasOverlayPermission

                Button(
                    onClick = {
                        viewModel.completeSetup(context)
                        onSetupComplete()
                    },
                    modifier = Modifier.fillMaxWidth(),
                    enabled = allPermissionsGranted
                ) {
                    Text("Complete Setup")
                }

                if (!allPermissionsGranted) {
                    Text(
                        text = "Grant all permissions to continue",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.align(Alignment.CenterHorizontally)
                    )
                }
            }
        }
    }
}

@Composable
private fun PermissionCard(
    title: String,
    description: String,
    isGranted: Boolean,
    onRequest: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = if (isGranted) Icons.Default.Check else Icons.Default.Warning,
                        contentDescription = null,
                        tint = if (isGranted) {
                            MaterialTheme.colorScheme.primary
                        } else {
                            MaterialTheme.colorScheme.error
                        },
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = title,
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.Bold
                    )
                }
                Text(
                    text = description,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            if (!isGranted) {
                OutlinedButton(onClick = onRequest) {
                    Text("Grant")
                }
            }
        }
    }
}
