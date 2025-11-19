# Data Persistence Migration Plan

## Executive Summary

This document outlines the migration strategy from the current UserDefaults-based local storage to a robust Core Data / SwiftData implementation for the Screen Time Balancer Child app.

**Current State:** UserDefaults + App Groups (JSON encoding)
**Target State:** Core Data / SwiftData with proper schema, migrations, and background contexts
**Timeline:** 2-3 weeks
**Priority:** Medium (P2) - Should be done before v2.0

---

## Problem Analysis

### Current Implementation Issues

1. **Storage Limitations**
   - UserDefaults limited to ~1MB total
   - Not designed for large datasets
   - No indexing or efficient queries
   - Risk of data loss if size limit exceeded

2. **Performance Problems**
   - Full JSON encoding/decoding on every read/write
   - No background processing
   - Main thread blocking
   - Slow queries (must load entire dataset)

3. **Data Integrity**
   - No transactions
   - No foreign key constraints
   - No validation at storage level
   - Corruption risk with concurrent access

4. **Scalability**
   - Cannot handle thousands of usage sessions
   - No automatic cleanup of old data
   - Memory issues with large datasets

### Where We Use UserDefaults Today

**Child App:**
- `/ScreenTimeMonitor/SharedDataManager.swift` - Session tracking
- `/App/ScreenTimeChildApp.swift` - Family/device IDs
- `/Features/Enforcement/AppTokenStorage.swift` - FamilyActivitySelection

**Data Types Stored:**
- Active sessions (~10 items)
- Completed sessions (potentially hundreds)
- App categories (dozens)
- Educational progress
- Configuration values

---

## Recommended Solution: SwiftData

### Why SwiftData (iOS 17+)?

**Pros:**
- ✅ Modern Swift-first API
- ✅ Macro-based models (less boilerplate)
- ✅ Automatic schema inference
- ✅ Built-in iCloud sync support
- ✅ Type-safe queries
- ✅ Better Xcode integration

**Cons:**
- ❌ iOS 17+ only (acceptable for new app)
- ❌ Less mature than Core Data
- ❌ Smaller community

### Alternative: Core Data

If we need iOS 15/16 support:
- More mature and battle-tested
- Larger community and resources
- More complex setup
- More boilerplate code

**Recommendation: SwiftData** (modern, cleaner API, future-proof)

---

## Migration Strategy

### Phase 1: Setup (Week 1)

#### 1.1 Add SwiftData Framework

```swift
// ScreenTimeChildApp.swift
import SwiftUI
import SwiftData

@main
struct ScreenTimeChildApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UsageSessionModel.self,
            EducationalProgressModel.self,
            AppCategoryModel.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            groupContainer: .identifier("group.com.yourcompany.screentimechild")
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
```

#### 1.2 Define Models

```swift
// UsageSessionModel.swift
import Foundation
import SwiftData

@Model
final class UsageSessionModel {
    @Attribute(.unique) var id: UUID
    var activityName: String
    var bundleId: String
    var appName: String
    var startTime: Date
    var endTime: Date?
    var durationSeconds: Int?
    var category: String
    var date: String
    var synced: Bool = false

    init(id: UUID = UUID(),
         activityName: String,
         bundleId: String,
         appName: String,
         startTime: Date,
         category: String,
         date: String) {
        self.id = id
        self.activityName = activityName
        self.bundleId = bundleId
        self.appName = appName
        self.startTime = startTime
        self.category = category
        self.date = date
    }
}

@Model
final class EducationalProgressModel {
    var currentMinutes: Int
    var requiredMinutes: Int
    var date: String
    var lastUpdated: Date

    init(currentMinutes: Int,
         requiredMinutes: Int,
         date: String) {
        self.currentMinutes = currentMinutes
        self.requiredMinutes = requiredMinutes
        self.date = date
        self.lastUpdated = Date()
    }
}

@Model
final class AppCategoryModel {
    @Attribute(.unique) var bundleId: String
    var category: String
    var displayName: String?

    init(bundleId: String, category: String) {
        self.bundleId = bundleId
        self.category = category
    }
}
```

#### 1.3 Create Data Access Layer

