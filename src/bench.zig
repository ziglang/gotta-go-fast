const std = @import("std");
const app = @import("app");

const NUM_SAMPLES = 1_000_000;
const MAX_NS = std.time.ns_per_s * 5;

var SAMPLES_BUF: [NUM_SAMPLES]Sample = undefined;
var PERF_FDS = [1]std.os.fd_t{-1} ** PERF_MEASUREMENTS.len;

const PERF_MEASUREMENTS = [_]PerfMeasurement{
    .{ .name = "cpu_cycles", .config = std.os.linux.PERF.COUNT.HW.CPU_CYCLES },
    .{ .name = "instructions", .config = std.os.linux.PERF.COUNT.HW.INSTRUCTIONS },
    .{ .name = "cache_references", .config = std.os.linux.PERF.COUNT.HW.CACHE_REFERENCES },
    .{ .name = "cache_misses", .config = std.os.linux.PERF.COUNT.HW.CACHE_MISSES },
    .{ .name = "branch_misses", .config = std.os.linux.PERF.COUNT.HW.BRANCH_MISSES },
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) {
        @panic("Memory leak has occurred!\n");
    };

    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const allocator = arena.allocator();

    const zig_exe = std.mem.sliceTo(std.os.argv[1], 0);
    const zig_src_root = zig_exe[0 .. std.mem.indexOf(u8, zig_exe, "zig/").? + 3];

    var options = Options{ .zig_exe = zig_exe, .zig_src_root = zig_src_root };
    const context = try app.setup(allocator, &options);

    const results = bench(options, app.run, .{ allocator, context });
    try std.json.stringify(results, std.json.StringifyOptions{}, std.io.getStdOut().writer());
}

const PerfMeasurement = struct {
    name: []const u8,
    config: std.os.linux.PERF.COUNT.HW,
};

