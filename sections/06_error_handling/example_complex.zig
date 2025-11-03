const std = @import("std");

// Complex scenario: File processing with multiple error points
const FileProcessor = struct {
    allocator: std.mem.Allocator,
    buffer: []u8,
    metadata: Metadata,

    const Metadata = struct {
        size: usize,
        checksum: u32,
    };

    const Error = error{
        FileTooLarge,
        CorruptedData,
        ProcessingFailed,
    };

    fn init(allocator: std.mem.Allocator, size: usize) !FileProcessor {
        if (size > 1024 * 1024) {
            return error.FileTooLarge;
        }

        var buffer = try allocator.alloc(u8, size);
        errdefer allocator.free(buffer);

        // Simulate initialization that could fail
        const metadata = Metadata{
            .size = size,
            .checksum = 0,
        };

        return FileProcessor{
            .allocator = allocator,
            .buffer = buffer,
            .metadata = metadata,
        };
    }

    fn deinit(self: *FileProcessor) void {
        self.allocator.free(self.buffer);
    }

    fn process(self: *FileProcessor, data: []const u8) !void {
        if (data.len > self.buffer.len) {
            return error.ProcessingFailed;
        }

        @memcpy(self.buffer[0..data.len], data);
        self.metadata.size = data.len;

        // Calculate checksum
        var sum: u32 = 0;
        for (data) |byte| {
            sum +%= byte;
        }
        self.metadata.checksum = sum;
    }

    fn validate(self: *const FileProcessor) !void {
        if (self.metadata.checksum == 0 and self.metadata.size > 0) {
            return error.CorruptedData;
        }
    }
};

// Nested error handling with multiple resources
fn processMultipleFiles(allocator: std.mem.Allocator, count: usize) !void {
    std.debug.print("\n=== Processing {d} Files ===\n", .{count});

    var processors = std.ArrayList(FileProcessor).init(allocator);
    defer {
        for (processors.items) |*proc| {
            proc.deinit();
        }
        processors.deinit();
    }

    for (0..count) |i| {
        const size = (i + 1) * 100;
        var processor = try FileProcessor.init(allocator, size);
        errdefer processor.deinit(); // Clean up if append fails

        try processors.append(processor);

        // Process some data
        var data: [50]u8 = undefined;
        @memset(&data, @intCast(i));
        try processors.items[i].process(&data);

        std.debug.print("Processed file {d}: {d} bytes, checksum={d}\n", .{
            i,
            processors.items[i].metadata.size,
            processors.items[i].metadata.checksum,
        });
    }

    // Validate all processors
    for (processors.items, 0..) |*proc, i| {
        try proc.validate();
        std.debug.print("File {d} validated successfully\n", .{i});
    }
}

// Transaction-like pattern with rollback
const Transaction = struct {
    allocator: std.mem.Allocator,
    operations: std.ArrayList(Operation),
    committed: bool,

    const Operation = struct {
        id: u32,
        data: []u8,
    };

    fn init(allocator: std.mem.Allocator) Transaction {
        return Transaction{
            .allocator = allocator,
            .operations = std.ArrayList(Operation).init(allocator),
            .committed = false,
        };
    }

    fn deinit(self: *Transaction) void {
        if (!self.committed) {
            // Rollback - free all operations
            std.debug.print("Rolling back {d} operations\n", .{self.operations.items.len});
            for (self.operations.items) |op| {
                self.allocator.free(op.data);
            }
        }
        self.operations.deinit();
    }

    fn addOperation(self: *Transaction, id: u32, size: usize) !void {
        const data = try self.allocator.alloc(u8, size);
        errdefer self.allocator.free(data);

        const op = Operation{ .id = id, .data = data };
        try self.operations.append(op);

        std.debug.print("Added operation {d} with {d} bytes\n", .{ id, size });
    }

    fn commit(self: *Transaction) !void {
        // Validate all operations before commit
        for (self.operations.items) |op| {
            if (op.data.len == 0) {
                return error.InvalidOperation;
            }
        }

        self.committed = true;
        std.debug.print("Transaction committed with {d} operations\n", .{self.operations.items.len});

        // Caller is now responsible for cleanup
        for (self.operations.items) |op| {
            self.allocator.free(op.data);
        }
        self.operations.clearRetainingCapacity();
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Test file processor
    {
        var processor = try FileProcessor.init(allocator, 256);
        defer processor.deinit();

        const data = "Hello, error handling!";
        try processor.process(data);
        try processor.validate();

        std.debug.print("Single file processed successfully\n", .{});
    }

    // Test multiple files with cleanup
    try processMultipleFiles(allocator, 3);

    // Test transaction with successful commit
    std.debug.print("\n=== Successful Transaction ===\n", .{});
    {
        var tx = Transaction.init(allocator);
        defer tx.deinit();

        try tx.addOperation(1, 100);
        try tx.addOperation(2, 200);
        try tx.addOperation(3, 300);

        try tx.commit();
    }

    // Test transaction with rollback
    std.debug.print("\n=== Failed Transaction (Rollback) ===\n", .{});
    {
        var tx = Transaction.init(allocator);
        defer tx.deinit(); // Will trigger rollback

        try tx.addOperation(10, 100);
        try tx.addOperation(11, 200);

        // Simulate failure - don't commit
        std.debug.print("Simulating failure before commit\n", .{});
        // tx.deinit() will rollback
    }

    // Test error path with processor
    std.debug.print("\n=== Error Handling Test ===\n", .{});
    {
        _ = FileProcessor.init(allocator, 2 * 1024 * 1024) catch |err| {
            std.debug.print("Expected error for large file: {s}\n", .{@errorName(err)});
        };
    }
}
