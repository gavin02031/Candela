// SPDX-License-Identifier: AGPL-3.0-or-later
using Ryujinx.Common.Logging;
using System;
using System.Diagnostics;

namespace Ryujinx.Graphics.Vulkan
{
    /// <summary>
    /// Log-only frame pacing numbers. Called once per presented frame from the render thread.
    /// Every 30 seconds it writes frame time p50/p95/p99, the slowest frame, and how long the
    /// swapchain acquire blocked (drawable wait), then starts over. It changes no behaviour.
    /// </summary>
    static class FrameStats
    {
        private const int MaxSamples = 4096;
        private static readonly float[] _frames = new float[MaxSamples];
        private static readonly float[] _waits = new float[MaxSamples];
        private static int _count;
        private static long _last;
        private static long _windowStart = Stopwatch.GetTimestamp();
        private static long _acquireStart;
        private static int _over33;
        private static int _over50;

        public static void BeginAcquire() => _acquireStart = Stopwatch.GetTimestamp();

        public static void EndAcquire()
        {
            // Wait is stored by the frame that follows; keep the latest value.
            _pendingWait = (float)((Stopwatch.GetTimestamp() - _acquireStart) * 1000.0 / Stopwatch.Frequency);
        }

        private static float _pendingWait;

        public static void FramePresented()
        {
            long now = Stopwatch.GetTimestamp();

            if (_last != 0)
            {
                float ms = (float)((now - _last) * 1000.0 / Stopwatch.Frequency);

                // Ignore pauses and menus: anything over two seconds is not a frame.
                if (ms < 2000f && _count < MaxSamples)
                {
                    _frames[_count] = ms;
                    _waits[_count] = _pendingWait;
                    _count++;

                    if (ms > 33.4f)
                    {
                        _over33++;
                    }

                    if (ms > 50f)
                    {
                        _over50++;
                    }
                }
            }

            _last = now;

            if (now - _windowStart >= Stopwatch.Frequency * 30)
            {
                Flush(now);
            }
        }

        private static float Percentile(float[] sorted, int n, double p)
        {
            return n == 0 ? 0 : sorted[Math.Min(n - 1, (int)(n * p))];
        }

        private static void Flush(long now)
        {
            int n = _count;

            if (n >= 10)
            {
                float[] f = new float[n];
                float[] w = new float[n];
                Array.Copy(_frames, f, n);
                Array.Copy(_waits, w, n);
                Array.Sort(f);
                Array.Sort(w);

                double secs = (now - _windowStart) / (double)Stopwatch.Frequency;

                Logger.Notice.PrintMsg(LogClass.Gpu,
                    $"[Candela][frames] {n} frames in {secs:F0}s ({n / secs:F1}/s), " +
                    $"frame ms p50 {Percentile(f, n, 0.50):F1} p95 {Percentile(f, n, 0.95):F1} p99 {Percentile(f, n, 0.99):F1} max {f[n - 1]:F0}, " +
                    $"over 33ms: {_over33}, over 50ms: {_over50}, " +
                    $"drawable wait ms p50 {Percentile(w, n, 0.50):F1} p95 {Percentile(w, n, 0.95):F1} max {w[n - 1]:F1}");
            }

            _count = 0;
            _over33 = 0;
            _over50 = 0;
            _windowStart = now;
        }
    }
}
