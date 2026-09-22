# `window.opoobo` Bridge Reference

Injected by `MiniAppBridge.inject()` (`lib/bridge/mini_app_bridge.dart`,
source in `lib/bridge/bridge_js.dart`) on every page load inside
`MiniAppScreen`. Never assume it exists — always guard for plain browsers.

## Guard + ready pattern (copy this)

```js
function opoobo() { return window.opoobo && window.opoobo._bridgeReady ? window.opoobo : null; }

window.addEventListener('opoobo:ready', init);
window.addEventListener('opoobo:tokenReady', init);
if (opoobo()) init(); // already injected (e.g. soft nav)
```

## Identity (sync getters)

| Member | Type | Notes |
|---|---|---|
| `opoobo.accessToken` | `string \| null` | Keycloak access token. Send as `Authorization: Bearer <token>` to **your own** backend; validate against `https://account.opoobo.com/realms/opoobo`. Never log or store it in plain text. |
| `opoobo.moduleName` | `string` | Slug, e.g. `"hello-opoobo"`. Set by Flutter from the `Module` record. |
| `opoobo.moduleVersion` | `string` | e.g. `"1.0.0"`. |
| `opoobo.getUserProfile()` | `object` | Copy of SSO profile (`sub`, `name`, `email`, …). Read-only snapshot — re-read after resume. |
| `opoobo.getModuleInfo()` | `{name, version}` | Same as the two getters above. |
| `opoobo.getTheme()` | `'light' \| 'dark'` | Mirrors the app theme at injection time. Listen for changes below. |
| `opoobo.getPlatform()` | `{os, appVersion, locale}` | `os` is `'unknown'` today; `locale` is `navigator.language`. |

## Async data (Promises, 10s timeout)

| Call | Resolves to | Notes |
|---|---|---|
| `opoobo.getWalletBalance()` | balance payload | Read-only. Handled natively; may resolve empty on older shells — handle `null`. |
| `opoobo.getSavedAddresses()` | address list | Same as above. |
| `opoobo.getPaymentMethods()` | payment-method list | Same as above. |

```js
try {
  const balance = await opoobo().getWalletBalance();
} catch (e) {
  // 'Bridge call timed out' — degrade gracefully
}
```

## Actions (fire-and-forget)

| Call | Effect |
|---|---|
| `opoobo.requestBack()` | Pops the mini-app (respects WebView history first). |
| `opoobo.showToast(message)` | Native `SnackBar`, 2s. Use for confirmations, not errors. |
| `opoobo.trackEvent(name, props)` | Analytics hook (`props` optional object). |

## Events (listen on `window`)

| Event | `detail` | When |
|---|---|---|
| `opoobo:ready` | `{moduleName}` | Bridge injected, safe to call sync APIs. |
| `opoobo:tokenReady` | `{accessToken, moduleName}` | Token set — start authed fetches here. |
| `opoobo:themeChanged` | `{theme}` | User toggled light/dark — re-theme without reload. |
| `opoobo:appPause` | — | App backgrounded — pause timers/media. |
| `opoobo:appResume` | — | App foregrounded — refresh profile/balance. |

```js
window.addEventListener('opoobo:themeChanged', (e) => applyTheme(e.detail.theme));
window.addEventListener('opoobo:appResume', () => refresh());
```

## Host-side rules that affect you

- **Origin lock:** `MiniAppScreen` cancels navigation away from your
  `module_url` origin. External links (`tel:`, `sms:`, `mailto:` allowed)
  must use `target="_blank"` flows or in-page modals — no cross-domain nav.
- **Back button:** Android back goes through WebView history before exiting.
- **Header:** the shell renders `MiniAppHeader` (back / refresh / copy link /
  report). Don't build your own top back button; do leave `env(safe-area)` room.
- **Install counting:** opening from `MiniAppDetailScreen` fires
  `POST /store/install/{id}` — no work needed on your side.
- **Compliance badges** on the detail page (`HTTPS`, `Loads correctly`,
  `Reviewed`) come from `ssl_valid`, `url_loads`, `last_preflight_status`.
  Ship HTTPS + fast first paint to pass preflight.
