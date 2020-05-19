const std = @import("std");
const fs = std.fs;
const json = std.json;
const assert = std.debug.assert;

const Record = struct {
    timestamp: u64,
    benchmark_name: []const u8,
    allocator: WhichAllocator,
    commit_hash: [20]u8,
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
    maxrss: u64 = 0,

    baseline_error_message: []const u8 = &[0]u8{},
    baseline_samples_taken: u64 = 0,
    baseline_wall_time_median: u64 = 0,
    baseline_wall_time_mean: u64 = 0,
    baseline_wall_time_min: u64 = 0,
    baseline_wall_time_max: u64 = 0,
    baseline_utime_median: u64 = 0,
    baseline_utime_mean: u64 = 0,
    baseline_utime_min: u64 = 0,
    baseline_utime_max: u64 = 0,
    baseline_stime_median: u64 = 0,
    baseline_stime_mean: u64 = 0,
    baseline_stime_min: u64 = 0,
    baseline_stime_max: u64 = 0,
    baseline_maxrss: u64 = 0,

    const WhichAllocator = enum {
        /// malloc/realloc/free
        libc,
        /// the default general purpose allocator in the zig std lib.
        /// currently std.heap.page_allocator
        std_gpa,
    };

    const Key = struct {
        commit_hash: [20]u8,
        benchmark_name: []const u8,
        allocator: Record.WhichAllocator,

        fn eql(self: Key, other: Key) bool {
            return self.allocator == other.allocator and
                std.mem.eql(u8, &self.commit_hash, &other.commit_hash) and
                std.mem.eql(u8, self.benchmark_name, other.benchmark_name);
        }
    };
};

