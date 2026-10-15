// SPDX-License-Identifier: AGPL-3.0-or-later
using System.Threading;

namespace Ryujinx.Graphics.GAL
{
    /// <summary>
    /// Cumulative timers (Stopwatch ticks) used only by the log-only frame report. They change no behaviour.
    /// RenderIdle: the render thread waiting for the GPU thread to hand it work (the game side is the bottleneck).
    /// FenceWait: threads blocked waiting for the GPU to finish earlier work (the GPU side is the bottleneck).
    /// Submit: time inside the queue submit call, including waiting for the queue lock.
    /// </summary>
    public static class CandelaPerf
    {
        public static long RenderIdleTicks;
        public static long FenceWaitTicks;
        public static long FenceWaitCount;
        public static long SubmitTicks;

        public static void AddRenderIdle(long ticks) => Interlocked.Add(ref RenderIdleTicks, ticks);

        public static void AddFenceWait(long ticks)
        {
            Interlocked.Add(ref FenceWaitTicks, ticks);
            Interlocked.Increment(ref FenceWaitCount);
        }

        public static void AddSubmit(long ticks) => Interlocked.Add(ref SubmitTicks, ticks);
    }
}
