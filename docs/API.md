# API Documentation

Screen Time Balancer uses Supabase's auto-generated REST API (PostgREST) for all backend operations. This document describes the available endpoints and usage patterns.

## Base URL

```
https://YOUR_PROJECT_REF.supabase.co/rest/v1/
```

## Authentication

All requests require authentication using JWT tokens:

```
Authorization: Bearer YOUR_JWT_TOKEN
apikey: YOUR_SUPABASE_ANON_KEY
```

Get JWT token via login endpoint.

## Common Headers

```http
Content-Type: application/json
apikey: YOUR_SUPABASE_ANON_KEY
Authorization: Bearer YOUR_JWT_TOKEN
Prefer: return=representation  # Return created/updated record
```

---

## Authentication Endpoints

### Sign Up

```http
POST /auth/v1/signup
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securepassword123",
  "data": {
    "full_name": "John Doe",
    "role": "parent"
  }
}
```

**Response:**
```json
{
  "access_token": "eyJhbGc...",
  "token_type": "bearer",
  "expires_in": 3600,
  "refresh_token": "...",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "user_metadata": {
      "full_name": "John Doe",
      "role": "parent"
    }
  }
}
```

### Sign In

```http
POST /auth/v1/token?grant_type=password
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securepassword123"
}
```

**Response:** Same as Sign Up

### Refresh Token

```http
POST /auth/v1/token?grant_type=refresh_token
Content-Type: application/json

{
  "refresh_token": "your-refresh-token"
}
```

### Sign Out

```http
POST /auth/v1/logout
Authorization: Bearer YOUR_JWT_TOKEN
```

---

## User Profiles

### Create Profile (Auto-triggered on signup)

```http
POST /rest/v1/user_profiles
Content-Type: application/json

{
  "id": "user-uuid",
  "email": "user@example.com",
  "full_name": "John Doe",
  "role": "parent",
  "date_of_birth": "1985-05-15"
}
```

### Get Own Profile

```http
GET /rest/v1/user_profiles?id=eq.{user_id}
```

**Response:**
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "full_name": "John Doe",
  "role": "parent",
  "date_of_birth": "1985-05-15",
  "avatar_url": null,
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z"
}
```

### Update Profile

```http
PATCH /rest/v1/user_profiles?id=eq.{user_id}
Content-Type: application/json
Prefer: return=representation

{
  "full_name": "John Smith",
  "avatar_url": "https://..."
}
```

---

## Families

### Create Family

```http
POST /rest/v1/families
Content-Type: application/json
Prefer: return=representation

{
  "name": "Smith Family",
  "created_by": "parent-user-uuid"
}
```

**Response:**
```json
{
  "id": "family-uuid",
  "name": "Smith Family",
  "invite_code": "ABC123XY",
  "created_by": "parent-user-uuid",
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z"
}
```

### Get Family by ID

```http
GET /rest/v1/families?id=eq.{family_id}
```

### Get Family by Invite Code

```http
GET /rest/v1/families?invite_code=eq.ABC123XY
```

### List User's Families

```http
GET /rest/v1/family_overview
```

Returns view with member counts:
```json
[
  {
    "id": "family-uuid",
    "name": "Smith Family",
    "invite_code": "ABC123XY",
    "created_at": "2024-01-01T00:00:00Z",
    "child_count": 2,
    "parent_count": 2,
    "device_count": 3
  }
]
```

### Update Family

```http
PATCH /rest/v1/families?id=eq.{family_id}
Content-Type: application/json

{
  "name": "Updated Family Name"
}
```

---

## Family Members

### Add Member to Family (Parent invites child)

```http
POST /rest/v1/family_members
Content-Type: application/json
Prefer: return=representation

{
  "family_id": "family-uuid",
  "user_id": "child-user-uuid",
  "role": "child",
  "nickname": "Emma"
}
```

### Join Family (Child uses invite code)

1. First, get family by invite code
2. Then add self to family members

```http
POST /rest/v1/family_members
Content-Type: application/json

