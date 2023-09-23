const is_test = @import("builtin").is_test;
const Log2Int = @import("std").math.Log2Int;

pub fn fixuint(comptime fp_t: type, comptime fixuint_t: type, a: fp_t) fixuint_t {
    @setRuntimeSafety(is_test);

    const rep_t = switch (fp_t) {
        f32 => u32,
        f64 => u64,
        f128 => u128,
        else => unreachable,
    };
    const typeWidth = @typeInfo(rep_t).Int.bits;
    const significandBits = switch (fp_t) {
        f32 => 23,
        f64 => 52,
        f128 => 112,
        else => unreachable,
    };
    const exponentBits = (typeWidth - significandBits - 1);
    const signBit = (@as(rep_t, 1) << (significandBits + exponentBits));
    const maxExponent = ((1 << exponentBits) - 1);
    const exponentBias = (maxExponent >> 1);

    const implicitBit = (@as(rep_t, 1) << significandBits);
    const significandMask = (implicitBit - 1);

    // Break a into sign, exponent, significand
    const aRep: rep_t = @as(rep_t, @bitCast(a));
    const absMask = signBit - 1;
    const aAbs: rep_t = aRep & absMask;

    const sign = if ((aRep & signBit) != 0) @as(i32, -1) else @as(i32, 1);
    const exponent = @as(i32, @intCast(aAbs >> significandBits)) - exponentBias;
    const significand: rep_t = (aAbs & significandMask) | implicitBit;

    // If either the value or the exponent is negative, the result is zero.
    if (sign == -1 or exponent < 0) return 0;

    // If the value is too large for the integer type, saturate.
    if (@as(c_uint, @intCast(exponent)) >= @typeInfo(fixuint_t).Int.bits) return ~@as(fixuint_t, 0);

    // If 0 <= exponent < significandBits, right shift to get the result.
    // Otherwise, shift left.
    if (exponent < significandBits) {
        return @as(fixuint_t, @intCast(significand >> @as(Log2Int(rep_t), @intCast(significandBits - exponent))));
    } else {
        return @as(fixuint_t, @intCast(significand)) << @as(Log2Int(fixuint_t), @intCast(exponent - significandBits));
    }
}
