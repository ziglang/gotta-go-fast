const __lshrti3 = @import("shift.zig").__lshrti3;
const testing = @import("std").testing;

fn test__lshrti3(a: i128, b: i32, expected: i128) !void {
    const x = __lshrti3(a, b);
    try testing.expectEqual(expected, x);
}

test "lshrti3" {
    try test__lshrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 0, @as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))));
    try test__lshrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 1, @as(i128, @bitCast(@as(u128, @intCast(0x7F6E5D4C3B2A190AFF6E5D4C3B2A190A)))));
    try test__lshrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 2, @as(i128, @bitCast(@as(u128, @intCast(0x3FB72EA61D950C857FB72EA61D950C85)))));
    try test__lshrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 3, @as(i128, @bitCast(@as(u128, @intCast(0x1FDB97530ECA8642BFDB97530ECA8642)))));
    try test__lshrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 4, @as(i128, @bitCast(@as(u128, @intCast(0x0FEDCBA9876543215FEDCBA987654321)))));
    try test__lshrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 28, @as(i128, @bitCast(@as(u128, @intCast(0x0000000FEDCBA9876543215FEDCBA987)))));
    try test__lshrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 29, @as(i128, @bitCast(@as(u128, @intCast(0x00000007F6E5D4C3B2A190AFF6E5D4C3)))));
    try test__lshrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 30, @as(i128, @bitCast(@as(u128, @intCast(0x00000003FB72EA61D950C857FB72EA61)))));
    try test__lshrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 31, @as(i128, @bitCast(@as(u128, @intCast(0x00000001FDB97530ECA8642BFDB97530)))));
    try test__lshrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 32, @as(i128, @bitCast(@as(u128, @intCast(0x00000000FEDCBA9876543215FEDCBA98)))));
    try test__lshrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 33, @as(i128, @bitCast(@as(u128, @intCast(0x000000007F6E5D4C3B2A190AFF6E5D4C)))));
    try test__lshrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 34, @as(i128, @bitCast(@as(u128, @intCast(0x000000003FB72EA61D950C857FB72EA6)))));
    try test__lshrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 35, @as(i128, @bitCast(@as(u128, @intCast(0x000000001FDB97530ECA8642BFDB9753)))));
    try test__lshrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 36, @as(i128, @bitCast(@as(u128, @intCast(0x000000000FEDCBA9876543215FEDCBA9)))));
    try test__lshrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 60, @as(i128, @bitCast(@as(u128, @intCast(0x000000000000000FEDCBA9876543215F)))));
    try test__lshrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 61, @as(i128, @bitCast(@as(u128, @intCast(0x0000000000000007F6E5D4C3B2A190AF)))));
    try test__lshrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 62, @as(i128, @bitCast(@as(u128, @intCast(0x0000000000000003FB72EA61D950C857)))));
    try test__lshrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 63, @as(i128, @bitCast(@as(u128, @intCast(0x0000000000000001FDB97530ECA8642B)))));
    try test__lshrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 64, @as(i128, @bitCast(@as(u128, @intCast(0x0000000000000000FEDCBA9876543215)))));
    try test__lshrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 65, @as(i128, @bitCast(@as(u128, @intCast(0x00000000000000007F6E5D4C3B2A190A)))));
    try test__lshrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 66, @as(i128, @bitCast(@as(u128, @intCast(0x00000000000000003FB72EA61D950C85)))));
    try test__lshrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 67, @as(i128, @bitCast(@as(u128, @intCast(0x00000000000000001FDB97530ECA8642)))));
    try test__lshrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 68, @as(i128, @bitCast(@as(u128, @intCast(0x00000000000000000FEDCBA987654321)))));
    try test__lshrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 92, @as(i128, @bitCast(@as(u128, @intCast(0x00000000000000000000000FEDCBA987)))));
    try test__lshrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 93, @as(i128, @bitCast(@as(u128, @intCast(0x000000000000000000000007F6E5D4C3)))));
    try test__lshrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 94, @as(i128, @bitCast(@as(u128, @intCast(0x000000000000000000000003FB72EA61)))));
    try test__lshrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 95, @as(i128, @bitCast(@as(u128, @intCast(0x000000000000000000000001FDB97530)))));
    try test__lshrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 96, @as(i128, @bitCast(@as(u128, @intCast(0x000000000000000000000000FEDCBA98)))));
    try test__lshrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 97, @as(i128, @bitCast(@as(u128, @intCast(0x0000000000000000000000007F6E5D4C)))));
    try test__lshrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 98, @as(i128, @bitCast(@as(u128, @intCast(0x0000000000000000000000003FB72EA6)))));
    try test__lshrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 99, @as(i128, @bitCast(@as(u128, @intCast(0x0000000000000000000000001FDB9753)))));
    try test__lshrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 100, @as(i128, @bitCast(@as(u128, @intCast(0x0000000000000000000000000FEDCBA9)))));
    try test__lshrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 124, @as(i128, @bitCast(@as(u128, @intCast(0x0000000000000000000000000000000F)))));
    try test__lshrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 125, @as(i128, @bitCast(@as(u128, @intCast(0x00000000000000000000000000000007)))));
    try test__lshrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 126, @as(i128, @bitCast(@as(u128, @intCast(0x00000000000000000000000000000003)))));
    try test__lshrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 127, @as(i128, @bitCast(@as(u128, @intCast(0x00000000000000000000000000000001)))));
}
