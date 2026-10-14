// SPDX-License-Identifier: AGPL-3.0-or-later
// Keeps the emulator log small. Output is read from a pipe and written to the log file in two rotating segments,
// so a session never uses more than about twice the segment size on disk, however chatty it is.
import Foundation

enum CandelaLogCapture {
    static let segmentLimit = 6 * 1024 * 1024

    static func start(to url: URL) {
        FileManager.default.createFile(atPath: url.path, contents: nil)
        var fds: [Int32] = [0, 0]
        guard pipe(&fds) == 0 else {
            let fd = open(url.path, O_WRONLY | O_APPEND, 0o644)
            guard fd >= 0 else { return }
            dup2(fd, STDOUT_FILENO)
            dup2(fd, STDERR_FILENO)
            close(fd)
            return
        }
        let readFD = fds[0]
        dup2(fds[1], STDOUT_FILENO)
        dup2(fds[1], STDERR_FILENO)
        close(fds[1])

        let earlier = URL(fileURLWithPath: url.path + ".1")
        Thread.detachNewThread {
            var out = FileHandle(forWritingAtPath: url.path)
            var written = 0
            var buffer = [UInt8](repeating: 0, count: 64 * 1024)
            while true {
                let n = read(readFD, &buffer, buffer.count)
                if n < 0 && errno == EINTR { continue }
                if n <= 0 { break }
                out?.write(Data(buffer[0..<n]))
                written += n
                if written >= segmentLimit {
                    try? out?.close()
                    try? FileManager.default.removeItem(at: earlier)
                    try? FileManager.default.moveItem(at: url, to: earlier)
                    FileManager.default.createFile(atPath: url.path, contents: nil)
                    out = FileHandle(forWritingAtPath: url.path)
                    written = 0
                }
            }
            try? out?.close()
        }
    }
}
