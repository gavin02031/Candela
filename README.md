<p align="center">
  <img src="src/MeloNX/MeloNX/Assets/AppIcons/AppIcon.icon/Assets/Candela.png" alt="Candela icon" width="120">
</p>
<h1 align="center">Candela</h1>
<p align="center">A NS emulator for iPhone and iPad, with an iPhone 15-focused frontend and starting presets.</p>

> Candela is an unofficial fork of [MeloNX](https://starforgejo.dev/projects/MeloNX). It is not affiliated with the upstream teams. Report Candela problems in this repository, not to upstream.

## About

Candela is a emulator with a custom icon and app display name, a native SwiftUI home screen and per-game starting presets. The core and iOS platform use the pinned 2.7 source (13700519f3abc4e6d7ed8a065b118b2cc59bcd67).

**Validation status:** the Release build passed and an unsigned IPA was packaged with the RAM donor extension. No performance benchmarks or physical-device tests have been completed. A source feature is not a promise that it works on every iPhone, game or sideloading setup. Check Actions for the current build result; an unsigned IPA still needs signing and on-device testing.

## Candela features

- **Candela Home (beta):** Continue Playing, Recently Added, Favorites and the full library grid. Enable "New Candela Home (beta)" in Interface settings. It is off by default; "Use classic library" switches back.
- **Local favorites and play history:** kept on-device. Artwork currently uses embedded game icons; external artwork integration is not shipped.
- **Per-game starting presets:** Tears of the Kingdom, Super Mario Odyssey and Tomodachi Life. Presets apply only when there are no saved settings for that title. Saved per-game settings win, and global settings are not overwritten.
- **Shader cache and macro HLE defaults:** enabled for the Candela starting configuration. The presets are unmeasured starting points, not FPS claims.
- **Candela identity:** custom icon and display name. The existing MeloVertex bundle identifier is retained, so installing Candela can replace that app. Back up saves and settings first.

## Emulation and platform features

The app includes these implementations from the 2.7 source:

- **RAM offload:** NSExtensions and `xpc_shmem` move guest RAM into a donor app extension using shared memory. This is separate from the in-app Memory Limit Tester; do not use that tester as proof that RAM offload works. The extension must remain included when signing. OS behavior, entitlement requirements and sideloading compatibility need device testing. Upstream uses private NSExtension APIs here.
- **MetalFX spatial upscaling**, plus an anti-aliasing setting.
- **In-app controller remapping** and **library controller navigation**.
- **Experimental Steam Controller support** over CoreBluetooth.
- **iOS 27 AirPlay source retained, unavailable in the current build:** the runner has Xcode 26.3 and SDK 26.2, so scene-accessory registration is compile-gated. The workflow enables `CANDELA_IOS27_AIRPLAY` when an Xcode 27 runner is available. This is not full iOS 27 AirPlay support today.
- **Improved asynchronous shader compilation** and a fragment ClipDistance SPIR-V lookup fix.
- **BCn-to-ETC2 texture recompression** for GPUs without BCn support.
- **GPU buffer eviction under memory pressure**.
- Audio fixes, virtual-control opacity and disable fixes, background firmware import with better error reporting, improved per-game settings and save-folder access.

No RAM saving, frame rate, battery life or game compatibility improvement has been measured for Candela yet. Experimental features may fail or regress on some devices.

## Installing and JIT

Candela requires JIT. An unsigned build is not ready to install until it has been signed with your sideloader. Use the current installation and entitlement guidance in the Entitlements section below, and make sure your signing setup preserves the app extension and required entitlements.

Add only keys, firmware and games dumped from your own Switch, or legal homebrew. No keys, firmware or games are bundled or supplied here. Enable JIT using a method compatible with your exact iOS version. StikDebug is one upstream-recommended route; support for a particular OS/device must be checked, not assumed.

## Entitlements

Entitlements are permissions iOS grants an app to use certain features. Candela can use two:

- **Increased Memory Limit** lets the app use the most RAM iOS allows. It is required on every device.
- **Extended Virtual Addressing** lets the app ask iOS for more address space than the device physically has. It is a paid developer account entitlement (a TrollStore install also provides it). It is only needed on devices with less than 4 GB of RAM (iPhone) or less than 8 GB (iPad).

Your signing tool has to keep these entitlements and the app extension when it re-signs the IPA. Which entitlements a free account can add depends on your signing tool and iOS version, so check that before relying on it. This section follows the upstream project's guidance: https://starforgejo.dev/projects/MeloNX

## Building

The repository's Actions workflows build an unsigned iOS IPA on macOS runners. The 2.7 integration uses .NET 10, the `Ryujinx.Library` native AOT project and Xcode 26.3. The app build includes the RAM donor extension and checks for it before packaging.

Use **Build unsigned iOS IPA** from Actions on the working branch. Its artifact, if the build succeeds, is `Candela-2.7-unsigned-ipa`. The validated 2.7 build is [sync run #7](https://github.com/gavin02031/VortexClub/actions/runs/38466747430). A failed run has no installable artifact. Download successful artifacts from Actions and sign them with your sideloader. Do not treat an Actions success as device or performance verification.

LibHac `0.21.0-alpha.129` is rebuilt from exact archived revision `23e402ebb6dedc517e34a98a033078dc0f6fd478`. The original 2.7 dylib embeds that revision, tying the dependency to its original source. Validation: 1,616 tests passed, 0 failed, 11 skipped. The workflow repeats code generation, package build and tests rather than relying on the unavailable old feed.

Swift 6.2.4 crashes optimizing the synthesized generic `Setting` destructor; a local `@_optimize(none) deinit {}` workaround keeps normal Release optimization everywhere else. See [Swift issue 87462](https://github.com/swiftlang/swift/issues/87462).

## Credits and licenses

- MeloNX: iOS platform, frontend, controller, RAM-offload and graphics work.
- Ryujinx and its contributors: emulation core.
- [MeloVertex](https://github.com/VertexSelection/MeloVertex): the fork Candela started from.
- Third-party notices remain in the source and distribution documentation.

This fork's [LICENSE.txt](LICENSE.txt) declares AGPLv3 or later. Upstream 2.7's README says GPLv3, while its actual LICENSE.txt contains the MIT license. Its original license text is preserved in `docs/upstream-2.7-LICENSE.txt` with integration notes. Do not describe Candela as MIT-only or replace upstream notices; clarification may be needed before redistribution.
