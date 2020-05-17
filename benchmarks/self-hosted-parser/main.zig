const std = @import("std");

pub const Measurement = struct {
    median: u64,
    mean: u64,
    min: u64,
    max: u64,

    fn compute(all_samples: []Sample, comptime field: []const u8) Measurement {
        const S = struct {
            fn order(a: Sample, b: Sample) bool {
                return @field(a, field) < @field(b, field);
            }
        };
        // Remove the 2 outliers
        std.sort.sort(Sample, all_samples, S.order);
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

pub fn bench(comptime func: var, args: var) Results {
    var samples_buf: [100000]Sample = undefined;
    var sample_index: usize = 0;
    const timer = std.time.Timer.start() catch @panic("need timer to work");
    const first_start = timer.read();
    while ((sample_index < 3 or
        (timer.read() - first_start) < std.time.ns_per_s * 5) and
        sample_index < samples_buf.len)
    {
        const start_rusage = std.os.getrusage(std.os.RUSAGE_SELF);
        const start = timer.read();
        @call(.{}, func, args) catch |err| {
            return .{ .fail = err };
        };
        const end = timer.read();
        const end_rusage = std.os.getrusage(std.os.RUSAGE_SELF);
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

    const final_rusage = std.os.getrusage(std.os.RUSAGE_SELF);
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

pub fn main() !void {
    const gpa = if (std.builtin.link_libc) std.heap.c_allocator else std.heap.page_allocator;
    //try run(gpa);
    const results = bench(run, .{gpa});
    std.debug.warn("results={}\n", .{results});
}

pub fn run(gpa: *std.mem.Allocator) !void {
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
