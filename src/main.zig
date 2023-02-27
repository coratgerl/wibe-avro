const std = @import("std");
const schema = @import("./schema.zig");

pub fn main() !void {
    const schema_test: schema.Schema = schema.Schema{ .type = "test" };
    schema.display_schema(schema_test);
}
