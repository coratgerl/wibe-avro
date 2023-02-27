const std = @import("std");
const AvroError = @import("error.zig").AvroError;
const ArrayList = std.ArrayList;
const Allocator = std.mem;
const stdout = std.io.getStdOut().writer();
// const testing = std.testing;

// try stdout.print("Array lenght {}!\n", .{array.items.len});

pub const DEFAULT_MAX_ALLOCATION_BYTES: usize = 512 * 1024 * 1024;
pub var MAX_ALLOCATION_BYTES: usize = DEFAULT_MAX_ALLOCATION_BYTES;

pub fn read_long(comptime T: type, reader: *T) AvroError!u64 {
    return zag_i64(T, reader);
}

pub fn zag_i32(comptime T: type, reader: *T) AvroError!i32 {
    return zag_i64(T, reader);
}

pub fn zag_i64(comptime T: type, reader: *T) AvroError!u64 {
    var z : u64 = try decode_variable(reader);
    if (z & 0x1 == 0) {
        return @as(i64, z >> 1);
    } else {
        return @as(i64, !(z >> 1));
    }
}

pub fn zig_i32(n: i32, buffer: *ArrayList(u8)) !void {
    try zig_i64(@as(i64, n), buffer);
}

pub fn zig_i64(n: i64, buffer: *ArrayList(u8)) !void {
    var z: u64 = @bitCast(u64, (n << 1) ^ (n >> 63));
    try encode_variable(&z, buffer);
}

pub fn encode_variable(z: *u64, buffer: *ArrayList(u8)) !void {
    while (true) {
        if (z.* <= 0x7F) {
            try buffer.append(@truncate(u8, z.* & 0x7F));
            break;
        } else {
            try buffer.append(@truncate(u8, 0x80 | (z.* & 0x7F)));
            z.* >>= 7;
        }
    }
}

pub fn decode_variable(comptime T: type, reader: *T) AvroError!u64 {
    var i: u64 = 0;
    var buf = [1]u8{0};
    var j: i32 = 0;
    while (true) {
        if (j > 9) {
            return AvroError.IntegerOverflow;
        }
        var fbs = std.io.fixedBufferStream(reader);
        _ = try fbs.reader().read(buf[0..]);
        i |= @as(u64, buf[0] & 0x7F) <<| (j * 7);
        if ((buf[0] >> 7) == 0) {
            break;
        } else {
            j += 1;
        }
    }
    return i;
}

pub fn max_allocation_bytes(num_bytes: usize) usize {
    MAX_ALLOCATION_BYTES = num_bytes;
    return MAX_ALLOCATION_BYTES;
}

pub fn safe_len(len: usize) AvroError!usize {
    var max_bytes: usize = max_allocation_bytes(DEFAULT_MAX_ALLOCATION_BYTES);
    if (len <= max_bytes) {
        return len;
    } else {
        return AvroError.MemoryAllocation;
    }
}

test "test_zigzag" {
    {
        var a = ArrayList(u8).init(std.testing.allocator);
        defer a.deinit();
        var b = ArrayList(u8).init(std.testing.allocator);
        defer b.deinit();
        _ = try zig_i32(@as(i32, 42), &a);
        _ = try zig_i64(@as(i64, 42), &b);
        try std.testing.expectEqualSlices(u8,  a.items, b.items);
    }
}

