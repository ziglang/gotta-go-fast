const std = @import("std");
const bench = @import("root");

pub fn setup(gpa: std.mem.Allocator, options: *bench.Options) ![]const u8 {
    _ = gpa;
    options.useChildProcess();
    return options.zig_exe;
}

pub fn run(gpa: std.mem.Allocator, zig_exe: []const u8) !void {
    return bench.exec(gpa, &[_][]const u8{
        zig_exe,
        "build-exe",
        "tetris/src/main.zig",
        "-fLLVM",
        "-OReleaseFast",
        "-fno-stage1",
        "-fno-lto",
        "-lc",
        "-Istb_image-2.22",
        "--main-pkg-path",
        ".",
        "-I",
        "include",
        "-I",
        "tetris/stb_image-2.22",
        "tetris/stb_image-2.22/stb_image_impl.c",
        "glfw-and-epoxy-stubs.s",
    }, .{});
}
