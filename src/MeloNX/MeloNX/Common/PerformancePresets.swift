//
//  PerformancePresets.swift
//  MeloNX
//
//  Built-in starting settings for a few demanding titles on iPhone-class hardware.
//  Used only when the user has NOT saved per-game settings for that title.
//  UNTESTED: these are starting points, not measured results.
//

import Foundation

enum PerformancePresets {
    /// Returns a tuned copy of `base` for known titles, or nil when no preset applies.
    /// Always works on a copy so the user's global settings object is never modified.
    static func config(for game: GameInfo, base: Options) -> Options? {
        let name = game.titleName.lowercased()

        let isTotK = name.contains("tears of the kingdom")
        let isOdyssey = name.contains("super mario odyssey")
        let isTomodachi = name.contains("tomodachi life")

        guard isTotK || isOdyssey || isTomodachi else { return nil }

        var tuned = base

        // Shared: cache compiled shaders, build shaders on a background thread, and use
        // macro HLE to cut CPU/GPU work. Stub logging is off: it spams and costs CPU.
        tuned.disableShaderCache = false
        tuned.enableAsyncShaderCompilation = true
        tuned.disableMacroHLE = false
        tuned.loggingDisableStub = true
        // Handheld mode renders at a much lower resolution than docked.
        tuned.disableDockedMode = true

        if isTotK {
            // Heaviest of the three: render at most 0.75x.
            tuned.resScale = min(tuned.resScale, 0.75)
        } else if isOdyssey {
            // Device logs show the GPU thread is the limiter in busy scenes.
            tuned.resScale = min(tuned.resScale, 0.85)
        } else if isTomodachi {
            // The fork README says this fixes crashes for Tomodachi Life.
            tuned.ignoreMissingServices = true
        }

        return tuned
    }
}
