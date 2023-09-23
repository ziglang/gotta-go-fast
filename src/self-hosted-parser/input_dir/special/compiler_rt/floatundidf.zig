const builtin = @import("builtin");
const std = @import("std");

const twop52: f64 = 0x1.0p52;
const twop84: f64 = 0x1.0p84;
const twop84_plus_twop52: f64 = 0x1.00000001p84;

pub fn __floatundidf(a: u64) callconv(.C) f64 {
    @setRuntimeSafety(builtin.is_test);

    if (a == 0) return 0;

    var high = @as(u64, @bitCast(twop84));
    var low = @as(u64, @bitCast(twop52));

    high |= a >> 32;
    low |= a & 0xFFFFFFFF;

    return (@as(f64, @bitCast(high)) - twop84_plus_twop52) + @as(f64, @bitCast(low));
}

pub fn __aeabi_ul2d(arg: u64) callconv(.AAPCS) f64 {
    @setRuntimeSafety(false);
    return @call(.{ .modifier = .always_inline }, __floatundidf, .{arg});
}

test {
    _ = @import("floatundidf_test.zig");
}
