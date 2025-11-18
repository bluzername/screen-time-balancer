# Screen Time Balancer - Parental Control App MVP

A comprehensive parental control and screen time management system for iOS and iPadOS that enforces a **positive use-first model**. Children earn recreational screen time by engaging with educational apps first.

## 🎯 Core Concept

Children must spend time in educational apps before unlocking recreational apps (games, YouTube, social media). Parents configure requirements and monitor usage in real-time.

## 🏗️ Architecture

### Three-Component System

1. **Backend (Supabase)**
   - User authentication and authorization
   - Family account management
   - Real-time data synchronization
   - Screen time rules engine
   - Usage tracking and analytics

2. **Parent iOS App**
   - Family management and child device linking
   - App categorization (educational vs recreational)
   - Screen time rules configuration
   - Real-time monitoring dashboard
   - Usage reports and analytics

3. **Child iOS App**
   - Educational time tracking
   - App enforcement engine
   - Progress dashboard
   - Parental lock mechanisms

## 📁 Project Structure

```
screen-time-balancer/
├── backend/                 # Supabase backend configuration
│   ├── supabase/
│   │   └── migrations/     # Database migrations
│   ├── api/                # API documentation
│   └── docs/               # Backend architecture docs
├── ios-parent/             # Parent iOS application
│   └── ScreenTimeParent/
│       ├── App/            # App lifecycle and configuration
│       ├── Features/       # Feature modules
│       ├── Shared/         # Shared components and utilities
│       └── Resources/      # Assets and resources
├── ios-child/              # Child iOS application
│   └── ScreenTimeChild/
│       ├── App/            # App lifecycle and configuration
│       ├── Features/       # Feature modules
│       ├── Shared/         # Shared components and utilities
│       └── Resources/      # Assets and resources
└── docs/                   # Project-wide documentation
    ├── ARCHITECTURE.md     # System architecture
    ├── API.md             # API documentation
    └── DEPLOYMENT.md      # Deployment guide
```

## 🚀 Quick Start

### Prerequisites

- Xcode 15.0+ (for iOS development)
- iOS 17.0+ (deployment target)
- Supabase account (free tier available)
- Node.js 18+ (for Supabase CLI)

### Backend Setup

1. Install Supabase CLI:
```bash
npm install -g supabase
```

2. Create a Supabase project at [supabase.com](https://supabase.com)

3. Initialize Supabase locally:
```bash
cd backend
supabase init
supabase link --project-ref YOUR_PROJECT_REF
```

4. Run migrations:
```bash
supabase db push
```

5. Copy the Supabase URL and anon key for iOS app configuration

### iOS Apps Setup

#### Parent App

1. Open `ios-parent/ScreenTimeParent.xcodeproj` in Xcode
2. Update `Config.swift` with your Supabase credentials
3. Select your development team in signing settings
4. Build and run on device or simulator

#### Child App

1. Open `ios-child/ScreenTimeChild.xcodeproj` in Xcode
2. Update `Config.swift` with your Supabase credentials
3. Select your development team in signing settings
4. Build and run on device or simulator

## 🔑 Key Features

### For Parents
- ✅ Real-time usage monitoring
- ✅ Flexible screen time rules
- ✅ App categorization
- ✅ Remote device control
- ✅ Weekly usage reports
- ✅ Multiple child management

### For Children
- ✅ Clear progress indicators
- ✅ Educational time tracking
- ✅ Earn-to-play system
- ✅ Age-appropriate interface

### Backend
- ✅ Secure authentication
- ✅ Real-time synchronization
- ✅ Family account linking
- ✅ Usage data analytics
- ✅ COPPA/GDPR compliant

## 🔒 Security & Privacy

- End-to-end encryption for sensitive data
- COPPA compliant for children's privacy
- Role-based access control
- Secure family linking with invite codes
- Local data validation with server synchronization

## 📱 Platform Requirements

- iOS 17.0+ / iPadOS 17.0+
- Swift 5.9+
- SwiftUI framework
- Screen Time API integration

## 🧪 Testing

Both iOS apps include comprehensive unit and integration tests:

```bash
# Run Parent app tests
cd ios-parent
xcodebuild test -scheme ScreenTimeParent -destination 'platform=iOS Simulator,name=iPhone 15'

# Run Child app tests
cd ios-child
xcodebuild test -scheme ScreenTimeChild -destination 'platform=iOS Simulator,name=iPhone 15'
```

## 📚 Documentation

- [Architecture Overview](docs/ARCHITECTURE.md)
- [API Documentation](docs/API.md)
- [Deployment Guide](docs/DEPLOYMENT.md)
- [Backend Setup](backend/docs/SETUP.md)

## 🛣️ Roadmap

### MVP (Current)
- Core authentication and family management
- Basic educational time enforcement
- App categorization
- Usage tracking and reporting

### Future Enhancements
- Machine learning for app recommendations
- Gamification and rewards system
- Advanced scheduling (school time, bedtime)
- Integration with educational platforms
- Multi-device enforcement
- Content filtering

## 📄 License

Copyright © 2024. All rights reserved.

## 🤝 Support

For issues and questions, please contact support or create an issue in the repository.

---

Built with ❤️ for families who want balanced screen time
