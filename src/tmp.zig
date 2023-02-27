const std = @import("std");
const stdout = std.io.getStdOut().writer();
// const testing = std.testing;

// try stdout.print("Array lenght {}!\n", .{array.items.len});

const FileOpenError = error {
    AccessDenied,
    OutOfMemory,
    FileNotFound,
};

const AllocationError = error {
    OutOfMemory,
};

test "coerce subset to superset" {
    const err = foo(AllocationError.OutOfMemory);




    try std.testing.expect(err == FileOpenError.OutOfMemory);


    try stdout.print("toto error {}, FileOpenError.OutOfMemory {}!\n", .{err, FileOpenError.OutOfMemory});
}

fn foo(err: AllocationError) FileOpenError {
    return err;
}