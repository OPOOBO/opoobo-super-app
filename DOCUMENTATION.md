# OPOOBO Super App (opoobo) - Project Documentation

## Overview

OPOOBO is the **main super-app** container that aggregates multiple services (Bus, Market, Mall, and future services) under one unified account. It features SSO via Keycloak, a module system with auto-linking, a mini-app WebView platform with JavaScript bridge, and fully implemented Bus booking and Marketplace native modules.

**Package:** `com.opoobo` | **Backend:** `https://one.opoobo.com/api/v1`

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart SDK ^3.11.3) |
| State Management | Provider (ChangeNotifier) |
| Networking | Dio |
| Auth | Keycloak SSO (OIDC PKCE via flutter_appauth) |
| Secure Storage | flutter_secure_storage |
| Payments | Flutterwave |
| WebView | flutter_inappwebview |
| Typography | Google Fonts (Sora + Plus Jakarta Sans) |
| Design | Glass-morphism, Material 3 |

---

## Project Structure

```
opoobo/
  lib/
    main.dart                    # Entry point, MultiProvider
    app.dart                     # MaterialApp, auth routing
    core/
      api_client.dart            # OPOOBO backend REST client
      bus_api_client.dart        # Bus module REST client
      module_api_client.dart     # Module linking, Store APIs
      user_api_client.dart       # Payment, addresses, security
      dio_factory.dart           # Dio config with SSO interceptor
      sso_config.dart            # Keycloak constants
      sso_service.dart           # OIDC lifecycle: login, refresh, logout
    bridge/
      bridge_js.dart             # window.opoobo JS SDK source
      mini_app_bridge.dart       # Flutter-side injection + handler
    models/                      # Data models
    providers/                   # 10 ChangeNotifier providers
    screens/                     # 43 screen files
    services/market_service.dart # Market API client
    theme/                       # Colors, theme, typography
    widgets/                     # 10 reusable widgets
    data/mock_data.dart          # Mock services, activity items
  docs/                          # Developer documentation
    create-mini-app.md           # Mini-app developer tutorial
    create-native-module.md      # Native module guide
    mini-app-bridge.md           # JS bridge API reference
    examples/hello-opoobo/       # Demo mini-app
```

---

## What Has Been Done

### Authentication (SSO)
- Keycloak OIDC PKCE login (single button, no in-app form)
- Auto token refresh with single-flight deduplication
- JWT expiry detection with clock skew leeway
- Session persistence via secure storage
- Auth state machine: initial -> loading -> authenticated/error

### Module System (Super App)
- Auto-linking: On login, silently links Bus and Market accounts
- Module routing: mini-apps via WebView, native modules via Flutter screens
- Fallback catalogue if backend unreachable
- Module states: linked, unlinked, coming soon, active, featured

### Bus Booking (Fully Implemented)
- City search with autocomplete
- Multi-step wizard: Search -> Results -> Boarding -> Package -> Seat -> Passenger -> Payment -> Success
- Interactive seat selection
- Economy/business package selection
- Coupon validation
- Flutterwave payment (saved cards + new)
- Booking history, ticket details, cancellation

### Marketplace
- Paginated item browsing with pull-to-refresh
- Category filtering, search
- Favourites, item detail with offers
- Chat system (list + thread)
- Offers, reviews, ratings
- Job applications, reels, notifications

### Mini-App Platform
- WebView container with InAppWebView
- Origin lock (navigation outside module URL cancelled)
- JS Bridge (window.opoobo):
  - Sync: getUserProfile, getModuleInfo, getTheme, accessToken
  - Async: getWalletBalance, getSavedAddresses, getPaymentMethods
  - Actions: requestBack, showToast, trackEvent
  - Events: opoobo:ready, opoobo:tokenReady, opoobo:themeChanged
- Store for browsing/installing mini-apps
- Compliance badges

### Dashboard & Profile
- Wallet card with balance (hide/show toggle)
- Quick stats: reward points, monthly spend
- Recent activity feed
- Services grid with linked/unlinked badges
- Connected apps management
- All settings (payments, addresses, security, theme, language)

### UI/UX
- Animated splash with mesh background, glass circles
- 4-step onboarding carousel
- Custom navigation transitions
- Bottom navigation with gradient active state
- Glass-morphism design throughout
- Full light + dark mode

---

## What Can Be Added

### High Priority
1. Push notifications - FCM integration for module updates
2. Biometric auth - Fingerprint/face unlock
3. Offline mode - Cache critical data for offline use
4. Deep linking - Universal links for specific modules
5. App shortcuts - Quick actions for common tasks

### Medium Priority
6. Widget support - Home screen widgets for wallet, quick actions
7. Apple Watch - Companion watch app for notifications
8. Accessibility - Screen reader support, dynamic type
9. Multi-language - Add Hausa, Yoruba, Igbo
10. Performance - Profile startup, reduce bundle size

### Low Priority
11. In-app updates - Google Play in-app update API
12. Analytics dashboard - User behavior tracking
13. A/B testing - Test different UI flows
14. Voice commands - "Hey Google, show my bus tickets"
15. AR features - AR navigation to bus terminals

---

## How to Add New Features

### Adding a New Native Module
1. See `docs/create-native-module.md`
2. Create module screens in `lib/screens/`
3. Create API client in `lib/core/`
4. Create provider in `lib/providers/`
5. Register in module provider routing
6. Add to mock_data.dart if needed

### Adding a New Mini-App
1. See `docs/create-mini-app.md`
2. Build web app using window.opoobo bridge
3. Submit via Store API or admin portal
4. Test with bridge API reference in `docs/mini-app-bridge.md`

### Adding a New Screen
1. Create screen in `lib/screens/`
2. Add route if needed (update app.dart or use NavigationHelper)
3. Create provider if needed in `lib/providers/`
4. Register in MultiProvider in main.dart

### Adding a New API Client
1. Create client in `lib/core/`
2. Use DioFactory for consistent config
3. Add SSO interceptor for authenticated requests
4. Register in MultiProvider

---

## Build & Run

```bash
# Run with custom backend
flutter run --dart-define=API_BASE_URL=http://your-server:8000/api/v1

# Build APK for LAN device
flutter build apk --release --dart-define=API_BASE_URL=http://192.168.1.4:8000/api/v1

# Start Laravel backend
cd ~/Documents/Projects/opoobo-backend
php artisan serve --host=0.0.0.0

# Standard Flutter
flutter run
flutter build apk --release
flutter build ios --release
flutter test
flutter analyze
```

### Key Config
- `lib/core/sso_config.dart` - Keycloak OIDC config
- `lib/core/api_client.dart` - Backend API base URL
- `lib/core/bus_api_client.dart` - Bus API base URL
- `--dart-define=API_BASE_URL=...` - Override backend URL at build time
