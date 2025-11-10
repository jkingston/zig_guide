const std = @import("std");
const testing = std.testing;

/// Validator module demonstrating parameterized tests
/// Shows data-driven testing with various return types (bool, enum, error)

pub const PasswordStrength = enum {
    Weak,
    Medium,
    Strong,
};

/// Validate email address format
/// Basic validation: contains @ and . after @, no spaces
pub fn validateEmail(email: []const u8) bool {
    if (email.len < 3) return false; // Minimum: a@b

    var has_at = false;
    var at_index: usize = 0;
    var has_dot_after_at = false;

    for (email, 0..) |char, i| {
        if (char == ' ') return false; // No spaces allowed

        if (char == '@') {
            if (has_at) return false; // Multiple @ signs
            if (i == 0 or i == email.len - 1) return false; // @ at start or end
            has_at = true;
            at_index = i;
        }

        if (char == '.' and has_at and i > at_index) {
            if (i > at_index + 1 and i < email.len - 1) {
                has_dot_after_at = true;
            }
        }
    }

    return has_at and has_dot_after_at;
}

/// Validate URL format
/// Basic validation: starts with http:// or https://, has domain
pub fn validateUrl(url: []const u8) bool {
    if (url.len < 10) return false; // Minimum: http://a.b

    const has_http = std.mem.startsWith(u8, url, "http://");
    const has_https = std.mem.startsWith(u8, url, "https://");

    if (!has_http and !has_https) return false;

    const start: usize = if (has_https) 8 else 7;
    if (start >= url.len) return false;

    const domain = url[start..];
    if (domain.len < 3) return false; // Minimum: a.b

    // Check for at least one dot in domain
    return std.mem.indexOfScalar(u8, domain, '.') != null;
}

/// Validate phone number format
/// Accepts: digits, spaces, hyphens, parentheses, +
/// Must have 10-15 digits
pub fn validatePhoneNumber(phone: []const u8) bool {
    if (phone.len < 10) return false;

    var digit_count: usize = 0;

    for (phone) |char| {
        if (std.ascii.isDigit(char)) {
            digit_count += 1;
        } else if (char != ' ' and char != '-' and char != '(' and char != ')' and char != '+') {
            return false; // Invalid character
        }
    }

    return digit_count >= 10 and digit_count <= 15;
}

/// Validate password strength
/// Weak: < 8 characters
/// Medium: >= 8 characters, has letters and numbers
/// Strong: >= 12 characters, has letters, numbers, and special chars
pub fn validatePassword(password: []const u8) PasswordStrength {
    if (password.len < 8) return .Weak;

    var has_letter = false;
    var has_digit = false;
    var has_special = false;

    for (password) |char| {
        if (std.ascii.isAlphabetic(char)) has_letter = true;
        if (std.ascii.isDigit(char)) has_digit = true;
        if (!std.ascii.isAlphanumeric(char)) has_special = true;
    }

    if (password.len >= 12 and has_letter and has_digit and has_special) {
        return .Strong;
    }

    if (has_letter and has_digit) {
        return .Medium;
    }

    return .Weak;
}

/// Validate username
/// 3-20 characters, alphanumeric and underscore only, must start with letter
pub fn validateUsername(username: []const u8) bool {
    if (username.len < 3 or username.len > 20) return false;

    if (!std.ascii.isAlphabetic(username[0])) return false;

    for (username) |char| {
        if (!std.ascii.isAlphanumeric(char) and char != '_') {
            return false;
        }
    }

    return true;
}

// ============================================================================
// Parameterized Tests for Email Validation
// ============================================================================

test "validateEmail: valid emails" {
    const valid_emails = [_][]const u8{
        "user@example.com",
        "test@test.co.uk",
        "name.surname@domain.org",
        "user+tag@example.com",
        "first.last@subdomain.example.com",
        "user123@test123.com",
        "a@b.c",
        "very.long.email.address@very.long.domain.name.com",
        "user_name@example.com",
        "user-name@example.com",
    };

    for (valid_emails) |email| {
        const result = validateEmail(email);
        testing.expect(result) catch |err| {
            std.debug.print("Expected valid email: '{s}'\n", .{email});
            return err;
        };
    }
}