{
  "family_id": "family-uuid",
  "user_id": "current-user-uuid",
  "role": "child"
}
```

### List Family Members

```http
GET /rest/v1/family_members?family_id=eq.{family_id}&select=*,user_profiles(*)
```

**Response:**
```json
[
  {
    "id": "member-uuid",
    "family_id": "family-uuid",
    "user_id": "user-uuid",
    "role": "child",
    "nickname": "Emma",
    "joined_at": "2024-01-01T00:00:00Z",
    "user_profiles": {
      "full_name": "Emma Smith",
      "email": "emma@example.com",
      "role": "child"
    }
  }
]
```

### Remove Member

```http
DELETE /rest/v1/family_members?id=eq.{member_id}
```

---

## Devices

### Register Device

```http
POST /rest/v1/devices
Content-Type: application/json
Prefer: return=representation

{
  "child_id": "child-user-uuid",
  "family_id": "family-uuid",
  "device_name": "Emma's iPhone",
  "device_identifier": "ios-device-uuid",
  "platform": "ios",
  "os_version": "17.1",
  "app_version": "1.0.0"
}
```

### List Child's Devices

```http
GET /rest/v1/devices?child_id=eq.{child_id}
```

### Update Device (Sync heartbeat)

```http
PATCH /rest/v1/devices?id=eq.{device_id}
Content-Type: application/json

{
  "last_sync": "2024-01-01T12:30:00Z"
}
```

### Deactivate Device

```http
PATCH /rest/v1/devices?id=eq.{device_id}
Content-Type: application/json

{
  "is_active": false
}
```

---

## Apps (Categorization)

### Add App Categorization

```http
POST /rest/v1/apps
Content-Type: application/json
Prefer: return=representation

{
  "family_id": "family-uuid",
  "bundle_id": "com.apple.iBooks",
  "app_name": "Books",
  "category": "educational",
  "icon_url": "https://...",
  "time_limit_minutes": null
}
```

### List Family Apps

```http
GET /rest/v1/apps?family_id=eq.{family_id}&order=app_name.asc
```

### Get App by Bundle ID

```http
GET /rest/v1/apps?family_id=eq.{family_id}&bundle_id=eq.com.apple.iBooks
```

### Update App Category

```http
PATCH /rest/v1/apps?id=eq.{app_id}
Content-Type: application/json

{
  "category": "recreational",
  "time_limit_minutes": 60
}
```

### Bulk Update Apps

```http
PATCH /rest/v1/apps?family_id=eq.{family_id}&category=eq.uncategorized
Content-Type: application/json

{
  "category": "utility"
}
```

---

## Screen Time Rules

### Create Rule

```http
POST /rest/v1/screen_time_rules
Content-Type: application/json
Prefer: return=representation

{
  "family_id": "family-uuid",
  "child_id": null,
  "name": "Default Family Rule",
  "description": "30 minutes educational time required",
  "required_educational_minutes": 30,
  "max_recreational_minutes": 120,
  "start_time": "06:00:00",
  "end_time": "21:00:00",
  "active_days": [0,1,2,3,4,5,6],
  "priority": 0,
  "is_active": true
}
```

### List Rules for Child

```http
GET /rest/v1/screen_time_rules?family_id=eq.{family_id}&or=(child_id.eq.{child_id},child_id.is.null)&is_active=eq.true&order=priority.desc,child_id.nullslast
```

### Get Active Rule for Child

```http
GET /rest/v1/screen_time_rules?family_id=eq.{family_id}&or=(child_id.eq.{child_id},child_id.is.null)&is_active=eq.true&order=priority.desc&limit=1
```

### Update Rule

```http
PATCH /rest/v1/screen_time_rules?id=eq.{rule_id}
Content-Type: application/json

