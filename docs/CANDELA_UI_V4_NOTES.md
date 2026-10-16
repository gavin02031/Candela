# Candela UI V4 — visual refresh

Implementation branch: `u/Candela`. Date: October 16, 2026.

## Inspiration, not imitation

We reviewed **iiSU** (Android emulation frontend) and **SUMEE!** (iOS retro gaming OS). We borrowed their broad emphasis on game artwork, personally customized hubs, accessible shortcuts, and a console-like experience, without copying trademarks, assets or layouts.

References:
- https://github.com/iisu-network/iiSU
- https://sumee.online/

## Changes

1. **Game-first home and constrained hero:** fix oversized hero caused by unconstrained blurred artwork, maintain game-first presentation and functional resume, and remove duplicate system clock/battery detail from the launcher status pill.
2. **Settings dashboard:** replace the top-level emulator-list UI with a compact native SwiftUI dashboard. Direct links to Touch Studio, Themes, Gamepads/Input, Library/Misc, Graphics, System, Advanced; quick performance presets, thermal-governor toggle and volume slider work from the landing page.
3. **Profile:** smaller identity header, optional edit tray for nickname/avatar, genuine play session stats, recently opened fallback for people whose sessions predate tracking, and existing Share/Profiles integration.

## Preserved

- MeloNX input, renderer and native core, untouched.
- Existing in-depth Settings categories and the `SettingsView.sectionsView(for:)` destination path. Old `CandelaHubScreen` remains as legacy fallback; it is not the new root.
- App identity, entitlement, signing, Xcode project membership and build recipe.
- Per-game Touch Studio layouts, Odyssey Glass and Bluetooth controller support.
- UserDefaults game favorites, playtime and session tracking, and current saved theme.

## Device acceptance checks

- Launch home with 0, 1 and 3+ games. Featured hero remains **roughly 153 points tall**, never expands to hundreds of points from art.
- iPhone 15 portrait: status pill, greeting, hero and a portion of the library are reachable without unusual blank space; floating navigation remains available.
- Open Settings: theme feature responds to theme selection, Touch Studio works, Graphics opens existing advanced graphics settings, System/Library/Advanced categories are reachable and operational.
- Cool/Balanced/Bright quick presets persist actual config value; thermal switch and volume slider still work.
- Profile displays actual playtime only. Changing name and selecting an avatar persist; dismiss and return without losing state.
- Check Dark Mode, VoiceOver labels and Dynamic Type; increase system text size for clipping risks.
- Build through the existing unsigned IPA GitHub Action; physical device screenshots decide additional layout polish.

## Later refinements

- A fully distinct details hero with enriched covers when users provide/enable authorized artwork sources.
- Optional grid density choices and larger landscape layouts.
- Better page transitions and haptics with Reduce Motion checks.
- Profile history graph after at least several actual play sessions.
- Authenticated optional Discord integration, not a stub. Networking/LDN is a separate compatibility project.
