# Tomodachi Touch V2 — Candela per-game control profile

Branch: `u/Candela`. Game: **Tomodachi Life: Living the Dream** (Nintendo Switch). This profile is not for the Nintendo 3DS Tomodachi Life.

## Research-backed constraints

Nintendo confirms **button controls are primary**; some scenes, including Mii creation and the Palette House workshop, support direct touch:
https://en-americas-support.nintendo.com/app/answers/detail/a_id/71507

Nintendo's official local play guide explicitly says to press **A** on the title screen and **X** to open the game's menu:
https://en-americas-support.nintendo.com/app/answers/detail/a_id/71492

This profile does **not** claim game-wide touch-to-click or magically jump to Gift, Shop, Apartment, Camera, or Map screens. The original MeltNX/Melo-Controller connection sends real A/B/X/Y, sticks, D-pad, shoulder and +/- inputs. The game interprets them.

## Implemented

- Native-style pastel translucent bubbles (mint confirm, lavender back, pink menu, peach secondary action) and compact menu selector.
- **Casual**: small analog stick + primary buttons; minimal overlay. Still navigable when the game only accepts controller input.
- **Hybrid** (default): movement stick + button helpers, with optional camera stick.
- **Classic**: exact original Melo-Controller runtime layout and original editor, preserving saved positions.
- Explicit in-game modes: **Island**, **Interaction**, **Shop**, **Activity**, and **Touch Scene**.
- Touch Scene hides everything except A/B and the mode menu so Nintendo's supported direct-touch interactions can reach the existing emulated touchscreen.
- Activity mode reveals D-pad and shoulder controls for games needing extra inputs; other modes can show those optionally.
- Manual Focus mode reduces clutter but preserves A/B/X.
- The game itself is **not** inspected for its scene; mode changes are manual. The mode bubble selects a layout, not a screen in the game.
- Touch Studio: live, drag-to-move landscape preview; mode preview; preset cards; left-handed mirroring, labels, size, opacity, shoulder and directional buttons, reset/save; settings persist per title ID.
- UIKit multitouch hit areas with matching press/release events, analog dead zone and recentering; release all inputs when leaving or backgrounding the scene.
- Separate opt-in enable/disable setting under Touch Studio. Enabled by default for the named Switch game; turning it off restores the existing untouched controller system.
- iPhone portrait falls back to the original controller, because this is a landscape-first control design.

## Limits / device validation

- A/B/X/Y may take different roles in different game scenes. Button bubble labels describe the physical input, not universal shortcuts.
- A controls confirmation, X opens the game menu where supported by the title. The "Shop", "Interaction", and "Activity" modes only select available button arrangements.
- The current runtime uses the existing MeloNX touch-forwarding; full virtual mouse/cursor emulation outside Nintendo's touch-capable scenes is **not** part of V2.
- Neither official Nintendo local wireless nor Switch Online has been implemented in this profile.
- Visual bubble presses should never block unrelated parts of the gameplay screen. If taps fail outside the bubbles, investigate the SwiftUI overlay hit testing and MetalView forwarding.
- Test name detection on the **actual imported game metadata**; test physical controller connected vs disconnected, Mii editor touch scene, gameplay navigation, A on title screen, X in island mode, B to back out, held stick multitouch, portrait fallback, saved position after relaunch and original layout after disabling.
- No game files or Nintendo artwork included. Candela licensing, signing, build configuration, entitlements and MeloNX core are unchanged.

## Next after validation

1. Test Tomodachi on-device and tune bubble geometry/contrast/gestures based on real screenshots.
2. For Tears of the Kingdom, build a separate action-focused Touch Studio profile and verify hardware performance independently.
