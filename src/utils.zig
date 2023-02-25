const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem;
const stdout = std.io.getStdOut().writer();
// const testing = std.testing;

// try stdout.print("Array lenght {}!\n", .{array.items.len});


// pub fn zig_i32(n: i32, buffer: *ArrayList(u8)) !void {
//     zig_i64(n, buffer);
// }

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

test "zig_i64" {
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
        try cloned.append(255);
        try cloned.append(255);
        try cloned.append(255);
        try cloned.append(15);
        try std.testing.expectEqualSlices(u8,  array.items, cloned.items);
    }
    {
        var array = ArrayList(u8).init(std.testing.allocator);
        defer array.deinit();
        var cloned = try array.clone();
        defer cloned.deinit();
        _ = try zig_i64(@as(i64, std.math.maxInt(i32)) + 1, &array);
        try cloned.append(128);
        try cloned.append(128);
        try cloned.append(128);
        try cloned.append(128);
        try cloned.append(16);
        try std.testing.expectEqualSlices(u8,  array.items, cloned.items);
    }
    {
        var array = ArrayList(u8).init(std.testing.allocator);
        defer array.deinit();
        var cloned = try array.clone();
        defer cloned.deinit();
        _ = try zig_i64(@as(i64, std.math.minInt(i32)), &array);
        try cloned.append(255);
        try cloned.append(255);
        try cloned.append(255);
        try cloned.append(255);
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
        try cloned.append(128);
        try cloned.append(128);
        try cloned.append(128);
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
        var i: usize = 0;
        while (i < 8) : (i += 1) {
            try cloned.append(255);
        }
        try cloned.append(1);
        try std.testing.expectEqualSlices(u8,  array.items, cloned.items);
    }
    {
        var array = ArrayList(u8).init(std.testing.allocator);
        defer array.deinit();
        var cloned = try array.clone();
        defer cloned.deinit();
        _ = try zig_i64(std.math.minInt(i64), &array);
        var i: usize = 0;
        while (i < 9) : (i += 1) {
            try cloned.append(255);
        }
        try cloned.append(1);
        try std.testing.expectEqualSlices(u8,  array.items, cloned.items);
    }




    // array.clearAndFree();
    // cloned.clearAndFree();


    // try stdout.print("Array lenght {}!\n", .{array.items.len});

}
