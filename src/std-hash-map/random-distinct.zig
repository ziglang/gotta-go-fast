const std = @import("std");
const bench = @import("root");

pub fn setup(_: std.mem.Allocator, _: *bench.Options) !void {}

pub fn run(gpa: std.mem.Allocator, _: void) !void {
    // Benchmarks ported from https://github.com/martinus/map_benchmark
    randomDistinct(gpa);
}

fn randomDistinct(gpa: std.mem.Allocator) void {
    const num_iters = 5_000_000;
    const _5distinct = num_iters / 20;
    const _25distinct = num_iters / 4;
    const _50distinct = num_iters / 2;

    var rng = Sfc64.init(123);
    var checksum: i32 = 0;

    {
        var map = std.AutoHashMap(i32, i32).init(gpa);
        defer map.deinit();
        var i: u32 = 0;
        while (i < num_iters) : (i += 1) {
            const key = @as(i32, @intCast(rng.random().uintLessThan(u32, _5distinct)));
            var n = map.getOrPutValue(key, 0) catch unreachable;
            n.value_ptr.* += 1;
            checksum += n.value_ptr.*;
        }
        if (checksum != 54_992_517) @panic("bad checksum");
    }

    {
        var map = std.AutoHashMap(i32, i32).init(gpa);
        defer map.deinit();
        checksum = 0;
        var i: u32 = 0;
        while (i < num_iters) : (i += 1) {
            const key = @as(i32, @intCast(rng.random().uintLessThan(u32, _25distinct)));
            var n = map.getOrPutValue(key, 0) catch unreachable;
            n.value_ptr.* += 1;
            checksum += n.value_ptr.*;
        }
        if (checksum != 15_001_972) @panic("bad checksum");
    }

    {
        var map = std.AutoHashMap(i32, i32).init(gpa);
        defer map.deinit();
        checksum = 0;
        var i: u32 = 0;
        while (i < num_iters) : (i += 1) {
            const key = @as(i32, @intCast(rng.random().uintLessThan(u32, _50distinct)));
            var n = map.getOrPutValue(key, 0) catch unreachable;
            n.value_ptr.* += 1;
            checksum += n.value_ptr.*;
        }
        if (checksum != 10_001_436) @panic("bad checksum");
    }

    {
        var map = std.AutoHashMap(i32, i32).init(gpa);
        defer map.deinit();
        checksum = 0;
        var i: u32 = 0;
        while (i < num_iters) : (i += 1) {
            const key = @as(i32, @bitCast(@as(u32, @truncate(rng.next()))));
            var n = map.getOrPutValue(key, 0) catch unreachable;
            n.value_ptr.* += 1;
            checksum += n.value_ptr.*;
        }
        if (checksum != 5_002_904) @panic("bad checksum");
    }
}

// Copy of std.rand.Sfc64 with a public next() function. The random API is
// slower than just calling next() and these benchmarks only require getting
// consecutive u64's.
pub const Sfc64 = struct {
    a: u64 = undefined,
    b: u64 = undefined,
    c: u64 = undefined,
    counter: u64 = undefined,

    const Random = std.rand.Random;
    const math = std.math;

    const Rotation = 24;
    const RightShift = 11;
    const LeftShift = 3;

    pub fn init(init_s: u64) Sfc64 {
        var x = Sfc64{};

        x.seed(init_s);
        return x;
    }

    pub fn random(self: *Sfc64) Random {
        return Random.init(self, fill);
    }

    pub fn next(self: *Sfc64) u64 {
        const tmp = self.a +% self.b +% self.counter;
        self.counter += 1;
        self.a = self.b ^ (self.b >> RightShift);
        self.b = self.c +% (self.c << LeftShift);
        self.c = math.rotl(u64, self.c, Rotation) +% tmp;
        return tmp;
    }

    fn seed(self: *Sfc64, init_s: u64) void {
        self.a = init_s;
        self.b = init_s;
        self.c = init_s;
        self.counter = 1;
        var i: u32 = 0;
        while (i < 12) : (i += 1) {
            _ = self.next();
        }
    }

    pub fn fill(self: *Sfc64, buf: []u8) void {
        var i: usize = 0;
        const aligned_len = buf.len - (buf.len & 7);

        // Complete 8 byte segments.
        while (i < aligned_len) : (i += 8) {
            var n = self.next();
            comptime var j: usize = 0;
            inline while (j < 8) : (j += 1) {
                buf[i + j] = @as(u8, @truncate(n));
                n >>= 8;
            }
        }

        // Remaining. (cuts the stream)
        if (i != buf.len) {
            var n = self.next();
            while (i < buf.len) : (i += 1) {
                buf[i] = @as(u8, @truncate(n));
                n >>= 8;
            }
        }
    }
};
