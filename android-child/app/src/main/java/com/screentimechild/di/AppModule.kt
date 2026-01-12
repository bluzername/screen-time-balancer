package com.screentimechild.di

import android.content.Context
import com.screentimechild.data.repository.AuthRepository
import com.screentimechild.data.repository.FamilyRepository
import com.screentimechild.data.repository.UsageRepository
import com.screentimechild.enforcement.EnforcementEngine
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AppModule {

    @Provides
    @Singleton
    fun provideAuthRepository(): AuthRepository {
        return AuthRepository()
    }

    @Provides
    @Singleton
    fun provideFamilyRepository(): FamilyRepository {
        return FamilyRepository()
    }

    @Provides
    @Singleton
    fun provideUsageRepository(familyRepository: FamilyRepository): UsageRepository {
        return UsageRepository(familyRepository)
    }

    @Provides
    @Singleton
    fun provideEnforcementEngine(
        @ApplicationContext context: Context,
        familyRepository: FamilyRepository,
        usageRepository: UsageRepository
    ): EnforcementEngine {
        return EnforcementEngine(context, familyRepository, usageRepository)
    }
}
