const std = @import("std");
const bench = @import("root");

pub fn setup(gpa: *std.mem.Allocator, options: *bench.Options) !void { }

pub fn run(gpa: *std.mem.Allocator, context: void) !void {
    var cache = std.AutoHashMap(u64, u64).init(gpa);
    defer cache.deinit();

    try cache.ensureCapacity(2000000);

    var x: u64 = 0;
    var maxx: u64 = 0;
    var maxl: u64 = 0;
    while (x < 1000000) : (x += 1) {
        const l = length(&cache, x);
        if (l > maxl) {
            maxl = l;
            maxx = x;
        }
    }
    if (maxx != 837799) @panic("bad maxx");
    if (maxl != 524) @panic("bad maxl");
}

fn step(x: u64) u64 {
    if (x & 1 > 0) {
        return 3 * x + 1;
    } else {
        return x / 2;
    }
}

fn length(cache: *std.AutoHashMap(u64, u64), x: u64) u64 {
    if (x <= 1) return 0;
    if (cache.getValue(x)) |e| {
        return e;
    } else {
        const next = step(x);
        const len = 1 + length(cache, next);
        cache.putAssumeCapacityNoClobber(x, len);
        return len;
    }
}