test "validateEmail: invalid emails" {
    const TestCase = struct {
        email: []const u8,
        reason: []const u8,
    };

    const invalid_emails = [_]TestCase{
        .{ .email = "", .reason = "empty" },
        .{ .email = "a", .reason = "too short" },
        .{ .email = "ab", .reason = "too short, no @" },
        .{ .email = "user", .reason = "no @" },
        .{ .email = "@example.com", .reason = "no local part" },
        .{ .email = "user@", .reason = "no domain" },
        .{ .email = "user@@example.com", .reason = "double @" },
        .{ .email = "user@example", .reason = "no TLD" },
        .{ .email = "user @example.com", .reason = "space in local" },
        .{ .email = "user@exa mple.com", .reason = "space in domain" },
        .{ .email = "user@.com", .reason = "dot right after @" },
        .{ .email = "user@example.", .reason = "dot at end" },
    };

    for (invalid_emails) |case| {
        const result = validateEmail(case.email);
        testing.expect(!result) catch |err| {
            std.debug.print("Expected invalid email '{s}' ({s}) but got valid\n", .{
                case.email,
                case.reason,
            });
            return err;
        };
    }
}

// ============================================================================
// Parameterized Tests for URL Validation
// ============================================================================

test "validateUrl: valid URLs" {
    const valid_urls = [_][]const u8{
        "http://example.com",
        "https://example.com",
        "http://www.example.com",
        "https://subdomain.example.com",
        "http://example.com/path",
        "https://example.com/path/to/resource",
        "http://example.com?query=value",
        "https://example.com:8080",
        "http://192.168.1.1",
        "https://example.co.uk",
    };

    for (valid_urls) |url| {
        const result = validateUrl(url);
        testing.expect(result) catch |err| {
            std.debug.print("Expected valid URL: '{s}'\n", .{url});
            return err;
        };
    }
}

test "validateUrl: invalid URLs" {
    const TestCase = struct {
        url: []const u8,
        reason: []const u8,
    };

    const invalid_urls = [_]TestCase{
        .{ .url = "", .reason = "empty" },
        .{ .url = "example.com", .reason = "no protocol" },
        .{ .url = "ftp://example.com", .reason = "wrong protocol" },
        .{ .url = "http://", .reason = "no domain" },
        .{ .url = "https://", .reason = "no domain" },
        .{ .url = "http://a", .reason = "no TLD" },
        .{ .url = "http://example", .reason = "no TLD" },
        .{ .url = "http:/example.com", .reason = "single slash" },
        .{ .url = "https//example.com", .reason = "no colon" },
    };

    for (invalid_urls) |case| {
        const result = validateUrl(case.url);
        testing.expect(!result) catch |err| {
            std.debug.print("Expected invalid URL '{s}' ({s}) but got valid\n", .{
                case.url,
                case.reason,
            });
            return err;
        };
    }
}

// ============================================================================
// Parameterized Tests for Phone Number Validation
// ============================================================================

test "validatePhoneNumber: valid phone numbers" {
    const valid_phones = [_][]const u8{
        "1234567890",
        "123-456-7890",
        "(123) 456-7890",
        "+1 123 456 7890",
        "+44 20 7946 0958",
        "123 456 7890",
        "(123)456-7890",
        "+1-123-456-7890",
        "12345678901",
        "123456789012345", // 15 digits (max)
    };

    for (valid_phones) |phone| {
        const result = validatePhoneNumber(phone);
        testing.expect(result) catch |err| {
            std.debug.print("Expected valid phone number: '{s}'\n", .{phone});
            return err;
        };
    }
}

test "validatePhoneNumber: invalid phone numbers" {
    const TestCase = struct {
        phone: []const u8,
        reason: []const u8,
    };

    const invalid_phones = [_]TestCase{
        .{ .phone = "", .reason = "empty" },
        .{ .phone = "123", .reason = "too few digits" },
        .{ .phone = "123456789", .reason = "only 9 digits" },
        .{ .phone = "1234567890123456", .reason = "too many digits (16)" },
        .{ .phone = "abc-def-ghij", .reason = "letters" },
        .{ .phone = "123.456.7890", .reason = "dots not allowed" },
        .{ .phone = "123/456/7890", .reason = "slashes not allowed" },
        .{ .phone = "123@456@7890", .reason = "@ not allowed" },
    };

    for (invalid_phones) |case| {
        const result = validatePhoneNumber(case.phone);
        testing.expect(!result) catch |err| {
            std.debug.print("Expected invalid phone '{s}' ({s}) but got valid\n", .{
                case.phone,
                case.reason,
            });
            return err;
        };
    }
}

// ============================================================================
// Parameterized Tests for Password Strength
// ============================================================================

