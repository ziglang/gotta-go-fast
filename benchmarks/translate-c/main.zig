const std = @import("std");
const bench = @import("root");

pub fn setup(gpa: *std.mem.Allocator, options: *bench.Options) ![]const u8 {
    _ = gpa;
    options.useChildProcess();
    return options.zig_exe;
}

pub fn run(gpa: *std.mem.Allocator, zig_exe: []const u8) !void {
    return bench.exec(gpa, &[_][]const u8{
        zig_exe, "translate-c", "input.h", "-target", "x86_64-windows-gnu", "-lc",
    }, .{
        .stdout_behavior = .Ignore,
    });
}
