package com.screentimechild.data.repository

import com.screentimechild.data.models.*
import com.screentimechild.data.remote.SupabaseClientProvider
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.postgrest.postgrest
import java.time.Instant
import java.time.LocalDate
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class UsageRepository @Inject constructor(
    private val familyRepository: FamilyRepository
) {
    private val supabase = SupabaseClientProvider.client

    suspend fun recordSession(
        deviceId: String,
        packageName: String,
        appName: String,
        category: AppCategory,
        startTime: Instant,
        endTime: Instant
    ): Result<UsageSession> {
        return try {
            val userId = supabase.auth.currentUserOrNull()?.id
                ?: return Result.failure(Exception("User not authenticated"))

            val durationSeconds = (endTime.epochSecond - startTime.epochSecond).toInt()
            val today = LocalDate.now().toString()

            val session = UsageSession(
                id = UUID.randomUUID().toString(),
                childId = userId,
                deviceId = deviceId,
                bundleId = packageName,
                appName = appName,
                category = category,
                startedAt = startTime.toString(),
                endedAt = endTime.toString(),
                durationSeconds = durationSeconds,
                date = today,
                syncedAt = Instant.now().toString()
            )

            supabase.postgrest["usage_sessions"].insert(session)

            // Update earned time
            updateEarnedTime(userId, category, durationSeconds)

            Result.success(session)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    private suspend fun updateEarnedTime(userId: String, category: AppCategory, durationSeconds: Int) {
        val today = LocalDate.now().toString()
        val family = familyRepository.getCurrentFamily() ?: return
        val rules = familyRepository.getActiveRules()
        val requiredMinutes = rules.maxOfOrNull { it.requiredEducationalMinutes } ?: 30

        try {
            // Get or create today's earned time record
            var earnedTime = supabase.postgrest["earned_time"]
                .select {
                    filter {
                        eq("child_id", userId)
                        eq("date", today)
                    }
                }
                .decodeSingleOrNull<EarnedTime>()

            val durationMinutes = durationSeconds / 60

            if (earnedTime == null) {
                // Create new record
                earnedTime = EarnedTime(
                    id = UUID.randomUUID().toString(),
                    childId = userId,
                    familyId = family.id,
                    date = today,
                    educationalMinutes = if (category == AppCategory.EDUCATIONAL) durationMinutes else 0,
                    requiredEducationalMinutes = requiredMinutes,
                    recreationalMinutesUsed = if (category == AppCategory.RECREATIONAL) durationMinutes else 0,
                    requirementMet = false,
                    lastCalculated = Instant.now().toString()
                )
                supabase.postgrest["earned_time"].insert(earnedTime)
            } else {
                // Update existing record
                val newEducational = if (category == AppCategory.EDUCATIONAL) {
                    earnedTime.educationalMinutes + durationMinutes
                } else {
                    earnedTime.educationalMinutes
                }

                val newRecreational = if (category == AppCategory.RECREATIONAL) {
                    earnedTime.recreationalMinutesUsed + durationMinutes
                } else {
                    earnedTime.recreationalMinutesUsed
                }

                val requirementMet = newEducational >= requiredMinutes

                supabase.postgrest["earned_time"]
                    .update({
                        set("educational_minutes", newEducational)
                        set("recreational_minutes_used", newRecreational)
                        set("requirement_met", requirementMet)
                        set("last_calculated", Instant.now().toString())
                    }) {
                        filter {
                            eq("id", earnedTime.id)
                        }
                    }
            }
        } catch (e: Exception) {
            // Log error but don't fail the session recording
            e.printStackTrace()
        }
    }

    suspend fun getTodayEarnedTime(): EarnedTime? {
        val userId = supabase.auth.currentUserOrNull()?.id ?: return null
        val today = LocalDate.now().toString()

        return try {
            supabase.postgrest["earned_time"]
                .select {
                    filter {
                        eq("child_id", userId)
                        eq("date", today)
                    }
                }
                .decodeSingleOrNull<EarnedTime>()
        } catch (e: Exception) {
            null
        }
    }

    suspend fun isRequirementMet(): Boolean {
        val earnedTime = getTodayEarnedTime() ?: return false
        return earnedTime.requirementMet
    }

    suspend fun syncPendingSessions(sessions: List<UsageSession>): Result<Unit> {
        return try {
            if (sessions.isNotEmpty()) {
                supabase.postgrest["usage_sessions"].insert(sessions)
            }
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