test "validatePassword: weak passwords" {
    const TestCase = struct {
        password: []const u8,
        reason: []const u8,
    };

    const weak_passwords = [_]TestCase{
        .{ .password = "", .reason = "empty" },
        .{ .password = "a", .reason = "too short" },
        .{ .password = "1234567", .reason = "7 chars" },
        .{ .password = "password", .reason = "8 chars but only letters" },
        .{ .password = "12345678", .reason = "8 chars but only digits" },
        .{ .password = "abcdefgh", .reason = "8 chars, lowercase only" },
    };

    for (weak_passwords) |case| {
        const result = validatePassword(case.password);
        testing.expectEqual(PasswordStrength.Weak, result) catch |err| {
            std.debug.print("Expected weak password for '{s}' ({s}), got {}\n", .{
                case.password,
                case.reason,
                result,
            });
            return err;
        };
    }
}

test "validatePassword: medium passwords" {
    const TestCase = struct {
        password: []const u8,
        reason: []const u8,
    };

    const medium_passwords = [_]TestCase{
        .{ .password = "pass1234", .reason = "8 chars, letters and digits" },
        .{ .password = "hello123", .reason = "8 chars, mixed" },
        .{ .password = "abc12345", .reason = "8 chars, starts with letters" },
        .{ .password = "12345abc", .reason = "8 chars, starts with digits" },
        .{ .password = "test1234test", .reason = "12 chars but no special" },
    };

    for (medium_passwords) |case| {
        const result = validatePassword(case.password);
        testing.expectEqual(PasswordStrength.Medium, result) catch |err| {
            std.debug.print("Expected medium password for '{s}' ({s}), got {}\n", .{
                case.password,
                case.reason,
                result,
            });
            return err;
        };
    }
}

test "validatePassword: strong passwords" {
    const TestCase = struct {
        password: []const u8,
        reason: []const u8,
    };

    const strong_passwords = [_]TestCase{
        .{ .password = "Pass1234!@#$", .reason = "12+ chars with all types" },
        .{ .password = "MyP@ssw0rd!!", .reason = "12+ chars, mixed case, special" },
        .{ .password = "Str0ng_P@ssw0rd", .reason = "15 chars with underscore" },
        .{ .password = "C0mpl3x!P@ss", .reason = "12 chars, complex" },
        .{ .password = "!@#$abc123DEF", .reason = "13 chars, all types" },
    };

    for (strong_passwords) |case| {
        const result = validatePassword(case.password);
        testing.expectEqual(PasswordStrength.Strong, result) catch |err| {
            std.debug.print("Expected strong password for '{s}' ({s}), got {}\n", .{
                case.password,
                case.reason,
                result,
            });
            return err;
        };
    }
}

// ============================================================================
// Parameterized Tests for Username Validation
// ============================================================================

test "validateUsername: valid usernames" {
    const valid_usernames = [_][]const u8{
        "abc",
        "user",
        "user123",
        "user_name",
        "User_Name_123",
        "a_b_c",
        "username",
        "VeryLongUsername123",
        "a12",
        "Test_User_99",
    };

    for (valid_usernames) |username| {
        const result = validateUsername(username);
        testing.expect(result) catch |err| {
            std.debug.print("Expected valid username: '{s}'\n", .{username});
            return err;
        };
    }
}

test "validateUsername: invalid usernames" {
    const TestCase = struct {
        username: []const u8,
        reason: []const u8,
    };

    const invalid_usernames = [_]TestCase{
        .{ .username = "", .reason = "empty" },
        .{ .username = "ab", .reason = "too short (2 chars)" },
        .{ .username = "a", .reason = "too short (1 char)" },
        .{ .username = "123user", .reason = "starts with digit" },
        .{ .username = "_user", .reason = "starts with underscore" },
        .{ .username = "user-name", .reason = "contains hyphen" },
        .{ .username = "user.name", .reason = "contains dot" },
        .{ .username = "user name", .reason = "contains space" },
        .{ .username = "user@example", .reason = "contains @" },
        .{ .username = "ThisUsernameIsWayTooLongForValidation", .reason = "too long (21+ chars)" },
    };

    for (invalid_usernames) |case| {
        const result = validateUsername(case.username);
        testing.expect(!result) catch |err| {
            std.debug.print("Expected invalid username '{s}' ({s}) but got valid\n", .{
                case.username,
                case.reason,
            });
            return err;
        };
    }
}

// ============================================================================
// Edge Case Tests
// ============================================================================