{
  "required_educational_minutes": 45,
  "max_recreational_minutes": 90
}
```

### Deactivate Rule

```http
PATCH /rest/v1/screen_time_rules?id=eq.{rule_id}
Content-Type: application/json

{
  "is_active": false
}
```

---

## Usage Sessions

### Create Usage Session

```http
POST /rest/v1/usage_sessions
Content-Type: application/json
Prefer: return=representation

{
  "child_id": "child-user-uuid",
  "device_id": "device-uuid",
  "bundle_id": "com.apple.iBooks",
  "app_name": "Books",
  "category": "educational",
  "started_at": "2024-01-01T14:00:00Z",
  "date": "2024-01-01"
}
```

### End Usage Session

```http
PATCH /rest/v1/usage_sessions?id=eq.{session_id}
Content-Type: application/json

{
  "ended_at": "2024-01-01T14:25:00Z",
  "duration_seconds": 1500
}
```

### List Today's Usage

```http
GET /rest/v1/usage_sessions?child_id=eq.{child_id}&date=eq.2024-01-01&order=started_at.desc
```

### Get Daily Summary

```http
GET /rest/v1/daily_usage_summary?child_id=eq.{child_id}&date=eq.2024-01-01
```

**Response:**
```json
[
  {
    "child_id": "uuid",
    "date": "2024-01-01",
    "device_id": "uuid",
    "educational_minutes": 35,
    "recreational_minutes": 45,
    "total_minutes": 80,
    "unique_apps_used": 5,
    "first_usage": "2024-01-01T08:00:00Z",
    "last_usage": "2024-01-01T18:30:00Z"
  }
]
```

### Get Usage History (Last 7 Days)

```http
GET /rest/v1/usage_sessions?child_id=eq.{child_id}&date=gte.2024-01-01&date=lte.2024-01-07&order=started_at.desc
```

---

## Earned Time

### Get Today's Earned Time

```http
GET /rest/v1/earned_time?child_id=eq.{child_id}&date=eq.2024-01-01
```

**Response:**
```json
{
  "id": "uuid",
  "child_id": "uuid",
  "family_id": "uuid",
  "date": "2024-01-01",
  "educational_minutes": 35,
  "required_educational_minutes": 30,
  "recreational_minutes_used": 20,
  "recreational_minutes_available": 35,
  "requirement_met": true,
  "last_calculated": "2024-01-01T14:25:00Z",
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T14:25:00Z"
}
```

### Upsert Earned Time (Update or Insert)

```http
POST /rest/v1/earned_time
Content-Type: application/json
Prefer: resolution=merge-duplicates

{
  "child_id": "child-uuid",
  "family_id": "family-uuid",
  "date": "2024-01-01",
  "educational_minutes": 35,
  "required_educational_minutes": 30,
  "recreational_minutes_used": 20,
  "recreational_minutes_available": 35,
  "requirement_met": true,
  "last_calculated": "2024-01-01T14:25:00Z"
}
```

### Get Current Enforcement Status

```http
GET /rest/v1/current_enforcement_status?child_id=eq.{child_id}
```

---

## Parent Commands

### Send Lock Command

```http
POST /rest/v1/parent_commands
Content-Type: application/json
Prefer: return=representation

{
  "family_id": "family-uuid",
  "parent_id": "parent-uuid",
  "child_id": "child-uuid",
  "device_id": "device-uuid",
  "command_type": "lock",
  "payload": {
    "reason": "Bedtime",
    "duration_minutes": null
  }
}
```

### Send Unlock Command

```http
POST /rest/v1/parent_commands
Content-Type: application/json

{
  "family_id": "family-uuid",
  "parent_id": "parent-uuid",
  "child_id": "child-uuid",
  "command_type": "unlock",
  "payload": {}
}
```

### Get Pending Commands (Child Device)

```http
GET /rest/v1/parent_commands?child_id=eq.{child_id}&status=eq.pending&order=created_at.desc
```

### Mark Command as Executed

```http
PATCH /rest/v1/parent_commands?id=eq.{command_id}
Content-Type: application/json

