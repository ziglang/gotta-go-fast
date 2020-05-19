const std = @import("std");
const bench = @import("root");

pub fn setup(gpa: *std.mem.Allocator, options: *bench.Options) ![]const u8 {
    options.rusage_who = std.os.RUSAGE_CHILDREN;
    return options.zig_exe;
}

pub fn run(gpa: *std.mem.Allocator, zig_exe: []const u8) !void {
    return exec(gpa, &[_][]const u8{
        zig_exe,
        "test",
        "../test/stage1/behavior.zig",
        "--cache",
        "off",
    }, .{
        .cwd = "../../zig-builds/src/build",
    });
}

fn exec(
    gpa: *std.mem.Allocator,
    argv: []const []const u8,
    options: struct { cwd: ?[]const u8 = null },
) !void {
    const child = try std.ChildProcess.init(argv, gpa);
    defer child.deinit();

    child.stdin_behavior = .Inherit;
    child.stdout_behavior = .Inherit;
    child.stderr_behavior = .Inherit;
    child.cwd = options.cwd;

    const term = try child.spawnAndWait();
    switch (term) {
        .Exited => |code| {
            if (code != 0) {
                return error.ChildProcessBadExitCode;
            }
        },
        else => {
            return error.ChildProcessCrashed;
        },
    }
}
