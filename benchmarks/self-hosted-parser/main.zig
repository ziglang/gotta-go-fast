const std = @import("std");
const bench = @import("root");

pub fn setup(gpa: *std.mem.Allocator, options: *bench.Options) !void {}

pub fn run(gpa: *std.mem.Allocator, context: void) !void {
    var walker = try std.fs.walkPath(gpa, "input_dir");
    defer walker.deinit();

    var total_count: usize = 0;
    while (try walker.next()) |entry| switch (entry.kind) {
        .File => {
            const source = try entry.dir.readFileAlloc(gpa, entry.basename, 30 * 1024 * 1024);
            defer gpa.free(source);

            var tree = try std.zig.parse(gpa, source);
            defer tree.deinit();

            std.testing.expect(tree.errors.len == 0);
            total_count += iterate(&tree.root_node.base);
        },
        else => continue,
    };

    std.testing.expect(total_count == 1205875);
}

fn iterate(node: *std.zig.ast.Node) usize {
    var count: usize = 0;
    var i: usize = 0;
    while (node.iterate(i)) |child| : (i += 1) {
        count += iterate(child);
    }
    return count + i;
}
