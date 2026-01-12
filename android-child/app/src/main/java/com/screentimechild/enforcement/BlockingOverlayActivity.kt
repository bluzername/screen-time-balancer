package com.screentimechild.enforcement

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.screentimechild.ui.theme.ScreenTimeChildTheme

class BlockingOverlayActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val educationalMinutes = intent.getIntExtra("educational_minutes", 0)
        val requiredMinutes = intent.getIntExtra("required_minutes", 30)

        setContent {
            ScreenTimeChildTheme {
                BlockingOverlayScreen(
                    educationalMinutes = educationalMinutes,
                    requiredMinutes = requiredMinutes,
                    onGoToEducational = {
                        // Navigate back to home to select educational app
                        finish()
                        // Could launch a specific educational app selector here
                    }
                )
            }
        }
    }

    override fun onBackPressed() {
        // Go to home instead of back to blocked app
        val homeIntent = android.content.Intent(android.content.Intent.ACTION_MAIN).apply {
            addCategory(android.content.Intent.CATEGORY_HOME)
            flags = android.content.Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(homeIntent)
        finish()
    }
}

@Composable
fun BlockingOverlayScreen(
    educationalMinutes: Int,
    requiredMinutes: Int,
    onGoToEducational: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF1A1A2E)),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.padding(32.dp)
        ) {
            Icon(
                imageVector = Icons.Default.Lock,
                contentDescription = null,
                tint = Color(0xFFE94560),
                modifier = Modifier.size(80.dp)
            )

            Spacer(modifier = Modifier.height(24.dp))

            Text(
                text = "App Locked",
                style = MaterialTheme.typography.headlineLarge,
                color = Color.White,
                fontWeight = FontWeight.Bold
            )

            Spacer(modifier = Modifier.height(16.dp))

            Text(
                text = "Complete your educational time to unlock recreational apps",
                style = MaterialTheme.typography.bodyLarge,
                color = Color.White.copy(alpha = 0.8f),
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(32.dp))

            // Progress card
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = Color.White.copy(alpha = 0.1f)
                )
            ) {
                Column(
                    modifier = Modifier.padding(24.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        text = "Educational Progress",
                        style = MaterialTheme.typography.titleMedium,
                        color = Color.White
                    )

                    Spacer(modifier = Modifier.height(16.dp))

                    val progress = if (requiredMinutes > 0) {
                        (educationalMinutes.toFloat() / requiredMinutes).coerceIn(0f, 1f)
                    } else 0f

                    LinearProgressIndicator(
                        progress = { progress },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(12.dp),
                        color = Color(0xFF0F3460),
                        trackColor = Color.White.copy(alpha = 0.2f)
                    )

                    Spacer(modifier = Modifier.height(12.dp))

                    Text(
                        text = "$educationalMinutes / $requiredMinutes minutes",
                        style = MaterialTheme.typography.titleLarge,
                        color = Color.White,
                        fontWeight = FontWeight.Bold
                    )

                    val remainingMinutes = (requiredMinutes - educationalMinutes).coerceAtLeast(0)
                    Text(
                        text = "$remainingMinutes minutes remaining",
                        style = MaterialTheme.typography.bodyMedium,
                        color = Color.White.copy(alpha = 0.7f)
                    )
                }
            }

            Spacer(modifier = Modifier.height(32.dp))

            Button(
                onClick = onGoToEducational,
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color(0xFF0F3460)
                ),
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(
                    text = "Use Educational Apps",
                    modifier = Modifier.padding(vertical = 8.dp)
                )
            }

            Spacer(modifier = Modifier.height(16.dp))

            Text(
                text = "Open an educational app to earn screen time",
                style = MaterialTheme.typography.bodySmall,
                color = Color.White.copy(alpha = 0.5f),
                textAlign = TextAlign.Center
            )
        }
    }
}