test "test_zig_i64" {
    {
        var array = ArrayList(u8).init(std.testing.allocator);
        defer array.deinit();
        var cloned = try array.clone();
        defer cloned.deinit();
        _ = try zig_i64(0, &array);
        try cloned.append(0);
        try std.testing.expectEqualSlices(u8,  array.items, cloned.items);
    }
    {
        var array = ArrayList(u8).init(std.testing.allocator);
        defer array.deinit();
        var cloned = try array.clone();
        defer cloned.deinit();
        _ = try zig_i64(-1, &array);
        try cloned.append(1);
        try std.testing.expectEqualSlices(u8,  array.items, cloned.items);
    }
    {
        var array = ArrayList(u8).init(std.testing.allocator);
        defer array.deinit();
        var cloned = try array.clone();
        defer cloned.deinit();
        _ = try zig_i64(1, &array);
        try cloned.append(2);
        try std.testing.expectEqualSlices(u8,  array.items, cloned.items);
    }
    {
        var array = ArrayList(u8).init(std.testing.allocator);
        defer array.deinit();
        var cloned = try array.clone();
        defer cloned.deinit();
        _ = try zig_i64(-64, &array);
        try cloned.append(127);
        try std.testing.expectEqualSlices(u8,  array.items, cloned.items);
    }
    {
        var array = ArrayList(u8).init(std.testing.allocator);
        defer array.deinit();
        var cloned = try array.clone();
        defer cloned.deinit();
        _ = try zig_i64(64, &array);
        try cloned.append(128);
        try cloned.append(1);
        try std.testing.expectEqualSlices(u8,  array.items, cloned.items);
    }
    {
        var array = ArrayList(u8).init(std.testing.allocator);
        defer array.deinit();
        var cloned = try array.clone();
        defer cloned.deinit();
        _ = try zig_i64(@as(i64, std.math.maxInt(i32)), &array);
        try cloned.append(254);
        try cloned.appendNTimes(255, 3);
        try cloned.append(15);
        try std.testing.expectEqualSlices(u8,  array.items, cloned.items);
    }
    {
        var array = ArrayList(u8).init(std.testing.allocator);
        defer array.deinit();
        var cloned = try array.clone();
        defer cloned.deinit();
        _ = try zig_i64(@as(i64, std.math.maxInt(i32)) + 1, &array);
        try cloned.appendNTimes(128, 4);
        try cloned.append(16);
        try std.testing.expectEqualSlices(u8,  array.items, cloned.items);
    }
    {
        var array = ArrayList(u8).init(std.testing.allocator);
        defer array.deinit();
        var cloned = try array.clone();
        defer cloned.deinit();
        _ = try zig_i64(@as(i64, std.math.minInt(i32)), &array);
        try cloned.appendNTimes(255, 4);
        try cloned.append(15);
        try std.testing.expectEqualSlices(u8,  array.items, cloned.items);
    }
    {
        var array = ArrayList(u8).init(std.testing.allocator);
        defer array.deinit();
        var cloned = try array.clone();
        defer cloned.deinit();
        _ = try zig_i64(@as(i64, std.math.minInt(i32)) - 1, &array);
        try cloned.append(129);
        try cloned.appendNTimes(128, 3);
        try cloned.append(16);
        try std.testing.expectEqualSlices(u8,  array.items, cloned.items);
    }
    {
        var array = ArrayList(u8).init(std.testing.allocator);
        defer array.deinit();
        var cloned = try array.clone();
        defer cloned.deinit();
        _ = try zig_i64(std.math.maxInt(i64), &array);
        try cloned.append(254);
        try cloned.appendNTimes(255, 8);
        try cloned.append(1);
        try std.testing.expectEqualSlices(u8,  array.items, cloned.items);
    }
    {
        var array = ArrayList(u8).init(std.testing.allocator);
        defer array.deinit();
        var cloned = try array.clone();
        defer cloned.deinit();
        _ = try zig_i64(std.math.minInt(i64), &array);
        try cloned.appendNTimes(255, 9);
        try cloned.append(1);
        try std.testing.expectEqualSlices(u8,  array.items, cloned.items);
    }
}

test "test_zig_i32" {
    {
        var array = ArrayList(u8).init(std.testing.allocator);
        defer array.deinit();
        var cloned = try array.clone();
        defer cloned.deinit();
        _ = try zig_i32(std.math.maxInt(i32) / 2, &array);
        try cloned.append(254);
        try cloned.appendNTimes(255, 3);
        try cloned.append(7);
        try std.testing.expectEqualSlices(u8,  array.items, cloned.items);
    }
    {
        var array = ArrayList(u8).init(std.testing.allocator);
        defer array.deinit();
        var cloned = try array.clone();
        defer cloned.deinit();
        _ = try zig_i32(std.math.minInt(i32) / 2, &array);
        try cloned.appendNTimes(255, 4);
        try cloned.append(7);
        try std.testing.expectEqualSlices(u8,  array.items, cloned.items);
    }
    {
        var array = ArrayList(u8).init(std.testing.allocator);
        defer array.deinit();
        var cloned = try array.clone();
        defer cloned.deinit();
        _ = try zig_i32(-std.math.minInt(i32) / 2, &array);
        try cloned.appendNTimes(128, 4);
        try cloned.append(8);
        try std.testing.expectEqualSlices(u8,  array.items, cloned.items);
    }
    {
        var array = ArrayList(u8).init(std.testing.allocator);
        defer array.deinit();
        var cloned = try array.clone();
        defer cloned.deinit();
        _ = try zig_i32(std.math.minInt(i32) / 2 - 1, &array);
        try cloned.append(129);
        try cloned.appendNTimes(128, 3);
        try cloned.append(8);
        try std.testing.expectEqualSlices(u8,  array.items, cloned.items);
    }
    {
        var array = ArrayList(u8).init(std.testing.allocator);
        defer array.deinit();
        var cloned = try array.clone();
        defer cloned.deinit();
        _ = try zig_i32(std.math.maxInt(i32), &array);
        try cloned.append(254);
        try cloned.appendNTimes(255, 3);
        try cloned.append(15);
        try std.testing.expectEqualSlices(u8,  array.items, cloned.items);
    }
    {
        var array = ArrayList(u8).init(std.testing.allocator);
        defer array.deinit();
        var cloned = try array.clone();
        defer cloned.deinit();
        _ = try zig_i32(std.math.minInt(i32), &array);
        try cloned.appendNTimes(255, 4);
        try cloned.append(15);
        try std.testing.expectEqualSlices(u8,  array.items, cloned.items);
    }
}


test "test_overflow_decode" {
    {
        var causes_left_shift_overflow = [_]u8{0xe1, 0xe1, 0xe1, 0xe1, 0xe1};
        try std.testing.expectError(AvroError.IntegerOverflow, decode_variable([5]u8, &causes_left_shift_overflow));
    }
}

test "test_safe_len" {
    {

    }
}
