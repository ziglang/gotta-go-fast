const builtin = @import("builtin");
const is_test = builtin.is_test;
const std = @import("std");
const maxInt = std.math.maxInt;

const LDBL_MANT_DIG = 113;

pub fn __floattitf(arg: i128) callconv(.C) f128 {
    @setRuntimeSafety(is_test);

    if (arg == 0)
        return 0.0;

    var ai = arg;
    const N: u32 = 128;
    const si = ai >> @as(u7, @intCast((N - 1)));
    ai = ((ai ^ si) -% si);
    var a = @as(u128, @bitCast(ai));

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
                const shift1_amt = @as(i32, @intCast(sd - (LDBL_MANT_DIG + 2)));
                const shift1_amt_u7 = @as(u7, @intCast(shift1_amt));

                const shift2_amt = @as(i32, @intCast(N + (LDBL_MANT_DIG + 2))) - sd;
                const shift2_amt_u7 = @as(u7, @intCast(shift2_amt));

                a = (a >> shift1_amt_u7) | @intFromBool((a & (@as(u128, @intCast(maxInt(u128))) >> shift2_amt_u7)) != 0);
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

    const s = @as(u128, @bitCast(arg)) >> (128 - 64);
    const high: u128 = (@as(u64, @intCast(s)) & 0x8000000000000000) | // sign
        (@as(u64, @intCast((e + 16383))) << 48) | // exponent
        (@as(u64, @truncate(a >> 64)) & 0x0000ffffffffffff); // mantissa-high
    const low = @as(u64, @truncate(a)); // mantissa-low

    return @as(f128, @bitCast(low | (high << 64)));
}

test {
    _ = @import("floattitf_test.zig");
}
