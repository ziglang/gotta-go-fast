const std = @import("std");
const bench = @import("root");

pub fn setup(gpa: *std.mem.Allocator, options: *bench.Options) !void {}

pub fn run(gpa: *std.mem.Allocator, context: void) !void {
    // Benchmarks ported from https://github.com/martinus/map_benchmark
    insert(gpa);
}

fn insert(gpa: *std.mem.Allocator) void {
    const num_iters = 10_000_000;

    var rng = Sfc64.init(213);

    var map = std.AutoHashMap(i32, i32).init(gpa);

    var i: i32 = 0;
    while (i < num_iters) : (i += 1) {
        const key = @bitCast(i32, @truncate(u32, rng.next()));
        _ = map.put(key, 0) catch unreachable;
    }
    if (map.count() != 9988484) @panic("bad count");

    map.clearRetainingCapacity();

    const state = rng;
    i = 0;
    while (i < num_iters) : (i += 1) {
        const key = @bitCast(i32, @truncate(u32, rng.next()));
        _ = map.put(key, 0) catch unreachable;
    }
    if (map.count() != 9988324) @panic("bad count");

    rng = state;
    i = 0;
    while (i < num_iters) : (i += 1) {
        const key = @bitCast(i32, @truncate(u32, rng.next()));
        _ = map.remove(key);
    }
    if (map.count() != 0) @panic("bad count");

    map.deinit();
}

// Copy of std.rand.Sfc64 with a public next() function. The random API is
// slower than just calling next() and these benchmarks only require getting
// consecutive u64's.
pub const Sfc64 = struct {
    random: std.rand.Random,

    a: u64 = undefined,
    b: u64 = undefined,
    c: u64 = undefined,
    counter: u64 = undefined,

    const Rotation = 24;
    const RightShift = 11;
    const LeftShift = 3;

    pub fn init(init_s: u64) Sfc64 {
        var x = Sfc64{
            .random = std.rand.Random{ .fillFn = fill },
        };

        x.seed(init_s);
        return x;
    }

    pub fn next(self: *Sfc64) u64 {
        const tmp = self.a +% self.b +% self.counter;
        self.counter += 1;
        self.a = self.b ^ (self.b >> RightShift);
        self.b = self.c +% (self.c << LeftShift);
        self.c = std.math.rotl(u64, self.c, Rotation) +% tmp;
        return tmp;
    }

    pub fn seed(self: *Sfc64, init_s: u64) void {
        self.a = init_s;
        self.b = init_s;
        self.c = init_s;
        self.counter = 1;
        var i: u32 = 0;
        while (i < 12) : (i += 1) {
            _ = self.next();
        }
    }

    fn fill(r: *std.rand.Random, buf: []u8) void {
        const self = @fieldParentPtr(Sfc64, "random", r);

        var i: usize = 0;
        const aligned_len = buf.len - (buf.len & 7);

        // Complete 8 byte segments.
        while (i < aligned_len) : (i += 8) {
            var n = self.next();
            comptime var j: usize = 0;
            inline while (j < 8) : (j += 1) {
                buf[i + j] = @truncate(u8, n);
                n >>= 8;
            }
        }

        // Remaining. (cuts the stream)
        if (i != buf.len) {
            var n = self.next();
            while (i < buf.len) : (i += 1) {
                buf[i] = @truncate(u8, n);
                n >>= 8;
            }
        }
    }
};
