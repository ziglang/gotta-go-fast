const udivmod = @import("udivmod.zig").udivmod;
const builtin = @import("builtin");

pub fn __divti3(a: i128, b: i128) callconv(.C) i128 {
    @setRuntimeSafety(builtin.is_test);

    const s_a = a >> (128 - 1);
    const s_b = b >> (128 - 1);

    const an = (a ^ s_a) -% s_a;
    const bn = (b ^ s_b) -% s_b;

    const r = udivmod(u128, @as(u128, @bitCast(an)), @as(u128, @bitCast(bn)), null);
    const s = s_a ^ s_b;
    return (@as(i128, @bitCast(r)) ^ s) -% s;
}

const v128 = @import("std").meta.Vector(2, u64);
pub fn __divti3_windows_x86_64(a: v128, b: v128) callconv(.C) v128 {
    return @as(v128, @bitCast(@call(.{ .modifier = .always_inline }, __divti3, .{
        @as(i128, @bitCast(a)),
        @as(i128, @bitCast(b)),
    })));
}

test {
    _ = @import("divti3_test.zig");
}
