package com.screentimeparent.data.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import java.util.UUID

// User & Authentication Models

@Serializable
data class UserProfile(
    val id: String,
    val email: String,
    @SerialName("full_name") val fullName: String,
    val role: UserRole,
    @SerialName("date_of_birth") val dateOfBirth: String? = null,
    @SerialName("avatar_url") val avatarUrl: String? = null,
    @SerialName("created_at") val createdAt: String? = null,
    @SerialName("updated_at") val updatedAt: String? = null
)

@Serializable
enum class UserRole {
    @SerialName("parent") PARENT,
    @SerialName("child") CHILD
}

// Family Models

@Serializable
data class Family(
    val id: String,
    val name: String,
    @SerialName("invite_code") val inviteCode: String,
    @SerialName("created_by") val createdBy: String,
    @SerialName("created_at") val createdAt: String? = null,
    @SerialName("updated_at") val updatedAt: String? = null
)

@Serializable
data class FamilyMember(
    val id: String,
    @SerialName("family_id") val familyId: String,
    @SerialName("user_id") val userId: String,
    val role: FamilyMemberRole,
    val nickname: String? = null,
    @SerialName("joined_at") val joinedAt: String? = null,
    @SerialName("user_profile") val userProfile: UserProfile? = null
)

@Serializable
enum class FamilyMemberRole {
    @SerialName("admin") ADMIN,
    @SerialName("parent") PARENT,
    @SerialName("child") CHILD
}

// Device Models

@Serializable
data class Device(
    val id: String,
    @SerialName("child_id") val childId: String,
    @SerialName("family_id") val familyId: String,
    @SerialName("device_name") val deviceName: String,
    @SerialName("device_identifier") val deviceIdentifier: String,
    val platform: DevicePlatform,
    @SerialName("os_version") val osVersion: String? = null,
    @SerialName("app_version") val appVersion: String? = null,
    @SerialName("last_sync") val lastSync: String? = null,
    @SerialName("is_active") val isActive: Boolean = true,
    @SerialName("registered_at") val registeredAt: String? = null
)

@Serializable
enum class DevicePlatform {
    @SerialName("ios") IOS,
    @SerialName("ipados") IPADOS,
    @SerialName("android") ANDROID
}

// App Models

@Serializable
data class App(
    val id: String,
    @SerialName("family_id") val familyId: String,
    @SerialName("bundle_id") val bundleId: String,
    @SerialName("app_name") val appName: String,
    val category: AppCategory,
    @SerialName("icon_url") val iconUrl: String? = null,
    @SerialName("is_blocked") val isBlocked: Boolean = false,
    @SerialName("time_limit_minutes") val timeLimitMinutes: Int? = null,
    val notes: String? = null,
    @SerialName("created_at") val createdAt: String? = null,
    @SerialName("updated_at") val updatedAt: String? = null
)

@Serializable
enum class AppCategory {
    @SerialName("educational") EDUCATIONAL,
    @SerialName("recreational") RECREATIONAL,
    @SerialName("utility") UTILITY,
    @SerialName("uncategorized") UNCATEGORIZED
}

// Screen Time Rules

@Serializable
data class ScreenTimeRule(
    val id: String,
    @SerialName("family_id") val familyId: String,
    @SerialName("child_id") val childId: String? = null,
    val name: String,
    val description: String? = null,
    @SerialName("required_educational_minutes") val requiredEducationalMinutes: Int,
    @SerialName("max_recreational_minutes") val maxRecreationalMinutes: Int? = null,
    @SerialName("start_time") val startTime: String? = null,
    @SerialName("end_time") val endTime: String? = null,
    @SerialName("active_days") val activeDays: List<Int> = listOf(0, 1, 2, 3, 4, 5, 6),
    val priority: Int = 0,
    @SerialName("is_active") val isActive: Boolean = true,
    @SerialName("created_at") val createdAt: String? = null,
    @SerialName("updated_at") val updatedAt: String? = null
)

// Usage & Enforcement Models

@Serializable
data class UsageSession(
    val id: String,
    @SerialName("child_id") val childId: String,
    @SerialName("device_id") val deviceId: String,
    @SerialName("app_id") val appId: String? = null,
    @SerialName("bundle_id") val bundleId: String,
    @SerialName("app_name") val appName: String,
    val category: AppCategory,
    @SerialName("started_at") val startedAt: String,
    @SerialName("ended_at") val endedAt: String? = null,
    @SerialName("duration_seconds") val durationSeconds: Int? = null,
    val date: String,
    @SerialName("synced_at") val syncedAt: String? = null,
    @SerialName("created_at") val createdAt: String? = null
)

@Serializable
data class EarnedTime(
    val id: String,
    @SerialName("child_id") val childId: String,
    @SerialName("family_id") val familyId: String,
    val date: String,
    @SerialName("educational_minutes") val educationalMinutes: Int = 0,
    @SerialName("required_educational_minutes") val requiredEducationalMinutes: Int = 0,
    @SerialName("recreational_minutes_used") val recreationalMinutesUsed: Int = 0,
    @SerialName("recreational_minutes_available") val recreationalMinutesAvailable: Int? = null,
    @SerialName("requirement_met") val requirementMet: Boolean = false,
    @SerialName("last_calculated") val lastCalculated: String? = null,
    @SerialName("created_at") val createdAt: String? = null,
    @SerialName("updated_at") val updatedAt: String? = null
)

// Dashboard Models

data class ChildStatus(
    val childId: String,
    val childName: String,
    val deviceName: String?,
    val educationalMinutes: Int,
    val requiredEducationalMinutes: Int,
    val recreationalMinutesUsed: Int,
    val recreationalMinutesAvailable: Int?,
    val requirementMet: Boolean,
    val lastSync: String?,
    val isOnline: Boolean
)

data class FamilyOverview(
    val id: String,
    val name: String,
    val inviteCode: String,
    val childCount: Int,
    val parentCount: Int,
    val deviceCount: Int
)
