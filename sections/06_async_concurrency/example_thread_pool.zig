const std = @import("std");

// Demonstrate thread pool pattern using std.Thread.Pool

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("=== Thread Pool Examples ===\n\n", .{});

    // Example 1: Basic thread pool usage
    {
        std.debug.print("Example 1: Basic thread pool with WaitGroup\n", .{});

        var pool: std.Thread.Pool = undefined;
        try pool.init(.{ .allocator = allocator });
        defer pool.deinit();

        var wait_group: std.Thread.WaitGroup = .{};

        // Task function
        const Task = struct {
            fn process(task_id: usize) void {
                std.debug.print("Task {d} running on thread\n", .{task_id});

                // Simulate work
                var sum: u64 = 0;
                for (0..1_000_000) |i| {
                    sum +%= i;
                }
                std.mem.doNotOptimizeAway(&sum);

                std.debug.print("Task {d} completed\n", .{task_id});
            }
        };

        // Spawn multiple tasks
        for (0..5) |i| {
            pool.spawnWg(&wait_group, Task.process, .{i});
        }

        // Wait for all tasks to complete
        pool.waitAndWork(&wait_group);

        std.debug.print("\n", .{});
    }

    // Example 2: Thread pool with shared state
    {
        std.debug.print("Example 2: Thread pool with synchronized counter\n", .{});

        var pool: std.Thread.Pool = undefined;
        try pool.init(.{ .allocator = allocator });
        defer pool.deinit();

        var wait_group: std.Thread.WaitGroup = .{};

        // Shared counter protected by atomic operations
        var counter = std.atomic.Value(u32).init(0);

        const Worker = struct {
            fn increment(c: *std.atomic.Value(u32), iterations: u32) void {
                for (0..iterations) |_| {
                    _ = c.fetchAdd(1, .monotonic);
                }
            }
        };

        // Spawn multiple workers
        const num_workers = 10;
        const increments_per_worker = 1000;

        for (0..num_workers) |_| {
            pool.spawnWg(&wait_group, Worker.increment, .{ &counter, increments_per_worker });
        }

        pool.waitAndWork(&wait_group);

        const final_count = counter.load(.monotonic);
        const expected = num_workers * increments_per_worker;

        std.debug.print("Final count: {d} (expected: {d})\n", .{ final_count, expected });
        if (final_count == expected) {
            std.debug.print("✓ All increments successful!\n\n", .{});
        }
    }

    // Example 3: Thread pool with results collection
    {
        std.debug.print("Example 3: Collecting results from pool tasks\n", .{});

        var pool: std.Thread.Pool = undefined;
        try pool.init(.{ .allocator = allocator });
        defer pool.deinit();

        var wait_group: std.Thread.WaitGroup = .{};

        // Shared results array with mutex protection
        var mutex: std.Thread.Mutex = .{};
        var results = try std.ArrayList(u64).initCapacity(allocator, 10);
        defer results.deinit(allocator);

        const ComputeTask = struct {
            fn compute(
                n: usize,
                m: *std.Thread.Mutex,
                r: *std.ArrayList(u64),
                alloc: std.mem.Allocator,
            ) void {
                // Compute factorial
                var result: u64 = 1;
                for (1..n + 1) |i| {
                    result *%= @as(u64, @intCast(i));
                }

                std.debug.print("Computed factorial({d}) = {d}\n", .{ n, result });

                // Store result safely
                m.lock();
                defer m.unlock();
                r.append(alloc, result) catch {};
            }
        };

        // Spawn tasks to compute factorials
        for (1..11) |n| {
            pool.spawnWg(&wait_group, ComputeTask.compute, .{ n, &mutex, &results, allocator });
        }

        pool.waitAndWork(&wait_group);

        std.debug.print("Collected {d} results\n\n", .{results.items.len});
    }

    // Example 4: CPU-bound vs I/O-bound tasks
    {
        std.debug.print("Example 4: Understanding thread pool sizing\n", .{});

        const cpu_count = try std.Thread.getCpuCount();
        std.debug.print("Available CPU cores: {d}\n", .{cpu_count});
        std.debug.print("Recommendation for CPU-bound tasks: {d} threads\n", .{cpu_count});
        std.debug.print("Recommendation for I/O-bound tasks: {d}-{d} threads\n\n", .{ cpu_count * 2, cpu_count * 4 });
    }

    // Example 5: Thread pool with custom configuration
    {
        std.debug.print("Example 5: Custom thread pool configuration\n", .{});

        const custom_thread_count = 4;

        var pool: std.Thread.Pool = undefined;
        try pool.init(.{
            .allocator = allocator,
            .n_jobs = custom_thread_count,
        });
        defer pool.deinit();

        std.debug.print("Created pool with {d} worker threads\n", .{custom_thread_count});

        var wait_group: std.Thread.WaitGroup = .{};

        const QuickTask = struct {
            fn run(task_id: usize) void {
                std.debug.print("Quick task {d} executed\n", .{task_id});
            }
        };

        // Spawn more tasks than workers
        for (0..20) |i| {
            pool.spawnWg(&wait_group, QuickTask.run, .{i});
        }

        pool.waitAndWork(&wait_group);

        std.debug.print("All tasks completed with {d} workers\n\n", .{custom_thread_count});
    }

    // Example 6: Work distribution demonstration
    {
        std.debug.print("Example 6: Visualizing work distribution\n", .{});

        var pool: std.Thread.Pool = undefined;
        try pool.init(.{ .allocator = allocator, .n_jobs = 2 });
        defer pool.deinit();

        var wait_group: std.Thread.WaitGroup = .{};

        // Track which thread executes each task
        var mutex: std.Thread.Mutex = .{};
        var thread_map = std.AutoHashMap(std.Thread.Id, usize).init(allocator);
        defer thread_map.deinit();

        const TrackedTask = struct {
            fn run(
                task_id: usize,
                m: *std.Thread.Mutex,
                map: *std.AutoHashMap(std.Thread.Id, usize),
            ) void {
                const thread_id = std.Thread.getCurrentId();

                m.lock();
                defer m.unlock();

                const entry = map.getOrPut(thread_id) catch return;
                if (!entry.found_existing) {
                    entry.value_ptr.* = 0;
                }
                entry.value_ptr.* += 1;

                std.debug.print("Task {d} on thread {any}\n", .{ task_id, thread_id });
            }
        };

        // Spawn tasks
        for (0..10) |i| {
            pool.spawnWg(&wait_group, TrackedTask.run, .{ i, &mutex, &thread_map });
        }

        pool.waitAndWork(&wait_group);

        // Show distribution
        std.debug.print("\nWork distribution:\n", .{});
        var iter = thread_map.iterator();
        while (iter.next()) |entry| {
            std.debug.print("  Thread {any}: {d} tasks\n", .{ entry.key_ptr.*, entry.value_ptr.* });
        }

        std.debug.print("\n", .{});
    }

    std.debug.print("=== All thread pool examples completed ===\n", .{});
}
