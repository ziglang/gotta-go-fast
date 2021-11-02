const std = @import("std");
const fs = std.fs;
const assert = std.debug.assert;

pub fn main() !void {
    const gpa = std.heap.page_allocator;
    var arena_state = std.heap.ArenaAllocator.init(gpa);
    defer arena_state.deinit();
    const arena = &arena_state.allocator;

    const args = try std.process.argsAlloc(arena);
    const records_csv_path = args[1];
    const zig_git_path = args[2];
    const commits_file = args[3];

    const commits_file_text = try fs.cwd().readFileAlloc(arena, commits_file, 2 * 1024 * 1024);

    const new_zig_build_dir = try fs.path.join(arena, &[_][]const u8{ zig_git_path, "build-release" });
    const new_zig_exe = try fs.path.join(arena, &[_][]const u8{ new_zig_build_dir, "zig" });
    const old_zig_build_dir = try fs.path.join(arena, &[_][]const u8{ zig_git_path, "build-backfill" });
    const old_zig_exe = try fs.path.join(arena, &[_][]const u8{ old_zig_build_dir, "zig" });

    std.debug.print("Checking out origin/master at {s}...\n", .{zig_git_path});
    try exec(gpa, &[_][]const u8{ "git", "checkout", "origin/master" }, .{
        .cwd = zig_git_path,
    });

    std.debug.print("Building new zig to {s}...\n", .{new_zig_exe});
    try exec(gpa, &[_][]const u8{"ninja"}, .{
        .cwd = new_zig_build_dir,
    });

    var commits = std.mem.tokenize(u8, commits_file_text, " \r\n\t");
    while (commits.next()) |commit| {
        std.debug.print("Checking out {s} to backfill...\n", .{commit});
        try exec(gpa, &[_][]const u8{ "git", "checkout", commit }, .{
            .cwd = zig_git_path,
        });
        // Touch CMakeLists.txt to force the new `zig version` to be picked up.
        try exec(gpa, &[_][]const u8{ "touch", "CMakeLists.txt" }, .{
            .cwd = zig_git_path,
        });

        std.debug.print("Building old zig to {s}...\n", .{old_zig_exe});
        try exec(gpa, &[_][]const u8{"ninja"}, .{
            .cwd = old_zig_build_dir,
        });

        const zig_version_raw = try execCapture(arena, &[_][]const u8{ old_zig_exe, "version" }, .{});
        const zig_version = std.mem.trim(u8, zig_version_raw, " \r\n\t");

        const timestamp_untrimmed = try execCapture(gpa, &[_][]const u8{
            "git",                 "log",
            "-n1",                 commit,
            "--pretty=format:%at",
        }, .{
            .cwd = zig_git_path,
        });
        const timestamp = std.mem.trim(u8, timestamp_untrimmed, " \r\n\t");

        std.debug.print("Collecting measurements for zig version {s} timestamp {s}...\n", .{
            zig_version, timestamp,
        });
        try exec(gpa, &[_][]const u8{
            new_zig_exe,      "run",       "collect-measurements.zig", "--",
            records_csv_path, old_zig_exe, commit,                     timestamp,
        }, .{});
    }
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

fn execCapture(
    gpa: *std.mem.Allocator,
    argv: []const []const u8,
    options: struct { cwd: ?[]const u8 = null },
) ![]u8 {
    //std.debug.print("exec argv[0]={} cwd={}\n", .{argv[0], options.cwd});
    const child = try std.ChildProcess.init(argv, gpa);
    defer child.deinit();

    child.stdin_behavior = .Inherit;
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Inherit;
    child.cwd = options.cwd;

    //std.debug.print("cwd={}\n", .{child.cwd});
    //for (argv) |arg| {
    //    std.debug.print("{} ", .{arg});
    //}
    //std.debug.print("\n", .{});

    try child.spawn();

    const stdout_in = child.stdout.?.reader();

    const stdout = try stdout_in.readAllAlloc(gpa, 9999);
    errdefer gpa.free(stdout);

    const term = try child.wait();
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

    return stdout;
}
