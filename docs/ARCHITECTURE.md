# System Architecture

## Overview

Screen Time Balancer is a three-tier application consisting of a cloud backend (Supabase), Parent iOS app, and Child iOS app. The system enforces educational screen time requirements before allowing recreational app access.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                       Cloud Backend (Supabase)              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ Auth Service │  │  PostgreSQL  │  │  Realtime    │     │
│  │   (GoTrue)   │  │   Database   │  │   Service    │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  Row Level   │  │   Storage    │  │  Edge        │     │
│  │  Security    │  │   Service    │  │  Functions   │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                              ▲
                              │ HTTPS / WebSocket
                              │
        ┌─────────────────────┴─────────────────────┐
        │                                           │
┌───────▼────────┐                         ┌───────▼────────┐
│  Parent App    │                         │   Child App    │
│  (iOS/iPadOS)  │                         │  (iOS/iPadOS)  │
│                │                         │                │
│ ┌────────────┐ │                         │ ┌────────────┐ │
│ │ Dashboard  │ │                         │ │ Enforcement│ │
│ │   & Rules  │ │                         │ │   Engine   │ │
│ └────────────┘ │                         │ └────────────┘ │
│ ┌────────────┐ │                         │ ┌────────────┐ │
│ │  Family    │ │◄────Invite Link────────►│ │  Usage     │ │
│ │  Manager   │ │                         │ │  Tracker   │ │
│ └────────────┘ │                         │ └────────────┘ │
└────────────────┘                         └────────────────┘
```

## Core Components

### 1. Backend (Supabase)

#### Database Schema

**users** (extends Supabase auth.users)
- Basic authentication and profile information
- Role: parent or child

**families**
- Family account container
- Created by parent user
- Invite code for linking children

**family_members**
- Links users to families
- Defines role within family (admin, parent, child)

**devices**
- Child devices registered in system
- Device identifiers and metadata

**apps**
- Catalog of apps (educational vs recreational)
- Custom categorization per family

**screen_time_rules**
- Daily educational time requirements
- Time windows and schedules
- Per-child or family-wide rules

**usage_sessions**
- Tracks app usage on child devices
- Start/end times, app category
- Synced to backend for reporting

**earned_time**
- Tracks earned recreational time
- Calculated from educational usage
- Expires daily

#### Security Model

**Row Level Security (RLS) Policies:**

- Parents can only access their family's data
- Children can only read their own usage data
- Children cannot modify rules or settings
- Family admins have full access to family data

**Authentication:**
- Supabase Auth (email/password, OAuth)
- JWT tokens for API access
- Refresh token rotation

### 2. Parent iOS App

#### Architecture Pattern: MVVM + Clean Architecture

**Layers:**

1. **Presentation Layer**
   - SwiftUI views
   - ViewModels
   - Navigation coordinators

2. **Domain Layer**
   - Business logic
   - Use cases
   - Domain models

3. **Data Layer**
   - Repository pattern
   - API clients
   - Local cache (UserDefaults/CoreData)

**Key Modules:**

- **Authentication**: Login, signup, password reset
- **Family Management**: Create family, invite children, manage members
- **App Categorization**: Browse installed apps, categorize as educational/recreational
- **Rules Configuration**: Set daily requirements, time windows
- **Dashboard**: Real-time usage monitoring, statistics
- **Reports**: Weekly/monthly usage analytics

### 3. Child iOS App

#### Architecture Pattern: MVVM + Clean Architecture

**Layers:**

1. **Presentation Layer**
   - SwiftUI views
   - ViewModels
   - Lock screen overlays

2. **Domain Layer**
   - Enforcement logic
   - Usage tracking
   - Time calculation

3. **Data Layer**
   - Repository pattern
   - Local usage tracking
   - Background sync

**Key Modules:**

- **Authentication**: Child login, device registration
- **Enforcement Engine**: App category detection, lock/unlock logic
- **Usage Tracker**: Monitor app usage, track educational time
- **Dashboard**: Show progress, earned time, locked apps
- **Sync Service**: Background sync with backend

## Data Flow

### 1. Family Setup Flow

```
Parent App:
1. Parent creates account → Backend creates user
2. Parent creates family → Backend generates invite code
3. Parent shares invite code → QR code or text

Child App:
4. Child uses invite code → Backend validates & links
5. Backend creates family_member record
6. Parent sees child device → Can configure rules
```

### 2. Rule Configuration Flow

```
Parent App:
1. Parent sets educational time requirement (e.g., 30 min)
2. Parent categorizes apps
3. Changes sync to backend via Supabase realtime

