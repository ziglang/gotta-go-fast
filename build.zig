const std = @import("std");

pub fn build(b: *std.Build) !void {
    const backfill = b.option(bool, "backfill", "Backfill data for previous Zig versions") orelse false;

    if (backfill) {
        // Parse arguments
        const args = b.args.?;
        const records_csv_path = args[0];
        const zig_git_dir_path = args[1];
        const commits_txt_path = args[2];

        // Load commits
        var commit_raw_iter = std.mem.tokenize(u8, try std.fs.cwd().readFileAlloc(b.allocator, commits_txt_path, 2 * 1024 * 1024), "\r\n");

        // Create paths
        const zig_build_dir_path = try std.fs.path.join(b.allocator, &.{ zig_git_dir_path, "build-backfill" });
        const zig_exe_path = try std.fs.path.join(b.allocator, &.{ zig_build_dir_path, "stage3/bin/zig" });

        // Run benchmarks for each commit
        while (commit_raw_iter.next()) |commit_raw| {
            // Check out commit
            std.debug.print("Checking out {s} to backfill...\n", .{commit_raw});
            _ = try std.ChildProcess.exec(.{ .allocator = b.allocator, .argv = &.{ "git", "checkout", commit_raw }, .cwd = zig_git_dir_path });

            // Touch CMakeLists.txt to pick up the new Zig version
            _ = try std.ChildProcess.exec(.{ .allocator = b.allocator, .argv = &.{ "touch", "CMakeLists.txt" }, .cwd = zig_git_dir_path });

            // Build Zig
            std.debug.print("Building Zig to {s}...\n", .{zig_exe_path});
            _ = try std.ChildProcess.exec(.{ .allocator = b.allocator, .argv = &.{"ninja"}, .cwd = zig_build_dir_path });

            // Parse Zig version
            const zig_version = std.mem.trimRight(u8, b.exec(&.{ zig_exe_path, "version" }), "\r\n");

            // Parse commit
            const commit = try parseCommit(commit_raw);

            // Parse commit timestamp
            const commit_timestamp_result = try std.ChildProcess.exec(.{ .allocator = b.allocator, .argv = &.{ "git", "log", "-n1", commit_raw, "--pretty=format:%at" }, .cwd = zig_git_dir_path });
            const commit_timestamp_raw = commit_timestamp_result.stdout;
            const commit_timestamp = try std.fmt.parseInt(u64, std.mem.trimRight(u8, commit_timestamp_raw, "\r\n"), 10);

            // Collect measurements
            try collectMeasurements(b, records_csv_path, zig_exe_path, zig_version, commit, commit_timestamp);
        }
    } else {
        // Parse arguments
        const args = b.args.?;
        const records_csv_path = args[0];
        const zig_exe_path = args[1];
        const zig_version = std.mem.trimRight(u8, b.exec(&.{ zig_exe_path, "version" }), "\r\n");
        const commit = try parseCommit(args[2]);
        const commit_timestamp = try std.fmt.parseInt(u64, std.mem.trimRight(u8, args[3], "\r\n"), 10);

        // Collect measurements
        try collectMeasurements(b, records_csv_path, zig_exe_path, zig_version, commit, commit_timestamp);
    }
}

const RecordList = std.ArrayList(Record);
const CommitTable = std.HashMap(Record.Key, usize, CommitTableContext, std.hash_map.default_max_load_percentage);

const CommitTableContext = struct {
    pub fn eql(_: CommitTableContext, a: Record.Key, b: Record.Key) bool {
        return a.eql(b);
    }

    pub fn hash(_: CommitTableContext, key: Record.Key) u64 {
        var hasher = std.hash.Wyhash.init(0);
        std.hash.autoHashStrat(&hasher, key, .Deep);
        return hasher.final();
    }
};

const Record = struct {
    timestamp: u64,
    benchmark_name: []const u8,
    commit_hash: [20]u8,
    commit_timestamp: u64,
    zig_version: []const u8,
    error_message: []const u8 = &[0]u8{},
    samples_taken: u64 = 0,
    wall_time_median: u64 = 0,
    wall_time_mean: u64 = 0,
    wall_time_min: u64 = 0,
    wall_time_max: u64 = 0,
    utime_median: u64 = 0,
    utime_mean: u64 = 0,
    utime_min: u64 = 0,
    utime_max: u64 = 0,
    stime_median: u64 = 0,
    stime_mean: u64 = 0,
    stime_min: u64 = 0,
    stime_max: u64 = 0,
    cpu_cycles_median: u64 = 0,
    cpu_cycles_mean: u64 = 0,
    cpu_cycles_min: u64 = 0,
    cpu_cycles_max: u64 = 0,
    instructions_median: u64 = 0,
    instructions_mean: u64 = 0,
    instructions_min: u64 = 0,
    instructions_max: u64 = 0,
    cache_references_median: u64 = 0,
    cache_references_mean: u64 = 0,
    cache_references_min: u64 = 0,
    cache_references_max: u64 = 0,
    cache_misses_median: u64 = 0,
    cache_misses_mean: u64 = 0,
    cache_misses_min: u64 = 0,
    cache_misses_max: u64 = 0,
    branch_misses_median: u64 = 0,
    branch_misses_mean: u64 = 0,
    branch_misses_min: u64 = 0,
    branch_misses_max: u64 = 0,
    maxrss: u64 = 0,

    const Key = struct {
        commit_hash: [20]u8,
        benchmark_name: []const u8,

        fn eql(self: Key, other: Key) bool {
            return std.mem.eql(u8, &self.commit_hash, &other.commit_hash) and
                std.mem.eql(u8, self.benchmark_name, other.benchmark_name);
        }
    };
};

