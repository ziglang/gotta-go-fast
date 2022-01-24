const std = @import("std");

pub fn main() void {}

comptime {
    const count = 5000;
    var guid: [38]u8 = "{00000000-98b5-11cf-bb82-00aa00bdce0b}".*;

    @setEvalBranchQuota(count * 2000);
    var i: usize = 0;
    while (i < count) : (i += 1) {
        _ = std.os.windows.GUID.parse(&guid);
    }
}
