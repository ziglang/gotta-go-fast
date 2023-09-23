const std = @import("std");
const bench = @import("root");

const Rng = std.rand.Xoroshiro128;

pub fn setup(_: std.mem.Allocator, _: *bench.Options) !void {}

pub fn run(gpa: std.mem.Allocator, _: void) !void {
    const byte_count = 100_000_000;

    try rawBytes(gpa, byte_count);

    const int_types = .{
        .{ .T = u16, .sum = 49_279 },
        .{ .T = u32, .sum = 1_728_230_005 },
        .{ .T = u64, .sum = 8_541_645_926_972_368_502 },
    };

    inline for (int_types) |t| {
        if (integers(t.T, byte_count) != t.sum) @panic("bad sum");
    }
}

fn rawBytes(gpa: std.mem.Allocator, size: usize) !void {
    var buf = try gpa.alignedAlloc(u8, 8, size);
    defer gpa.free(buf);

    var rng = Rng.init(123_456_789);
    const random = rng.random();
    random.bytes(buf);

    if (buf[size - 1] != 42) @panic("error");
}

fn integers(comptime T: type, size: usize) T {
    var res: T = 0;
    var rng = Rng.init(123_456_789);
    const random = rng.random();

    var i = @as(u32, 0);
    while (i < size) : (i += @sizeOf(T)) {
        res +%= random.int(T);
    }

    return res;
}
