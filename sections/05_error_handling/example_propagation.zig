const std = @import("std");

const DatabaseError = error{
    ConnectionFailed,
    QueryFailed,
    Timeout,
};

const ValidationError = error{
    InvalidInput,
    MissingField,
};

// Simple propagation with try
fn queryDatabase(id: u32) DatabaseError![]const u8 {
    if (id == 0) {
        return error.InvalidInput;
    }
    if (id > 1000) {
        return error.QueryFailed;
    }
    return "result";
}

// Propagating with context
fn getUserData(user_id: u32) ![]const u8 {
    // try propagates the error directly
    const data = try queryDatabase(user_id);
    return data;
}

// Catching and re-wrapping errors with context
fn validateAndQuery(input: ?u32) ![]const u8 {
    const id = input orelse {
        std.debug.print("Validation failed: missing user ID\n", .{});
        return error.MissingField;
    };

    const result = queryDatabase(id) catch |err| {
        // Log error with context before propagating
        std.debug.print("Database query failed for user {d}: {s}\n", .{ id, @errorName(err) });
        return err;
    };

    return result;
}

// Switch on error type for specific handling
fn processRequest(user_id: u32) !void {
    const data = queryDatabase(user_id) catch |err| switch (err) {
        error.ConnectionFailed => {
            std.debug.print("Retrying after connection failure...\n", .{});
            // Could implement retry logic here
            return err;
        },
        error.Timeout => {
            std.debug.print("Request timed out, will retry later\n", .{});
            return err;
        },
        error.QueryFailed => {
            std.debug.print("Query failed, using cached data\n", .{});
            // Return cached data instead of propagating error
            return;
        },
        else => return err,
    };

    std.debug.print("Received data: {s}\n", .{data});
}

// Multi-step error propagation with cleanup
fn complexOperation(allocator: std.mem.Allocator, id: u32) !void {
    std.debug.print("\n=== Complex Operation for ID {d} ===\n", .{id});

    // Step 1: Query database
    const data = try queryDatabase(id);
    std.debug.print("Step 1: Retrieved data\n", .{});

    // Step 2: Allocate buffer
    var buffer = try allocator.alloc(u8, data.len);
    errdefer allocator.free(buffer); // Cleanup on subsequent errors
    defer allocator.free(buffer); // Always cleanup on success
    std.debug.print("Step 2: Allocated buffer\n", .{});

    // Step 3: Process data (could fail)
    @memcpy(buffer, data);
    std.debug.print("Step 3: Processed data successfully\n", .{});
}

// Accumulating errors vs fail-fast
fn tryMultipleOperations(ids: []const u32) !u32 {
    var success_count: u32 = 0;
    var first_error: ?anyerror = null;

    for (ids) |id| {
        queryDatabase(id) catch |err| {
            // Capture first error but continue processing
            if (first_error == null) {
                first_error = err;
            }
            std.debug.print("Failed for ID {d}: {s}\n", .{ id, @errorName(err) });
            continue;
        };
        success_count += 1;
    }

    // Return first error if any occurred
    if (first_error) |err| {
        std.debug.print("Operations completed with errors. Success: {d}/{d}\n", .{ success_count, ids.len });
        return err;
    }

    std.debug.print("All operations successful\n", .{});
    return success_count;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Simple propagation
    std.debug.print("=== Simple Propagation ===\n", .{});
    {
        const data = try getUserData(100);
        std.debug.print("Retrieved: {s}\n", .{data});
    }

    // Validation and error context
    std.debug.print("\n=== Validation and Context ===\n", .{});
    {
        _ = validateAndQuery(null) catch |err| {
            std.debug.print("Caught: {s}\n", .{@errorName(err)});
        };

        _ = validateAndQuery(2000) catch |err| {
            std.debug.print("Caught: {s}\n", .{@errorName(err)});
        };
    }

    // Error-specific handling
    std.debug.print("\n=== Error-Specific Handling ===\n", .{});
    {
        try processRequest(500);
        try processRequest(1500); // Will use cached data
    }

    // Complex operation with cleanup
    try complexOperation(allocator, 42);

    // Multiple operations with error accumulation
    std.debug.print("\n=== Multiple Operations ===\n", .{});
    {
        const ids = [_]u32{ 10, 0, 50, 2000, 100 };
        _ = tryMultipleOperations(&ids) catch |err| {
            std.debug.print("Final error: {s}\n", .{@errorName(err)});
        };
    }
}