fn jsonToRecord(
    arena: *std.mem.Allocator,
    /// main object
    mo: json.Value,
    /// baseline object
    bo: json.Value,
    timestamp: u64,
    benchmark_name: []const u8,
    commit_hash: [20]u8,
    which_allocator: Record.WhichAllocator,
) !Record {
    // Example success output of benchmark program:
    // {"samples_taken":3,"wall_time":{"median":1922782021,"mean":1922782021,"min":1922782021,"max":1922782021},"utime":{"median":1872974000,"mean":1872974000,"min":1872974000,"max":1872974000},"stime":{"median":49022000,"mean":49022000,"min":49022000,"max":49022000},"maxrss":66240}
    //
    // Example failure output of the benchmark program:
    // FileNotFound
    var record: Record = .{
        .timestamp = timestamp,
        .benchmark_name = try arena.dupe(u8, benchmark_name),
        .commit_hash = commit_hash,
        .allocator = which_allocator,
    };
    if (mo == .String) {
        record.error_message = try arena.dupe(u8, mo.String);
    } else {
        record.samples_taken = @intCast(u64, mo.Object.getValue("samples_taken").?.Integer);
        record.wall_time_median = @intCast(u64, mo.Object.getValue("wall_time").?.Object.getValue("median").?.Integer);
        record.wall_time_mean = @intCast(u64, mo.Object.getValue("wall_time").?.Object.getValue("mean").?.Integer);
        record.wall_time_min = @intCast(u64, mo.Object.getValue("wall_time").?.Object.getValue("min").?.Integer);
        record.wall_time_max = @intCast(u64, mo.Object.getValue("wall_time").?.Object.getValue("max").?.Integer);
        record.utime_median = @intCast(u64, mo.Object.getValue("utime").?.Object.getValue("median").?.Integer);
        record.utime_mean = @intCast(u64, mo.Object.getValue("utime").?.Object.getValue("mean").?.Integer);
        record.utime_min = @intCast(u64, mo.Object.getValue("utime").?.Object.getValue("min").?.Integer);
        record.utime_max = @intCast(u64, mo.Object.getValue("utime").?.Object.getValue("max").?.Integer);
        record.stime_median = @intCast(u64, mo.Object.getValue("stime").?.Object.getValue("median").?.Integer);
        record.stime_mean = @intCast(u64, mo.Object.getValue("stime").?.Object.getValue("mean").?.Integer);
        record.stime_min = @intCast(u64, mo.Object.getValue("stime").?.Object.getValue("min").?.Integer);
        record.stime_max = @intCast(u64, mo.Object.getValue("stime").?.Object.getValue("max").?.Integer);
        record.maxrss = @intCast(u64, mo.Object.getValue("maxrss").?.Integer);
    }
    if (bo == .String) {
        record.error_message = try arena.dupe(u8, bo.String);
    } else {
        record.baseline_samples_taken = @intCast(u64, bo.Object.getValue("samples_taken").?.Integer);
        record.baseline_wall_time_median = @intCast(u64, bo.Object.getValue("wall_time").?.Object.getValue("median").?.Integer);
        record.baseline_wall_time_mean = @intCast(u64, bo.Object.getValue("wall_time").?.Object.getValue("mean").?.Integer);
        record.baseline_wall_time_min = @intCast(u64, bo.Object.getValue("wall_time").?.Object.getValue("min").?.Integer);
        record.baseline_wall_time_max = @intCast(u64, bo.Object.getValue("wall_time").?.Object.getValue("max").?.Integer);
        record.baseline_utime_median = @intCast(u64, bo.Object.getValue("utime").?.Object.getValue("median").?.Integer);
        record.baseline_utime_mean = @intCast(u64, bo.Object.getValue("utime").?.Object.getValue("mean").?.Integer);
        record.baseline_utime_min = @intCast(u64, bo.Object.getValue("utime").?.Object.getValue("min").?.Integer);
        record.baseline_utime_max = @intCast(u64, bo.Object.getValue("utime").?.Object.getValue("max").?.Integer);
        record.baseline_stime_median = @intCast(u64, bo.Object.getValue("stime").?.Object.getValue("median").?.Integer);
        record.baseline_stime_mean = @intCast(u64, bo.Object.getValue("stime").?.Object.getValue("mean").?.Integer);
        record.baseline_stime_min = @intCast(u64, bo.Object.getValue("stime").?.Object.getValue("min").?.Integer);
        record.baseline_stime_max = @intCast(u64, bo.Object.getValue("stime").?.Object.getValue("max").?.Integer);
        record.baseline_maxrss = @intCast(u64, bo.Object.getValue("maxrss").?.Integer);
    }

    return record;
}

const records_csv_path = "records.csv";
const comma = ",";
const zig_src_root = "zig-builds/src";
const zig_src_build = "zig-builds/src/build";
const zig_src_bin = "zig-builds/src/build/zig";
const CommitTable = std.HashMap(
    Record.Key,
    usize,
    std.hash_map.getAutoHashStratFn(Record.Key, .Deep),
    Record.Key.eql,
);
const poll_timeout = 60 * std.time.ns_per_s;

