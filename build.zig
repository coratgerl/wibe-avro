const std = @import("std");
const Pkg = std.build.Pkg;

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();

    const lib = b.addStaticLibrary("wibe-avro", "src/main.zig");
    lib.setBuildMode(mode);
    lib.install();
}
