package com.screentimeparent.di

import com.screentimeparent.data.repository.AuthRepository
import com.screentimeparent.data.repository.FamilyRepository
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
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
}
