# MeloNX 2.7 integration

Upstream: https://starforgejo.dev/projects/MeloNX, tag 2.7, source commit 13700519f3abc4e6d7ed8a065b118b2cc59bcd67.

The fork source matched upstream 2.3 (c2924ca27), apart from five LFS-materialized libraries, Git attributes and personal workspace state. Upstream rewrote Git history, so this integration uses a source snapshot rather than a misleading behind count. Releases 2.3.1, 2.4, 2.5, 2.6 and 2.7 were missing.

Candela's home views use upstream GameInfo and RyujinxController now. Presets use Options value copies and never override saved per-game settings. The beta home stays off by default. The install bundle ID remains com.vertexselection.MeloVertex; the RAM extension shares its prefix. All upstream 2.7 RAM, GPU, controller and AirPlay implementations are retained.

Build uses .NET 10 Ryujinx.Library and Xcode 26.3, and packages the RAM-donor extension inside the app. This has not been tested on a physical device. RAM donor uses private NSExtension APIs upstream; its sideloading behavior, entitlement needs and OS compatibility must be tested rather than assumed.

License caveat: the fork LICENSE.txt declares AGPLv3. Upstream 2.7 README declares GPLv3 but its LICENSE.txt contains MIT. Both original license files are preserved, upstream's at docs/upstream-2.7-LICENSE.txt. Do not describe this combined fork as MIT-only. Upstream attribution remains in source. Clarification from upstream may be needed for distribution.

The iOS27 scene accessory requires its SDK. Builds below SDK27 retain its source but compile it out using CANDELA_IOS27_AIRPLAY. Do not claim iOS27 AirPlay registration in these interim builds.
LibHac alpha.129 rebuilt from 23e402ebb6dedc517e34a98a033078dc0f6fd478; official MeloNX 2.7 dylib embedded version confirms this source.
