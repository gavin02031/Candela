<p align="center">
  <img src="src/MeloNX/MeloNX/Assets/Assets.xcassets/AppIcon.appiconset/1-nxgradientpng.png" alt="Candela icon" width="120">
</p>
<h1 align="center">Candela</h1>
<p align="center">A Nintendo Switch emulator for iPhone and iPad, with an iPhone 15-focused frontend and starting presets.</p>

> Unofficial fork. Candela is not affiliated with the MeloNX, MeloVertex or Ryujinx teams. Report Candela problems in this repository, not to upstream.

## About

Candela builds on MeloNX and Ryujinx, through the MeloVertex fork. It combines the Candela name, custom icon and app display name with a native SwiftUI home screen and per-game starting presets. The MeloNX 2.7 source integration is being validated on the temporary `sync/melonx-2.7` branch before landing on the working branch.

**Validation status:** no performance benchmarks or physical-device tests have been completed. A source feature is not a promise that it works on every iPhone, game or sideloading setup. Check Actions for the current build result; an unsigned IPA still needs signing and on-device testing.

## Candela features

- **Candela Home (beta):** Continue Playing, Recently Added, Favorites and the full library grid. Enable "New Candela Home (beta)" in Interface settings. It is off by default; "Use classic library" switches back.
- **Local favorites and play history:** kept on-device. Artwork currently uses embedded game icons; external artwork integration is not shipped.
- **Per-game starting presets:** Tears of the Kingdom, Super Mario Odyssey and Tomodachi Life. Presets apply only when there are no saved settings for that title. Saved per-game settings win, and global settings are not overwritten.
- **Shader cache and macro HLE defaults:** enabled for the Candela starting configuration. The presets are unmeasured starting points, not FPS claims.
- **Candela identity:** custom icon and display name. The existing MeloVertex bundle identifier is retained, so installing Candela can replace that app. Back up saves and settings first.

## MeloNX 2.7 features being integrated

These implementations come from upstream MeloNX 2.7, not new Candela inventions:

- **RAM offload:** NSExtensions and `xpc_shmem` move guest RAM into a donor app extension using shared memory. This is separate from the in-app Memory Limit Tester; do not use that tester as proof that RAM offload works. The extension must remain included when signing. OS behavior, entitlement requirements and sideloading compatibility need device testing. Upstream uses private NSExtension APIs here.
- **MetalFX spatial upscaling**, plus an anti-aliasing setting.
- **In-app controller remapping** and **library controller navigation**.
- **Experimental Steam Controller support** over CoreBluetooth.
- **iOS 27 AirPlay support** in upstream's presentation path.
- **Improved asynchronous shader compilation** and a fragment ClipDistance SPIR-V lookup fix.
- **BCn-to-ETC2 texture recompression** for GPUs without BCn support.
- **GPU buffer eviction under memory pressure**.
- Audio fixes, virtual-control opacity and disable fixes, background firmware import with better error reporting, improved per-game settings and save-folder access.

No RAM saving, frame rate, battery life or game compatibility improvement has been measured for Candela yet. Experimental features may fail or regress on some devices.

## Installing and JIT

Candela requires JIT. An unsigned build is not ready to install until it has been signed with your sideloader. Use the current upstream installation and entitlement guidance at [MeloNX](https://starforgejo.dev/projects/MeloNX#faq), and make sure your signing setup preserves the app extension and required entitlements.

Add only keys, firmware and games dumped from your own Switch, or legal homebrew. No keys, firmware or games are bundled or supplied here. Enable JIT using a method compatible with your exact iOS version. StikDebug is one upstream-recommended route; support for a particular OS/device must be checked, not assumed.

## Building

The repository's Actions workflows build an unsigned iOS IPA on macOS runners. The 2.7 integration uses .NET 10, the `Ryujinx.Library` native AOT project and Xcode 26.3. The app build includes the `MeloNXRamDonor.appex` extension and checks for it before packaging.

The temporary sync workflow is **Sync MeloNX 2.7 and build Candela**. Its artifact, if the build succeeds, is `Candela-2.7-unsigned-ipa`. A failed run has no installable artifact. Download successful artifacts from Actions and sign them with your sideloader. Do not treat an Actions success as device or performance verification.

## Credits and licenses

- [MeloNX](https://starforgejo.dev/projects/MeloNX): iOS platform, frontend, controller, RAM-offload and graphics work.
- Ryujinx and its contributors: emulation core.
- [MeloVertex](https://github.com/VertexSelection/MeloVertex): the fork Candela started from.
- Third-party notices remain in the source and distribution documentation.

This fork's [LICENSE.txt](LICENSE.txt) declares AGPLv3 or later. Upstream 2.7's README says GPLv3, while its actual LICENSE.txt contains the MIT license. Its original license text is preserved in `docs/upstream-2.7-LICENSE.txt` with integration notes. Do not describe Candela as MIT-only or replace upstream notices; clarification may be needed before redistribution.
