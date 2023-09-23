const __ashrti3 = @import("shift.zig").__ashrti3;
const testing = @import("std").testing;

fn test__ashrti3(a: i128, b: i32, expected: i128) !void {
    const x = __ashrti3(a, b);
    try testing.expectEqual(expected, x);
}

test "ashrti3" {
    try test__ashrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 0, @as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))));
    try test__ashrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 1, @as(i128, @bitCast(@as(u128, @intCast(0xFF6E5D4C3B2A190AFF6E5D4C3B2A190A)))));
    try test__ashrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 2, @as(i128, @bitCast(@as(u128, @intCast(0xFFB72EA61D950C857FB72EA61D950C85)))));
    try test__ashrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 3, @as(i128, @bitCast(@as(u128, @intCast(0xFFDB97530ECA8642BFDB97530ECA8642)))));
    try test__ashrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 4, @as(i128, @bitCast(@as(u128, @intCast(0xFFEDCBA9876543215FEDCBA987654321)))));

    try test__ashrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 28, @as(i128, @bitCast(@as(u128, @intCast(0xFFFFFFFFEDCBA9876543215FEDCBA987)))));
    try test__ashrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 29, @as(i128, @bitCast(@as(u128, @intCast(0xFFFFFFFFF6E5D4C3B2A190AFF6E5D4C3)))));
    try test__ashrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 30, @as(i128, @bitCast(@as(u128, @intCast(0xFFFFFFFFFB72EA61D950C857FB72EA61)))));
    try test__ashrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 31, @as(i128, @bitCast(@as(u128, @intCast(0xFFFFFFFFFDB97530ECA8642BFDB97530)))));

    try test__ashrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 32, @as(i128, @bitCast(@as(u128, @intCast(0xFFFFFFFFFEDCBA9876543215FEDCBA98)))));

    try test__ashrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 33, @as(i128, @bitCast(@as(u128, @intCast(0xFFFFFFFFFF6E5D4C3B2A190AFF6E5D4C)))));
    try test__ashrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 34, @as(i128, @bitCast(@as(u128, @intCast(0xFFFFFFFFFFB72EA61D950C857FB72EA6)))));
    try test__ashrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 35, @as(i128, @bitCast(@as(u128, @intCast(0xFFFFFFFFFFDB97530ECA8642BFDB9753)))));
    try test__ashrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 36, @as(i128, @bitCast(@as(u128, @intCast(0xFFFFFFFFFFEDCBA9876543215FEDCBA9)))));

    try test__ashrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 60, @as(i128, @bitCast(@as(u128, @intCast(0xFFFFFFFFFFFFFFFFEDCBA9876543215F)))));
    try test__ashrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 61, @as(i128, @bitCast(@as(u128, @intCast(0xFFFFFFFFFFFFFFFFF6E5D4C3B2A190AF)))));
    try test__ashrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 62, @as(i128, @bitCast(@as(u128, @intCast(0xFFFFFFFFFFFFFFFFFB72EA61D950C857)))));
    try test__ashrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 63, @as(i128, @bitCast(@as(u128, @intCast(0xFFFFFFFFFFFFFFFFFDB97530ECA8642B)))));

    try test__ashrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 64, @as(i128, @bitCast(@as(u128, @intCast(0xFFFFFFFFFFFFFFFFFEDCBA9876543215)))));

    try test__ashrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 65, @as(i128, @bitCast(@as(u128, @intCast(0xFFFFFFFFFFFFFFFFFF6E5D4C3B2A190A)))));
    try test__ashrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 66, @as(i128, @bitCast(@as(u128, @intCast(0xFFFFFFFFFFFFFFFFFFB72EA61D950C85)))));
    try test__ashrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 67, @as(i128, @bitCast(@as(u128, @intCast(0xFFFFFFFFFFFFFFFFFFDB97530ECA8642)))));
    try test__ashrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 68, @as(i128, @bitCast(@as(u128, @intCast(0xFFFFFFFFFFFFFFFFFFEDCBA987654321)))));

    try test__ashrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 92, @as(i128, @bitCast(@as(u128, @intCast(0xFFFFFFFFFFFFFFFFFFFFFFFFEDCBA987)))));
    try test__ashrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 93, @as(i128, @bitCast(@as(u128, @intCast(0xFFFFFFFFFFFFFFFFFFFFFFFFF6E5D4C3)))));
    try test__ashrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 94, @as(i128, @bitCast(@as(u128, @intCast(0xFFFFFFFFFFFFFFFFFFFFFFFFFB72EA61)))));
    try test__ashrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 95, @as(i128, @bitCast(@as(u128, @intCast(0xFFFFFFFFFFFFFFFFFFFFFFFFFDB97530)))));

    try test__ashrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 96, @as(i128, @bitCast(@as(u128, @intCast(0xFFFFFFFFFFFFFFFFFFFFFFFFFEDCBA98)))));

    try test__ashrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 97, @as(i128, @bitCast(@as(u128, @intCast(0xFFFFFFFFFFFFFFFFFFFFFFFFFF6E5D4C)))));
    try test__ashrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 98, @as(i128, @bitCast(@as(u128, @intCast(0xFFFFFFFFFFFFFFFFFFFFFFFFFFB72EA6)))));
    try test__ashrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 99, @as(i128, @bitCast(@as(u128, @intCast(0xFFFFFFFFFFFFFFFFFFFFFFFFFFDB9753)))));
    try test__ashrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 100, @as(i128, @bitCast(@as(u128, @intCast(0xFFFFFFFFFFFFFFFFFFFFFFFFFFEDCBA9)))));

    try test__ashrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 124, @as(i128, @bitCast(@as(u128, @intCast(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)))));
    try test__ashrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 125, @as(i128, @bitCast(@as(u128, @intCast(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)))));
    try test__ashrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 126, @as(i128, @bitCast(@as(u128, @intCast(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)))));
    try test__ashrti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 127, @as(i128, @bitCast(@as(u128, @intCast(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)))));
}