```swift
// PersistenceManager.swift
import SwiftData
import Foundation

@MainActor
class PersistenceManager {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Session Operations

    func saveSession(_ session: UsageSessionModel) throws {
        modelContext.insert(session)
        try modelContext.save()
    }

    func fetchUnsynced Sessions() throws -> [UsageSessionModel] {
        let descriptor = FetchDescriptor<UsageSessionModel>(
            predicate: #Predicate { $0.synced == false },
            sortBy: [SortDescriptor(\.startTime)]
        )
        return try modelContext.fetch(descriptor)
    }

    func markSessionsSynced(_ sessions: [UsageSessionModel]) throws {
        for session in sessions {
            session.synced = true
        }
        try modelContext.save()
    }

    func deleteOldSessions(olderThan days: Int = 30) throws {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let descriptor = FetchDescriptor<UsageSessionModel>(
            predicate: #Predicate { $0.startTime < cutoffDate }
        )
        let oldSessions = try modelContext.fetch(descriptor)
        for session in oldSessions {
            modelContext.delete(session)
        }
        try modelContext.save()
    }

    // MARK: - Progress Operations

    func saveProgress(_ progress: EducationalProgressModel) throws {
        // Delete old progress for same date
        let descriptor = FetchDescriptor<EducationalProgressModel>(
            predicate: #Predicate { $0.date == progress.date }
        )
        let existing = try modelContext.fetch(descriptor)
        for old in existing {
            modelContext.delete(old)
        }

        modelContext.insert(progress)
        try modelContext.save()
    }

    func getTodaysProgress() throws -> EducationalProgressModel? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())

        let descriptor = FetchDescriptor<EducationalProgressModel>(
            predicate: #Predicate { $0.date == today }
        )
        return try modelContext.fetch(descriptor).first
    }
}
```

### Phase 2: Migration Implementation (Week 2)

#### 2.1 Create Migration Logic

```swift
// DataMigrator.swift
import Foundation
import SwiftData

@MainActor
class DataMigrator {
    private let modelContext: ModelContext
    private let sharedData = SharedDataManager() // Old system

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func migrateFromUserDefaults() async throws {
        print("🔄 Starting migration from UserDefaults...")

        // Check if already migrated
        guard !UserDefaults.standard.bool(forKey: "data_migrated_to_swiftdata") else {
            print("✅ Already migrated")
            return
        }

        // Migrate sessions
        let sessions = sharedData.getTodaysSessions()
        for sessionData in sessions {
            let model = UsageSessionModel(
                id: sessionData.id,
                activityName: sessionData.activityName,
                bundleId: sessionData.bundleId,
                appName: sessionData.appName,
                startTime: sessionData.startTime,
                category: sessionData.category.rawValue,
                date: sessionData.date
            )
            model.endTime = sessionData.endTime
            model.durationSeconds = sessionData.durationSeconds
            modelContext.insert(model)
        }

        // Migrate progress
        let progress = sharedData.getEducationalProgress()
        let progressModel = EducationalProgressModel(
            currentMinutes: progress.currentMinutes,
            requiredMinutes: progress.requiredMinutes,
            date: progress.date
        )
        modelContext.insert(progressModel)

        // Migrate app categories
        let categories = sharedData.getAppCategories()
        for (bundleId, category) in categories {
            let model = AppCategoryModel(bundleId: bundleId, category: category)
            modelContext.insert(model)
        }

        // Save all
        try modelContext.save()

        // Mark as migrated
        UserDefaults.standard.set(true, forKey: "data_migrated_to_swiftdata")

        print("✅ Migration complete: \(sessions.count) sessions migrated")
    }

    func verifyMigration() -> MigrationStatus {
        // Count records in new system
        let sessionDescriptor = FetchDescriptor<UsageSessionModel>()
        let sessionCount = (try? modelContext.fetchCount(sessionDescriptor)) ?? 0

        let progressDescriptor = FetchDescriptor<EducationalProgressModel>()
        let progressCount = (try? modelContext.fetchCount(progressDescriptor)) ?? 0

        return MigrationStatus(
            sessionsMigrated: sessionCount,
            progressRecordsMigrated: progressCount,
            isComplete: UserDefaults.standard.bool(forKey: "data_migrated_to_swiftdata")
        )
    }
}

struct MigrationStatus {
    let sessionsMigrated: Int
    let progressRecordsMigrated: Int
    let isComplete: Bool
}
```

#### 2.2 Update SharedDataManager

```swift
// Update SharedDataManager to use SwiftData
class SharedDataManagerV2 {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func saveSessionStart(_ session: UsageSessionModel) {
        do {
            modelContext.insert(session)
            try modelContext.save()
        } catch {
            print("❌ Failed to save session: \(error)")
        }
    }

    func getTodaysSessions() -> [UsageSessionModel] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())

        let descriptor = FetchDescriptor<UsageSessionModel>(
            predicate: #Predicate { $0.date == today && $0.synced == false }
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // ... rest of methods updated to use SwiftData
}
```

