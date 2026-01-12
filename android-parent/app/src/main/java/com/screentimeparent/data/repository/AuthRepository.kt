package com.screentimeparent.data.repository

import com.screentimeparent.data.models.UserProfile
import com.screentimeparent.data.models.UserRole
import com.screentimeparent.data.remote.SupabaseClientProvider
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.auth.providers.builtin.Email
import io.github.jan.supabase.postgrest.postgrest
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AuthRepository @Inject constructor() {

    private val supabase = SupabaseClientProvider.client

    suspend fun signUp(email: String, password: String, fullName: String): Result<UserProfile> {
        return try {
            // Sign up with Supabase Auth
            supabase.auth.signUpWith(Email) {
                this.email = email
                this.password = password
            }

            // Get the user ID
            val userId = supabase.auth.currentUserOrNull()?.id
                ?: return Result.failure(Exception("User ID not found after signup"))

            // Create user profile
            val profile = UserProfile(
                id = userId,
                email = email,
                fullName = fullName,
                role = UserRole.PARENT
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

            // Fetch user profile
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

    fun observeAuthState(): Flow<Boolean> = flow {
        emit(isAuthenticated())
        // In a real app, you'd observe the auth state changes
    }
}