pub fn main() !void {
    const gpa = std.heap.page_allocator;
    var arena_state = std.heap.ArenaAllocator.init(gpa);
    defer arena_state.deinit();
    const arena = &arena_state.allocator;

    const args = try std.process.argsAlloc(arena);
    var auto_commit_and_push = false;
    for (args[1..]) |arg| {
        if (std.mem.eql(u8, arg, "--auto-commit-and-push")) {
            auto_commit_and_push = true;
        } else {
            std.debug.warn("unrecognized command line parameter: '{}'\n", .{arg});
            std.process.exit(1);
        }
    }

    // Load CSV into memory
    std.debug.warn("Loading CSV data...\n", .{});
    var records = std.ArrayList(Record).init(gpa);
    defer records.deinit();
    var commit_table = CommitTable.init(gpa);
    defer commit_table.deinit();

    {
        const csv_text = try fs.cwd().readFileAlloc(gpa, records_csv_path, 2 * 1024 * 1024 * 1024);
        defer gpa.free(csv_text);

        var field_indexes: [@typeInfo(Record).Struct.fields.len]usize = undefined;
        var seen_fields = [1]bool{false} ** field_indexes.len;
        var line_it = std.mem.split(csv_text, "\n");
        {
            const first_line = line_it.next() orelse {
                std.debug.warn("empty CSV file", .{});
                std.process.exit(1);
            };
            var csv_index: usize = 0;
            var it = std.mem.split(first_line, comma);
            while (it.next()) |field_name| : (csv_index += 1) {
                if (csv_index >= field_indexes.len) {
                    std.debug.warn("extra CSV field: {}\n", .{field_name});
                    std.process.exit(1);
                }
                const field_index = fieldIndex(Record, field_name) orelse {
                    std.debug.warn("bad CSV field name: {}\n", .{field_name});
                    std.process.exit(1);
                };
                //std.debug.warn("found field '{}' = {}\n", .{ field_name, field_index });
                field_indexes[csv_index] = field_index;
                seen_fields[field_index] = true;
            }
            inline for (@typeInfo(Record).Struct.fields) |field, i| {
                if (!seen_fields[i]) {
                    std.debug.warn("missing CSV field: {}", .{field.name});
                    std.process.exit(1);
                }
            }
        }

        var line_index: usize = 1;
        while (line_it.next()) |line| : (line_index += 1) {
            if (std.mem.eql(u8, line, "")) continue; // Skip blank lines.
            var it = std.mem.split(line, comma);
            var csv_index: usize = 0;
            const record_index = records.items.len;
            const record = try records.addOne();
            while (it.next()) |field| : (csv_index += 1) {
                if (csv_index >= field_indexes.len) {
                    std.debug.warn("extra CSV field on line {}\n", .{line_index + 1});
                    std.process.exit(1);
                }
                setRecordField(arena, record, field, field_indexes[csv_index]);
            }
            if (csv_index != field_indexes.len) {
                std.debug.warn("CSV line {} missing a field\n", .{line_index + 1});
                std.process.exit(1);
            }
            const key: Record.Key = .{
                .commit_hash = record.commit_hash,
                .benchmark_name = record.benchmark_name,
                .allocator = record.allocator,
            };
            if (try commit_table.put(key, record_index)) |existing| {
                const existing_record = records.items[existing.value];
                if (existing_record.timestamp > record.timestamp) {
                    _ = commit_table.putAssumeCapacity(key, existing.value);
                }
            }
        }
    }

    var manifest_parser = json.Parser.init(gpa, false);
    const manifest_text = try fs.cwd().readFileAlloc(gpa, "benchmarks/manifest.json", 3 * 1024 * 1024);
    const manifest_tree = try manifest_parser.parse(manifest_text);

    var queue = std.ArrayList([20]u8).init(gpa);
    defer queue.deinit();

    var last_time_slept = false;

    while (true) {
        queue.shrink(0);
        // Detect queue.txt items
        const queue_txt_path = "queue.txt";
        if (fs.cwd().readFileAlloc(gpa, queue_txt_path, 1024 * 1024)) |queue_txt| {
            defer gpa.free(queue_txt);
            var it = std.mem.tokenize(queue_txt, " \r\n\t");
            while (it.next()) |commit_txt| {
                const commit = parseCommit(commit_txt) catch |err| {
                    std.debug.warn("bad commit format: '{}': {}\n", .{ commit_txt, @errorName(err) });
                    continue;
                };
                try queue.append(commit);
            }
        } else |err| {
            std.debug.warn("unable to read {}: {}\n", .{ queue_txt_path, @errorName(err) });
        }
        // Eliminate the ones already done.
        {
            var queue_index: usize = 0;
            while (queue_index < queue.items.len) {
                const queue_commit = queue.items[queue_index];
                if (isCommitDone(manifest_tree.root, &commit_table, queue_commit)) {
                    _ = queue.orderedRemove(queue_index);
                    continue;
                }
                queue_index += 1;
            }
        }
        {
            const baf = try std.io.BufferedAtomicFile.create(gpa, fs.cwd(), queue_txt_path, .{});
            defer baf.destroy();

            const out = baf.stream();
            for (queue.items) |commit| {
                try out.print("{x}\n", .{commit});
            }

            try baf.finish();
        }

        // Detect changes to zig master branch
        while (true) {
            exec(gpa, &[_][]const u8{ "git", "fetch", "origin", "--prune", "--tags" }, .{
                .cwd = zig_src_root,
            }) catch |err| {
                std.debug.warn("unable to fetch latest git commits: {}\n", .{@errorName(err)});
                std.time.sleep(poll_timeout);
                continue;
            };
            const commit_str = execCapture(gpa, &[_][]const u8{
                "git",                "log",
                "-n1",                "origin/master",
                "--pretty=format:%H",
            }, .{
                .cwd = zig_src_root,
            }) catch |err| {
                std.debug.warn("unable to check latest master commit: {}\n", .{@errorName(err)});
                std.time.sleep(poll_timeout);
                continue;
            };
            defer gpa.free(commit_str);
            const trimmed = std.mem.trim(u8, commit_str, " \n\r\t");
            const latest = try parseCommit(trimmed);
            if (!isCommitDone(manifest_tree.root, &commit_table, latest)) {
                try queue.append(latest);
            }
            break;
        }

        const prev_records_len = records.items.len;
        for (queue.items) |queue_item| {
            runBenchmarks(gpa, arena, &records, &commit_table, manifest_tree.root, queue_item) catch |err| {
                std.debug.warn("error running benchmarks: {}\n", .{@errorName(err)});
            };
        }

        if (records.items.len != prev_records_len) {
            last_time_slept = false;
            // Save CSV
            std.debug.warn("Updating {}...\n", .{records_csv_path});
            {
                const baf = try std.io.BufferedAtomicFile.create(gpa, fs.cwd(), records_csv_path, .{});
                defer baf.destroy();

                const out = baf.stream();
                inline for (@typeInfo(Record).Struct.fields) |field, i| {
                    if (i != 0) {
                        try out.writeAll(comma);
                    }
                    try out.writeAll(field.name);
                }
                try out.writeAll("\n");
                for (records.items) |record| {
                    try writeCSVRecord(out, record);
                    try out.writeAll("\n");
                }

                try baf.finish();
            }

            if (auto_commit_and_push) {
                std.debug.warn("Committing changes to git and pushing...\n", .{});

                // Commit CSV changes to git and push
                exec(gpa, &[_][]const u8{ "git", "add", records_csv_path }, .{}) catch |err| {
                    std.debug.warn("unable to stage {} for git commit: {}\n", .{ records_csv_path, @errorName(err) });
                    std.time.sleep(poll_timeout);
                    continue;
                };

                const commit_message = "add new benchmark records";
                exec(gpa, &[_][]const u8{ "git", "commit", "-m", commit_message }, .{}) catch |err| {
                    std.debug.warn("unable to stage {} for git commit: {}\n", .{ records_csv_path, @errorName(err) });
                    std.time.sleep(poll_timeout);
                    continue;
                };

                exec(gpa, &[_][]const u8{ "git", "push", "origin", "master" }, .{}) catch |err| {
                    std.debug.warn("unable to git push: {}\n", .{@errorName(err)});
                    std.time.sleep(poll_timeout);
                    continue;
                };
            } else {
                std.debug.warn("Skipping git commit and push. Use --auto-commit-and-push to change this.\n", .{});
            }
        } else {
            if (!last_time_slept) {
                std.debug.warn("Waiting until new commits are pushed to zig master branch...\n", .{});
            }
            std.time.sleep(poll_timeout);
            last_time_slept = true;
        }
    }
}

