# Create a Mini-App (third-party track)

Build a mobile web app, host it at your own HTTPS URL, submit it to the
OPOOBO Store — users open it inside OPOOBO with single sign-on.
**No Flutter, no app-store release, no login screen needed.**

Follow this guide top to bottom and you will finish with a working demo
module (**Hello OPOOBO**) visible in Store → Detail → Open → Services.

## 0. What you need

- Any static host with **HTTPS** (GitHub Pages, Vercel, Netlify, your VPS).
- 30 minutes + a text editor. The demo is one `index.html` file.
- An OPOOBO account to test with. To submit to the Store you need a
  backend session — see step 5.

## 1. Understand what runs where

| Piece | Lives | You own? |
|---|---|---|
| Your mini-app (HTML/JS/CSS) | `https://your-app.com` | yes, everything |
| `MiniAppScreen` WebView + `window.opoobo` bridge | OPOOBO shell (`lib/screens/mini_app_screen.dart`, `lib/bridge/`) | no, see `mini-app-bridge.md` |
| `Module` record + Store listing | OPOOBO backend (`GET /store`, `POST /store/submit`, `GET /mini-apps/{id}`) | you create it via API |
| SSO (Keycloak `opoobo-mobile`) | `https://account.opoobo.com/realms/opoobo` | you consume the token |

Rules that shape your app:

1. **Origin lock** — the shell cancels navigation outside your
   `module_url` origin. Keep it a single-page app.
2. **Bridge may be absent** in a plain browser — always guard
   (`window.opoobo && window.opoobo._bridgeReady`) and provide fallbacks.
3. **Light + dark** — the shell injects the theme; respect it.

## 2. Scaffold Hello OPOOBO (5 min)

Copy the runnable demo at `examples/hello-opoobo/index.html`
— or recreate it yourself. It demonstrates every required pattern:

- bridge guard + `opoobo:ready` / `opoobo:tokenReady` init,
- profile, module info, theme, platform display,
- `getWalletBalance()` with timeout fallback,
- `showToast()`, `requestBack()`, `trackEvent()`,
- `themeChanged` / `appPause` / `appResume` listeners,
- `?mock=1` query param that fakes the bridge for desktop testing.

```bash
# preview locally (bridge absent -> page shows fallback, still usable)
cd docs/examples/hello-opoobo
python3 -m http.server 8080
# open http://localhost:8080/index.html and .../index.html?mock=1
```

CHECKPOINT-1: both URLs render. `?mock=1` shows mock profile.

## 3. Use the bridge (the 6 calls you need)

Full API: `mini-app-bridge.md`. Minimum viable:

```js
const sdk = () => (window.opoobo && window.opoobo._bridgeReady) ? window.opoobo : null;

function init() {
  const b = sdk(); if (!b) return renderFallback();
  document.getElementById('name').textContent = b.getUserProfile().name || 'OPOOBO user';
  applyTheme(b.getTheme());
  b.trackEvent('hello_opened', b.getModuleInfo());
}
window.addEventListener('opoobo:ready', init);
window.addEventListener('opoobo:tokenReady', init);
if (sdk()) init();
```

Auth from your backend (optional at demo stage):

```js
const token = sdk()?.accessToken; // Keycloak JWT
fetch('https://your-api.example.com/me', {
  headers: { Authorization: `Bearer ${token}` },
});
// Validate the JWT against https://account.opoobo.com/realms/opoobo —
// never accept a user id the client merely claims.
```

## 4. Host it on HTTPS

The Store preflight checks `ssl_valid` + `url_loads` — plain HTTP fails.
Ship one file, no build step, under ~100 KB for fast 3G first paint.

CHECKPOINT-2: your public URL loads on a phone browser with no
console errors.

## 5. Submit to the Store

You need an authenticated session against the OPOOBO backend
(default `https://one.opoobo.com/api/v1`, override with
`--dart-define=API_BASE_URL=...` — see `commands.md`). Same contract the
app uses in `lib/core/module_api_client.dart` (`storeSubmit`):

```bash
export API=https://one.opoobo.com/api/v1
export TOKEN="<your SSO access token>"

curl -X POST "$API/store/submit" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "display_name": "Hello OPOOBO",
    "description": "Demo mini-app: greets you with your OPOOBO profile.",
    "module_url": "https://your-app.com/hello-opoobo/",
    "developer_name": "Your Name",
    "developer_url": "https://you.example.com",
    "category": "demo",
    "icon": "waving_hand"
  }'
```

Icon strings map to Material icons in `StoreScreen` / `MiniAppDetailScreen`
(`_getIcon`): `directions_bus_rounded`, `shopping_cart_rounded`,
`directions_car_rounded`, `storefront_rounded`,
`account_balance_wallet_rounded`, `card_giftcard_rounded`,
`play_circle_outline_rounded`, `work_outline_rounded` — anything else falls
back to `widgets_rounded`.

## 6. Verify end-to-end (demo acceptance test)

1. **Store:** your app appears under category filter + search
   (`GET /store?q=hello` — `lib/screens/store_screen.dart`).
2. **Detail:** tap it — icon, stats, compliance badges render
   (`GET /mini-apps/{id}` — `lib/screens/mini_app_detail_screen.dart`).
3. **Open:** tap Open — `MiniAppScreen` loads your URL, injects token +
   profile + theme; `opoobo:ready` fires. Opening fires
   `POST /store/install/{id}` automatically.
4. **Inside:** name greets from `getUserProfile()`, theme matches the app,
   balance button works or degrades, toast/back respond.
5. **Services:** listed in Services/Home grids (`ModuleData.isMiniApp` →
   `MiniAppScreen` routing in `lib/screens/services_screen.dart`).

DONE when: all five pass on a physical device in light + dark mode.

## 7. Ship checklist (review checks these)

- [ ] HTTPS, fast first paint, no cross-origin navigation.
- [ ] Works with no bridge (browser) and no token — friendly fallback.
- [ ] Respects `getTheme()` + `themeChanged`; tap targets 44pt+; safe-area honored.
- [ ] No login form — SSO only. Token never in URLs or logs.
- [ ] Back behavior sane (in-app back calls `requestBack()`, no traps).
- [ ] `trackEvent()` on key actions; pause timers on `appPause`.

## 8. Go further

- Full bridge surface: `mini-app-bridge.md`.
- Shell source: `lib/screens/mini_app_screen.dart` (origin lock, progress,
  lifecycle), `lib/bridge/bridge_js.dart` (injected source),
  `lib/screens/store_screen.dart` + `mini_app_detail_screen.dart`,
  `lib/screens/services_screen.dart` (routing).
- Need device APIs or payments beyond the read-only calls? That is a
  **native module** (`create-native-module.md`, core team only).

## Troubleshooting

| Symptom | Fix |
|---|---|
| `window.opoobo` undefined | Guard + wait for `opoobo:ready`. |
| `getWalletBalance()` rejects timeout | Catch and show "unavailable". |
| Link kills the app view | Cross-origin nav is blocked — stay in-page. |
| Red compliance badges | Fix HTTPS / load errors, wait for `approved` preflight. |
| `401` from your backend | Token expired — ask user to re-open for a fresh inject. |