Child App:
4. Receives realtime update
5. Enforcement engine updates local rules
6. Applies new requirements immediately
```

### 3. Usage Tracking & Enforcement Flow

```
Child Device:
1. Child opens app → App category detected
2. If recreational & time not earned → Block with overlay
3. If educational → Start tracking usage
4. Usage tracked locally with timestamps
5. Background task syncs to backend every 5 minutes
6. When educational requirement met → Unlock recreational apps
7. Realtime update to parent dashboard
```

### 4. Sync Strategy

**Child to Backend:**
- Usage sessions uploaded every 5 minutes (background)
- Immediate sync on app categorization change
- Heartbeat every 30 seconds when tracking

**Backend to Child:**
- Realtime subscription for rule changes
- Realtime subscription for parent commands (lock, unlock)
- Pull sync on app launch

**Backend to Parent:**
- Realtime subscription for usage updates
- Realtime subscription for earned time changes
- Pull sync for historical reports

## API Architecture

### REST Endpoints (Supabase PostgREST)

All database tables exposed via auto-generated REST API with RLS:

**Authentication:**
- `POST /auth/v1/signup` - Create account
- `POST /auth/v1/token` - Login
- `POST /auth/v1/logout` - Logout

**Families:**
- `GET /rest/v1/families` - List families
- `POST /rest/v1/families` - Create family
- `GET /rest/v1/families/{id}` - Get family details

**Family Members:**
- `POST /rest/v1/family_members` - Add member (join family)
- `GET /rest/v1/family_members?family_id=eq.{id}` - List members
- `DELETE /rest/v1/family_members/{id}` - Remove member

**Apps:**
- `GET /rest/v1/apps?family_id=eq.{id}` - List categorized apps
- `POST /rest/v1/apps` - Add app categorization
- `PATCH /rest/v1/apps/{id}` - Update app category

**Screen Time Rules:**
- `GET /rest/v1/screen_time_rules?family_id=eq.{id}` - Get rules
- `POST /rest/v1/screen_time_rules` - Create rule
- `PATCH /rest/v1/screen_time_rules/{id}` - Update rule

**Usage Sessions:**
- `POST /rest/v1/usage_sessions` - Record usage
- `GET /rest/v1/usage_sessions?child_id=eq.{id}` - Get usage history

**Earned Time:**
- `GET /rest/v1/earned_time?child_id=eq.{id}&date=eq.{date}` - Get earned time for today
- `POST /rest/v1/earned_time` - Update earned time

### Realtime Channels

**Channel: `family:{family_id}:rules`**
- Subscribe to rule changes
- Broadcasts when rules updated

**Channel: `family:{family_id}:usage`**
- Subscribe to usage updates
- Broadcasts when child usage changes

**Channel: `device:{device_id}:commands`**
- Parent sends remote commands
- Child receives lock/unlock commands

## Security Considerations

### Data Protection

1. **Encryption in Transit:** All API calls via HTTPS
2. **Encryption at Rest:** Supabase PostgreSQL encryption
3. **Token Security:** Short-lived JWTs, secure refresh tokens
4. **Local Storage:** Keychain for sensitive data

### Privacy Compliance

1. **COPPA Compliance:**
   - Parental consent required for child accounts
   - Minimal data collection
   - Data deletion on account removal

2. **GDPR Compliance:**
   - Data export functionality
   - Right to deletion
   - Clear privacy policy

### Anti-Tampering

1. **Server Authoritative:** All enforcement validated server-side
2. **Time Validation:** Server time used for calculations
3. **Device Attestation:** Device fingerprinting to prevent spoofing
4. **Checksum Validation:** Usage data integrity checks

## Scalability Considerations

### Current MVP Scale (Supabase Free Tier)

- **Users:** Up to 50,000 monthly active users
- **Database:** 500 MB storage
- **Bandwidth:** 2 GB monthly
- **Realtime:** 200 concurrent connections

### Scaling Strategy

1. **Database Optimization:**
   - Indexed queries on frequently accessed data
   - Partitioning for usage_sessions (by date)
   - Materialized views for reports

2. **Caching:**
   - Client-side caching of rules (5-minute TTL)
   - CDN for static assets
   - Redis for session data (if needed)

3. **Background Jobs:**
   - Supabase Edge Functions for:
     - Daily earned time reset
     - Weekly report generation
     - Cleanup of old usage data

4. **Migration Path:**
   - Supabase Pro: 8 GB database, 250 GB bandwidth
   - Custom infrastructure if needed beyond Supabase limits

## Technology Stack

### Backend
- **Platform:** Supabase (PostgreSQL + realtime + auth)
- **Database:** PostgreSQL 15+
- **Authentication:** Supabase Auth (GoTrue)
- **Realtime:** WebSocket subscriptions
- **Edge Functions:** Deno runtime

### iOS Apps
- **Language:** Swift 5.9+
- **UI Framework:** SwiftUI
- **Minimum iOS:** 17.0
- **Dependencies:**
  - Supabase Swift client
  - Combine for reactive programming
  - Screen Time API (FamilyControls framework)

### Development Tools
- **Version Control:** Git
- **CI/CD:** GitHub Actions (for TestFlight deployment)
- **Code Quality:** SwiftLint
- **Testing:** XCTest

## Error Handling & Resilience

### Network Failures
- Exponential backoff retry logic
- Offline queue for usage tracking
- Local cache fallback

### Sync Conflicts
- Last-write-wins for simple data
- Server authoritative for enforcement rules
- Conflict resolution UI for complex cases

### Device State Persistence
- CoreData for local usage log
- Sync reconciliation on reconnect
- Timestamp-based deduplication

## Monitoring & Analytics

### Application Metrics
- User authentication success/failure rates
- API response times
- Realtime connection stability
- Usage sync lag

### Business Metrics
- Daily/weekly active families
- Average educational time per child
- App categorization trends
- Feature usage patterns

### Tools
- Supabase Dashboard for database metrics
- Custom analytics in parent dashboard
- Crash reporting (TestFlight)

## Future Considerations

### Phase 2 Features
- Machine learning app categorization
- Advanced scheduling (bedtime, school hours)
- Content filtering
- Educational achievements/badges

### Platform Expansion
- Android version
- Web dashboard for parents
- macOS screen time management

### Integration Opportunities
- Educational platform APIs (Khan Academy, etc.)
- School district integrations
- Pediatrician reporting

---

**Last Updated:** 2024-11-18
**Version:** 1.0 (MVP)