fn isCommitDone(manifest_tree_root: json.Value, commit_table: *CommitTable, commit: [20]u8) bool {
    var benchmarks_it = manifest_tree_root.Object.iterator();
    while (benchmarks_it.next()) |kv| {
        const skip_libc_alloc = if (kv.value.Object.getValue("skipLibCAllocator")) |v| v.Bool else false;
        const which_allocators = if (skip_libc_alloc)
            &[1]Record.WhichAllocator{.std_gpa}
        else
            &[_]Record.WhichAllocator{ .libc, .std_gpa };
        for (which_allocators) |which_allocator| {
            const key: Record.Key = .{
                .commit_hash = commit,
                .benchmark_name = kv.key,
                .allocator = which_allocator,
            };
            if (commit_table.get(key) == null) {
                return false;
            }
        }
    }
    return true;
}

fn fieldIndex(comptime T: type, name: []const u8) ?usize {
    inline for (@typeInfo(T).Struct.fields) |field, i| {
        if (std.mem.eql(u8, field.name, name))
            return i;
    }
    return null;
}

fn setRecordField(arena: *std.mem.Allocator, record: *Record, data: []const u8, index: usize) void {
    inline for (@typeInfo(Record).Struct.fields) |field, i| {
        if (i == index) {
            setRecordFieldT(arena, field.field_type, &@field(record, field.name), data);
            return;
        }
    }
    unreachable;
}

