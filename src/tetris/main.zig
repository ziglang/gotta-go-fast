const std = @import("std");
const bench = @import("root");

pub fn setup(_: std.mem.Allocator, options: *bench.Options) ![]const u8 {
    options.useChildProcess();
    return options.zig_exe;
}

pub fn run(gpa: std.mem.Allocator, zig_exe: []const u8) !void {
    return bench.exec(gpa, &.{
        zig_exe,
        "build-exe",
        "src/tetris/tetris/src/main.zig",
        "-fllvm",
        "-OReleaseFast",
        "-fno-lto",
        "-lc",
        "-Istb_image-2.22",
        "--main-pkg-path",
        "src/tetris",
        "-I",
        "src/tetris/include",
        "-I",
        "src/tetris/tetris/stb_image-2.22",
        "src/tetris/tetris/stb_image-2.22/stb_image_impl.c",
        "src/tetris/glfw-and-epoxy-stubs.s",
    }, .{});
}
