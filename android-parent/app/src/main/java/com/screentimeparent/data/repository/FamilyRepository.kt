package com.screentimeparent.data.repository

import com.screentimeparent.data.models.*
import com.screentimeparent.data.remote.SupabaseClientProvider
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.postgrest.query.Columns
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class FamilyRepository @Inject constructor() {

    private val supabase = SupabaseClientProvider.client

    suspend fun createFamily(name: String): Result<Family> {
        return try {
            val userId = supabase.auth.currentUserOrNull()?.id
                ?: return Result.failure(Exception("User not authenticated"))

            val inviteCode = generateInviteCode()
            val familyId = UUID.randomUUID().toString()

            val family = Family(
                id = familyId,
                name = name,
                inviteCode = inviteCode,
                createdBy = userId
            )

            supabase.postgrest["families"].insert(family)

            // Add creator as admin
            val member = FamilyMember(
                id = UUID.randomUUID().toString(),
                familyId = familyId,
                userId = userId,
                role = FamilyMemberRole.ADMIN
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

    suspend fun getCurrentFamilyOverview(): FamilyOverview? {
        val family = getCurrentFamily() ?: return null

        return try {
            val members = supabase.postgrest["family_members"]
                .select {
                    filter {
                        eq("family_id", family.id)
                    }
                }
                .decodeList<FamilyMember>()

            val childCount = members.count { it.role == FamilyMemberRole.CHILD }
            val parentCount = members.count { it.role != FamilyMemberRole.CHILD }

            val deviceCount = supabase.postgrest["devices"]
                .select {
                    filter {
                        eq("family_id", family.id)
                    }
                }
                .decodeList<Device>().size

            FamilyOverview(
                id = family.id,
                name = family.name,
                inviteCode = family.inviteCode,
                childCount = childCount,
                parentCount = parentCount,
                deviceCount = deviceCount
            )
        } catch (e: Exception) {
            null
        }
    }

    suspend fun getFamilyMembers(familyId: String): List<FamilyMember> {
        return try {
            supabase.postgrest["family_members"]
                .select(Columns.raw("*, user_profile:user_profiles(*)")) {
                    filter {
                        eq("family_id", familyId)
                    }
                }
                .decodeList<FamilyMember>()
        } catch (e: Exception) {
            emptyList()
        }
    }

    suspend fun getChildStatuses(familyId: String): List<ChildStatus> {
        return try {
            val members = getFamilyMembers(familyId)
            val children = members.filter { it.role == FamilyMemberRole.CHILD }

            children.mapNotNull { member ->
                val profile = member.userProfile ?: return@mapNotNull null

                // Get device info
                val device = supabase.postgrest["devices"]
                    .select {
                        filter {
                            eq("child_id", member.userId)
                        }
                    }
                    .decodeSingleOrNull<Device>()

                // Get today's earned time
                val today = java.time.LocalDate.now().toString()
                val earnedTime = supabase.postgrest["earned_time"]
                    .select {
                        filter {
                            eq("child_id", member.userId)
                            eq("date", today)
                        }
                    }
                    .decodeSingleOrNull<EarnedTime>()

                ChildStatus(
                    childId = member.userId,
                    childName = member.nickname ?: profile.fullName,
                    deviceName = device?.deviceName,
                    educationalMinutes = earnedTime?.educationalMinutes ?: 0,
                    requiredEducationalMinutes = earnedTime?.requiredEducationalMinutes ?: 30,
                    recreationalMinutesUsed = earnedTime?.recreationalMinutesUsed ?: 0,
                    recreationalMinutesAvailable = earnedTime?.recreationalMinutesAvailable,
                    requirementMet = earnedTime?.requirementMet ?: false,
                    lastSync = device?.lastSync,
                    isOnline = device?.isActive ?: false
                )
            }
        } catch (e: Exception) {
            emptyList()
        }
    }

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

            // Add as parent
            val member = FamilyMember(
                id = UUID.randomUUID().toString(),
                familyId = family.id,
                userId = userId,
                role = FamilyMemberRole.PARENT
            )
            supabase.postgrest["family_members"].insert(member)

            Result.success(family)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    private fun generateInviteCode(): String {
        val chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return (1..6).map { chars.random() }.joinToString("")
    }

    fun observeFamilyUpdates(familyId: String): Flow<Family?> = flow {
        // Polling-based updates
        while (true) {
            try {
                val family = supabase.postgrest["families"]
                    .select {
                        filter {
                            eq("id", familyId)
                        }
                    }
                    .decodeSingleOrNull<Family>()
                emit(family)
            } catch (e: Exception) {
                emit(null)
            }
            kotlinx.coroutines.delay(60000) // Poll every 60 seconds
        }
    }
}
