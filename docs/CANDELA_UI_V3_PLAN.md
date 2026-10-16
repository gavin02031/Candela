# Candela UI V3 — mockup fidelity, local profile, play stats, and connected features

Status: first UI implementation batch committed on `u/Candela`. Last reviewed October 2026.

## Design contract

- Signature theme: Pastel Dream (blush, lavender, mint, cream, subtle glass).
- Main library: profile greeting + pastel featured game, recent games, searchable/filterable game cards.
- Detailed game page: real playtime, launch count, existing per-game Controls, Mods, DLC and Settings.
- Work toward more mockup-faithful home/game-details/settings while preserving MeloNX and input paths.
- Respect legibility (avoid white labels on light pastel), Dynamic Type, reduced motion, and iPhone 15 safe areas.
- Keep physical controllers functional while supporting custom touch input.

## Delivered in this batch

1. Compact **A** at top center in Odyssey Glass for menu confirmations, plus an editor toggle to show A/B/X/Y together. Existing Odyssey action buttons remain unchanged.
2. Launcher profile with editable display name and locally selected avatar.
3. Local foreground emulation session tracking. Time is paused on background/inactive; it is not fabricated for older sessions.
4. Updated home with profile avatar, games/playtime chips, softer hero, searchable library, favorites filter, and enlarged cards.
5. Upgraded game details with actual session statistics and live links into the existing per-game controller editor, mod manager, DLC manager, and settings.
6. iOS Share Sheet for sharing a short profile summary, which can be shared to Discord when it appears as an installed share destination.

## Implementation / persistence

- `CandelaLibraryStore` owns the session-clock state and persists seconds + launch counts in versioned `UserDefaults` keys.
- `EmulationView` starts/stops sessions with view lifecycle and pauses on scene background; do not count time outside foreground gameplay.
- Saved game layouts are preserved; Odyssey's new menu controls are appended to the existing versioned glass profile. Full ABXY is optional.
- Local Candela launcher profile is **not** the same as the emulator's Switch-user/account manager; both are available.
- No profile data is synced or uploaded by this batch.

## Existing mods

Candela already has `ModsManagerSheet` and per-game mod folder/metadata handling. It can import mod directories, toggle enabled state and remove mods. Support remains limited and game-dependent, as its existing warning states. Do not introduce an unreviewed mod store or automatically download copyrighted content.

## Discord integration — next milestone, not delivered

Discord Social SDK 1.10+ supports iOS. A *proper* integration needs:

- developer application credentials / OAuth login, user-consented scopes, privacy review
- iOS client/dependency integration and authentication state storage
- explicit opt-in for Rich Presence showing game and elapsed time
- disabling presence when gameplay stops, and opt-out/deletion controls
- verify terms of service for displaying third-party Nintendo game names/artwork

**Important:** unauthenticated Discord Rich Presence RPC is unavailable on iOS; use authenticated SDK if approved. The current iOS share sheet is the interim working social feature, not Discord account linking or automatic Rich Presence.

Docs:
- https://discord.com/blog/mobile-platform-support-arrives-in-discord-social-sdk
- https://github.com/discord/discord-api-docs/blob/main/developers/discord-social-sdk/development-guides/setting-rich-presence.mdx

## Multiplayer/online feasibility — investigation only

Distinguish:
- **Candela social features:** sharing profile/playtime, Discord friends/presence; feasible later with consent and SDK work
- **LDN local wireless over a network:** some Ryujinx variants implement this; inspect Candela's *actual core, networking build, and compatibility*, then validate with two devices. iOS NAT/traversal and performance are open issues
- **Nintendo Switch Online:** not unlocked or supported by adding a launcher UI; do not advertise that as a feature

LDN documentation: https://docs.ryujinx.app/guides/ldn-guide/

## Test plan

- Compile Xcode Release via existing GitHub Actions IPA workflow, preserving existing build recipe.
- Test A menu input on the Odyssey title screen; optionally enable full ABXY in Odyssey Glass editor, confirm all four work.
- Test landscape placements and custom persisted controls without losing current layout.
- Launch a game, play for a measured minute, background/resume, exit; verify session count and tracked playtime.
- Test search/favorite filter, jump-back-in, profile nickname persistence, library mod manager, settings, DLC and controller editor.
- Validate no changes to MeloNX core, licensing, signing/entitlements, project metadata or build workflow behavior.

## Next recommended UI passes

1. Further mockup fidelity: bottom navigation, hero artwork typography, per-game visual headers.
2. Theme selection previews, accessible contrast, consistent typography.
3. Optional game banner/cover artwork sourcing with rights and API reliability checks.
4. Discord OAuth + optional Rich Presence behind a separate feature gate.
5. Network compatibility audit for supported local-wireless titles; no premature multiplayer claims.
