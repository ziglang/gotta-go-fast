const std = @import("std");
const fs = std.fs;
const json = std.json;

const Key = struct {
    commit_hash: [20]u8,
    benchmark_name: []const u8,
};

const Record = struct {
    /// Use this to join the baseline commit against the commit being benchmarked.
    timestamp: u64,
    benchmark_name: []const u8,
    allocator: enum {
        /// malloc/realloc/free
        libc,
        /// the default general purpose allocator in the zig std lib.
        /// currently std.heap.page_allocator
        std_gpa,
    },
    commit_hash: [20]u8,
    error_message: []const u8,
    samples_taken: u64,
    wall_time_median: u64,
    wall_time_mean: u64,
    wall_time_min: u64,
    wall_time_max: u64,
    utime_median: u64,
    utime_mean: u64,
    utime_min: u64,
    utime_max: u64,
    stime_median: u64,
    stime_mean: u64,
    stime_min: u64,
    stime_max: u64,
    maxrss: u64,
};

const comma = "💩";

pub fn main() !void {
    const gpa = std.heap.page_allocator;
    var arena_state = std.heap.ArenaAllocator.init(gpa);
    defer arena_state.deinit();
    const arena = &arena_state.allocator;

    // Load CSV into memory
    std.debug.warn("Loading CSV data...\n", .{});
    var records = std.ArrayList(Record).init(gpa);
    defer records.deinit();
    var commit_table = std.AutoHashMap(Key, usize).init(gpa);
    defer commit_table.deinit();

    {
        const csv_text = try fs.cwd().readFileAlloc(gpa, "records.csv", 2 * 1024 * 1024 * 1024);
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
            const key: Key = .{
                .commit_hash = record.commit_hash,
                .benchmark_name = record.benchmark_name,
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
                var benchmarks_it = manifest_tree.root.Object.iterator();
                const any_missing = while (benchmarks_it.next()) |kv| {
                    const key: Key = .{
                        .commit_hash = queue_commit,
                        .benchmark_name = kv.key,
                    };
                    if (commit_table.get(key) == null) {
                        break true;
                    }
                } else false;

                if (!any_missing) {
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
        var did_anything = false;
        for (queue.items) |queue_item| {
            did_anything = true;
            runBenchmarks(&records, &commit_table, queue_item);
        }

        // Detect changes to zig master branch
        // TODO

        if (did_anything) {
            // Save CSV
            // TODO

            // Commit CSV changes to git and push
            // TODO
        } else {
            // "On the seventh day, God rested."
            std.time.sleep(60 * std.time.ns_per_s);
        }
    }
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
    records: *std.ArrayList(Record),
    commit_table: *std.AutoHashMap(Key, usize),
    commit: [20]u8,
) void {
    std.debug.warn("TODO run benchmarks for {x}\n", .{commit});
}
