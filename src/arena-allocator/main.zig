const std = @import("std");
const bench = @import("root");

var rng = std.rand.DefaultPrng.init(0x1234);

pub fn setup(_: std.mem.Allocator, _: *bench.Options) !std.rand.Random {
    return rng.random();
}

pub fn run(gpa: std.mem.Allocator, random: std.rand.Random) !void {
    var arena_state = std.heap.ArenaAllocator.init(gpa);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

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
    while (i < 10_000) : (i += 1) {
        const alloc_size = random.uintAtMostBiased(usize, sizes.len);
        const slice = try arena.alloc(u8, alloc_size);
        @memset(slice, 0xff);
    }
}
