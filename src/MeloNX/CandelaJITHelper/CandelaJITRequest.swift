// SPDX-License-Identifier: GPL-3.0-or-later
// Structure adapted from willfaust/Madeira (GPL-3.0-or-later, Dan Perks). Candela is AGPLv3-or-later.
// Shared by the Candela app target and the CandelaJITHelper extension (a copy lives in each folder).
import Foundation

nonisolated struct CandelaJITRequest: Codable {
    enum Operation: String, Codable { case prepare, enable, resetDDI }

    static let itemKey = "candela.jit.request"

    var operation: Operation
    var pairingData: Data?      // sent in memory, never logged
    var targetPID: Int32?       // the Candela process
    var scriptBase64: String?   // nil means StikJIT's universal script

    struct Response: Codable {
        static let itemKey = "candela.jit.response"
        var success: Bool
        var message: String
        var txmPresent: Bool?
    }
}
