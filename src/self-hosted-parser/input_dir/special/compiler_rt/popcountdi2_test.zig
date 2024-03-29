const __popcountdi2 = @import("popcountdi2.zig").__popcountdi2;
const testing = @import("std").testing;

fn naive_popcount(a_param: i64) i32 {
    var a = a_param;
    var r: i32 = 0;
    while (a != 0) : (a = @as(i64, @bitCast(@as(u64, @bitCast(a)) >> 1))) {
        r += @as(i32, @intCast(a & 1));
    }
    return r;
}

fn test__popcountdi2(a: i64) !void {
    const x = __popcountdi2(a);
    const expected = naive_popcount(a);
    try testing.expect(expected == x);
}

test "popcountdi2" {
    try test__popcountdi2(0);
    try test__popcountdi2(1);
    try test__popcountdi2(2);
    try test__popcountdi2(@as(i64, @bitCast(@as(u64, 0xFFFFFFFFFFFFFFFD))));
    try test__popcountdi2(@as(i64, @bitCast(@as(u64, 0xFFFFFFFFFFFFFFFE))));
    try test__popcountdi2(@as(i64, @bitCast(@as(u64, 0xFFFFFFFFFFFFFFFF))));
    // TODO some fuzz testing
}
