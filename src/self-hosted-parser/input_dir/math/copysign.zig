// Ported from musl, which is licensed under the MIT license:
// https://git.musl-libc.org/cgit/musl/tree/COPYRIGHT
//
// https://git.musl-libc.org/cgit/musl/tree/src/math/copysignf.c
// https://git.musl-libc.org/cgit/musl/tree/src/math/copysign.c

const std = @import("../std.zig");
const math = std.math;
const expect = std.testing.expect;
const maxInt = std.math.maxInt;

/// Returns a value with the magnitude of x and the sign of y.
pub fn copysign(comptime T: type, x: T, y: T) T {
    return switch (T) {
        f16 => copysign16(x, y),
        f32 => copysign32(x, y),
        f64 => copysign64(x, y),
        f128 => copysign128(x, y),
        else => @compileError("copysign not implemented for " ++ @typeName(T)),
    };
}

fn copysign16(x: f16, y: f16) f16 {
    const ux = @as(u16, @bitCast(x));
    const uy = @as(u16, @bitCast(y));

    const h1 = ux & (maxInt(u16) / 2);
    const h2 = uy & (@as(u16, 1) << 15);
    return @as(f16, @bitCast(h1 | h2));
}

fn copysign32(x: f32, y: f32) f32 {
    const ux = @as(u32, @bitCast(x));
    const uy = @as(u32, @bitCast(y));

    const h1 = ux & (maxInt(u32) / 2);
    const h2 = uy & (@as(u32, 1) << 31);
    return @as(f32, @bitCast(h1 | h2));
}

fn copysign64(x: f64, y: f64) f64 {
    const ux = @as(u64, @bitCast(x));
    const uy = @as(u64, @bitCast(y));

    const h1 = ux & (maxInt(u64) / 2);
    const h2 = uy & (@as(u64, 1) << 63);
    return @as(f64, @bitCast(h1 | h2));
}

fn copysign128(x: f128, y: f128) f128 {
    const ux = @as(u128, @bitCast(x));
    const uy = @as(u128, @bitCast(y));

    const h1 = ux & (maxInt(u128) / 2);
    const h2 = uy & (@as(u128, 1) << 127);
    return @as(f128, @bitCast(h1 | h2));
}

test "math.copysign" {
    try expect(copysign(f16, 1.0, 1.0) == copysign16(1.0, 1.0));
    try expect(copysign(f32, 1.0, 1.0) == copysign32(1.0, 1.0));
    try expect(copysign(f64, 1.0, 1.0) == copysign64(1.0, 1.0));
    try expect(copysign(f128, 1.0, 1.0) == copysign128(1.0, 1.0));
}

test "math.copysign16" {
    try expect(copysign16(5.0, 1.0) == 5.0);
    try expect(copysign16(5.0, -1.0) == -5.0);
    try expect(copysign16(-5.0, -1.0) == -5.0);
    try expect(copysign16(-5.0, 1.0) == 5.0);
}

test "math.copysign32" {
    try expect(copysign32(5.0, 1.0) == 5.0);
    try expect(copysign32(5.0, -1.0) == -5.0);
    try expect(copysign32(-5.0, -1.0) == -5.0);
    try expect(copysign32(-5.0, 1.0) == 5.0);
}

test "math.copysign64" {
    try expect(copysign64(5.0, 1.0) == 5.0);
    try expect(copysign64(5.0, -1.0) == -5.0);
    try expect(copysign64(-5.0, -1.0) == -5.0);
    try expect(copysign64(-5.0, 1.0) == 5.0);
}

test "math.copysign128" {
    try expect(copysign128(5.0, 1.0) == 5.0);
    try expect(copysign128(5.0, -1.0) == -5.0);
    try expect(copysign128(-5.0, -1.0) == -5.0);
    try expect(copysign128(-5.0, 1.0) == 5.0);
}