fn setRecordFieldT(arena: *std.mem.Allocator, comptime T: type, ptr: *T, data: []const u8) void {
    if (@typeInfo(T) == .Enum) {
        ptr.* = std.meta.stringToEnum(T, data) orelse {
            std.debug.warn("bad enum value: {}\n", .{data});
            std.process.exit(1);
        };
        return;
    }
    switch (T) {
        u64 => {
            ptr.* = std.fmt.parseInt(u64, data, 10) catch |err| {
                std.debug.warn("bad u64 value '{}': {}\n", .{ data, @errorName(err) });
                std.process.exit(1);
            };
        },
        []const u8 => {
            ptr.* = arena.dupe(u8, data) catch @panic("out of memory");
        },
        [20]u8 => {
            ptr.* = parseCommit(data) catch |err| {
                std.debug.warn("wrong format for commit hash: '{}': {}", .{ data, @errorName(err) });
                std.process.exit(1);
            };
        },
        else => @compileError("no deserialization for " ++ @typeName(T)),
    }
}

fn writeCSVRecord(out: var, record: Record) !void {
    inline for (@typeInfo(Record).Struct.fields) |field, i| {
        if (i != 0) {
            try out.writeAll(comma);
        }
        try writeCSVRecordField(out, @field(record, field.name));
    }
}

fn writeCSVRecordField(out: var, field: var) !void {
    const T = @TypeOf(field);
    if (@typeInfo(T) == .Enum) {
        return out.writeAll(@tagName(field));
    }
    switch (T) {
        u64 => return out.print("{}", .{field}),
        []const u8 => return out.writeAll(field),
        [20]u8 => return out.print("{x}", .{field}),
        else => @compileError("unsupported writeCSVRecordField type: " ++ @typeName(T)),
    }
}

fn parseCommit(text: []const u8) ![20]u8 {
    var result: [20]u8 = undefined;
    if (text.len != 40) {
        return error.WrongSHALength;
    }
    var i: usize = 0;
    while (i < 20) : (i += 1) {
        const byte = std.fmt.parseInt(u8, text[i * 2 ..][0..2], 16) catch |err| {
            return error.BadSHACharacter;
        };
        result[i] = byte;
    }
    return result;
}

