const std = @import("std");
const bench = @import("root");

pub fn setup(_: std.mem.Allocator, _: *bench.Options) !void {}

pub fn run(gpa: std.mem.Allocator, _: void) !void {
    var input_dir = try std.fs.cwd().openIterableDir("src/self-hosted-parser/input_dir", .{});
    defer input_dir.close();

    var walker = try input_dir.walk(gpa);
    defer walker.deinit();

    var total_count: usize = 0;
    var any_bad = false;
    while (try walker.next()) |entry| switch (entry.kind) {
        .file => {
            const source = try entry.dir.readFileAllocOptions(gpa, entry.basename, 30 * 1024 * 1024, null, @alignOf(u8), 0);
            defer gpa.free(source);

            var ast = try std.zig.Ast.parse(gpa, source, .zig);
            defer ast.deinit(gpa);

            if (ast.errors.len != 0) {
                for (ast.errors) |parse_error| {
                    std.log.err("{s}: {s}", .{ entry.basename, @tagName(parse_error.tag) });
                }
                any_bad = true;
            }

            total_count += ast.nodes.len;
        },
        else => continue,
    };

    try std.testing.expect(!any_bad);
    try std.testing.expect(total_count >= 1_000_000);
}
