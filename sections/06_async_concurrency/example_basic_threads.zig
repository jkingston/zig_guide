const std = @import("std");

// Demonstrate basic thread creation, data passing, and joining

fn workerThread(id: u32, iterations: u32) void {
    std.debug.print("Worker {d} starting...\n", .{id});

    // Simulate some work
    var sum: u64 = 0;
    for (0..iterations) |i| {
        sum += i;
    }

    std.debug.print("Worker {d} completed. Sum: {d}\n", .{ id, sum });
}

// Struct to pass multiple values to a thread
const WorkerData = struct {
    id: u32,
    message: []const u8,
    result: *u32, // Shared result (needs synchronization if accessed concurrently)

    fn run(self: WorkerData) void {
        std.debug.print("Worker {d}: {s}\n", .{ self.id, self.message });

        // Simulate computation
        std.Thread.sleep(100 * std.time.ns_per_ms);

        // Store result (this example runs one thread at a time, so no race)
        self.result.* = self.id * 10;

        std.debug.print("Worker {d} finished, result: {d}\n", .{ self.id, self.result.* });
    }
};

pub fn main() !void {
    std.debug.print("=== Basic Threading Examples ===\n\n", .{});

    // Example 1: Simple thread with function arguments
    {
        std.debug.print("Example 1: Simple thread creation\n", .{});

        const thread = try std.Thread.spawn(.{}, workerThread, .{ 1, 1000 });
        thread.join(); // Wait for thread to complete

        std.debug.print("\n", .{});
    }

    // Example 2: Multiple threads
    {
        std.debug.print("Example 2: Multiple threads\n", .{});

        var threads: [3]std.Thread = undefined;

        // Spawn multiple worker threads
        for (&threads, 0..) |*thread, i| {
            thread.* = try std.Thread.spawn(.{}, workerThread, .{ @as(u32, @intCast(i)), 500 });
        }

        // Join all threads
        for (threads) |thread| {
            thread.join();
        }

        std.debug.print("\n", .{});
    }

    // Example 3: Passing structured data
    {
        std.debug.print("Example 3: Passing structured data\n", .{});

        var result: u32 = 0;
        const data = WorkerData{
            .id = 42,
            .message = "Hello from structured data",
            .result = &result,
        };

        const thread = try std.Thread.spawn(.{}, WorkerData.run, .{data});
        thread.join();

        std.debug.print("Final result: {d}\n\n", .{result});
    }

    // Example 4: Thread configuration
    {
        std.debug.print("Example 4: Thread with custom stack size\n", .{});

        const config = std.Thread.SpawnConfig{
            .stack_size = 2 * 1024 * 1024, // 2 MiB stack
        };

        const thread = try std.Thread.spawn(config, workerThread, .{ 99, 100 });
        thread.join();

        std.debug.print("\n", .{});
    }

    // Example 5: Thread detachment
    {
        std.debug.print("Example 5: Detached thread (fire and forget)\n", .{});
        std.debug.print("Note: Detached threads clean up automatically\n", .{});

        const thread = try std.Thread.spawn(.{}, workerThread, .{ 777, 50 });
        thread.detach(); // Don't wait for completion, thread cleans up itself

        // Give detached thread time to run before main exits
        std.Thread.sleep(200 * std.time.ns_per_ms);

        std.debug.print("\n", .{});
    }

    // Example 6: Thread yielding
    {
        std.debug.print("Example 6: Cooperative threading with yield\n", .{});

        const CooperativeWorker = struct {
            fn run(worker_id: u32) void {
                for (0..3) |i| {
                    std.debug.print("Worker {d} iteration {d}\n", .{ worker_id, i });
                    // Yield to allow other threads to run
                    std.Thread.yield() catch {};
                }
            }
        };

        const t1 = try std.Thread.spawn(.{}, CooperativeWorker.run, .{1});
        const t2 = try std.Thread.spawn(.{}, CooperativeWorker.run, .{2});

        t1.join();
        t2.join();

        std.debug.print("\n", .{});
    }

    // Example 7: Getting thread information
    {
        std.debug.print("Example 7: Thread information\n", .{});

        const thread_id = std.Thread.getCurrentId();
        std.debug.print("Main thread ID: {any}\n", .{thread_id});

        const cpu_count = try std.Thread.getCpuCount();
        std.debug.print("Available CPU cores: {d}\n", .{cpu_count});

        std.debug.print("\n", .{});
    }

    std.debug.print("=== All examples completed ===\n", .{});
}