pub const Measurement = struct {
    median: u64,
    mean: u64,
    min: u64,
    max: u64,

    fn compute(all_samples: []Sample, comptime field: []const u8) Measurement {
        std.sort.block(Sample, all_samples, {}, Sample.order);
        const samples = all_samples[1 .. all_samples.len - 1];
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
    branch_misses: u64,

    fn order(_: void, a: Sample, b: Sample) bool {
        return a.wall_time < b.wall_time;
    }
};

pub const Options = struct {
    zig_exe: []const u8,
    zig_src_root: []const u8,
    clear_zig_cache: bool = false,
    use_child_process: bool = false,

    pub fn useChildProcess(options: *Options) void {
        options.use_child_process = true;
    }
};

fn timevalToNs(tv: std.os.timeval) u64 {
    const ns_per_us = std.time.ns_per_s / std.time.us_per_s;
    return @as(usize, @bitCast(tv.tv_sec)) * std.time.ns_per_s + @as(usize, @bitCast(tv.tv_usec)) * ns_per_us;
}

fn readPerfFd(fd: std.os.fd_t) usize {
    var result: usize = 0;
    const n = std.os.read(fd, std.mem.asBytes(&result)) catch |err| {
        std.debug.panic("unable to read perf fd: {s}\n", .{@errorName(err)});
    };
    std.debug.assert(n == @sizeOf(usize));
    return result;
}

pub fn bench(options: Options, comptime func: anytype, args: anytype) Results {
    const rusage_who: i32 = if (options.use_child_process) std.os.rusage.CHILDREN else std.os.rusage.SELF;
    var sample_idx: usize = 0;
    var timer = std.time.Timer.start() catch @panic("need timer to work");
    const first_start = timer.read();
    while (sample_idx < NUM_SAMPLES and (sample_idx < 3 or (timer.read() - first_start) < MAX_NS)) : (sample_idx += 1) {
        for (PERF_MEASUREMENTS, 0..) |measurement, i| {
            var attr: std.os.linux.perf_event_attr = .{
                .type = std.os.linux.PERF.TYPE.HARDWARE,
                .config = @intFromEnum(measurement.config),
                .flags = if (options.use_child_process) .{
                    .disabled = true,
                    .exclude_kernel = true,
                    .exclude_hv = true,
                    .inherit = true,
                    .enable_on_exec = true,
                } else .{
                    .disabled = true,
                    .exclude_kernel = true,
                    .exclude_hv = true,
                },
            };
            PERF_FDS[i] = std.os.perf_event_open(&attr, 0, -1, PERF_FDS[0], std.os.linux.PERF.FLAG.FD_CLOEXEC) catch |err| {
                std.debug.panic("unable to open perf event: {s}\n", .{@errorName(err)});
            };
        }
        if (options.clear_zig_cache) {
            std.fs.cwd().deleteTree("zig-cache") catch |err| {
                std.debug.panic("unable to delete zig-cache: {s}", .{@errorName(err)});
            };
        }
        if (options.use_child_process) {
            _ = std.os.linux.ioctl(PERF_FDS[0], std.os.linux.PERF.EVENT_IOC.DISABLE, std.os.linux.PERF.IOC_FLAG_GROUP);
        }
        _ = std.os.linux.ioctl(PERF_FDS[0], std.os.linux.PERF.EVENT_IOC.RESET, std.os.linux.PERF.IOC_FLAG_GROUP);
        const start_rusage = std.os.getrusage(rusage_who);
        const start = timer.read();
        if (!options.use_child_process) {
            _ = std.os.linux.ioctl(PERF_FDS[0], std.os.linux.PERF.EVENT_IOC.ENABLE, std.os.linux.PERF.IOC_FLAG_GROUP);
        }
        const result = @call(.auto, func, args);
        _ = std.os.linux.ioctl(PERF_FDS[0], std.os.linux.PERF.EVENT_IOC.DISABLE, std.os.linux.PERF.IOC_FLAG_GROUP);
        const end = timer.read();
        const end_rusage = std.os.getrusage(rusage_who);
        result catch |err| {
            return .{ .fail = err };
        };
        SAMPLES_BUF[sample_idx] = .{
            .wall_time = end - start,
            .utime = timevalToNs(end_rusage.utime) - timevalToNs(start_rusage.utime),
            .stime = timevalToNs(end_rusage.stime) - timevalToNs(start_rusage.stime),
            .cpu_cycles = readPerfFd(PERF_FDS[0]),
            .instructions = readPerfFd(PERF_FDS[1]),
            .cache_references = readPerfFd(PERF_FDS[2]),
            .cache_misses = readPerfFd(PERF_FDS[3]),
            .branch_misses = readPerfFd(PERF_FDS[4]),
        };
        for (PERF_MEASUREMENTS, 0..) |_, i| {
            std.os.close(PERF_FDS[i]);
            PERF_FDS[i] = -1;
        }
    }
    const all_samples = SAMPLES_BUF[0..sample_idx];
    const wall_time = Measurement.compute(all_samples, "wall_time");
    const utime = Measurement.compute(all_samples, "utime");
    const stime = Measurement.compute(all_samples, "stime");
    const cpu_cycles = Measurement.compute(all_samples, "cpu_cycles");
    const instructions = Measurement.compute(all_samples, "instructions");
    const cache_references = Measurement.compute(all_samples, "cache_references");
    const cache_misses = Measurement.compute(all_samples, "cache_misses");
    const branch_misses = Measurement.compute(all_samples, "branch_misses");

    const final_rusage = std.os.getrusage(rusage_who);
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
            .branch_misses = branch_misses,
            .maxrss = @as(usize, @bitCast(final_rusage.maxrss)),
        },
    };
}

pub fn exec(
    gpa: std.mem.Allocator,
    argv: []const []const u8,
    options: struct {
        cwd: ?[]const u8 = null,
        stdin_behavior: std.ChildProcess.StdIo = .Inherit,
        stdout_behavior: std.ChildProcess.StdIo = .Inherit,
        stderr_behavior: std.ChildProcess.StdIo = .Inherit,
    },
) !void {
    var child = std.ChildProcess.init(argv, gpa);
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
