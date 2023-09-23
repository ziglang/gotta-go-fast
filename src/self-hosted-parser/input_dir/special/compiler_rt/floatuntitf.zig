const builtin = @import("builtin");
const is_test = builtin.is_test;
const std = @import("std");
const maxInt = std.math.maxInt;

const LDBL_MANT_DIG = 113;

pub fn __floatuntitf(arg: u128) callconv(.C) f128 {
    @setRuntimeSafety(is_test);

    if (arg == 0)
        return 0.0;

    var a = arg;
    const N: u32 = @sizeOf(u128) * 8;
    const sd = @as(i32, @bitCast(N - @clz(a))); // number of significant digits
    var e: i32 = sd - 1; // exponent
    if (sd > LDBL_MANT_DIG) {
        //  start:  0000000000000000000001xxxxxxxxxxxxxxxxxxxxxxPQxxxxxxxxxxxxxxxxxx
        //  finish: 000000000000000000000000000000000000001xxxxxxxxxxxxxxxxxxxxxxPQR
        //                                                12345678901234567890123456
        //  1 = msb 1 bit
        //  P = bit LDBL_MANT_DIG-1 bits to the right of 1
        //  Q = bit LDBL_MANT_DIG bits to the right of 1
        //  R = "or" of all bits to the right of Q
        switch (sd) {
            LDBL_MANT_DIG + 1 => {
                a <<= 1;
            },
            LDBL_MANT_DIG + 2 => {},
            else => {
                const shift_amt = @as(i32, @bitCast(N + (LDBL_MANT_DIG + 2))) - sd;
                const shift_amt_u7 = @as(u7, @intCast(shift_amt));
                a = (a >> @as(u7, @intCast(sd - (LDBL_MANT_DIG + 2)))) |
                    @intFromBool((a & (@as(u128, maxInt(u128)) >> shift_amt_u7)) != 0);
            },
        }
        // finish
        a |= @intFromBool((a & 4) != 0); // Or P into R
        a += 1; // round - this step may add a significant bit
        a >>= 2; // dump Q and R
        // a is now rounded to LDBL_MANT_DIG or LDBL_MANT_DIG+1 bits
        if ((a & (@as(u128, 1) << LDBL_MANT_DIG)) != 0) {
            a >>= 1;
            e += 1;
        }
        // a is now rounded to LDBL_MANT_DIG bits
    } else {
        a <<= @as(u7, @intCast(LDBL_MANT_DIG - sd));
        // a is now rounded to LDBL_MANT_DIG bits
    }

    const high: u128 = (@as(u64, @intCast((e + 16383))) << 48) | // exponent
        (@as(u64, @truncate(a >> 64)) & 0x0000ffffffffffff); // mantissa-high
    const low = @as(u64, @truncate(a)); // mantissa-low

    return @as(f128, @bitCast(low | (high << 64)));
}

test {
    _ = @import("floatuntitf_test.zig");
}
