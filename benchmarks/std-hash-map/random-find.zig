const std = @import("std");
const bench = @import("root");

pub fn setup(gpa: *std.mem.Allocator, options: *bench.Options) !void {
    _ = gpa;
    _ = options;
}

pub fn run(gpa: *std.mem.Allocator, context: void) !void {
    _ = context;
    // Benchmarks ported from https://github.com/martinus/map_benchmark
    const lower32bit = 0x00000000FFFFFFFF;
    const upper32bit = 0xFFFFFFFF00000000;
    const num_inserts = 2000;
    const find_per_insert = 50_000;
    randomFind(gpa, 4, lower32bit, num_inserts, find_per_insert, 0);
    randomFind(gpa, 4, upper32bit, num_inserts, find_per_insert, 0);
    randomFind(gpa, 3, lower32bit, num_inserts, find_per_insert, 24919456);
    randomFind(gpa, 3, upper32bit, num_inserts, find_per_insert, 24919456);
    randomFind(gpa, 2, lower32bit, num_inserts, find_per_insert, 49838914);
    randomFind(gpa, 2, upper32bit, num_inserts, find_per_insert, 49838914);
    randomFind(gpa, 1, lower32bit, num_inserts, find_per_insert, 74758370);
    randomFind(gpa, 1, upper32bit, num_inserts, find_per_insert, 74758370);
    randomFind(gpa, 0, lower32bit, num_inserts, find_per_insert, 99677826);
    randomFind(gpa, 0, upper32bit, num_inserts, find_per_insert, 99677826);
}

fn randomFind(gpa: *std.mem.Allocator, num_rand: u32, mask: u64, num_insert: u64, find_per_insert: u64, expected: u64) void {
    const total = 4;

    const find_per_iter = find_per_insert * total;

    var rng = Sfc64.init(123);

    var num_found: u64 = 0;
    var insert_random = [_]bool{false} ** 4;
    for (insert_random[0..num_rand]) |*b| b.* = true;

    var other_rng = Sfc64.init(987654321);
    const state = other_rng;
    var find_rng = state;

    {
        var map = std.AutoHashMap(u64, u64).init(gpa);
        var i: u64 = 0;
        var find_count: u64 = 0;

        while (i < num_insert) {
            // insert NumTotal entries: some random, some sequential.
            std.rand.Random.shuffle(rng.random(), bool, insert_random[0..]);
            for (insert_random) |isRandomToInsert| {
                const val = other_rng.next();
                if (isRandomToInsert) {
                    _ = map.put(rng.next() & mask, 1) catch unreachable;
                } else {
                    _ = map.put(val & mask, 1) catch unreachable;
                }
                i += 1;
            }

            var j: u64 = 0;
            while (j < find_per_iter) : (j += 1) {
                find_count += 1;
                if (find_count > i) {
                    find_count = 0;
                    find_rng = state;
                }
                const key = find_rng.next() & mask;
                if (map.get(key)) |val| num_found += val;
            }
        }

        if (expected != num_found) @panic("bad result");
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
