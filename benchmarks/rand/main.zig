const std = @import("std");
const bench = @import("root");

const Rng = std.rand.Xoroshiro128; // DefaultPrng at time of writing

pub fn setup(gpa: *std.mem.Allocator, options: *bench.Options) !void {}

pub fn run(gpa: *std.mem.Allocator, context: void) !void {
    const byte_count = 100_000_000;

    try rawBytes(gpa, byte_count);

    const int_types = .{
        .{ .T = u16, .sum = 49279 },
        .{ .T = u32, .sum = 1728230005 },
        .{ .T = u64, .sum = 8541645926972368502 },
    };

    inline for (int_types) |t| {
        if (integers(t.T, byte_count) != t.sum) @panic("bad sum");
    }
}

fn rawBytes(gpa: *std.mem.Allocator, size: usize) !void {
    var buf = try gpa.alignedAlloc(u8, 8, size);
    defer gpa.free(buf);

    var rng = Rng.init(123456789);
    rng.random.bytes(buf);

    if (buf[size - 1] != 42) @panic("error");
}

/// Generate `size` random bytes in the form of integers.
fn integers(comptime T: type, size: usize) T {
    var res: T = 0;
    var rng = Rng.init(123456789);

    var i = @as(u32, 0);
    while (i < size) : (i += @sizeOf(T)) {
        res +%= rng.random.int(T);
    }

    return res;
}
