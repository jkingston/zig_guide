const std = @import("std");

const Database = struct {
    tables: std.ArrayList(Table),
    allocator: std.mem.Allocator,

    const Table = struct {
        name: []u8,
        rows: std.ArrayList([]u8),
    };

    pub fn init(allocator: std.mem.Allocator, table_names: []const []const u8) !Database {
        var tables = std.ArrayList(Table).empty;
        errdefer {
            // Clean up any successfully initialized tables on error
            for (tables.items) |*table| {
                for (table.rows.items) |row| {
                    allocator.free(row);
                }
                table.rows.deinit(allocator);
                allocator.free(table.name);
            }
            tables.deinit(allocator);
        }

        for (table_names) |name| {
            const table_name = try allocator.dupe(u8, name);
            errdefer allocator.free(table_name);  // If rows allocation fails

            var rows = std.ArrayList([]u8).empty;
            errdefer rows.deinit(allocator);  // If append to tables fails

            try tables.append(allocator, .{
                .name = table_name,
                .rows = rows,
            });
        }

        return .{
            .tables = tables,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Database) void {
        for (self.tables.items) |*table| {
            for (table.rows.items) |row| {
                self.allocator.free(row);
            }
            table.rows.deinit(self.allocator);
            self.allocator.free(table.name);
        }
        self.tables.deinit(self.allocator);
    }

    pub fn addRow(self: *Database, table_idx: usize, data: []const u8) !void {
        if (table_idx >= self.tables.items.len) return error.InvalidTable;

        const row = try self.allocator.dupe(u8, data);
        errdefer self.allocator.free(row);

        try self.tables.items[table_idx].rows.append(allocator, self.allocator, row);
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("=== Nested Container with errdefer ===\n", .{});

    // Success case
    const table_names = [_][]const u8{ "users", "products", "orders" };
    var db = try Database.init(allocator, &table_names);
    defer db.deinit(allocator);

    try db.addRow(0, "Alice");
    try db.addRow(0, "Bob");
    try db.addRow(1, "Widget");

    for (db.tables.items, 0..) |table, i| {
        std.debug.print("Table {s} has {} rows\n", .{ table.name, table.rows.items.len });
    }

    std.debug.print("\nDatabase cleaned up successfully\n", .{});
}
```
