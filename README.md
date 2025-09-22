# Spotify App (Flutter)

A modern Flutter music streaming application inspired by Spotify, featuring user authentication, dynamic theming, music playback, and comprehensive user settings with Firebase integration.

## Table of Contents

- [Features](#features)
- [Screenshots](#screenshots)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Firebase Setup](#firebase-setup)
- [Installation](#installation)
- [Configuration](#configuration)
- [Roadmap](#roadmap)
- [Contributing](#contributing)

## Features

### Core Features
- **Music Streaming**: Browse and play songs with a modern player interface
- **Dynamic Themes**: Light/Dark mode with system theme support
- **User Authentication**: Email/Password authentication via Firebase
- **Music Discovery**: Curated new songs and playlists
- **Offline Support**: Downloaded music playback capability

### UI/UX
- **Modern Design**: Glass morphism effects and smooth animations
- **Responsive Layout**: Optimized for various screen sizes
- **Intuitive Navigation**: Easy-to-use interface following Material Design

### User Management
- **Profile System**: User profiles with customizable settings
- **Settings Panel**: Comprehensive preference management
- **Social Integration**: Ready for Google/Apple sign-in integration

## Screenshots

<table>
  <tr>
    <td><img src="assets/screenshots/get_started.png" width="200"/></td>
    <td><img src="assets/screenshots/choose_mode.png" width="200"/></td>
    <td><img src="assets/screenshots/settings.png" width="200"/></td>
  </tr>
  <tr>
    <td align="center">Get Started</td>
    <td align="center">Choose Mode</td>
    <td align="center">Settings</td>
  </tr>
  <tr>
    <td><img src="assets/screenshots/home.png" width="200"/></td>
    <td><img src="assets/screenshots/profile.png" width="200"/></td>
  </tr>
  <tr>
    <td align="center">Home</td>
    <td align="center">Music Player</td>
    <td align="center">Profile</td>
  </tr>
</table>

## Architecture

The application follows **Clean Architecture** principles with clear separation of concerns:

```
Presentation Layer (UI) → Domain Layer (Business Logic) → Data Layer (Repository)
```

- **BLoC Pattern**: State management using `flutter_bloc` with Cubit
- **Feature-based Structure**: Each feature is self-contained
- **Dependency Injection**: Service locator pattern for dependencies

## Tech Stack

| Technology | Purpose |
|------------|---------|
| **Flutter** | Cross-platform mobile framework |
| **Dart** | Programming language |
| **Firebase Auth** | User authentication |
| **Cloud Firestore** | NoSQL database |
| **Firebase Storage** | Media file storage |
| **flutter_bloc** | State management |
| **flutter_svg** | Vector graphics |

## Project Structure

```
lib/
├── common/
│   ├── helpers/              # Utility functions and helpers
│   └── widgets/              # Reusable UI components
├── core/
│   ├── configs/
│   │   ├── assets/           # Asset path definitions
│   │   ├── constants/        # App constants
│   │   └── theme/           # Theme configuration
├── data/
│   ├── models/              # Data models
│   ├── repository/          # Data repositories
│   └── sources/             # Data sources (remote/local)
├── domain/
│   ├── entities/            # Business entities
│   ├── repository/          # Repository interfaces
│   └── usecases/            # Business use cases
├── presentation/
│   ├── auth/                # Authentication screens
│   ├── choose_mode/         # Theme selection
│   ├── get_started/         # Onboarding
│   ├── home/                # Home feed and navigation
│   ├── profile/             # User profile
│   ├── settings/            # App settings
│   ├── song_player/         # Music player
│   └── splash/              # Splash screen
├── service_locator.dart     # Dependency injection
└── main.dart               # App entry point
```

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio / VS Code
- A Firebase project

### Firebase Setup

1. **Create a Firebase Project**
   ```bash
   # Visit https://console.firebase.google.com/
   # Create a new project
   ```

2. **Install FlutterFire CLI**
   ```bash
   dart pub global activate flutterfire_cli
   ```

3. **Configure Firebase for your app**
   ```bash
   flutterfire configure
   ```

4. **Enable Services**
   - Authentication (Email/Password)
   - Cloud Firestore
   - Firebase Storage (optional)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/spotify_app.git
   cd spotify_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## Configuration

### Firebase Security Rules

**Firestore Rules**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /songs/{songId} {
      allow read: if request.auth != null;
    }
  }
}
```

**Storage Rules**
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /songs/{allPaths=**} {
      allow read: if request.auth != null;
    }
  }
}
```

### Environment Variables

Create a `.env` file in the root directory:
```env
# App Configuration
APP_NAME=Spotify Clone
DEBUG_MODE=true

# Firebase (handled by flutterfire configure)
# No manual configuration needed
```

### Asset Configuration

Ensure your `pubspec.yaml` includes:
```yaml
flutter:
  assets:
    - assets/images/
    - assets/vectors/
    - assets/screenshots/
```

## Key Features Detail

### Authentication System
- Email/password registration and login
- Password reset functionality
- Social login integration ready
- Secure session management

### Music Player
- Play/pause controls with smooth animations
- Progress bar with seek functionality
- Next/previous track navigation
- Volume control and repeat modes
- Beautiful vinyl-style UI with 3D effects

### Settings Management
- **Account**: Email management, password changes, subscription info
- **Profile & Privacy**: Display name, playlist privacy, activity sharing
- **Playback**: Audio quality, autoplay, crossfade, volume normalization
- **Notifications**: Granular notification preferences
- **Appearance**: Theme selection, language preferences
- **Storage**: Download quality, cache management

### State Management
Using BLoC pattern with Cubit for clean state management:
```dart
// Example: Authentication Cubit
class AuthCubit extends Cubit<AuthState> {
  final SigninUseCase signinUseCase;
  final SignupUseCase signupUseCase;
  
  AuthCubit({
    required this.signinUseCase,
    required this.signupUseCase,
  }) : super(AuthInitial());
  
  Future<void> signin(SigninUserReq params) async {
    emit(AuthLoading());
    final result = await signinUseCase.call(params: params);
    result.fold(
      (error) => emit(AuthFailure(error)),
      (success) => emit(AuthSuccess()),
    );
  }
}
```

## Roadmap

### Phase 1 (Current)
- [x] User Authentication
- [x] Basic Music Player
- [x] Profile Management
- [x] Settings Panel
- [x] Theme System

### Phase 2 (Next)
- [ ] Search Functionality
- [ ] Create Custom Playlists
- [ ] Social Features (Follow/Unfollow)
- [ ] Music Recommendations
- [ ] Offline Mode Enhancement

### Phase 3 (Future)
- [ ] Podcast Support
- [ ] Live Radio Streams
- [ ] Music Discovery AI
- [ ] Social Sharing
- [ ] Cross-device Sync

## Acknowledgments

- Spotify for design inspiration
- Flutter team for the amazing framework
- Firebase for backend services
- Contributors and community feedback

---

**Note**: This is a clone application created for educational purposes. Spotify is a trademark of Spotify AB.

## Support

If you find this project helpful, please consider:
- Starring the repository ⭐
- Following for updates
- Contributing to improvements
- Sharing with others

For questions or support, please open an issue or contact [thanhhbao4123@gmail.com](mailto:thanhhbao4123@gmail.com).
