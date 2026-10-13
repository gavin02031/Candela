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

        // Shared: cache compiled shaders and use macro HLE to cut CPU/GPU work.
        tuned.disableShaderCache = false
        tuned.disableMacroHLE = false
        // Handheld mode renders at a much lower resolution than docked.
        tuned.disableDockedMode = true

        if isTotK {
            // Heaviest of the three: render at most 0.75x.
            tuned.resScale = min(tuned.resScale, 0.75)
        } else if isOdyssey {
            tuned.resScale = min(tuned.resScale, 1.0)
        } else if isTomodachi {
            // The fork README says this fixes crashes for Tomodachi Life.
            tuned.ignoreMissingServices = true
        }

        return tuned
    }
}
