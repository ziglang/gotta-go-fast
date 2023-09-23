const builtin = @import("builtin");
const std = @import("std");
const maxInt = std.math.maxInt;

const FLT_MANT_DIG = 24;

fn __floatXisf(comptime T: type, arg: T) f32 {
    @setRuntimeSafety(builtin.is_test);

    const bits = @typeInfo(T).Int.bits;
    const Z = std.meta.Int(.unsigned, bits);
    const S = std.meta.Int(.unsigned, bits - @clz(@as(Z, bits) - 1));

    if (arg == 0) {
        return @as(f32, 0.0);
    }

    var ai = arg;
    const N: u32 = bits;
    const si = ai >> @as(S, @intCast((N - 1)));
    ai = ((ai ^ si) -% si);
    var a = @as(Z, @bitCast(ai));

    const sd = @as(i32, @bitCast(N - @clz(a))); // number of significant digits
    var e: i32 = sd - 1; // exponent

    if (sd > FLT_MANT_DIG) {
        //  start:  0000000000000000000001xxxxxxxxxxxxxxxxxxxxxxPQxxxxxxxxxxxxxxxxxx
        //  finish: 000000000000000000000000000000000000001xxxxxxxxxxxxxxxxxxxxxxPQR
        //                                                12345678901234567890123456
        //  1 = msb 1 bit
        //  P = bit FLT_MANT_DIG-1 bits to the right of 1
        //  Q = bit FLT_MANT_DIG bits to the right of 1
        //  R = "or" of all bits to the right of Q
        switch (sd) {
            FLT_MANT_DIG + 1 => {
                a <<= 1;
            },
            FLT_MANT_DIG + 2 => {},
            else => {
                const shift1_amt = @as(i32, @intCast(sd - (FLT_MANT_DIG + 2)));
                const shift1_amt_u7 = @as(S, @intCast(shift1_amt));

                const shift2_amt = @as(i32, @intCast(N + (FLT_MANT_DIG + 2))) - sd;
                const shift2_amt_u7 = @as(S, @intCast(shift2_amt));

                a = (a >> shift1_amt_u7) | @intFromBool((a & (@as(Z, @intCast(maxInt(Z))) >> shift2_amt_u7)) != 0);
            },
        }
        // finish
        a |= @intFromBool((a & 4) != 0); // Or P into R
        a += 1; // round - this step may add a significant bit
        a >>= 2; // dump Q and R
        // a is now rounded to FLT_MANT_DIG or FLT_MANT_DIG+1 bits
        if ((a & (@as(Z, 1) << FLT_MANT_DIG)) != 0) {
            a >>= 1;
            e += 1;
        }
        // a is now rounded to FLT_MANT_DIG bits
    } else {
        a <<= @as(S, @intCast(FLT_MANT_DIG - sd));
        // a is now rounded to FLT_MANT_DIG bits
    }

    const s = @as(Z, @bitCast(arg)) >> (@typeInfo(T).Int.bits - 32);
    const r = (@as(u32, @intCast(s)) & 0x80000000) | // sign
        (@as(u32, @intCast((e + 127))) << 23) | // exponent
        (@as(u32, @truncate(a)) & 0x007fffff); // mantissa-high

    return @as(f32, @bitCast(r));
}

pub fn __floatdisf(arg: i64) callconv(.C) f32 {
    @setRuntimeSafety(builtin.is_test);
    return @call(.{ .modifier = .always_inline }, __floatXisf, .{ i64, arg });
}

pub fn __floattisf(arg: i128) callconv(.C) f32 {
    @setRuntimeSafety(builtin.is_test);
    return @call(.{ .modifier = .always_inline }, __floatXisf, .{ i128, arg });
}

pub fn __aeabi_l2f(arg: i64) callconv(.AAPCS) f32 {
    @setRuntimeSafety(false);
    return @call(.{ .modifier = .always_inline }, __floatdisf, .{arg});
}

test {
    _ = @import("floattisf_test.zig");
}
test {
    _ = @import("floattisf_test.zig");
}
