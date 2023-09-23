const std = @import("../std.zig");
const math = std.math;
const expect = std.testing.expect;
const maxInt = std.math.maxInt;

// Returns whether x has a normalized representation (i.e. integer part of mantissa is 1).
pub fn isNormal(x: anytype) bool {
    const T = @TypeOf(x);
    switch (T) {
        f16 => {
            const bits = @as(u16, @bitCast(x));
            return (bits + (1 << 10)) & (maxInt(u16) >> 1) >= (1 << 11);
        },
        f32 => {
            const bits = @as(u32, @bitCast(x));
            return (bits + (1 << 23)) & (maxInt(u32) >> 1) >= (1 << 24);
        },
        f64 => {
            const bits = @as(u64, @bitCast(x));
            return (bits + (1 << 52)) & (maxInt(u64) >> 1) >= (1 << 53);
        },
        f128 => {
            const bits = @as(u128, @bitCast(x));
            return (bits + (1 << 112)) & (maxInt(u128) >> 1) >= (1 << 113);
        },
        else => {
            @compileError("isNormal not implemented for " ++ @typeName(T));
        },
    }
}

test "math.isNormal" {
    try expect(!isNormal(math.nan(f16)));
    try expect(!isNormal(math.nan(f32)));
    try expect(!isNormal(math.nan(f64)));
    try expect(!isNormal(math.nan(f128)));
    try expect(!isNormal(@as(f16, 0)));
    try expect(!isNormal(@as(f32, 0)));
    try expect(!isNormal(@as(f64, 0)));
    try expect(!isNormal(@as(f128, 0)));
    try expect(isNormal(@as(f16, 1.0)));
    try expect(isNormal(@as(f32, 1.0)));
    try expect(isNormal(@as(f64, 1.0)));
    try expect(isNormal(@as(f128, 1.0)));
}
