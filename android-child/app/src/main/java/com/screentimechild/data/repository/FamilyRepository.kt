package com.screentimechild.data.repository

import android.os.Build
import com.screentimechild.data.models.*
import com.screentimechild.data.remote.SupabaseClientProvider
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.postgrest.postgrest
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class FamilyRepository @Inject constructor() {

    private val supabase = SupabaseClientProvider.client

    suspend fun joinFamily(inviteCode: String): Result<Family> {
        return try {
            val userId = supabase.auth.currentUserOrNull()?.id
                ?: return Result.failure(Exception("User not authenticated"))

            val family = supabase.postgrest["families"]
                .select {
                    filter {
                        eq("invite_code", inviteCode.uppercase())
                    }
                }
                .decodeSingleOrNull<Family>()
                ?: return Result.failure(Exception("Invalid invite code"))

            // Check if already a member
            val existingMember = supabase.postgrest["family_members"]
                .select {
                    filter {
                        eq("family_id", family.id)
                        eq("user_id", userId)
                    }
                }
                .decodeSingleOrNull<FamilyMember>()

            if (existingMember != null) {
                return Result.failure(Exception("Already a member of this family"))
            }

            // Add as child
            val member = FamilyMember(
                id = UUID.randomUUID().toString(),
                familyId = family.id,
                userId = userId,
                role = FamilyMemberRole.CHILD
            )
            supabase.postgrest["family_members"].insert(member)

            Result.success(family)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getCurrentFamily(): Family? {
        val userId = supabase.auth.currentUserOrNull()?.id ?: return null

        return try {
            val membership = supabase.postgrest["family_members"]
                .select {
                    filter {
                        eq("user_id", userId)
                    }
                }
                .decodeSingleOrNull<FamilyMember>()

            if (membership != null) {
                supabase.postgrest["families"]
                    .select {
                        filter {
                            eq("id", membership.familyId)
                        }
                    }
                    .decodeSingle<Family>()
            } else {
                null
            }
        } catch (e: Exception) {
            null
        }
    }

    suspend fun registerDevice(deviceName: String, deviceIdentifier: String): Result<Device> {
        return try {
            val userId = supabase.auth.currentUserOrNull()?.id
                ?: return Result.failure(Exception("User not authenticated"))

            val family = getCurrentFamily()
                ?: return Result.failure(Exception("Not a member of any family"))

            // Check if device already registered
            val existingDevice = supabase.postgrest["devices"]
                .select {
                    filter {
                        eq("device_identifier", deviceIdentifier)
                        eq("child_id", userId)
                    }
                }
                .decodeSingleOrNull<Device>()

            if (existingDevice != null) {
                // Update last sync
                supabase.postgrest["devices"]
                    .update({
                        set("last_sync", java.time.Instant.now().toString())
                        set("is_active", true)
                    }) {
                        filter {
                            eq("id", existingDevice.id)
                        }
                    }
                return Result.success(existingDevice)
            }

            val device = Device(
                id = UUID.randomUUID().toString(),
                childId = userId,
                familyId = family.id,
                deviceName = deviceName,
                deviceIdentifier = deviceIdentifier,
                platform = DevicePlatform.ANDROID,
                osVersion = "Android ${Build.VERSION.RELEASE}",
                appVersion = "1.0.0",
                isActive = true
            )

            supabase.postgrest["devices"].insert(device)

            Result.success(device)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getActiveRules(): List<ScreenTimeRule> {
        val userId = supabase.auth.currentUserOrNull()?.id ?: return emptyList()
        val family = getCurrentFamily() ?: return emptyList()

        return try {
            supabase.postgrest["screen_time_rules"]
                .select {
                    filter {
                        eq("family_id", family.id)
                        eq("is_active", true)
                    }
                }
                .decodeList<ScreenTimeRule>()
                .filter { rule ->
                    // Filter rules that apply to this child or all children
                    rule.childId == null || rule.childId == userId
                }
        } catch (e: Exception) {
            emptyList()
        }
    }

    suspend fun getAppCategories(): Map<String, AppCategory> {
        val family = getCurrentFamily() ?: return emptyMap()

        return try {
            val apps = supabase.postgrest["apps"]
                .select {
                    filter {
                        eq("family_id", family.id)
                    }
                }
                .decodeList<App>()

            apps.associate { it.bundleId to it.category }
        } catch (e: Exception) {
            emptyMap()
        }
    }

    suspend fun getBlockedApps(): Set<String> {
        val family = getCurrentFamily() ?: return emptySet()

        return try {
            val apps = supabase.postgrest["apps"]
                .select {
                    filter {
                        eq("family_id", family.id)
                        eq("is_blocked", true)
                    }
                }
                .decodeList<App>()

            apps.map { it.bundleId }.toSet()
        } catch (e: Exception) {
            emptySet()
        }
    }
}
