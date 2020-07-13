const std = @import("std");
const app = @import("app");

pub const Measurement = struct {
    median: u64,
    mean: u64,
    min: u64,
    max: u64,

    fn compute(all_samples: []Sample, comptime field: []const u8) Measurement {
        const S = struct {
            fn order(context: void, a: Sample, b: Sample) bool {
                return @field(a, field) < @field(b, field);
            }
        };
        // Remove the 2 outliers
        std.sort.sort(Sample, all_samples, {}, S.order);
        const samples = all_samples[1 .. all_samples.len - 1];
        // Compute stats
        var total: u64 = 0;
        var min: u64 = std.math.maxInt(u64);
        var max: u64 = 0;
        for (samples) |s| {
            const v = @field(s, field);
            total += v;
            if (v < min) min = v;
            if (v > max) max = v;
        }
        return .{
            .median = @field(samples[samples.len / 2], field),
            .mean = total / samples.len,
            .min = min,
            .max = max,
        };
    }
};

pub const Results = union(enum) {
    fail: anyerror,
    ok: struct {
        samples_taken: usize,
        wall_time: Measurement,
        utime: Measurement,
        stime: Measurement,
        maxrss: usize,
    },
};

const Sample = struct {
    wall_time: u64,
    utime: u64,
    stime: u64,
};

fn timeval_to_ns(timeval: std.os.timeval) u64 {
    const ns_per_us = std.time.ns_per_s / std.time.us_per_s;
    return @bitCast(usize, timeval.tv_sec) * std.time.ns_per_s +
        @bitCast(usize, timeval.tv_usec) * ns_per_us;
}

var samples_buf: [1000000]Sample = undefined;
const max_nano_seconds = std.time.ns_per_s * 10;

pub fn bench(options: Options, comptime func: anytype, args: anytype) Results {
    var sample_index: usize = 0;
    const timer = std.time.Timer.start() catch @panic("need timer to work");
    const first_start = timer.read();
    while ((sample_index < 3 or
        (timer.read() - first_start) < max_nano_seconds) and
        sample_index < samples_buf.len)
    {
        if (options.clear_zig_cache) {
            std.fs.cwd().deleteTree("zig-cache") catch |err| {
                std.debug.panic("unable to delete zig-cache: {}", .{@errorName(err)});
            };
            std.fs.cwd().deleteTree("../../zig-builds/src/zig-cache") catch |err| {
                std.debug.panic("unable to delete zig-cache: {}", .{@errorName(err)});
            };
            std.fs.cwd().deleteTree("../../zig-builds/src/build/zig-cache") catch |err| {
                std.debug.panic("unable to delete zig-cache: {}", .{@errorName(err)});
            };
        }
        const start_rusage = std.os.getrusage(options.rusage_who);
        const start = timer.read();
        @call(.{}, func, args) catch |err| {
            return .{ .fail = err };
        };
        const end = timer.read();
        const end_rusage = std.os.getrusage(options.rusage_who);
        samples_buf[sample_index] = .{
            .wall_time = end - start,
            .utime = timeval_to_ns(end_rusage.utime) - timeval_to_ns(start_rusage.utime),
            .stime = timeval_to_ns(end_rusage.stime) - timeval_to_ns(start_rusage.stime),
        };
        sample_index += 1;
    }
    const all_samples = samples_buf[0..sample_index];
    const wall_time = Measurement.compute(all_samples, "wall_time");
    const utime = Measurement.compute(all_samples, "utime");
    const stime = Measurement.compute(all_samples, "stime");

    const final_rusage = std.os.getrusage(options.rusage_who);
    return .{
        .ok = .{
            .samples_taken = all_samples.len,
            .wall_time = wall_time,
            .utime = utime,
            .stime = stime,
            .maxrss = @bitCast(usize, final_rusage.maxrss),
        },
    };
}

pub const Options = struct {
    rusage_who: i32 = std.os.RUSAGE_SELF,
    zig_exe: []const u8,
    clear_zig_cache: bool = false,
};

pub fn main() !void {
    const gpa = if (std.builtin.link_libc) std.heap.c_allocator else std.heap.page_allocator;
    var options: Options = .{
        .zig_exe = std.mem.spanZ(std.os.argv[1]),
    };
    const context = try app.setup(gpa, &options);
    const results = bench(options, app.run, .{ gpa, context });
    try std.json.stringify(results, std.json.StringifyOptions{}, std.io.getStdOut().outStream());
}

pub fn exec(
    gpa: *std.mem.Allocator,
    argv: []const []const u8,
    options: struct {
        cwd: ?[]const u8 = null,
        stdin_behavior: std.ChildProcess.StdIo = .Inherit,
        stdout_behavior: std.ChildProcess.StdIo = .Inherit,
        stderr_behavior: std.ChildProcess.StdIo = .Inherit,
    },
) !void {
    const child = try std.ChildProcess.init(argv, gpa);
    defer child.deinit();

    child.stdin_behavior = options.stdin_behavior;
    child.stdout_behavior = options.stdout_behavior;
    child.stderr_behavior = options.stderr_behavior;
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
