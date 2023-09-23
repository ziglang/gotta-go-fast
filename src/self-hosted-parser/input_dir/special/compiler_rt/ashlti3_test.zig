const __ashlti3 = @import("shift.zig").__ashlti3;
const testing = @import("std").testing;

fn test__ashlti3(a: i128, b: i32, expected: i128) !void {
    const x = __ashlti3(a, b);
    try testing.expectEqual(expected, x);
}

test "ashlti3" {
    try test__ashlti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 0, @as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))));
    try test__ashlti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 1, @as(i128, @bitCast(@as(u128, @intCast(0xFDB97530ECA8642BFDB97530ECA8642A)))));
    try test__ashlti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 2, @as(i128, @bitCast(@as(u128, @intCast(0xFB72EA61D950C857FB72EA61D950C854)))));
    try test__ashlti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 3, @as(i128, @bitCast(@as(u128, @intCast(0xF6E5D4C3B2A190AFF6E5D4C3B2A190A8)))));
    try test__ashlti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 4, @as(i128, @bitCast(@as(u128, @intCast(0xEDCBA9876543215FEDCBA98765432150)))));
    try test__ashlti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 28, @as(i128, @bitCast(@as(u128, @intCast(0x876543215FEDCBA98765432150000000)))));
    try test__ashlti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 29, @as(i128, @bitCast(@as(u128, @intCast(0x0ECA8642BFDB97530ECA8642A0000000)))));
    try test__ashlti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 30, @as(i128, @bitCast(@as(u128, @intCast(0x1D950C857FB72EA61D950C8540000000)))));
    try test__ashlti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 31, @as(i128, @bitCast(@as(u128, @intCast(0x3B2A190AFF6E5D4C3B2A190A80000000)))));
    try test__ashlti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 32, @as(i128, @bitCast(@as(u128, @intCast(0x76543215FEDCBA987654321500000000)))));
    try test__ashlti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 33, @as(i128, @bitCast(@as(u128, @intCast(0xECA8642BFDB97530ECA8642A00000000)))));
    try test__ashlti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 34, @as(i128, @bitCast(@as(u128, @intCast(0xD950C857FB72EA61D950C85400000000)))));
    try test__ashlti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 35, @as(i128, @bitCast(@as(u128, @intCast(0xB2A190AFF6E5D4C3B2A190A800000000)))));
    try test__ashlti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 36, @as(i128, @bitCast(@as(u128, @intCast(0x6543215FEDCBA9876543215000000000)))));
    try test__ashlti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 60, @as(i128, @bitCast(@as(u128, @intCast(0x5FEDCBA9876543215000000000000000)))));
    try test__ashlti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 61, @as(i128, @bitCast(@as(u128, @intCast(0xBFDB97530ECA8642A000000000000000)))));
    try test__ashlti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 62, @as(i128, @bitCast(@as(u128, @intCast(0x7FB72EA61D950C854000000000000000)))));
    try test__ashlti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 63, @as(i128, @bitCast(@as(u128, @intCast(0xFF6E5D4C3B2A190A8000000000000000)))));
    try test__ashlti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 64, @as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA98765432150000000000000000)))));
    try test__ashlti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 65, @as(i128, @bitCast(@as(u128, @intCast(0xFDB97530ECA8642A0000000000000000)))));
    try test__ashlti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 66, @as(i128, @bitCast(@as(u128, @intCast(0xFB72EA61D950C8540000000000000000)))));
    try test__ashlti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 67, @as(i128, @bitCast(@as(u128, @intCast(0xF6E5D4C3B2A190A80000000000000000)))));
    try test__ashlti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 68, @as(i128, @bitCast(@as(u128, @intCast(0xEDCBA987654321500000000000000000)))));
    try test__ashlti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 92, @as(i128, @bitCast(@as(u128, @intCast(0x87654321500000000000000000000000)))));
    try test__ashlti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 93, @as(i128, @bitCast(@as(u128, @intCast(0x0ECA8642A00000000000000000000000)))));
    try test__ashlti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 94, @as(i128, @bitCast(@as(u128, @intCast(0x1D950C85400000000000000000000000)))));
    try test__ashlti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 95, @as(i128, @bitCast(@as(u128, @intCast(0x3B2A190A800000000000000000000000)))));
    try test__ashlti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 96, @as(i128, @bitCast(@as(u128, @intCast(0x76543215000000000000000000000000)))));
    try test__ashlti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 97, @as(i128, @bitCast(@as(u128, @intCast(0xECA8642A000000000000000000000000)))));
    try test__ashlti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 98, @as(i128, @bitCast(@as(u128, @intCast(0xD950C854000000000000000000000000)))));
    try test__ashlti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 99, @as(i128, @bitCast(@as(u128, @intCast(0xB2A190A8000000000000000000000000)))));
    try test__ashlti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 100, @as(i128, @bitCast(@as(u128, @intCast(0x65432150000000000000000000000000)))));
    try test__ashlti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 124, @as(i128, @bitCast(@as(u128, @intCast(0x50000000000000000000000000000000)))));
    try test__ashlti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 125, @as(i128, @bitCast(@as(u128, @intCast(0xA0000000000000000000000000000000)))));
    try test__ashlti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 126, @as(i128, @bitCast(@as(u128, @intCast(0x40000000000000000000000000000000)))));
    try test__ashlti3(@as(i128, @bitCast(@as(u128, @intCast(0xFEDCBA9876543215FEDCBA9876543215)))), 127, @as(i128, @bitCast(@as(u128, @intCast(0x80000000000000000000000000000000)))));
}
