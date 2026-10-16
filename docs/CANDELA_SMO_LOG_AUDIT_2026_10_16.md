# SMO performance audit — Apple A16 / Candela

Date of supplied device session: 2026-10-16 00:12–00:21.
Supplied log: `Super Mario Odyssey v1.0.0`, title ID `0100000000010000`, A16 GPU, MoltenVK 1.4.0, firmware 22.0.0.
This note references a USER-PASTED partial log; no crash is visible in that excerpt.

## What the captured telemetry shows

- Shader loading: **1,088 cached shaders**, `LoadShaders` begins ~1.82s into app emulation and completes ~25.9s elapsed. Startup involved repeated expensive ~373.68 MiB Vulkan worker pipeline-cache checkpoint messages.
- Guest RAM: 4,096 MiB mapped using the RAM donor extension. Mapping success does *not* mean all 4 GiB are physical RAM pages in use; do not automatically raise it.
- Vulkan texture compression: MoltenVK cannot directly handle BC compression; emulator reports **software decoding**.
- GPU cache: buffer cache 341 MiB and AutoDelete 512 MiB from a 4,096 MiB process budget.
- Pipeline cache: main budget 256 MiB, each of two worker budgets 384 MiB; a worker cache checkpointed repeatedly at ~373.68 MiB and eventually recycled at 386.45 MiB.
- Pipeline compilation: at ~07:52, 2,272 pipelines completed with **74 demanded by a draw**; by ~08:26, 2,307 completed with **82 demanded by a draw**. Worst individual compile reported ~5,162 ms. These can cause large transient frame stalls.
- GPU warning: recurrent `GPU processing thread is too slow, waiting on CPU`. This points to emulator GPU/CPU producer-consumer contention, *not* by itself a conclusive GPU-only bottleneck.
- MoltenVK warning: `VK_ERROR_FEATURE_NOT_PRESENT: Metal does not support disabling primitive restart` repeats frequently. Requires backend capability/state compatibility audit before changing primitive restart semantics.
- Display wait near zero: drawable wait mostly p50/p95 ~0ms. Display surface acquisition is not visibly the limiting stage.

### 30s window summary from excerpt

| Elapsed | Delivered frames per second | Frame p50 | Frame p95 | Frame p99 | Max |
| --- | ---: | ---: | ---: | ---: | ---: |
| 01:01 | 39.9 | 16.6ms | 18.2ms | 34.4ms | 547ms |
| 01:31 | 35.6 | 19.8ms | 47.4ms | 75.9ms | 1165ms |
| 02:01 | 39.6 | 23.8ms | 37.5ms | 47.4ms | 100ms |
| 03:01 | 45.9 | 17.1ms | 27.6ms | 37.2ms | 163ms |
| 03:31 | 57.6 | 16.7ms | 22.0ms | 34.5ms | 144ms |
| 04:01 | 55.6 | 16.8ms | 27.0ms | 40.7ms | 218ms |
| 06:01 | 33.5 | 25.3ms | 62.0ms | 87.8ms | 171ms |
| 08:36 | 34.6 | 24.5ms | 45.6ms | 83.8ms | 1842ms |

These averages are render-loop frame output, not necessarily in-game full-speed emulation. A screenshot FPS near 60 does not establish stable frame pacing.

## Safe, limited change in code

File: `src/Ryujinx.Graphics.Vulkan/PipelineCacheManager.cs`.

**Old:** When `EstimatedBytes >= Budget`, the `Maintain` method bypassed its normal 64-pipeline / 15s checkpoint cadence and measured/saved the worker cache for each new pipeline. In the log this appeared as hundreds of MiB checkpointed repeatedly only a few seconds apart.

**New:** Use a minimum **10-second** near-budget probe interval for non-forced cache operations, except when the estimated size is **64 MiB beyond budget** (emergency path). Normal below-budget scheduling and final forced saves are unchanged. Do not alter actual pipeline compilation, shader results, format capabilities, memory allocations or discard caches. A benchmark is required to establish whether reducing the costly checkpoint frequency improves a real scene.

## Risk and follow-up

- This is a bounded, scheduling-only performance change. It intentionally does **not** silently increase RAM/cache budgets; untested budget increases can cause iOS termination.
- Re-running the exact same ~8-minute Odyssey route before/after change on same iPhone, room temperature, battery and charging state will show whether p95, p99, stalls and cache checkpoints improve.
- The `VK_ERROR_FEATURE_NOT_PRESENT` message should be traced through MoltenVK's primitive-restart capability and the draw pipeline state path; do not suppress before understanding correctness.
- Inspect GPU synchronizations/fenceWaits/s and shader compiles per minute in heavy scenes, then consider targeted CPU/GPU decoupling changes in a separate experiment.
- Existing Odyssey handheld 0.85x preset is a starting point, not measured proof of best render scale. Try 0.75x and 1.0x separately with the same route; avoid declaring 60fps on every stage.
- Add local CSV frame-time sampling or comparable timed sessions before proposing deeper GPU changes. Avoid interpreting startup cache replay spikes as steady-state performance.
- Ensure no log dumps retain personal filesystem identifiers, usernames or save metadata when sharing publicly.

## Regression list

- Existing MoltenVK and native library compile.
- Title load, shader cache warm start, exiting normally, and restarting preserves pipeline snapshots.
- Neither RAM donor behavior nor storage paths change.
- No graphical regressions in Odyssey scenes that use primitive restart, depth attachment effects, BC texture paths or gamepad input.
- Verify no new background stalls, iOS jetsam/OOM, or corrupted cache snapshots.
- Build through existing GitHub Actions workflow with untouched signing, entitlements and project configuration.

Tomodachi Touch V2 is a separate control/UI feature and is not modified by the performance fix.

## Diagnostic-probe overhead improvement

Production Vulkan framebuffer, scissor and viewport draw paths now check `CandelaProbe.Enabled` *before* formatting diagnostic strings or updating concurrent dictionaries. The existing `[Candela][probe]` capture is off by default; developers may opt in with the `CANDELA_GPU_PROBES=1` process environment variable. This doesn't disable the `[Candela][frames]`, `[Candela][bound]` and pipeline-compilation telemetry used for performance comparisons, and it makes no renderer correctness or MoltenVK capability changes.
