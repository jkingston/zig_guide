// Mock API server module demonstrating layered architecture
// This module depends on database.zig and shows how to structure business logic

const std = @import("std");
const Database = @import("database").Database;
const DatabaseError = @import("database").DatabaseError;
const Allocator = std.mem.Allocator;

pub const ApiError = error{
    UserNotFound,
    UserAlreadyExists,
    InvalidRequest,
    DatabaseError,
    OutOfMemory,
};

pub const User = struct {
    id: []const u8,
    name: []const u8,
    email: []const u8,

    /// Serialize user to JSON-like string
    pub fn serialize(self: User, allocator: Allocator) ![]u8 {
        return std.fmt.allocPrint(
            allocator,
            "{{\"id\":\"{s}\",\"name\":\"{s}\",\"email\":\"{s}\"}}",
            .{ self.id, self.name, self.email },
        );
    }

    /// Parse user from JSON-like format: {"id":"...","name":"...","email":"..."}
    pub fn deserialize(data: []const u8) !User {
        // Simple JSON-like parser for our specific format
        // Find id value
        const id_start = std.mem.indexOf(u8, data, "\"id\":\"") orelse return error.InvalidFormat;
        const id_value_start = id_start + 6;
        const id_end = std.mem.indexOfPos(u8, data, id_value_start, "\"") orelse return error.InvalidFormat;
        const id = data[id_value_start..id_end];

        // Find name value
        const name_start = std.mem.indexOf(u8, data, "\"name\":\"") orelse return error.InvalidFormat;
        const name_value_start = name_start + 8;
        const name_end = std.mem.indexOfPos(u8, data, name_value_start, "\"") orelse return error.InvalidFormat;
        const name = data[name_value_start..name_end];

        // Find email value
        const email_start = std.mem.indexOf(u8, data, "\"email\":\"") orelse return error.InvalidFormat;
        const email_value_start = email_start + 9;
        const email_end = std.mem.indexOfPos(u8, data, email_value_start, "\"") orelse return error.InvalidFormat;
        const email = data[email_value_start..email_end];

        return User{
            .id = id,
            .name = name,
            .email = email,
        };
    }
};

/// API server that manages users via a database backend
pub const ApiServer = struct {
    allocator: Allocator,
    db: *Database,

    /// Initialize API server with a database instance
    pub fn init(allocator: Allocator, db: *Database) ApiServer {
        return .{
            .allocator = allocator,
            .db = db,
        };
    }

    /// Create a new user
    /// Returns error.UserAlreadyExists if user ID already exists
    pub fn createUser(self: *ApiServer, user: User) ApiError!void {
        // Serialize user data
        const user_data = user.serialize(self.allocator) catch return ApiError.OutOfMemory;
        defer self.allocator.free(user_data);

        // Store in database
        self.db.insert(user.id, user_data) catch |err| switch (err) {
            DatabaseError.DuplicateKey => return ApiError.UserAlreadyExists,
            DatabaseError.OutOfMemory => return ApiError.OutOfMemory,
            else => return ApiError.DatabaseError,
        };
    }

    /// Get a user by ID
    /// Returns error.UserNotFound if user doesn't exist
    /// Caller must free the returned User's fields if they were allocated
    pub fn getUser(self: *ApiServer, user_id: []const u8) ApiError!User {
        // Fetch from database
        const user_data = self.db.get(user_id) catch |err| switch (err) {
            DatabaseError.KeyNotFound => return ApiError.UserNotFound,
            else => return ApiError.DatabaseError,
        };

        // Deserialize user data
        return User.deserialize(user_data) catch ApiError.InvalidRequest;
    }

    /// Update an existing user
    /// Returns error.UserNotFound if user doesn't exist
    pub fn updateUser(self: *ApiServer, user: User) ApiError!void {
        // Serialize user data
        const user_data = user.serialize(self.allocator) catch return ApiError.OutOfMemory;
        defer self.allocator.free(user_data);

        // Update in database
        self.db.update(user.id, user_data) catch |err| switch (err) {
            DatabaseError.KeyNotFound => return ApiError.UserNotFound,
            DatabaseError.OutOfMemory => return ApiError.OutOfMemory,
            else => return ApiError.DatabaseError,
        };
    }

    /// Delete a user by ID
    /// Returns error.UserNotFound if user doesn't exist
    pub fn deleteUser(self: *ApiServer, user_id: []const u8) ApiError!void {
        self.db.delete(user_id) catch |err| switch (err) {
            DatabaseError.KeyNotFound => return ApiError.UserNotFound,
            else => return ApiError.DatabaseError,
        };
    }

    /// Check if a user exists
    pub fn userExists(self: *const ApiServer, user_id: []const u8) bool {
        return self.db.exists(user_id);
    }

    /// Get total number of users
    pub fn getUserCount(self: *const ApiServer) usize {
        return self.db.count();
    }

    /// Handle a simple request (simplified API endpoint simulation)
    pub const RequestType = enum {
        create,
        get,
        update,
        delete,
    };

    pub const Request = struct {
        request_type: RequestType,
        user: User,
    };

    pub const Response = struct {
        success: bool,
        message: []const u8,
        user: ?User,
    };

    /// Process a request and return a response
    pub fn handleRequest(self: *ApiServer, request: Request) ApiError!Response {
        switch (request.request_type) {
            .create => {
                self.createUser(request.user) catch |err| {
                    return Response{
                        .success = false,
                        .message = @errorName(err),
                        .user = null,
                    };
                };
                return Response{
                    .success = true,
                    .message = "User created successfully",
                    .user = request.user,
                };
            },
            .get => {
                const user = self.getUser(request.user.id) catch |err| {
                    return Response{
                        .success = false,
                        .message = @errorName(err),
                        .user = null,
                    };
                };
                return Response{
                    .success = true,
                    .message = "User retrieved successfully",
                    .user = user,
                };
            },
            .update => {
                self.updateUser(request.user) catch |err| {
                    return Response{
                        .success = false,
                        .message = @errorName(err),
                        .user = null,
                    };
                };
                return Response{
                    .success = true,
                    .message = "User updated successfully",
                    .user = request.user,
                };
            },
            .delete => {
                self.deleteUser(request.user.id) catch |err| {
                    return Response{
                        .success = false,
                        .message = @errorName(err),
                        .user = null,
                    };
                };
                return Response{
                    .success = true,
                    .message = "User deleted successfully",
                    .user = null,
                };
            },
        }
    }
};
