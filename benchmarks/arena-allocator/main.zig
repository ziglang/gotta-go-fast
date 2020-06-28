const std = @import("std");
const bench = @import("root");

var rng = std.rand.DefaultPrng.init(0x1234);

pub fn setup(gpa: *std.mem.Allocator, options: *bench.Options) !*std.rand.Random {
    return &rng.random;
}

pub fn run(gpa: *std.mem.Allocator, random: *std.rand.Random) !void {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const sizes =
    // Some few weird sizes
    [_]usize{1} ++
        [_]usize{2} ++
        [_]usize{6} ++
        [_]usize{12} ++
        [_]usize{24} ++
        [_]usize{33} ++
        [_]usize{100} ++
        [_]usize{1000} ++
    // Much more frequent common sizes
        ([_]usize{4} ** 10) ++
        ([_]usize{8} ** 20) ++
        ([_]usize{16} ** 100) ++
        ([_]usize{32} ** 100) ++
        ([_]usize{64} ** 50);

    var i: usize = 0;
    while (i < 10000) : (i += 1) {
        const alloc_size = random.uintAtMostBiased(usize, sizes.len);
        const slice = try arena.allocator.alloc(u8, alloc_size);
        @memset(slice.ptr, 0xff, slice.len);
    }
}
