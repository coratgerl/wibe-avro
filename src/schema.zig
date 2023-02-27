const std = @import("std");
const stdout = std.io.getStdOut().writer();

const FieldsType = enum { Null, Boolean, Int, Long, Float, Double, Bytes, String, Array };
const Fields = struct { name : []const u8, type: FieldsType };

pub const Schema = struct { type: []const u8, namespace: []const u8, name: []const u8, fields: []const Fields };

test "schema_creation" {
    const schema_test: Schema = Schema{ .type = "TypeTest", .name = "NameTest", .namespace = "NamespaceTest", .fields = &[_]Fields {Fields {.name = "NameFields", .type = FieldsType.Int}}};

    try std.testing.expect(std.mem.eql(u8, schema_test.type, "TypeTest"));
    try std.testing.expect(std.mem.eql(u8, schema_test.name, "NameTest"));
    try std.testing.expect(std.mem.eql(u8, schema_test.namespace, "NamespaceTest"));
    try std.testing.expect(std.mem.eql(u8, schema_test.fields[0].name, "NameFields"));
    try std.testing.expect(schema_test.fields[0].type == FieldsType.Int);
}
