const std = @import("std");
const builtin = @import("builtin");
const app = @import("app");
const assert = std.debug.assert;
const PERF = std.os.linux.PERF;
const fd_t = std.os.fd_t;

pub const Measurement = struct {
    median: u64,
    mean: u64,
    min: u64,
    max: u64,

    fn compute(all_samples: []Sample, comptime field: []const u8) Measurement {
        const S = struct {
            fn order(context: void, a: Sample, b: Sample) bool {
                _ = context;
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
        cpu_cycles: Measurement,
        instructions: Measurement,
        cache_references: Measurement,
        cache_misses: Measurement,
        branch_instructions: Measurement,
        branch_misses: Measurement,
        maxrss: usize,
    },
};

const Sample = struct {
    wall_time: u64,
    utime: u64,
    stime: u64,
    cpu_cycles: u64,
    instructions: u64,
    cache_references: u64,
    cache_misses: u64,
    branch_instructions: u64,
    branch_misses: u64,
};

fn timeval_to_ns(timeval: std.os.timeval) u64 {
    const ns_per_us = std.time.ns_per_s / std.time.us_per_s;
    return @bitCast(usize, timeval.tv_sec) * std.time.ns_per_s +
        @bitCast(usize, timeval.tv_usec) * ns_per_us;
}

fn readPerfFd(fd: fd_t) usize {
    var result: usize = 0;
    const n = std.os.read(fd, std.mem.asBytes(&result)) catch |err| {
        std.debug.panic("unable to read perf fd: {s}\n", .{@errorName(err)});
    };
    assert(n == @sizeOf(usize));
    return result;
}

var samples_buf: [1000000]Sample = undefined;
const max_nano_seconds = std.time.ns_per_s * 5;

const PerfMeasurement = struct {
    name: []const u8,
    config: PERF.COUNT.HW,
};

const perf_measurements = [_]PerfMeasurement{
    .{ .name = "cpu_cycles", .config = PERF.COUNT.HW.CPU_CYCLES },
    .{ .name = "instructions", .config = PERF.COUNT.HW.INSTRUCTIONS },
    .{ .name = "cache_references", .config = PERF.COUNT.HW.CACHE_REFERENCES },
    .{ .name = "cache_misses", .config = PERF.COUNT.HW.CACHE_MISSES },
    .{ .name = "branch_instructions", .config = PERF.COUNT.HW.BRANCH_INSTRUCTIONS },
    .{ .name = "branch_misses", .config = PERF.COUNT.HW.BRANCH_MISSES },
};

var perf_fds = [1]fd_t{-1} ** perf_measurements.len;

pub fn bench(options: Options, comptime func: anytype, args: anytype) Results {
    // Set up perf measurements.
    for (perf_measurements) |measurement, i| {
        var attr: std.os.linux.perf_event_attr = .{
            .type = PERF.TYPE.HARDWARE,
            .config = @enumToInt(measurement.config),
            .flags = .{
                .disabled = true,
                .exclude_kernel = true,
                .exclude_hv = true,
            },
            .sample_type = PERF.SAMPLE.READ,
        };
        perf_fds[i] = std.os.perf_event_open(&attr, 0, -1, perf_fds[0], PERF.FLAG.FD_CLOEXEC) catch
            @panic("unable to open perf event");
    }

    var sample_index: usize = 0;
    const timer = std.time.Timer.start() catch @panic("need timer to work");
    const first_start = timer.read();
    while ((sample_index < 3 or
        (timer.read() - first_start) < max_nano_seconds) and
        sample_index < samples_buf.len)
    {
        if (options.clear_zig_cache) {
            std.fs.cwd().deleteTree("zig-cache") catch |err| {
                std.debug.panic("unable to delete zig-cache: {s}", .{@errorName(err)});
            };
        }
        _ = std.os.linux.ioctl(perf_fds[0], PERF.EVENT_IOC.RESET, PERF.IOC_FLAG_GROUP);
        const start_rusage = std.os.getrusage(options.rusage_who);
        const start = timer.read();
        _ = std.os.linux.ioctl(perf_fds[0], PERF.EVENT_IOC.ENABLE, PERF.IOC_FLAG_GROUP);
        const result = @call(.{}, func, args);
        _ = std.os.linux.ioctl(perf_fds[0], PERF.EVENT_IOC.DISABLE, PERF.IOC_FLAG_GROUP);
        const end = timer.read();
        const end_rusage = std.os.getrusage(options.rusage_who);
        result catch |err| {
            return .{ .fail = err };
        };
        samples_buf[sample_index] = .{
            .wall_time = end - start,
            .utime = timeval_to_ns(end_rusage.utime) - timeval_to_ns(start_rusage.utime),
            .stime = timeval_to_ns(end_rusage.stime) - timeval_to_ns(start_rusage.stime),
            .cpu_cycles = readPerfFd(perf_fds[0]),
            .instructions = readPerfFd(perf_fds[1]),
            .cache_references = readPerfFd(perf_fds[2]),
            .cache_misses = readPerfFd(perf_fds[3]),
            .branch_instructions = readPerfFd(perf_fds[4]),
            .branch_misses = readPerfFd(perf_fds[5]),
        };
        sample_index += 1;
    }
    const all_samples = samples_buf[0..sample_index];
    const wall_time = Measurement.compute(all_samples, "wall_time");
    const utime = Measurement.compute(all_samples, "utime");
    const stime = Measurement.compute(all_samples, "stime");
    const cpu_cycles = Measurement.compute(all_samples, "cpu_cycles");
    const instructions = Measurement.compute(all_samples, "instructions");
    const cache_references = Measurement.compute(all_samples, "cache_references");
    const cache_misses = Measurement.compute(all_samples, "cache_misses");
    const branch_instructions = Measurement.compute(all_samples, "branch_instructions");
    const branch_misses = Measurement.compute(all_samples, "branch_misses");

    const final_rusage = std.os.getrusage(options.rusage_who);
    return .{
        .ok = .{
            .samples_taken = all_samples.len,
            .wall_time = wall_time,
            .utime = utime,
            .stime = stime,
            .cpu_cycles = cpu_cycles,
            .instructions = instructions,
            .cache_references = cache_references,
            .cache_misses = cache_misses,
            .branch_instructions = branch_instructions,
            .branch_misses = branch_misses,
            .maxrss = @bitCast(usize, final_rusage.maxrss),
        },
    };
}

pub const Options = struct {
    rusage_who: i32 = std.os.rusage.SELF,
    zig_exe: []const u8,
    clear_zig_cache: bool = false,
};

var general_purpose_allocator: std.heap.GeneralPurposeAllocator(.{}) = .{};

pub fn main() !void {
    const gpa = if (builtin.link_libc) std.heap.c_allocator else &general_purpose_allocator.allocator;
    var options: Options = .{
        .zig_exe = std.mem.spanZ(std.os.argv[1]),
    };
    const context = try app.setup(gpa, &options);
    const results = bench(options, app.run, .{ gpa, context });
    try std.json.stringify(results, std.json.StringifyOptions{}, std.io.getStdOut().writer());
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
