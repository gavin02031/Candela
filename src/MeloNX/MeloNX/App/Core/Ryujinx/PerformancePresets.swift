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
    static func config(for game: Game, base: Ryujinx.Arguments) -> Ryujinx.Arguments? {
        let name = game.titleName.lowercased()

        let isTotK = name.contains("tears of the kingdom")
        let isOdyssey = name.contains("super mario odyssey")
        let isTomodachi = name.contains("tomodachi life")

        guard isTotK || isOdyssey || isTomodachi else { return nil }

        guard let data = try? JSONEncoder().encode(base),
              let tuned = try? JSONDecoder().decode(Ryujinx.Arguments.self, from: data) else {
            return nil
        }

        // Shared: cache compiled shaders and use macro HLE to cut CPU/GPU work.
        tuned.enableShaderCache = true
        tuned.macroHLE = true
        // Handheld mode renders at a much lower resolution than docked.
        tuned.enableDockedMode = false

        if isTotK {
            // Heaviest of the three: render at most 0.75x.
            tuned.resscale = min(tuned.resscale, 0.75)
        } else if isOdyssey {
            tuned.resscale = min(tuned.resscale, 1.0)
        } else if isTomodachi {
            // The fork README says this fixes crashes for Tomodachi Life.
            tuned.ignoreMissingServices = true
        }

        return tuned
    }
}
