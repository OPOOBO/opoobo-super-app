# Native Module Track (first-party, Flutter)

> Third-party developer? Stop here — build a **mini-app** instead
> ([`create-mini-app.md`](create-mini-app.md)). This track compiles Dart
> into the app binary and is reserved for the core team. It is documented
> here so the pattern stays consistent.

The reference implementation is the **Bus** module. Mirror its layers.

## 1. Layer map (Bus example)

| Layer | File(s) | Role |
|---|---|---|
| Transport | `lib/core/bus_api_client.dart` | Raw HTTP to the module backend. Uses its own `Dio(BaseOptions(...))` because the bus API has a different base URL + envelope (`Result`/`ResponseMsg`). Prefer `DioFactory.create()` when talking to the OPOOBO backend (`https://one.opoobo.com/api/v1`). |
| Models | `lib/models/bus/*.dart` | `fromJson` parsing: `city.dart`, `bus_search_result.dart`, `bus_layout.dart`, `boarding_point.dart`, `booking.dart`, `coupon.dart`, `operator.dart`. |
| State | `lib/providers/bus_booking_provider.dart` | `ChangeNotifier`: step machine (`BookingStep`), selections, loading/error, history. Registered in `main.dart` `MultiProvider`. |
| UI | `lib/screens/bus_module_screen.dart` + `bus_results_screen.dart`, `seat_map_screen.dart`, `passenger_info_screen.dart`, `bus_payment_screen.dart`, `booking_success_screen.dart`, `booking_history_screen.dart`, `ticket_detail_screen.dart` | Screens use `ScreenHeader`, `AppColors`, `GoogleFonts`, `NavigationHelper.push`. |
| Discovery | `lib/screens/services_screen.dart` (`_ModuleTile`), `lib/screens/home_screen.dart` (`_ModuleCard`), `lib/providers/module_provider.dart` (`_fallbackModules`) | Routing: `isMiniApp` → `MiniAppScreen`; `name == 'bus'` → `BusModuleScreen`; `name == 'market'` → `MarketplaceScreen`; else coming-soon dialog. |
| Identity | `lib/providers/auth_provider.dart` (`ensureModulesLinked` → `ModuleApiClient.autoLinkModules`), `lib/core/sso_service.dart` | Silent SSO link on login + first dashboard visit. New native modules that need per-module accounts must add a branch to the auto-link backend and the `ModuleRegistrationScreen` flow. |

## 2. Checklist for a new native module `food`

1. `lib/core/food_api_client.dart` — Dio calls, unwrap envelope, typed responses.
2. `lib/models/food/*.dart` — models with `fromJson`.
3. `lib/providers/food_provider.dart` — `ChangeNotifier`, `loading`/`error`, CRUD + reset.
4. Register in `lib/main.dart`: `ChangeNotifierProvider(create: (_) => FoodProvider())`.
5. `lib/screens/food_module_screen.dart` — `ScreenHeader` + themed scaffold; push sub-screens with `NavigationHelper.push`.
6. Route it: `services_screen.dart` `_ModuleTile.onTap`, `home_screen.dart` `_ModuleCard` tap handler, `_getIcon('food')` already exists.
7. Linking: extend backend `/modules/auto-link` + `ModuleData` (`module_provider.dart`) if the module needs its own `uid`; surface link state via `isModuleLinked(name)` / `getModuleUid(name)`.
8. Stats/activity: extend `DashboardProvider` + home cards if the module contributes spend/orders.

## 3. UI conventions (enforced in review)

- Colors only from `AppColors` (`lib/theme/app_colors.dart`); theme via `AppTheme.light()/dark()` — no hardcoded hex in screens.
- Typography: `GoogleFonts.sora` for titles, `GoogleFonts.plusJakartaSans` for body.
- Navigation: `NavigationHelper.push/replacement/popToRoot` — never raw `Navigator.push` with `MaterialPageRoute` in new code.
- Headers: `ScreenHeader(title:, subtitle:, showBack:)`; mini-app containers use `MiniAppHeader`.
- State widgets handle `loading` (spinner), `error` (message + Retry), empty (illustration + CTA) — see `MarketplaceScreen` pull-to-refresh + paged grid.
