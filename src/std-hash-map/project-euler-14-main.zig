const std = @import("std");
const bench = @import("root");

pub fn setup(_: std.mem.Allocator, _: *bench.Options) !void {}

pub fn run(gpa: std.mem.Allocator, _: void) !void {
    var cache = std.AutoHashMap(u64, u64).init(gpa);
    defer cache.deinit();

    try cache.ensureTotalCapacity(2_050_000);

    var x: u64 = 0;
    var maxx: u64 = 0;
    var maxl: u64 = 0;
    while (x < 1_000_000) : (x += 1) {
        const l = length(&cache, x);
        if (l > maxl) {
            maxl = l;
            maxx = x;
        }
    }
    if (maxx != 837_799) @panic("bad maxx");
    if (maxl != 524) @panic("bad maxl");

    {
        var total: u64 = 0;
        var it = cache.iterator();
        while (it.next()) |item| {
            total +%= item.key_ptr.*;
            total +%= item.value_ptr.*;
        }
        if (total != 1_238_720_324_0855) @panic("bad total");
    }
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
    if (cache.get(x)) |e| {
        return e;
    } else {
        const next = step(x);
        const len = 1 + length(cache, next);
        cache.putAssumeCapacityNoClobber(x, len);
        return len;
    }
}
