const std = @import("std");
const bench = @import("root");

pub fn setup(_: std.mem.Allocator, options: *bench.Options) ![]const u8 {
    options.useChildProcess();
    return options.zig_exe;
}

pub fn run(gpa: std.mem.Allocator, zig_exe: []const u8) !void {
    return bench.exec(gpa, &.{
        zig_exe,                                   "build-exe",
        "-target",                                 "aarch64-linux",
        "src/hello-world/hello-aarch64-linux.zig",
    }, .{});
}
