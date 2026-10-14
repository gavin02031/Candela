// SPDX-License-Identifier: AGPL-3.0-or-later
using Ryujinx.Common.Logging;
using System.Collections.Concurrent;
using System.Threading;

namespace Ryujinx.Graphics.Vulkan
{
    /// <summary>
    /// Log-only probe for size mismatches. Writes a line only when the value for a key changes,
    /// and stops after a fixed number of lines so it can never flood the log.
    /// </summary>
    static class CandelaProbe
    {
        private const int MaxLines = 300;
        private static readonly ConcurrentDictionary<string, string> _last = new();
        private static int _lines;
        private static readonly ConcurrentDictionary<string, int> _perKey = new();

        public static void Note(string key, string value)
        {
            if (_lines >= MaxLines)
            {
                return;
            }

            string previous = _last.AddOrUpdate(key, value, (_, _) => value);

            if (previous == value && _last[key] == value && _seen.ContainsKey(key + value))
            {
                return;
            }

            if (_perKey.AddOrUpdate(key, 1, (_, n) => n + 1) > 80)
            {
                return;
            }

            _seen[key + value] = true;

            if (Interlocked.Increment(ref _lines) <= MaxLines)
            {
                Logger.Notice.PrintMsg(LogClass.Gpu, $"[Candela][probe] {key}: {value}");
            }
        }

        private static readonly ConcurrentDictionary<string, bool> _seen = new();
    }
}