{
  "status": "executed",
  "executed_at": "2024-01-01T20:00:00Z"
}
```

---

## Realtime Subscriptions

### Subscribe to Rule Changes

```javascript
const channel = supabase
  .channel(`family:${familyId}:rules`)
  .on(
    'postgres_changes',
    {
      event: '*',
      schema: 'public',
      table: 'screen_time_rules',
      filter: `family_id=eq.${familyId}`
    },
    (payload) => {
      console.log('Rule changed:', payload)
    }
  )
  .subscribe()
```

### Subscribe to Usage Updates

```javascript
const channel = supabase
  .channel(`family:${familyId}:usage`)
  .on(
    'postgres_changes',
    {
      event: 'INSERT',
      schema: 'public',
      table: 'usage_sessions',
      filter: `child_id=eq.${childId}`
    },
    (payload) => {
      console.log('New usage session:', payload)
    }
  )
  .subscribe()
```

### Subscribe to Parent Commands

```javascript
const channel = supabase
  .channel(`device:${deviceId}:commands`)
  .on(
    'postgres_changes',
    {
      event: 'INSERT',
      schema: 'public',
      table: 'parent_commands',
      filter: `device_id=eq.${deviceId}`
    },
    (payload) => {
      console.log('New command received:', payload)
      // Execute command
    }
  )
  .subscribe()
```

---

## Error Responses

### 400 Bad Request

```json
{
  "code": "PGRST102",
  "message": "Invalid request body",
  "details": "Missing required field: family_id"
}
```

### 401 Unauthorized

```json
{
  "code": "PGRST301",
  "message": "JWT expired"
}
```

### 403 Forbidden (RLS Policy)

```json
{
  "code": "42501",
  "message": "new row violates row-level security policy"
}
```

### 404 Not Found

```json
{
  "code": "PGRST116",
  "message": "The result contains 0 rows"
}
```

### 409 Conflict (Duplicate)

```json
{
  "code": "23505",
  "message": "duplicate key value violates unique constraint"
}
```

---

## Rate Limits

Supabase applies rate limiting by default:

- **Free Tier**: 200 requests per second
- **Pro Tier**: 2000 requests per second

For high-frequency updates (like usage tracking), implement client-side batching.

---

## Best Practices

### 1. Use Efficient Queries

```http
# Good: Select only needed fields
GET /rest/v1/usage_sessions?select=id,started_at,ended_at,category

# Good: Use indexes (date, child_id are indexed)
GET /rest/v1/usage_sessions?child_id=eq.{id}&date=eq.2024-01-01

# Bad: Select all fields when not needed
GET /rest/v1/usage_sessions?select=*
```

### 2. Batch Updates

Instead of 10 individual API calls, send one bulk update.

### 3. Use Realtime for Live Updates

Don't poll APIs. Subscribe to realtime changes.

### 4. Cache Frequently Accessed Data

Cache rules and app categories locally with 5-minute TTL.

### 5. Handle Network Failures

Implement exponential backoff and offline queuing for usage tracking.

---

## Testing

### Using curl

```bash
# Set variables
SUPABASE_URL="https://xxxxx.supabase.co"
ANON_KEY="your-anon-key"
JWT_TOKEN="your-jwt-token"

# Get user profile
curl "$SUPABASE_URL/rest/v1/user_profiles?id=eq.{user_id}" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $JWT_TOKEN"
```

### Using Postman

Import the Supabase OpenAPI spec:
```
https://YOUR_PROJECT_REF.supabase.co/rest/v1/
```

---

## Support

- **Supabase API Docs**: https://supabase.com/docs/guides/api
- **PostgREST Docs**: https://postgrest.org/

---

**Last Updated**: 2024-11-18
**API Version**: 1.0