fn runBenchmarks(
    gpa: *std.mem.Allocator,
    arena: *std.mem.Allocator,
    records: *std.ArrayList(Record),
    commit_table: *CommitTable,
    manifest: json.Value,
    commit: [20]u8,
) !void {
    const abs_zig_src_bin = try fs.realpathAlloc(gpa, zig_src_bin);
    defer gpa.free(abs_zig_src_bin);

    try records.ensureCapacity(records.items.len + manifest.Object.size * 2);

    var commit_str: [40]u8 = undefined;
    _ = std.fmt.bufPrint(&commit_str, "{x}", .{commit}) catch unreachable;

    const timestamp_str = execCapture(gpa, &[_][]const u8{
        "git",                 "log",
        "-n1",                 &commit_str,
        "--pretty=format:%at",
    }, .{
        .cwd = zig_src_root,
    }) catch |err| {
        std.debug.warn("unable to check timestamp of commit {}: {}\n", .{ &commit_str, @errorName(err) });
        return error.UnableToCheckCommitTimestamp;
    };
    const timestamp = std.fmt.parseInt(u64, std.mem.trim(u8, timestamp_str, " \n\r\t"), 10) catch |err| {
        std.debug.warn("bad timestamp format: '{}': {}\n", .{ timestamp_str, @errorName(err) });
        return error.BadTimestampFormat;
    };

    // cd benchmarks/self-hosted-parser
    // zig run --main-pkg-path ../.. --pkg-begin app main.zig --pkg-end ../../bench.zig
    var benchmarks_it = manifest.Object.iterator();
    while (benchmarks_it.next()) |entry| {
        const skip_libc_alloc = if (entry.value.Object.getValue("skipLibCAllocator")) |v| v.Bool else false;
        const which_allocators = if (skip_libc_alloc)
            &[1]Record.WhichAllocator{.std_gpa}
        else
            &[_]Record.WhichAllocator{ .libc, .std_gpa };

        const benchmark_name = entry.key;
        const baseline_commit_str = entry.value.Object.getValue("baseline").?.String;
        const baseline_commit = try parseCommit(baseline_commit_str);
        const dir_name = entry.value.Object.getValue("dir").?.String;
        const main_basename = entry.value.Object.getValue("mainPath").?.String;
        const baseline_basename = entry.value.Object.getValue("baselinePath").?.String;

        const bench_cwd = try fs.path.join(gpa, &[_][]const u8{ "benchmarks", dir_name });
        defer gpa.free(bench_cwd);

        const full_main_path = try fs.path.join(gpa, &[_][]const u8{ bench_cwd, main_basename });
        defer gpa.free(full_main_path);
        const abs_main_path = try fs.realpathAlloc(gpa, full_main_path);
        defer gpa.free(abs_main_path);

        const full_baseline_path = try fs.path.join(gpa, &[_][]const u8{ bench_cwd, baseline_basename });
        defer gpa.free(full_baseline_path);
        const abs_baseline_path = try fs.realpathAlloc(gpa, full_baseline_path);
        defer gpa.free(abs_baseline_path);

        const baseline_zig = try fs.path.join(gpa, &[_][]const u8{
            "../../zig-builds", baseline_commit_str,
            "bin",              "zig",
        });
        defer gpa.free(baseline_zig);

        // Check out the appropriate commit and rebuild Zig.
        try exec(gpa, &[_][]const u8{ "git", "checkout", &commit_str }, .{
            .cwd = zig_src_root,
        });
        try exec(gpa, &[_][]const u8{"ninja"}, .{
            .cwd = zig_src_build,
        });

        for (which_allocators) |which_allocator| {
            std.debug.warn(
                "Running '{}' for {x}, allocator={}, baseline...\n",
                .{ benchmark_name, commit, @tagName(which_allocator) },
            );

            var baseline_argv = std.ArrayList([]const u8).init(gpa);
            defer baseline_argv.deinit();

            try appendBenchArgs(&baseline_argv, baseline_zig, abs_baseline_path, which_allocator);

            const baseline_stdout = try execCapture(gpa, baseline_argv.items, .{ .cwd = bench_cwd });
            defer gpa.free(baseline_stdout);

            var bench_parser = json.Parser.init(gpa, false);
            defer bench_parser.deinit();
            var baseline_json = bench_parser.parse(baseline_stdout) catch |err| {
                std.debug.warn("bad json: {}\n{}\n", .{ @errorName(err), baseline_stdout });
                return error.InvalidBenchJSON;
            };
            defer baseline_json.deinit();

            std.debug.warn(
                "Running '{}' for {x}, allocator={}...\n",
                .{ benchmark_name, commit, @tagName(which_allocator) },
            );

            var main_argv = std.ArrayList([]const u8).init(gpa);
            defer main_argv.deinit();
            try appendBenchArgs(&main_argv, abs_zig_src_bin, abs_main_path, which_allocator);

            const main_stdout = try execCapture(gpa, main_argv.items, .{ .cwd = bench_cwd });
            defer gpa.free(main_stdout);

            bench_parser.reset();
            var main_json = bench_parser.parse(main_stdout) catch |err| {
                std.debug.warn("bad json: {}\n{}\n", .{ @errorName(err), main_stdout });
                return error.InvalidBenchJSON;
            };
            defer main_json.deinit();

            const record = try jsonToRecord(
                arena,
                main_json.root,
                baseline_json.root,
                timestamp,
                benchmark_name,
                commit,
                which_allocator,
            );

            const key: Record.Key = .{
                .commit_hash = record.commit_hash,
                .benchmark_name = record.benchmark_name,
                .allocator = record.allocator,
            };
            const main_gop = try commit_table.getOrPut(key);
            if (main_gop.found_existing) {
                records.items[main_gop.kv.value] = record;
            } else {
                main_gop.kv.value = records.items.len;
                records.appendAssumeCapacity(record);
            }
        }
    }
}

