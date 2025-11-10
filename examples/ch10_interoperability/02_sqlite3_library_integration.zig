// Example 2: SQLite3 Library Integration
// 11 Interoperability
//
// Extracted from chapter content.md

const std = @import("std");

// Mock SQLite3 functions for demonstration (real version would use @cImport with sqlite3.h)
const c = struct {
    pub const sqlite3 = opaque {};
    pub const sqlite3_stmt = opaque {};

    pub const SQLITE_OK = 0;
    pub const SQLITE_TRANSIENT = @as(?*const fn (?*anyopaque) void, @ptrFromInt(@as(usize, @bitCast(@as(isize, -1)))));

    pub fn sqlite3_open(filename: [*:0]const u8, ppDb: *?*sqlite3) i32 {
        _ = filename;
        ppDb.* = @ptrFromInt(0x1000); // Mock handle
        return SQLITE_OK;
    }

    pub fn sqlite3_close(db: ?*sqlite3) i32 {
        _ = db;
        return SQLITE_OK;
    }

    pub fn sqlite3_errmsg(db: ?*sqlite3) [*:0]const u8 {
        _ = db;
        return "Mock error message";
    }

    pub fn sqlite3_exec(
        db: ?*sqlite3,
        sql: [*:0]const u8,
        callback: ?*const anyopaque,
        arg: ?*anyopaque,
        errmsg: *[*c]u8,
    ) i32 {
        _ = db;
        _ = sql;
        _ = callback;
        _ = arg;
        errmsg.* = null;
        return SQLITE_OK;
    }

    pub fn sqlite3_free(ptr: [*c]u8) void {
        _ = ptr;
    }

    pub fn sqlite3_prepare_v2(
        db: ?*sqlite3,
        sql: [*:0]const u8,
        nByte: c_int,
        ppStmt: *?*sqlite3_stmt,
        pzTail: ?*[*:0]const u8,
    ) i32 {
        _ = db;
        _ = sql;
        _ = nByte;
        _ = pzTail;
        ppStmt.* = @ptrFromInt(0x2000); // Mock statement handle
        return SQLITE_OK;
    }

    pub fn sqlite3_bind_text(
        stmt: ?*sqlite3_stmt,
        idx: c_int,
        text: [*:0]const u8,
        n: c_int,
        destructor: ?*const fn (?*anyopaque) void,
    ) i32 {
        _ = stmt;
        _ = idx;
        _ = text;
        _ = n;
        _ = destructor;
        return SQLITE_OK;
    }

    pub fn sqlite3_bind_int(stmt: ?*sqlite3_stmt, idx: c_int, value: c_int) i32 {
        _ = stmt;
        _ = idx;
        _ = value;
        return SQLITE_OK;
    }

    pub fn sqlite3_step(stmt: ?*sqlite3_stmt) i32 {
        _ = stmt;
        return 101; // SQLITE_DONE
    }

    pub fn sqlite3_finalize(stmt: ?*sqlite3_stmt) i32 {
        _ = stmt;
        return SQLITE_OK;
    }
};

pub fn main() !void {
    var db: ?*c.sqlite3 = null;
    defer _ = c.sqlite3_close(db);

    // Open in-memory database
    const rc = c.sqlite3_open(":memory:", &db);
    if (rc != c.SQLITE_OK) {
        std.debug.print("Cannot open database: {s}\n", .{c.sqlite3_errmsg(db)});
        return error.DatabaseError;
    }

    // Create table
    const create_sql = "CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, age INTEGER)";
    var errmsg: [*c]u8 = null;
    defer c.sqlite3_free(errmsg);

    _ = c.sqlite3_exec(db, create_sql, null, null, &errmsg);

    // Insert data using prepared statement
    const insert_sql = "INSERT INTO users (name, age) VALUES (?, ?)";
    var stmt: ?*c.sqlite3_stmt = null;
    defer _ = c.sqlite3_finalize(stmt);

    _ = c.sqlite3_prepare_v2(db, insert_sql, -1, &stmt, null);
    _ = c.sqlite3_bind_text(stmt, 1, "Alice", -1, c.SQLITE_TRANSIENT);
    _ = c.sqlite3_bind_int(stmt, 2, 30);
    _ = c.sqlite3_step(stmt);

    std.debug.print("Inserted user successfully\n", .{});
}