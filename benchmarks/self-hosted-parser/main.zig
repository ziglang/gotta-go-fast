const std = @import("std");
const bench = @import("root");
const log = std.log;

pub fn setup(gpa: *std.mem.Allocator, options: *bench.Options) !void {
    _ = gpa;
    _ = options;
}

pub fn run(gpa: *std.mem.Allocator, context: void) !void {
    _ = context;
    var input_dir = try std.fs.cwd().openDir("input_dir", .{ .iterate = true });
    defer input_dir.close();
    var walker = try input_dir.walk(gpa);
    defer walker.deinit();

    var total_count: usize = 0;
    var any_bad = false;
    while (try walker.next()) |entry| switch (entry.kind) {
        .File => {
            const source = try entry.dir.readFileAllocOptions(
                gpa,
                entry.basename,
                30 * 1024 * 1024,
                null,
                @alignOf(u8),
                0,
            );
            defer gpa.free(source);

            var ast = try std.zig.parse(gpa, source);
            defer ast.deinit(gpa);

            if (ast.errors.len != 0) {
                for (ast.errors) |parse_error| {
                    log.err("{s}: {s}", .{ entry.basename, @tagName(parse_error.tag) });
                }
                any_bad = true;
            }

            total_count += ast.nodes.len;
        },
        else => continue,
    };

    try std.testing.expect(!any_bad);
    try std.testing.expect(total_count >= 1000000);
}
