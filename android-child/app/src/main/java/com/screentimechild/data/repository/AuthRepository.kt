package com.screentimechild.data.repository

import com.screentimechild.data.models.UserProfile
import com.screentimechild.data.models.UserRole
import com.screentimechild.data.remote.SupabaseClientProvider
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.auth.providers.builtin.Email
import io.github.jan.supabase.postgrest.postgrest
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AuthRepository @Inject constructor() {

    private val supabase = SupabaseClientProvider.client

    suspend fun signUp(email: String, password: String, fullName: String): Result<UserProfile> {
        return try {
            supabase.auth.signUpWith(Email) {
                this.email = email
                this.password = password
            }

            val userId = supabase.auth.currentUserOrNull()?.id
                ?: return Result.failure(Exception("User ID not found after signup"))

            // Create user profile as CHILD role
            val profile = UserProfile(
                id = userId,
                email = email,
                fullName = fullName,
                role = UserRole.CHILD
            )

            supabase.postgrest["user_profiles"].insert(profile)

            Result.success(profile)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun signIn(email: String, password: String): Result<UserProfile> {
        return try {
            supabase.auth.signInWith(Email) {
                this.email = email
                this.password = password
            }

            val userId = supabase.auth.currentUserOrNull()?.id
                ?: return Result.failure(Exception("User ID not found after signin"))

            val profile = supabase.postgrest["user_profiles"]
                .select {
                    filter {
                        eq("id", userId)
                    }
                }
                .decodeSingle<UserProfile>()

            Result.success(profile)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun signOut(): Result<Unit> {
        return try {
            supabase.auth.signOut()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getCurrentUser(): UserProfile? {
        val userId = supabase.auth.currentUserOrNull()?.id ?: return null

        return try {
            supabase.postgrest["user_profiles"]
                .select {
                    filter {
                        eq("id", userId)
                    }
                }
                .decodeSingle<UserProfile>()
        } catch (e: Exception) {
            null
        }
    }

    fun isAuthenticated(): Boolean {
        return supabase.auth.currentUserOrNull() != null
    }

    fun getCurrentUserId(): String? {
        return supabase.auth.currentUserOrNull()?.id
    }
}
