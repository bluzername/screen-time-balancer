package com.screentimeparent.ui.dashboard

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ExitToApp
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.screentimeparent.data.models.ChildStatus

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DashboardScreen(
    viewModel: DashboardViewModel = hiltViewModel(),
    onNavigateToFamily: () -> Unit,
    onNavigateToRules: () -> Unit,
    onNavigateToApps: () -> Unit,
    onSignOut: () -> Unit
) {
    val uiState by viewModel.uiState.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Dashboard") },
                actions = {
                    IconButton(onClick = viewModel::refresh) {
                        Icon(Icons.Default.Refresh, contentDescription = "Refresh")
                    }
                    IconButton(onClick = onSignOut) {
                        Icon(Icons.Default.ExitToApp, contentDescription = "Sign Out")
                    }
                }
            )
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            when {
                uiState.isLoading -> {
                    CircularProgressIndicator(
                        modifier = Modifier.align(Alignment.Center)
                    )
                }
                uiState.error != null -> {
                    Column(
                        modifier = Modifier
                            .align(Alignment.Center)
                            .padding(24.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(
                            text = uiState.error ?: "Unknown error",
                            color = MaterialTheme.colorScheme.error
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Button(onClick = viewModel::refresh) {
                            Text("Retry")
                        }
                    }
                }
                !uiState.hasFamily -> {
                    NoFamilyContent(
                        onCreateFamily = onNavigateToFamily,
                        modifier = Modifier.align(Alignment.Center)
                    )
                }
                else -> {
                    DashboardContent(
                        familyName = uiState.familyOverview?.name ?: "",
                        inviteCode = uiState.familyOverview?.inviteCode ?: "",
                        childStatuses = uiState.childStatuses,
                        onNavigateToFamily = onNavigateToFamily,
                        onNavigateToRules = onNavigateToRules,
                        onNavigateToApps = onNavigateToApps
                    )
                }
            }
        }
    }
}

@Composable
private fun NoFamilyContent(
    onCreateFamily: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier.padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = "Welcome!",
            style = MaterialTheme.typography.headlineMedium,
            modifier = Modifier.padding(bottom = 16.dp)
        )
        Text(
            text = "Create a family to get started managing your children's screen time.",
            style = MaterialTheme.typography.bodyLarge,
            modifier = Modifier.padding(bottom = 24.dp)
        )
        Button(onClick = onCreateFamily) {
            Text("Create Family")
        }
    }
}

@Composable
private fun DashboardContent(
    familyName: String,
    inviteCode: String,
    childStatuses: List<ChildStatus>,
    onNavigateToFamily: () -> Unit,
    onNavigateToRules: () -> Unit,
    onNavigateToApps: () -> Unit
) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        item {
            FamilyOverviewCard(
                familyName = familyName,
                inviteCode = inviteCode,
                onManageFamily = onNavigateToFamily
            )
        }

        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                OutlinedButton(
                    onClick = onNavigateToRules,
                    modifier = Modifier.weight(1f)
                ) {
                    Text("Manage Rules")
                }
                OutlinedButton(
                    onClick = onNavigateToApps,
                    modifier = Modifier.weight(1f)
                ) {
                    Text("Manage Apps")
                }
            }
        }

        item {
            Text(
                text = "Children",
                style = MaterialTheme.typography.titleLarge,
                modifier = Modifier.padding(vertical = 8.dp)
            )
        }

        if (childStatuses.isEmpty()) {
            item {
                Card(
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(
                        modifier = Modifier.padding(24.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(
                            text = "No children in family yet",
                            style = MaterialTheme.typography.bodyLarge
                        )
                        Text(
                            text = "Share invite code: $inviteCode",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.primary
                        )
                    }
                }
            }
        } else {
            items(childStatuses) { childStatus ->
                ChildStatusCard(childStatus = childStatus)
            }
        }
    }
}

@Composable
private fun FamilyOverviewCard(
    familyName: String,
    inviteCode: String,
    onManageFamily: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                text = familyName,
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(8.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text(
                        text = "Invite Code",
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = inviteCode,
                        style = MaterialTheme.typography.titleMedium,
                        color = MaterialTheme.colorScheme.primary
                    )
                }
                TextButton(onClick = onManageFamily) {
                    Text("Manage")
                }
            }
        }
    }
}

@Composable
private fun ChildStatusCard(
    childStatus: ChildStatus
) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = childStatus.childName,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
                StatusBadge(
                    isOnline = childStatus.isOnline,
                    requirementMet = childStatus.requirementMet
                )
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Educational Progress
            Text(
                text = "Educational Progress",
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            LinearProgressIndicator(
                progress = {
                    if (childStatus.requiredEducationalMinutes > 0) {
                        (childStatus.educationalMinutes.toFloat() / childStatus.requiredEducationalMinutes).coerceIn(0f, 1f)
                    } else 0f
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 4.dp),
                color = if (childStatus.requirementMet) {
                    MaterialTheme.colorScheme.primary
                } else {
                    MaterialTheme.colorScheme.secondary
                }
            )
            Text(
                text = "${childStatus.educationalMinutes} / ${childStatus.requiredEducationalMinutes} min",
                style = MaterialTheme.typography.bodySmall
            )

            Spacer(modifier = Modifier.height(8.dp))

            // Recreational Usage
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Column {
                    Text(
                        text = "Recreational Used",
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = "${childStatus.recreationalMinutesUsed} min",
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
                Column(horizontalAlignment = Alignment.End) {
                    Text(
                        text = "Available",
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = "${childStatus.recreationalMinutesAvailable ?: "Unlimited"} min",
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
            }

            childStatus.deviceName?.let { device ->
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "Device: $device",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
private fun StatusBadge(
    isOnline: Boolean,
    requirementMet: Boolean
) {
    val (color, text) = when {
        !isOnline -> MaterialTheme.colorScheme.surfaceVariant to "Offline"
        requirementMet -> MaterialTheme.colorScheme.primaryContainer to "Unlocked"
        else -> MaterialTheme.colorScheme.errorContainer to "Locked"
    }

    Surface(
        color = color,
        shape = MaterialTheme.shapes.small
    ) {
        Text(
            text = text,
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
            style = MaterialTheme.typography.labelSmall
        )
    }
}
