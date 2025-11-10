// This example demonstrates xev event loop concepts
// NOTE: This example requires libxev as a dependency
// Add to build.zig.zon:
// .dependencies = .{
//     .libxev = .{
//         .url = "https://github.com/mitchellh/libxev/archive/<commit>.tar.gz",
//         .hash = "<hash>",
//     },
// }
//
// To run standalone without xev, see the conceptual examples below

const std = @import("std");

// Conceptual demonstration of event loop patterns
// (does not require xev, shows the concepts)

const Event = union(enum) {
    timer: TimerEvent,
    signal: SignalEvent,
    io: IoEvent,

    const TimerEvent = struct {
        id: u32,
        deadline_ns: u64,
    };

    const SignalEvent = struct {
        signal: i32,
    };

    const IoEvent = struct {
        fd: i32,
        readable: bool,
        writable: bool,
    };
};

const EventLoop = struct {
    events: std.ArrayList(Event),
    running: bool,
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator) EventLoop {
        return .{
            .events = std.ArrayList(Event).init(allocator),
            .running = false,
            .allocator = allocator,
        };
    }

    fn deinit(self: *EventLoop) void {
        self.events.deinit();
    }

    fn addTimer(self: *EventLoop, id: u32, delay_ms: u64) !void {
        const deadline = std.time.nanoTimestamp() + (delay_ms * std.time.ns_per_ms);
        try self.events.append(.{
            .timer = .{
                .id = id,
                .deadline_ns = @intCast(deadline),
            },
        });
    }

    fn run(self: *EventLoop) void {
        self.running = true;

        std.debug.print("Event loop started\n", .{});

        while (self.running and self.events.items.len > 0) {
            // Process events
            var i: usize = 0;
            while (i < self.events.items.len) {
                const event = self.events.items[i];

                switch (event) {
                    .timer => |t| {
                        const now = std.time.nanoTimestamp();
                        if (now >= t.deadline_ns) {
                            std.debug.print("Timer {d} fired!\n", .{t.id});
                            _ = self.events.orderedRemove(i);
                            continue;
                        }
                    },
                    .signal => |s| {
                        std.debug.print("Signal {} received\n", .{s.signal});
                        _ = self.events.orderedRemove(i);
                        continue;
                    },
                    .io => |io| {
                        if (io.readable) {
                            std.debug.print("FD {} is readable\n", .{io.fd});
                        }
                        if (io.writable) {
                            std.debug.print("FD {} is writable\n", .{io.fd});
                        }
                        _ = self.events.orderedRemove(i);
                        continue;
                    },
                }

                i += 1;
            }

            // Small sleep to prevent busy-waiting
            std.Thread.sleep(1 * std.time.ns_per_ms);
        }

        std.debug.print("Event loop stopped\n", .{});
    }

    fn stop(self: *EventLoop) void {
        self.running = false;
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("=== Event Loop Concepts (Conceptual Demo) ===\n\n", .{});

    std.debug.print(
        \\NOTE: This is a simplified conceptual demo.
        \\For production use, install libxev: https://github.com/mitchellh/libxev
        \\
        \\
    , .{});

    // Example 1: Basic event loop pattern
    {
        std.debug.print("Example 1: Event loop with timers\n", .{});

        var loop = EventLoop.init(allocator);
        defer loop.deinit();

        // Schedule some timers
        try loop.addTimer(1, 100);  // 100ms
        try loop.addTimer(2, 200);  // 200ms
        try loop.addTimer(3, 50);   // 50ms (fires first)

        loop.run();

        std.debug.print("\n", .{});
    }

    // Example 2: Explain proactor pattern
    {
        std.debug.print("Example 2: Proactor Pattern Explained\n", .{});

        std.debug.print(
            \\Proactor Pattern (used by libxev):
            \\  1. Submit I/O operation to kernel (non-blocking)
            \\  2. Continue doing other work
            \\  3. Kernel completes I/O operation
            \\  4. Callback is invoked with *completed* operation
            \\
            \\Compare with Reactor Pattern:
            \\  1. Register interest in I/O readiness
            \\  2. Get notified when socket is *ready*
            \\  3. Perform I/O operation yourself
            \\
            \\Benefits of Proactor:
            \\  - Simpler code (kernel does the I/O)
            \\  - Better performance with io_uring (Linux)
            \\  - Completion-based is more intuitive
            \\
            \\
        , .{});
    }

    // Example 3: Real libxev pseudo-code
    {
        std.debug.print("Example 3: Conceptual libxev Usage\n", .{});

        std.debug.print(
            \\// Actual libxev code would look like:
            \\
            \\const xev = @import("xev");
            \\
            \\pub fn main() !void {{
            \\    var loop = try xev.Loop.init(.{{}});
            \\    defer loop.deinit();
            \\
            \\    // Create timer
            \\    const timer = try xev.Timer.init();
            \\    defer timer.deinit();
            \\
            \\    // Completion structure (holds state)
            \\    var completion: xev.Completion = .{{}};
            \\
            \\    // Run timer for 1000ms
            \\    timer.run(&loop, &completion, 1000, void, null, timerCallback);
            \\
            \\    // Run event loop until done
            \\    try loop.run(.until_done);
            \\}}
            \\
            \\fn timerCallback(
            \\    userdata: ?*void,
            \\    loop: *xev.Loop,
            \\    completion: *xev.Completion,
            \\    result: xev.Timer.RunError!void,
            \\) xev.CallbackAction {{
            \\    _ = userdata;
            \\    _ = loop;
            \\    _ = completion;
            \\    _ = result catch |err| {{
            \\        std.debug.print("Timer error: {{}}\n", .{{err}});
            \\        return .disarm;
            \\    }};
            \\
            \\    std.debug.print("Timer fired!\n", .{{}});
            \\    return .disarm; // Stop the timer
            \\}}
            \\
            \\
        , .{});
    }

    // Example 4: When to use event loops vs threads
    {
        std.debug.print("Example 4: Choosing Between Event Loops and Threads\n", .{});

        std.debug.print(
            \\Use Event Loops (xev) when:
            \\  ✓ I/O-bound workload (network, files)
            \\  ✓ Many concurrent connections (1000s+)
            \\  ✓ Low memory overhead needed
            \\  ✓ Operations are mostly waiting
            \\  Example: Web server, database client
            \\
            \\Use Threads when:
            \\  ✓ CPU-bound workload (computation)
            \\  ✓ Need true parallelism
            \\  ✓ Blocking operations unavoidable
            \\  ✓ Simpler mental model needed
            \\  Example: Image processing, data analysis
            \\
            \\Use Both when:
            \\  ✓ I/O + CPU mix (event loop for I/O, thread pool for CPU)
            \\  Example: HTTP server with image resizing
            \\
            \\
        , .{});
    }

    // Example 5: Event loop backends
    {
        std.debug.print("Example 5: libxev Backends\n", .{});

        std.debug.print(
            \\libxev automatically selects the best backend:
            \\
            \\Linux:
            \\  - io_uring (preferred) - Modern async I/O
            \\  - epoll (fallback) - Traditional event notification
            \\
            \\macOS:
            \\  - kqueue - BSD-style event notification
            \\
            \\Windows:
            \\  - IOCP (in development) - Windows Completion Ports
            \\
            \\WebAssembly:
            \\  - poll_oneoff - WASI async interface
            \\
            \\Zero-cost abstraction: Only used backends are compiled in!
            \\
            \\
        , .{});
    }

    // Example 6: Common pitfalls
    {
        std.debug.print("Example 6: Event Loop Anti-Patterns\n", .{});

        std.debug.print(
            \\❌ DON'T block the event loop thread:
            \\   timer.run(&loop, &c, 1000, void, null, badCallback);
            \\
            \\   fn badCallback(...) void {{
            \\       std.Thread.sleep(5 * std.time.ns_per_s); // ❌ Blocks loop!
            \\       expensive_computation(); // ❌ Blocks loop!
            \\   }}
            \\
            \\✓ DO offload CPU work to thread pool:
            \\   fn goodCallback(...) void {{
            \\       // Queue work to thread pool
            \\       thread_pool.spawn(expensive_computation, .{{}});
            \\   }}
            \\
            \\❌ DON'T mix blocking I/O with event loop:
            \\   const file = std.fs.cwd().openFile(...); // ❌ Blocking!
            \\   _ = file.read(buffer); // ❌ Blocks loop!
            \\
            \\✓ DO use async I/O operations:
            \\   const file = try xev.File.open(...);
            \\   file.read(&loop, &c, buffer, 0, void, null, readCallback);
            \\
            \\
        , .{});
    }

    std.debug.print("=== Event loop concepts demonstration completed ===\n", .{});
    std.debug.print("\nFor working xev examples, see Ghostty source code:\n", .{});
    std.debug.print("https://github.com/ghostty-org/ghostty\n", .{});
}
