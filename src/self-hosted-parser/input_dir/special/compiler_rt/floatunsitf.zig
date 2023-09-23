const builtin = @import("builtin");
const is_test = builtin.is_test;
const std = @import("std");

pub fn __floatunsitf(a: u32) callconv(.C) f128 {
    @setRuntimeSafety(is_test);

    if (a == 0) {
        return 0;
    }

    const mantissa_bits = std.math.floatMantissaBits(f128);
    const exponent_bits = std.math.floatExponentBits(f128);
    const exponent_bias = (1 << (exponent_bits - 1)) - 1;
    const implicit_bit = 1 << mantissa_bits;

    const exp = (32 - 1) - @clz(a);
    const shift = mantissa_bits - @as(u7, @intCast(exp));

    // TODO(#1148): @bitCast alignment error
    var result align(16) = (@as(u128, @intCast(a)) << shift) ^ implicit_bit;
    result += (@as(u128, @intCast(exp)) + exponent_bias) << mantissa_bits;

    return @as(f128, @bitCast(result));
}

test {
    _ = @import("floatunsitf_test.zig");
}