### Phase 3: Testing & Rollout (Week 3)

#### 3.1 Testing Plan

**Unit Tests:**
```swift
@Test
func testSessionPersistence() async throws {
    let container = try ModelContainer(
        for: UsageSessionModel.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = ModelContext(container)

    let session = UsageSessionModel(
        activityName: "test",
        bundleId: "com.test",
        appName: "Test",
        startTime: Date(),
        category: "educational",
        date: "2024-01-01"
    )

    try context.save()

    let descriptor = FetchDescriptor<UsageSessionModel>()
    let sessions = try context.fetch(descriptor)

    #expect(sessions.count == 1)
    #expect(sessions.first?.bundleId == "com.test")
}
```

**Integration Tests:**
1. Migrate real UserDefaults data
2. Verify data integrity
3. Test sync with backend
4. Test performance with 1000+ records
5. Test concurrent access from app and extension

#### 3.2 Rollout Strategy

1. **Beta Testing (Week 3, Days 1-3)**
   - Enable for TestFlight beta users
   - Monitor crash reports
   - Collect performance metrics

2. **Gradual Rollout (Week 3, Days 4-5)**
   - 10% of users
   - 50% of users
   - Monitor for issues

3. **Full Release (Week 3, Days 6-7)**
   - 100% of users
   - Keep old UserDefaults code as fallback
   - Can rollback if critical issues

#### 3.3 Rollback Plan

If critical issues occur:

```swift
// Feature flag to switch between implementations
enum PersistenceMode {
    case userDefaults
    case swiftData
}

let persistenceMode: PersistenceMode = {
    if ProcessInfo.processInfo.environment["USE_SWIFTDATA"] == "true" {
        return .swiftData
    }
    return .userDefaults // Safe fallback
}()
```

---

## Performance Expectations

### Before (UserDefaults):
- Save 100 sessions: ~500ms
- Query today's sessions: ~200ms
- Memory usage: ~5MB for 1000 sessions

### After (SwiftData):
- Save 100 sessions: ~50ms (10x faster)
- Query today's sessions: ~10ms (20x faster)
- Memory usage: ~1MB for 1000 sessions (5x better)

---

## Benefits

1. **Scalability**: Handle 10,000+ sessions without performance degradation
2. **Reliability**: ACID transactions prevent data corruption
3. **Performance**: 10-20x faster queries
4. **Features**: Advanced queries, relationships, automatic cleanup
5. **Future-proof**: iCloud sync ready, better analytics support

---

## Risks & Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Migration data loss | High | Low | Comprehensive testing, keep backup |
| Performance regression | Medium | Low | Benchmarking, rollback plan |
| App Store rejection | Low | Very Low | Follows Apple guidelines |
| User confusion | Low | Low | Silent migration, no user action needed |

---

## Success Criteria

- ✅ 100% of user data migrated successfully
- ✅ No data loss during migration
- ✅ 90%+ improvement in query performance
- ✅ Zero increase in crash rate
- ✅ App size increase < 5MB

---

## Timeline

**Week 1: Setup**
- Day 1-2: Add SwiftData framework, define models
- Day 3-4: Create data access layer
- Day 5: Code review and refinement

**Week 2: Migration**
- Day 1-2: Implement migration logic
- Day 3-4: Update all data access to use SwiftData
- Day 5: Internal testing

**Week 3: Rollout**
- Day 1-3: Beta testing with select users
- Day 4-5: Gradual rollout (10% → 50%)
- Day 6-7: Full release + monitoring

---

## Post-Migration

### Cleanup (v1.1)
- Remove old UserDefaults code
- Remove migration logic (keep for 2 releases)
- Optimize queries based on usage patterns

### Future Enhancements (v2.0)
- iCloud sync for multi-device support
- Advanced analytics with aggregates
- Predictive caching
- Export functionality

---

## Conclusion

Migrating to SwiftData will:
1. Solve current scalability issues
2. Improve performance 10-20x
3. Enable future features
4. Provide better data integrity

**Recommended Timeline:** Start in Sprint 4, complete in 3 weeks
**Effort Estimate:** 40-60 hours
**Priority:** Medium (P2) - Required before v2.0

---

*Document Version: 1.0*
*Last Updated: 2024-11-19*
*Author: Engineering Team*