fn collectMeasurements(b: *std.Build, records_csv_path: []const u8, zig_exe_path: []const u8, zig_version: []const u8, commit: [20]u8, commit_timestamp: u64) !void {
    std.debug.print("Collecting measurements for Zig version {s} commit timestamp {d}...\n", .{ zig_version, commit_timestamp });

    // Parse manifest
    const manifest = try std.json.parseFromSlice(std.json.Value, b.allocator, @embedFile("manifest.json"), .{});
    defer manifest.deinit();

    // Load records
    var record_list = RecordList.init(b.allocator);
    defer record_list.deinit();
    var commit_table = CommitTable.init(b.allocator);
    defer commit_table.deinit();
    try loadCsv(b.allocator, records_csv_path, &record_list, &commit_table);
    try record_list.ensureUnusedCapacity(manifest.value.object.count() * 2);
    const timestamp: u64 = @intCast(std.time.timestamp());

    // Run benchmarks
    var benchmark_iter = manifest.value.object.iterator();
    while (benchmark_iter.next()) |benchmark| {
        // Parse benchmark
        const name = benchmark.key_ptr.*;
        const dir_name = benchmark.value_ptr.object.get("dir").?.string;
        const main_basename = benchmark.value_ptr.object.get("mainPath").?.string;
        const main_path = try std.fs.path.join(b.allocator, &.{ "src", dir_name, main_basename });

        // Build benchmark
        const mod = try std.fmt.allocPrint(b.allocator, "app::{s}", .{main_path});
        _ = b.exec(&.{ zig_exe_path, "build-exe", "-O", "ReleaseFast", "--deps", "app", "--mod", mod, "src/bench.zig" });

        // Run benchmark
        std.debug.print("Running '{s}' for {}...\n", .{ name, std.fmt.fmtSliceHexLower(&commit) });
        const bench_output = b.exec(&.{ "./bench", zig_exe_path });

        // Parse output
        const bench_json = try std.json.parseFromSlice(std.json.Value, b.allocator, bench_output, .{});
        defer bench_json.deinit();
        const record = try jsonToRecord(b.allocator, bench_json.value, timestamp, name, commit, zig_version, commit_timestamp);
        const key = Record.Key{ .commit_hash = record.commit_hash, .benchmark_name = record.benchmark_name };

        // Save record
        const main_gop = try commit_table.getOrPut(key);
        if (main_gop.found_existing) {
            record_list.items[main_gop.value_ptr.*] = record;
        } else {
            main_gop.value_ptr.* = record_list.items.len;
            record_list.appendAssumeCapacity(record);
        }
    }

    // Save records
    try saveCsv(b.allocator, records_csv_path, record_list.items);
}