test "validator: boundary lengths" {
    // Test exact boundary values

    // Username: exactly 3 chars (minimum)
    try testing.expect(validateUsername("abc"));

    // Username: exactly 20 chars (maximum)
    try testing.expect(validateUsername("abcdefghij1234567890"));

    // Username: 21 chars (over maximum)
    try testing.expect(!validateUsername("123456789012345678901"));

    // Password: exactly 7 chars (weak)
    try testing.expectEqual(PasswordStrength.Weak, validatePassword("pass123"));

    // Password: exactly 8 chars with letters and digits (medium)
    try testing.expectEqual(PasswordStrength.Medium, validatePassword("pass1234"));

    // Password: exactly 12 chars with all types (strong)
    try testing.expectEqual(PasswordStrength.Strong, validatePassword("Pass1234!@#$"));

    // Phone: exactly 10 digits (minimum)
    try testing.expect(validatePhoneNumber("1234567890"));

    // Phone: exactly 15 digits (maximum)
    try testing.expect(validatePhoneNumber("123456789012345"));

    // Phone: 16 digits (over maximum)
    try testing.expect(!validatePhoneNumber("1234567890123456"));
}

test "validator: empty input handling" {
    // All validators should handle empty input gracefully
    try testing.expect(!validateEmail(""));
    try testing.expect(!validateUrl(""));
    try testing.expect(!validatePhoneNumber(""));
    try testing.expect(!validateUsername(""));
    try testing.expectEqual(PasswordStrength.Weak, validatePassword(""));
}

test "validator: special characters" {
    // Test various special characters across validators

    // Email: common special chars
    try testing.expect(validateEmail("user+tag@example.com"));
    try testing.expect(validateEmail("user.name@example.com"));
    try testing.expect(validateEmail("user_name@example.com"));
    try testing.expect(validateEmail("user-name@example.com"));

    // URL: query parameters and paths
    try testing.expect(validateUrl("http://example.com?key=value"));
    try testing.expect(validateUrl("http://example.com/path/to/resource"));

    // Phone: formatting characters
    try testing.expect(validatePhoneNumber("+1-123-456-7890"));
    try testing.expect(validatePhoneNumber("(123) 456-7890"));

    // Username: underscore only
    try testing.expect(validateUsername("user_name"));
    try testing.expect(!validateUsername("user-name"));
    try testing.expect(!validateUsername("user.name"));

    // Password: various special chars make it strong
    try testing.expectEqual(PasswordStrength.Strong, validatePassword("Pass1234!@#$"));
    try testing.expectEqual(PasswordStrength.Strong, validatePassword("Test_Pass_123!"));
}

// ============================================================================
// Integration Test
// ============================================================================

test "validator: complete user registration validation" {
    // Simulate validating a user registration form

    const TestCase = struct {
        username: []const u8,
        email: []const u8,
        password: []const u8,
        phone: []const u8,
        should_pass: bool,
        reason: []const u8,
    };

    const cases = [_]TestCase{
        .{
            .username = "john_doe",
            .email = "john@example.com",
            .password = "SecureP@ss123",
            .phone = "123-456-7890",
            .should_pass = true,
            .reason = "all valid",
        },
        .{
            .username = "ab",
            .email = "valid@example.com",
            .password = "StrongP@ss123",
            .phone = "123-456-7890",
            .should_pass = false,
            .reason = "username too short",
        },
        .{
            .username = "validuser",
            .email = "invalid-email",
            .password = "StrongP@ss123",
            .phone = "123-456-7890",
            .should_pass = false,
            .reason = "invalid email",
        },
        .{
            .username = "validuser",
            .email = "valid@example.com",
            .password = "weak",
            .phone = "123-456-7890",
            .should_pass = false,
            .reason = "weak password",
        },
        .{
            .username = "validuser",
            .email = "valid@example.com",
            .password = "StrongP@ss123",
            .phone = "123",
            .should_pass = false,
            .reason = "invalid phone",
        },
    };

    for (cases) |case| {
        const username_valid = validateUsername(case.username);
        const email_valid = validateEmail(case.email);
        const password_strength = validatePassword(case.password);
        const phone_valid = validatePhoneNumber(case.phone);

        const all_valid = username_valid and
            email_valid and
            password_strength != .Weak and
            phone_valid;

        testing.expectEqual(case.should_pass, all_valid) catch |err| {
            std.debug.print("Validation failed for case '{s}':\n", .{case.reason});
            std.debug.print("  Username: {}\n", .{username_valid});
            std.debug.print("  Email: {}\n", .{email_valid});
            std.debug.print("  Password: {}\n", .{password_strength});
            std.debug.print("  Phone: {}\n", .{phone_valid});
            return err;
        };
    }
}
