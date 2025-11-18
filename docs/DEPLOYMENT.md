# Deployment Guide

Complete guide for deploying Screen Time Balancer to production (TestFlight/App Store) and setting up the backend infrastructure.

## Table of Contents

1. [Backend Deployment (Supabase)](#backend-deployment)
2. [iOS Parent App Deployment](#parent-app-deployment)
3. [iOS Child App Deployment](#child-app-deployment)
4. [TestFlight Beta Testing](#testflight-beta-testing)
5. [App Store Submission](#app-store-submission)
6. [Monitoring and Maintenance](#monitoring-and-maintenance)

---

## Backend Deployment

### 1. Create Production Supabase Project

1. **Sign up/Login to Supabase**
   - Go to [supabase.com](https://supabase.com)
   - Create a new organization (if needed)

2. **Create Project**
   ```
   Name: screen-time-balancer-prod
   Database Password: [Generate strong password]
   Region: [Closest to target users]
   Plan: Free (can upgrade later)
   ```

3. **Note Down Credentials**
   - Project URL: `https://xxxxx.supabase.co`
   - Project API Key (anon/public): `eyJhbG...`
   - Service Role Key (keep secret!): `eyJhbG...`

### 2. Run Database Migrations

```bash
cd backend

# Install Supabase CLI if not already installed
npm install -g supabase

# Login to Supabase
supabase login

# Link to your production project
supabase link --project-ref YOUR_PROJECT_REF

# Push migrations to production
supabase db push

# Verify migrations
supabase db diff
```

### 3. Deploy Edge Functions

```bash
# Deploy daily reset function
supabase functions deploy daily-reset

# Set up cron job for daily reset
# In Supabase Dashboard:
# Database → Cron Jobs → New Job
# Schedule: 0 0 * * * (midnight daily)
# Function: daily-reset
```

### 4. Configure Authentication

In Supabase Dashboard → Authentication → Settings:

**Email Auth:**
- Enable email provider: ✅
- Confirm email: ✅ (for production)
- Secure email change: ✅

**Site URL:**
- Set to your app's custom URL scheme or website

**Redirect URLs:**
```
com.yourcompany.screentimeparent://
com.yourcompany.screentimechild://
```

**OAuth Providers (Optional):**

For Sign in with Apple:
1. Create Apple Developer App ID
2. Enable Sign in with Apple capability
3. Add Service ID in Apple Developer Portal
4. Configure in Supabase with Service ID and Private Key

For Google Sign-In:
1. Create OAuth 2.0 credentials in Google Cloud Console
2. Add iOS URL schemes
3. Configure in Supabase with Client ID and Secret

### 5. Security Configuration

**Row Level Security:**
- Already enabled via migrations
- Verify policies in Dashboard → Authentication → Policies

**API Rate Limiting:**
- Configure in Dashboard → Settings → API
- Set appropriate limits for free tier

**CORS:**
- Only needed if you have a web dashboard
- Configure allowed origins in API settings

### 6. Monitoring Setup

**Enable Logs:**
- Dashboard → Logs
- Set up log retention (7 days on free tier)

**Set up Alerts:**
- Database size approaching limit
- API rate limit approaching
- Failed authentications

---

## Parent App Deployment

### 1. Xcode Project Configuration

Open `ios-parent/ScreenTimeParent.xcodeproj` in Xcode.

**Update Config.swift:**

```swift
// ios-parent/ScreenTimeParent/App/Config.swift

enum Config {
    static let supabaseURL = URL(string: "https://YOUR_PROJECT_REF.supabase.co")!
    static let supabaseAnonKey = "YOUR_ANON_KEY_HERE"

    // Update other production settings as needed
}
```

**IMPORTANT:** Never commit API keys to git. Use Xcode build configurations or environment variables.

### 2. Bundle Identifier and Signing

1. **Bundle Identifier:**
   ```
   com.yourcompany.screentimeparent
   ```

2. **Team and Signing:**
   - Select your Apple Developer Team
   - Enable "Automatically manage signing"
   - Choose appropriate Provisioning Profile

3. **Capabilities:**
   - Push Notifications (if implementing push)
   - Background Modes:
     - Background fetch
     - Remote notifications

### 3. App Icons and Assets

1. **App Icon:**
   - Create icon set in `Resources/Assets.xcassets`
   - Required sizes: 1024x1024 (App Store), plus all iOS sizes
   - Use SF Symbols or custom design

2. **Launch Screen:**
   - Design simple launch screen matching app theme

### 4. Build Configuration

**For TestFlight (Debug/Beta):**

```
Build Configuration: Release
Code Signing: iOS Distribution
Provisioning Profile: App Store
```

**Version Numbers:**
```
Version: 1.0
Build: 1 (increment for each TestFlight build)
```

### 5. Archive and Upload

```bash
# Clean build folder
Product → Clean Build Folder

# Archive
Product → Archive

# Upload to App Store Connect
Window → Organizer → Upload to App Store Connect
```

---

## Child App Deployment

### 1. Xcode Project Configuration

Open `ios-child/ScreenTimeChild.xcodeproj` in Xcode.

**Update Config.swift:**

```swift
// ios-child/ScreenTimeChild/App/Config.swift

enum Config {
    static let supabaseURL = URL(string: "https://YOUR_PROJECT_REF.supabase.co")!
    static let supabaseAnonKey = "YOUR_ANON_KEY_HERE"
}
```

### 2. Bundle Identifier and Signing

1. **Bundle Identifier:**
   ```
   com.yourcompany.screentimechild
   ```

2. **Capabilities:**
   - Family Controls (Required for Screen Time API)
   - Push Notifications
   - Background Modes:
     - Background fetch
     - Background processing

### 3. Screen Time API Setup

**Important:** The Screen Time API requires special entitlements.

1. **Request Family Controls Entitlement:**
   - Go to Apple Developer Portal
   - Certificates, IDs & Profiles → Identifiers
   - Select your app identifier
   - Enable "Family Controls" capability
   - Submit request (may require App Review approval)

2. **Add to Xcode:**
   - Target → Signing & Capabilities
   - + Capability → Family Controls

3. **Update Info.plist:**
   ```xml
   <key>NSFamilyControlsUsageDescription</key>
   <string>We need access to manage screen time based on parental rules.</string>
   ```

### 4. Build and Upload

Follow same process as Parent App (Archive → Upload).

---

## TestFlight Beta Testing

### 1. App Store Connect Setup

1. **Create App Records:**
   - Login to [App Store Connect](https://appstoreconnect.apple.com)
   - My Apps → + → New App

   **Parent App:**
   ```
   Name: Screen Time Balancer - Parent
   Primary Language: English
   Bundle ID: com.yourcompany.screentimeparent
   SKU: screentimeparent
   ```

   **Child App:**
   ```
   Name: Screen Time Balancer - Child
   Primary Language: English
   Bundle ID: com.yourcompany.screentimechild
   SKU: screentimechild
   ```

2. **Configure App Information:**
   - Category: Lifestyle or Productivity
   - Age Rating: 4+ (Parent), 9+ (Child)
   - Content Rights: Appropriate

### 2. Upload Builds

After archiving and uploading from Xcode:

1. Wait for processing (10-30 minutes)
2. Go to TestFlight tab in App Store Connect
3. Select build
4. Add export compliance (if applicable)

### 3. Internal Testing

**Add Internal Testers:**
1. TestFlight → Internal Testing → + (Add Group)
2. Name: "Internal Team"
3. Add testers (up to 100)
4. Select builds to test

**Testers receive email:**
- Install TestFlight app from App Store
- Accept invitation
- Install beta apps

### 4. External Testing

**Create External Test Group:**
1. TestFlight → External Testing → + (Add Group)
2. Name: "Beta Testers"
3. Add test information (required for first external test)
4. Submit for Beta App Review (1-2 days)

**Public Link (Optional):**
- Generate public link for testers
- Share link publicly or privately
- Up to 10,000 external testers

### 5. Collect Feedback

- Use TestFlight feedback mechanism
- Monitor crash reports in Xcode Organizer
- Track adoption metrics in App Store Connect

---

## App Store Submission

### 1. Prepare App Metadata

**Screenshots (Required):**
- 6.7" iPhone (iPhone 15 Pro Max): 1290 x 2796 pixels
- 6.5" iPhone (iPhone 11 Pro Max): 1242 x 2688 pixels
- 5.5" iPhone (iPhone 8 Plus): 1242 x 2208 pixels
- 12.9" iPad Pro: 2048 x 2732 pixels

**App Preview Videos (Optional but recommended):**
- 15-30 seconds
- Show key features
- No audio required

**App Description:**

```
Screen Time Balancer helps families create healthy screen time habits through a positive, educational-first approach.

PARENT APP:
• Set educational time requirements
• Monitor children's screen time in real-time
• Categorize apps as educational or recreational
• Create flexible rules and schedules
• View detailed usage reports

CHILD APP:
• Clear progress tracking
• Earn recreational time through educational app usage
• Age-appropriate interface
• Offline support

Screen Time Balancer uses Apple's Screen Time API for reliable enforcement.

Privacy: We take your family's privacy seriously. All data is encrypted and stored securely.
```

**Keywords:**
```
screen time, parental control, family, education, kids, children, monitor, balance
```

**Support URL:**
```
https://yourwebsite.com/support
```

**Privacy Policy URL:** (Required)
```
https://yourwebsite.com/privacy
```

### 2. Privacy Questionnaire

Complete the App Privacy questions in App Store Connect:

**Data Collected:**
- Email address (for authentication)
- Name (optional, for profile)
- App usage data (for tracking)

**Data Use:**
- Analytics
- App functionality

**Data Linked to User:** Yes

**COPPA Compliance:**
- App is subject to COPPA (children under 13)
- Parental consent required before child account creation

### 3. Submit for Review

1. Select build version
2. Complete all metadata
3. Answer export compliance questions
4. Submit for Review

**Review Times:**
- First submission: 2-5 days
- Updates: 1-3 days
- Rejections: Address issues and resubmit

**Common Rejection Reasons:**
- Missing privacy policy
- Screen Time API misuse
- COPPA compliance issues
- Incomplete metadata

---

## Monitoring and Maintenance

### 1. Backend Monitoring

**Supabase Dashboard:**
- Database usage
- API requests
- Error rates
- Active users

**Set up Alerts:**
```bash
# Example: Database size alert
# Use Supabase Dashboard → Settings → Alerts
```

### 2. App Analytics

**TestFlight Metrics:**
- Install rates
- Session duration
- Crash rates

**App Store Connect Analytics:**
- Downloads
- Updates
- Ratings and reviews

### 3. Crash Reporting

**Xcode Organizer:**
- Crashes and hangs
- Energy and performance
- Disk writes

**Symbolication:**
- Upload dSYMs for each build
- Automatic with Xcode Cloud or manual upload

### 4. Regular Maintenance

**Weekly:**
- Check crash reports
- Monitor database size
- Review error logs

**Monthly:**
- Analyze usage patterns
- Plan feature updates
- Review user feedback

**Quarterly:**
- Security audit
- Performance optimization
- Dependency updates

### 5. Scaling Considerations

**When to Upgrade Supabase:**
- Database approaching 500 MB
- API requests approaching limits
- Need better performance

**Supabase Pro ($25/month):**
- 8 GB database
- 250 GB bandwidth
- Point-in-time recovery
- Better support

**Beyond Supabase:**
- Consider dedicated infrastructure
- AWS, Google Cloud, or Azure
- Custom backend scaling

---

## Troubleshooting

### Common Issues

**Build Fails:**
- Clean build folder
- Delete Derived Data
- Check signing certificates
- Verify provisioning profiles

**TestFlight Not Appearing:**
- Wait for processing (up to 30 minutes)
- Check export compliance
- Verify build number is unique

**Screen Time API Not Working:**
- Check Family Controls entitlement
- Verify capability in project
- Request authorization at runtime

**Supabase Connection Fails:**
- Verify URL and API keys
- Check network connectivity
- Review RLS policies

### Getting Help

- **Supabase:** [discord.supabase.com](https://discord.supabase.com)
- **Apple Developer:** [developer.apple.com/support](https://developer.apple.com/support)
- **TestFlight:** [App Store Connect Help](https://help.apple.com/app-store-connect)

---

## Checklist

### Backend ✓
- [ ] Supabase project created
- [ ] Database migrations applied
- [ ] Edge functions deployed
- [ ] Authentication configured
- [ ] RLS policies verified
- [ ] Monitoring set up

### Parent App ✓
- [ ] Config updated with production credentials
- [ ] Bundle ID configured
- [ ] Signing certificates in place
- [ ] App icons added
- [ ] Build archived and uploaded
- [ ] TestFlight tested

### Child App ✓
- [ ] Config updated with production credentials
- [ ] Family Controls entitlement requested
- [ ] Bundle ID configured
- [ ] Signing certificates in place
- [ ] App icons added
- [ ] Build archived and uploaded
- [ ] TestFlight tested

### App Store Connect ✓
- [ ] App metadata complete
- [ ] Screenshots uploaded
- [ ] Privacy policy published
- [ ] App previews created (optional)
- [ ] Export compliance answered
- [ ] Submitted for review

---

**Last Updated:** 2024-11-18
**Version:** 1.0 (MVP)