fn loadCsv(allocator: std.mem.Allocator, records_csv_path: []const u8, record_list: *RecordList, commit_table: *CommitTable) !void {
    const csv_text = try std.fs.cwd().readFileAlloc(allocator, records_csv_path, 2 * 1024 * 1024 * 1024);
    defer allocator.free(csv_text);

    var field_indexes: [@typeInfo(Record).Struct.fields.len]usize = undefined;
    var seen_fields = [1]bool{false} ** field_indexes.len;
    var line_it = std.mem.split(u8, csv_text, "\n");
    {
        const first_line = line_it.next() orelse {
            std.debug.print("empty Csv file", .{});
            std.process.exit(1);
        };
        var csv_index: usize = 0;
        var it = std.mem.split(u8, first_line, ",");
        while (it.next()) |field_name| : (csv_index += 1) {
            if (csv_index >= field_indexes.len) {
                std.debug.print("extra Csv field: {s}\n", .{field_name});
                std.process.exit(1);
            }
            const field_index = fieldIndex(Record, field_name) orelse {
                std.debug.print("bad Csv field name: {s}\n", .{field_name});
                std.process.exit(1);
            };
            field_indexes[csv_index] = field_index;
            seen_fields[field_index] = true;
        }
        inline for (@typeInfo(Record).Struct.fields, 0..) |field, i| {
            if (!seen_fields[i]) {
                std.debug.print("missing Csv field: {s}", .{field.name});
                std.process.exit(1);
            }
        }
    }

    var line_index: usize = 1;
    while (line_it.next()) |line| : (line_index += 1) {
        if (std.mem.eql(u8, line, "")) continue;
        var it = std.mem.split(u8, line, ",");
        var csv_index: usize = 0;
        const record_index = record_list.items.len;
        const record = try record_list.addOne();
        while (it.next()) |field| : (csv_index += 1) {
            if (csv_index >= field_indexes.len) {
                std.debug.print("extra Csv field on line {d}\n", .{line_index + 1});
                std.process.exit(1);
            }
            setRecordField(allocator, record, field, field_indexes[csv_index]);
        }
        if (csv_index != field_indexes.len) {
            std.debug.print("Csv line {d} missing a field\n", .{line_index + 1});
            std.process.exit(1);
        }
        const key: Record.Key = .{
            .commit_hash = record.commit_hash,
            .benchmark_name = record.benchmark_name,
        };
        if (try commit_table.fetchPut(key, record_index)) |existing| {
            _ = commit_table.putAssumeCapacity(key, existing.value);
            record_list.shrinkRetainingCapacity(record_list.items.len - 1);
        }
    }
}

fn saveCsv(allocator: std.mem.Allocator, records_csv_path: []const u8, records: []Record) !void {
    const baf = try std.io.BufferedAtomicFile.create(allocator, std.fs.cwd(), records_csv_path, .{});
    defer baf.destroy();

    const out = baf.writer();
    inline for (@typeInfo(Record).Struct.fields, 0..) |field, i| {
        if (i != 0) {
            try out.writeAll(",");
        }
        try out.writeAll(field.name);
    }
    try out.writeAll("\n");
    for (records) |record| {
        try writeCsvRecord(out, record);
        try out.writeAll("\n");
    }

    try baf.finish();
}

fn jsonToRecord(
    allocator: std.mem.Allocator,
    mo: std.json.Value,
    timestamp: u64,
    benchmark_name: []const u8,
    commit_hash: [20]u8,
    zig_version: []const u8,
    commit_timestamp: u64,
) !Record {
    var record: Record = .{
        .timestamp = timestamp,
        .benchmark_name = try allocator.dupe(u8, benchmark_name),
        .commit_hash = commit_hash,
        .commit_timestamp = commit_timestamp,
        .zig_version = zig_version,
    };

    if (mo == .string) {
        record.error_message = try allocator.dupe(u8, mo.string);
    } else {
        const ok = mo.object.get("ok").?.object;
        record.samples_taken = @as(u64, @intCast(ok.get("samples_taken").?.integer));
        record.wall_time_median = @as(u64, @intCast(ok.get("wall_time").?.object.get("median").?.integer));
        record.wall_time_mean = @as(u64, @intCast(ok.get("wall_time").?.object.get("mean").?.integer));
        record.wall_time_min = @as(u64, @intCast(ok.get("wall_time").?.object.get("min").?.integer));
        record.wall_time_max = @as(u64, @intCast(ok.get("wall_time").?.object.get("max").?.integer));
        record.utime_median = @as(u64, @intCast(ok.get("utime").?.object.get("median").?.integer));
        record.utime_mean = @as(u64, @intCast(ok.get("utime").?.object.get("mean").?.integer));
        record.utime_min = @as(u64, @intCast(ok.get("utime").?.object.get("min").?.integer));
        record.utime_max = @as(u64, @intCast(ok.get("utime").?.object.get("max").?.integer));
        record.stime_median = @as(u64, @intCast(ok.get("stime").?.object.get("median").?.integer));
        record.stime_mean = @as(u64, @intCast(ok.get("stime").?.object.get("mean").?.integer));
        record.stime_min = @as(u64, @intCast(ok.get("stime").?.object.get("min").?.integer));
        record.stime_max = @as(u64, @intCast(ok.get("stime").?.object.get("max").?.integer));
        record.cpu_cycles_median = @as(u64, @intCast(ok.get("cpu_cycles").?.object.get("median").?.integer));
        record.cpu_cycles_mean = @as(u64, @intCast(ok.get("cpu_cycles").?.object.get("mean").?.integer));
        record.cpu_cycles_min = @as(u64, @intCast(ok.get("cpu_cycles").?.object.get("min").?.integer));
        record.cpu_cycles_max = @as(u64, @intCast(ok.get("cpu_cycles").?.object.get("max").?.integer));
        record.instructions_median = @as(u64, @intCast(ok.get("instructions").?.object.get("median").?.integer));
        record.instructions_mean = @as(u64, @intCast(ok.get("instructions").?.object.get("mean").?.integer));
        record.instructions_min = @as(u64, @intCast(ok.get("instructions").?.object.get("min").?.integer));
        record.instructions_max = @as(u64, @intCast(ok.get("instructions").?.object.get("max").?.integer));
        record.cache_references_median = @as(u64, @intCast(ok.get("cache_references").?.object.get("median").?.integer));
        record.cache_references_mean = @as(u64, @intCast(ok.get("cache_references").?.object.get("mean").?.integer));
        record.cache_references_min = @as(u64, @intCast(ok.get("cache_references").?.object.get("min").?.integer));
        record.cache_references_max = @as(u64, @intCast(ok.get("cache_references").?.object.get("max").?.integer));
        record.cache_misses_median = @as(u64, @intCast(ok.get("cache_misses").?.object.get("median").?.integer));
        record.cache_misses_mean = @as(u64, @intCast(ok.get("cache_misses").?.object.get("mean").?.integer));
        record.cache_misses_min = @as(u64, @intCast(ok.get("cache_misses").?.object.get("min").?.integer));
        record.cache_misses_max = @as(u64, @intCast(ok.get("cache_misses").?.object.get("max").?.integer));
        record.branch_misses_median = @as(u64, @intCast(ok.get("branch_misses").?.object.get("median").?.integer));
        record.branch_misses_mean = @as(u64, @intCast(ok.get("branch_misses").?.object.get("mean").?.integer));
        record.branch_misses_min = @as(u64, @intCast(ok.get("branch_misses").?.object.get("min").?.integer));
        record.branch_misses_max = @as(u64, @intCast(ok.get("branch_misses").?.object.get("max").?.integer));
        record.maxrss = @as(u64, @intCast(ok.get("maxrss").?.integer));
    }

    return record;
}