fn appendBenchArgs(
    list: *std.ArrayList([]const u8),
    zig_exe: []const u8,
    main_path: []const u8,
    which_allocator: Record.WhichAllocator,
) !void {
    try list.ensureCapacity(20);
    list.appendSliceAssumeCapacity(&[_][]const u8{
        zig_exe,
        "run",
        "--cache",
        "off",
        "--main-pkg-path",
        "../..",
        "--pkg-begin",
        "app",
        main_path,
        "--pkg-end",
        "--release-fast",
    });
    switch (which_allocator) {
        .libc => list.appendAssumeCapacity("-lc"),
        .std_gpa => {},
    }
    list.appendSliceAssumeCapacity(&[_][]const u8{
        "../../bench.zig",
        "--",
        zig_exe,
    });
}

fn exec(
    gpa: *std.mem.Allocator,
    argv: []const []const u8,
    options: struct { cwd: ?[]const u8 = null },
) !void {
    const child = try std.ChildProcess.init(argv, gpa);
    defer child.deinit();

    child.stdin_behavior = .Inherit;
    child.stdout_behavior = .Inherit;
    child.stderr_behavior = .Inherit;
    child.cwd = options.cwd;

    const term = try child.spawnAndWait();
    switch (term) {
        .Exited => |code| {
            if (code != 0) {
                return error.ChildProcessBadExitCode;
            }
        },
        else => {
            return error.ChildProcessCrashed;
        },
    }
}

fn execCapture(
    gpa: *std.mem.Allocator,
    argv: []const []const u8,
    options: struct { cwd: ?[]const u8 = null },
) ![]u8 {
    const child = try std.ChildProcess.init(argv, gpa);
    defer child.deinit();

    child.stdin_behavior = .Inherit;
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Inherit;
    child.cwd = options.cwd;

    //std.debug.warn("cwd={}\n", .{child.cwd});
    //for (argv) |arg| {
    //    std.debug.warn("{} ", .{arg});
    //}
    //std.debug.warn("\n", .{});

    try child.spawn();

    const stdout_in = child.stdout.?.inStream();

    const stdout = try stdout_in.readAllAlloc(gpa, 9999);
    errdefer gpa.free(stdout);

    const term = try child.wait();
    switch (term) {
        .Exited => |code| {
            if (code != 0) {
                return error.ChildProcessBadExitCode;
            }
        },
        else => {
            return error.ChildProcessCrashed;
        },
    }

    return stdout;
}
