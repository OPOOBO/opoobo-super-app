# OPOOBO Developer Docs

Guides for building on top of the OPOOBO super-app.

## Tracks — pick one

| Track | Who it's for | Start here |
|---|---|---|
| **Mini-app (web)** — recommended for all third-party developers. A mobile web app hosted at your own HTTPS URL, opened inside OPOOBO with SSO + `window.opoobo` bridge. | External developers, partners, hackathons | [`create-mini-app.md`](create-mini-app.md) |
| **Native module (Flutter)** — first-party only. A full `Provider` + `ApiClient` + `Screen` stack compiled into the app (the Bus/Market pattern). | Core team | [`create-native-module.md`](create-native-module.md) |

## Reference

- [`mini-app-bridge.md`](mini-app-bridge.md) — full `window.opoobo` JS bridge API (events, sync/async calls, actions).
- [`examples/hello-opoobo/index.html`](examples/hello-opoobo/index.html) — runnable demo mini-app. Open it in a browser, then host + submit it to the Store.

## Mental model (60 seconds)

```
Your web app (https://your-app.com)          OPOOBO Flutter shell
┌─────────────────────────────┐              ┌──────────────────────────────────┐
│ index.html                  │  loaded in   │ MiniAppScreen (InAppWebView)     │
│ uses window.opoobo.*        │ ◄──────────► │ injects SSO token + profile      │
│ no login screen needed      │  JS bridge   │ origin-locked, themed light/dark │
└─────────────────────────────┘              └──────────────────────────────────┘
        ▲ submits via POST /store/submit ──► Backend Module record
        └ appears in Store → Detail → Open → Services grid
```

A module is just a backend `Module` record with a `module_url`.
If `module_url` is set, the app treats it as a mini-app
(`ModuleData.isMiniApp`, see `lib/providers/module_provider.dart`)
and opens it in `MiniAppScreen` (`lib/screens/mini_app_screen.dart`).