fn fieldIndex(comptime T: type, name: []const u8) ?usize {
    inline for (@typeInfo(T).Struct.fields, 0..) |field, i| {
        if (std.mem.eql(u8, field.name, name))
            return i;
    }
    return null;
}

fn setRecordField(allocator: std.mem.Allocator, record: *Record, data: []const u8, index: usize) void {
    inline for (@typeInfo(Record).Struct.fields, 0..) |field, i| {
        if (i == index) {
            setRecordFieldT(allocator, field.type, &@field(record, field.name), data);
            return;
        }
    }
    unreachable;
}

fn setRecordFieldT(allocator: std.mem.Allocator, comptime T: type, ptr: *T, data: []const u8) void {
    if (@typeInfo(T) == .Enum) {
        ptr.* = std.meta.stringToEnum(T, data) orelse {
            std.debug.print("bad enum value: {d}\n", .{data});
            std.process.exit(1);
        };
        return;
    }
    switch (T) {
        u64 => {
            ptr.* = std.fmt.parseInt(u64, data, 10) catch |err| {
                std.debug.print("bad u64 value '{d}': {s}\n", .{ data, @errorName(err) });
                std.process.exit(1);
            };
        },
        []const u8 => {
            ptr.* = allocator.dupe(u8, data) catch @panic("out of memory");
        },
        [20]u8 => {
            ptr.* = parseCommit(data) catch |err| {
                std.debug.print("wrong format for commit hash: '{d}': {s}", .{ data, @errorName(err) });
                std.process.exit(1);
            };
        },
        else => @compileError("no deserialization for " ++ @typeName(T)),
    }
}

fn writeCsvRecord(out: anytype, record: Record) !void {
    inline for (@typeInfo(Record).Struct.fields, 0..) |field, i| {
        if (i != 0) {
            try out.writeAll(",");
        }
        try writeCsvRecordField(out, @field(record, field.name));
    }
}

fn writeCsvRecordField(out: anytype, field: anytype) !void {
    const T = @TypeOf(field);
    if (@typeInfo(T) == .Enum) {
        return out.writeAll(@tagName(field));
    }
    switch (T) {
        u64 => return out.print("{}", .{field}),
        []const u8 => return out.writeAll(field),
        [20]u8 => return out.print("{}", .{std.fmt.fmtSliceHexLower(&field)}),
        else => @compileError("unsupported writeCsvRecordField type: " ++ @typeName(T)),
    }
}

fn parseCommit(text: []const u8) ![20]u8 {
    var result: [20]u8 = undefined;
    if (text.len != 40) {
        return error.WrongShaLength;
    }
    var i: usize = 0;
    while (i < 20) : (i += 1) {
        const byte = std.fmt.parseInt(u8, text[i * 2 ..][0..2], 16) catch {
            return error.BadShaCharacter;
        };
        result[i] = byte;
    }
    return result;
}
