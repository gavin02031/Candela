# Candela Themes V1 — launcher-wide appearance

Updated October 16, 2026. Working branch: `u/Candela`.

## Product direction

Candela has a distinctive pastel identity rather than a copy of any other launcher. The user-provided pastel Candela mockup and the dark game-launcher reference inform a configurable console-like interface. SUMEE! is inspiration for coherent customization, not a source of assets or code.

## Implemented

- One set of seven appearance presets: Pastel Dream (default), Classic Blush, Arctic Glass, Sunset Pop, Obsidian Ember, Mint Arcade and Midnight Neon.
- A grid-based gallery in Settings with miniature launcher previews, descriptive names and a selected indicator.
- Shared semantic colors in `CandelaPalette`: backgrounds, card surfaces/strokes, text, primary/secondary accents and gradients.
- `ThemeManager` now persists gallery selection under `candela.theme.style.v1` and aligns the older `AppTheme` picker's selection, window interface style and SwiftUI environment.
- Main launch surfaces read the current `appTheme` environment so theme changes invalidate views even when both presets use the same light/dark color scheme.
- Theme defaults to Pastel Dream; older appearance preferences are migrated conservatively.
- Music V2 collection selection now uses an identifiable sheet wrapper so the player can compile.

## Non-goals and scope guards

- No core emulation, renderer, memory, JIT, touch input, signing or entitlements changes.
- A 60 FPS target displayed in a concept image is not a guarantee of Switch game performance.
- Themes affect Candela-owned launcher and music UI; system dialogs and in-game Nintendo visuals are not recolored.
- Built-in theme backgrounds are generated gradients and Candela-specific shapes; no game artwork is bundled.

## iPhone acceptance checklist

1. Install a newly built, signed IPA and open **Settings > Themes**. Verify seven previews and that the selected theme persists after relaunch.
2. Switch among two **light** presets and two **dark** presets; check Home, floating tab bar, game details, profile, Settings and the Music mini/full player.
3. Confirm black/dark themes use bright legible text, correct safe areas, and accessible selected controls.
4. Verify the older Settings appearance selector also updates the gallery.
5. Background and foreground Candela; check theme and music pause behavior remain correct.
6. Verify Leave Game, game launching, graphics/performance settings, touch layouts, gamepads and JIT unchanged.
7. Test larger Dynamic Type, VoiceOver selected state and Reduce Motion.

## Suggested next iterations (after device screenshots)

1. Match the mockup's game-detail hierarchy more closely: full-width art, readable metadata, purposeful Play button and sticky access to controls.
2. Refine the floating bottom navigation and interactive game-library cards to reflect the active palette with consistent corner radii and shadows.
3. Add a user-facing *custom theme editor* (accent color, secondary color, blur and background effect), using versioned data with safe defaults and no remote asset dependency.
4. Add optional game-specific UI wallpapers using user-provided lawful artwork, while preserving text contrast and loading performance.
5. Tune per-device layouts with screenshots from an actual iPhone 15; do not infer pixel-perfect parity from mockups alone.
