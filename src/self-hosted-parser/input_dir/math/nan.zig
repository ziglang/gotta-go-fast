const math = @import("../math.zig");

/// Returns the nan representation for type T.
pub fn nan(comptime T: type) T {
    return switch (T) {
        f16 => math.nan_f16,
        f32 => math.nan_f32,
        f64 => math.nan_f64,
        f128 => math.nan_f128,
        else => @compileError("nan not implemented for " ++ @typeName(T)),
    };
}

/// Returns the signalling nan representation for type T.
pub fn snan(comptime T: type) T {
    // Note: A signalling nan is identical to a standard right now by may have a different bit
    // representation in the future when required.
    return switch (T) {
        f16 => @as(f16, @bitCast(math.nan_u16)),
        f32 => @as(f32, @bitCast(math.nan_u32)),
        f64 => @as(f64, @bitCast(math.nan_u64)),
        else => @compileError("snan not implemented for " ++ @typeName(T)),
    };
}
