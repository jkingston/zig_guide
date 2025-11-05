const std = @import("std");

// Import SQLite3 C library
const c = @cImport({
    @cInclude("sqlite3.h");
});

pub fn main() !void {
    std.debug.print("=== SQLite3 Interoperability Demo ===\n\n", .{});

    // Open an in-memory database
    var db: ?*c.sqlite3 = null;
    const rc_open = c.sqlite3_open(":memory:", &db);
    if (rc_open != c.SQLITE_OK) {
        std.debug.print("Failed to open database: {s}\n", .{c.sqlite3_errmsg(db)});
        return error.DatabaseError;
    }
    defer {
        _ = c.sqlite3_close(db);
        std.debug.print("\nDatabase closed successfully\n", .{});
    }

    std.debug.print("Opened in-memory SQLite database\n", .{});
    std.debug.print("SQLite version: {s}\n\n", .{c.sqlite3_libversion()});

    // Create a table
    const create_table_sql =
        \\CREATE TABLE users (
        \\  id INTEGER PRIMARY KEY,
        \\  name TEXT NOT NULL,
        \\  age INTEGER
        \\);
    ;

    var err_msg: [*c]u8 = null;
    const rc_create = c.sqlite3_exec(db, create_table_sql, null, null, &err_msg);
    if (rc_create != c.SQLITE_OK) {
        std.debug.print("SQL error: {s}\n", .{err_msg});
        c.sqlite3_free(err_msg);
        return error.SqlError;
    }
    std.debug.print("Table created successfully\n", .{});

    // Insert data using prepared statements
    const insert_sql = "INSERT INTO users (name, age) VALUES (?, ?)";
    var stmt: ?*c.sqlite3_stmt = null;

    const rc_prepare = c.sqlite3_prepare_v2(db, insert_sql, -1, &stmt, null);
    if (rc_prepare != c.SQLITE_OK) {
        std.debug.print("Failed to prepare statement: {s}\n", .{c.sqlite3_errmsg(db)});
        return error.PrepareError;
    }
    defer _ = c.sqlite3_finalize(stmt);

    // Insert first user
    _ = c.sqlite3_bind_text(stmt, 1, "Alice", -1, c.SQLITE_TRANSIENT);
    _ = c.sqlite3_bind_int(stmt, 2, 30);

    const rc_insert1 = c.sqlite3_step(stmt);
    if (rc_insert1 != c.SQLITE_DONE) {
        std.debug.print("Failed to insert data\n", .{});
        return error.InsertError;
    }
    std.debug.print("Inserted: Alice, age 30\n", .{});

    // Reset and insert second user
    _ = c.sqlite3_reset(stmt);
    _ = c.sqlite3_bind_text(stmt, 1, "Bob", -1, c.SQLITE_TRANSIENT);
    _ = c.sqlite3_bind_int(stmt, 2, 25);

    const rc_insert2 = c.sqlite3_step(stmt);
    if (rc_insert2 != c.SQLITE_DONE) {
        std.debug.print("Failed to insert data\n", .{});
        return error.InsertError;
    }
    std.debug.print("Inserted: Bob, age 25\n\n", .{});

    // Query data
    const select_sql = "SELECT id, name, age FROM users ORDER BY id";
    var query_stmt: ?*c.sqlite3_stmt = null;

    const rc_query = c.sqlite3_prepare_v2(db, select_sql, -1, &query_stmt, null);
    if (rc_query != c.SQLITE_OK) {
        std.debug.print("Failed to prepare query: {s}\n", .{c.sqlite3_errmsg(db)});
        return error.QueryError;
    }
    defer _ = c.sqlite3_finalize(query_stmt);

    std.debug.print("Query results:\n", .{});
    while (c.sqlite3_step(query_stmt) == c.SQLITE_ROW) {
        const id = c.sqlite3_column_int(query_stmt, 0);
        const name = c.sqlite3_column_text(query_stmt, 1);
        const age = c.sqlite3_column_int(query_stmt, 2);

        std.debug.print("  ID: {d}, Name: {s}, Age: {d}\n", .{ id, name, age });
    }

    std.debug.print("\n=== Demo Complete ===\n", .{});
}
