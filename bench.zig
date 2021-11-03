const std = @import("std");
const builtin = @import("builtin");
const app = @import("app");
const assert = std.debug.assert;
const fd_t = std.os.fd_t;
const pid_t = std.os.pid_t;

// Here we reproduce the data from the zig standard library so that this file can be
// compiled by older zig versions.

pub const Measurement = struct {
    median: u64,
    mean: u64,
    min: u64,
    max: u64,

    fn compute(all_samples: []Sample, comptime field: []const u8) Measurement {
        const S = struct {
            fn order(context: void, a: Sample, b: Sample) bool {
                _ = context;
                return a.wall_time < b.wall_time;
            }
        };
        // Remove the 2 outliers, always according to wall_time.
        std.sort.sort(Sample, all_samples, {}, S.order);
        const samples = all_samples[1 .. all_samples.len - 1];
        // Compute stats
        var total: u64 = 0;
        var min: u64 = std.math.maxInt(u64);
        var max: u64 = 0;
        for (samples) |s| {
            const v = @field(s, field);
            total += v;
            if (v < min) min = v;
            if (v > max) max = v;
        }
        return .{
            .median = @field(samples[samples.len / 2], field),
            .mean = total / samples.len,
            .min = min,
            .max = max,
        };
    }
};

pub const Results = union(enum) {
    fail: anyerror,
    ok: struct {
        samples_taken: usize,
        wall_time: Measurement,
        utime: Measurement,
        stime: Measurement,
        cpu_cycles: Measurement,
        instructions: Measurement,
        cache_references: Measurement,
        cache_misses: Measurement,
        branch_misses: Measurement,
        maxrss: usize,
    },
};

const Sample = struct {
    wall_time: u64,
    utime: u64,
    stime: u64,
    cpu_cycles: u64,
    instructions: u64,
    cache_references: u64,
    cache_misses: u64,
    branch_misses: u64,
};

fn timeval_to_ns(tv: timeval) u64 {
    const ns_per_us = std.time.ns_per_s / std.time.us_per_s;
    return @bitCast(usize, tv.tv_sec) * std.time.ns_per_s +
        @bitCast(usize, tv.tv_usec) * ns_per_us;
}

fn readPerfFd(fd: fd_t) usize {
    var result: usize = 0;
    const n = std.os.read(fd, std.mem.asBytes(&result)) catch |err| {
        std.debug.panic("unable to read perf fd: {s}\n", .{@errorName(err)});
    };
    assert(n == @sizeOf(usize));
    return result;
}

var samples_buf: [1000000]Sample = undefined;
const max_nano_seconds = std.time.ns_per_s * 5;

const PerfMeasurement = struct {
    name: []const u8,
    config: PERF.COUNT.HW,
};

const perf_measurements = [_]PerfMeasurement{
    .{ .name = "cpu_cycles", .config = PERF.COUNT.HW.CPU_CYCLES },
    .{ .name = "instructions", .config = PERF.COUNT.HW.INSTRUCTIONS },
    .{ .name = "cache_references", .config = PERF.COUNT.HW.CACHE_REFERENCES },
    .{ .name = "cache_misses", .config = PERF.COUNT.HW.CACHE_MISSES },
    .{ .name = "branch_misses", .config = PERF.COUNT.HW.BRANCH_MISSES },
};

var perf_fds = [1]fd_t{-1} ** perf_measurements.len;

pub fn bench(options: Options, comptime func: anytype, args: anytype) Results {
    const rusage_who: i32 = if (options.use_child_process) rusage.CHILDREN else rusage.SELF;
    const flags: u64 = if (options.use_child_process)
        (1 << 0) | // disabled
            (1 << 5) | // exclude_kernel
            (1 << 6) | // exclude_hv
            (1 << 1) | // inherit
            (1 << 12) | // enable_on_exec
            0
    else
        (1 << 0) | // disabled
            (1 << 5) | // exclude_kernel
            (1 << 6) | // exclude_hv
            0;

    // Set up perf measurements.
    for (perf_measurements) |measurement, i| {
        var attr: perf_event_attr = .{
            .type = PERF.TYPE.HARDWARE,
            .config = @enumToInt(measurement.config),
            .flags = flags,
        };
        perf_fds[i] = perf_event_open(&attr, 0, -1, perf_fds[0], PERF.FLAG.FD_CLOEXEC) catch |err| {
            std.debug.panic("unable to open perf event: {s}\n", .{@errorName(err)});
        };
    }

    var sample_index: usize = 0;
    const timer = std.time.Timer.start() catch @panic("need timer to work");
    const first_start = timer.read();
    while ((sample_index < 3 or
        (timer.read() - first_start) < max_nano_seconds) and
        sample_index < samples_buf.len)
    {
        if (options.clear_zig_cache) {
            std.fs.cwd().deleteTree("zig-cache") catch |err| {
                std.debug.panic("unable to delete zig-cache: {s}", .{@errorName(err)});
            };
        }
        if (options.use_child_process) {
            _ = std.os.linux.ioctl(perf_fds[0], PERF.EVENT_IOC.DISABLE, PERF.IOC_FLAG_GROUP);
        }
        _ = std.os.linux.ioctl(perf_fds[0], PERF.EVENT_IOC.RESET, PERF.IOC_FLAG_GROUP);
        const start_rusage = std.os.getrusage(rusage_who);
        const start = timer.read();
        if (!options.use_child_process) {
            _ = std.os.linux.ioctl(perf_fds[0], PERF.EVENT_IOC.ENABLE, PERF.IOC_FLAG_GROUP);
        }
        const result = @call(.{}, func, args);
        _ = std.os.linux.ioctl(perf_fds[0], PERF.EVENT_IOC.DISABLE, PERF.IOC_FLAG_GROUP);
        const end = timer.read();
        const end_rusage = std.os.getrusage(rusage_who);
        result catch |err| {
            return .{ .fail = err };
        };
        samples_buf[sample_index] = .{
            .wall_time = end - start,
            .utime = timeval_to_ns(end_rusage.utime) - timeval_to_ns(start_rusage.utime),
            .stime = timeval_to_ns(end_rusage.stime) - timeval_to_ns(start_rusage.stime),
            .cpu_cycles = readPerfFd(perf_fds[0]),
            .instructions = readPerfFd(perf_fds[1]),
            .cache_references = readPerfFd(perf_fds[2]),
            .cache_misses = readPerfFd(perf_fds[3]),
            .branch_misses = readPerfFd(perf_fds[4]),
        };
        sample_index += 1;
    }
    const all_samples = samples_buf[0..sample_index];
    const wall_time = Measurement.compute(all_samples, "wall_time");
    const utime = Measurement.compute(all_samples, "utime");
    const stime = Measurement.compute(all_samples, "stime");
    const cpu_cycles = Measurement.compute(all_samples, "cpu_cycles");
    const instructions = Measurement.compute(all_samples, "instructions");
    const cache_references = Measurement.compute(all_samples, "cache_references");
    const cache_misses = Measurement.compute(all_samples, "cache_misses");
    const branch_misses = Measurement.compute(all_samples, "branch_misses");

    const final_rusage = std.os.getrusage(rusage_who);
    return .{
        .ok = .{
            .samples_taken = all_samples.len,
            .wall_time = wall_time,
            .utime = utime,
            .stime = stime,
            .cpu_cycles = cpu_cycles,
            .instructions = instructions,
            .cache_references = cache_references,
            .cache_misses = cache_misses,
            .branch_misses = branch_misses,
            .maxrss = @bitCast(usize, final_rusage.maxrss),
        },
    };
}

pub const Options = struct {
    zig_exe: []const u8,
    clear_zig_cache: bool = false,
    use_child_process: bool = false,

    pub fn useChildProcess(options: *Options) void {
        options.use_child_process = true;
    }
};

var general_purpose_allocator: std.heap.GeneralPurposeAllocator(.{}) = .{};

pub fn main() !void {
    const gpa = if (builtin.link_libc) std.heap.c_allocator else &general_purpose_allocator.allocator;
    var options: Options = .{
        .zig_exe = std.mem.spanZ(std.os.argv[1]),
    };
    const context = try app.setup(gpa, &options);
    const results = bench(options, app.run, .{ gpa, context });
    try std.json.stringify(results, std.json.StringifyOptions{}, std.io.getStdOut().writer());
}

pub fn exec(
    gpa: *std.mem.Allocator,
    argv: []const []const u8,
    options: struct {
        cwd: ?[]const u8 = null,
        stdin_behavior: std.ChildProcess.StdIo = .Inherit,
        stdout_behavior: std.ChildProcess.StdIo = .Inherit,
        stderr_behavior: std.ChildProcess.StdIo = .Inherit,
    },
) !void {
    const child = try std.ChildProcess.init(argv, gpa);
    defer child.deinit();

    child.stdin_behavior = options.stdin_behavior;
    child.stdout_behavior = options.stdout_behavior;
    child.stderr_behavior = options.stderr_behavior;
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
comptime {
    assert(@sizeOf(perf_event_attr) == 112);
}

pub const perf_event_attr = extern struct {
    /// Major type: hardware/software/tracepoint/etc.
    type: PERF.TYPE = undefined,
    /// Size of the attr structure, for fwd/bwd compat.
    size: u32 = @sizeOf(perf_event_attr),
    /// Type specific configuration information.
    config: u64 = 0,

    sample_period_or_freq: u64 = 0,
    sample_type: u64 = 0,
    read_format: u64 = 0,

    flags: u64 = 0,
    //flags: packed struct {
    //    /// off by default
    //    disabled: bool = false,
    //    /// children inherit it
    //    inherit: bool = false,
    //    /// must always be on PMU
    //    pinned: bool = false,
    //    /// only group on PMU
    //    exclusive: bool = false,
    //    /// don't count user
    //    exclude_user: bool = false,
    //    /// ditto kernel
    //    exclude_kernel: bool = false,
    //    /// ditto hypervisor
    //    exclude_hv: bool = false,
    //    /// don't count when idle
    //    exclude_idle: bool = false,
    //    /// include mmap data
    //    mmap: bool = false,
    //    /// include comm data
    //    comm: bool = false,
    //    /// use freq, not period
    //    freq: bool = false,
    //    /// per task counts
    //    inherit_stat: bool = false,
    //    /// next exec enables
    //    enable_on_exec: bool = false,
    //    /// trace fork/exit
    //    task: bool = false,
    //    /// wakeup_watermark
    //    watermark: bool = false,
    //    /// precise_ip:
    //    ///
    //    ///  0 - SAMPLE_IP can have arbitrary skid
    //    ///  1 - SAMPLE_IP must have constant skid
    //    ///  2 - SAMPLE_IP requested to have 0 skid
    //    ///  3 - SAMPLE_IP must have 0 skid
    //    ///
    //    ///  See also PERF_RECORD_MISC_EXACT_IP
    //    /// skid constraint
    //    precise_ip: u2 = 0,
    //    /// non-exec mmap data
    //    mmap_data: bool = false,
    //    /// sample_type all events
    //    sample_id_all: bool = false,

    //    /// don't count in host
    //    exclude_host: bool = false,
    //    /// don't count in guest
    //    exclude_guest: bool = false,

    //    /// exclude kernel callchains
    //    exclude_callchain_kernel: bool = false,
    //    /// exclude user callchains
    //    exclude_callchain_user: bool = false,
    //    /// include mmap with inode data
    //    mmap2: bool = false,
    //    /// flag comm events that are due to an exec
    //    comm_exec: bool = false,
    //    /// use @clockid for time fields
    //    use_clockid: bool = false,
    //    /// context switch data
    //    context_switch: bool = false,
    //    /// Write ring buffer from end to beginning
    //    write_backward: bool = false,
    //    /// include namespaces data
    //    namespaces: bool = false,

    //    __reserved_1: u35 = 0,
    //} = .{},
    /// wakeup every n events, or
    /// bytes before wakeup
    wakeup_events_or_watermark: u32 = 0,

    bp_type: u32 = 0,

    /// This field is also used for:
    /// bp_addr
    /// kprobe_func for perf_kprobe
    /// uprobe_path for perf_uprobe
    config1: u64 = 0,
    /// This field is also used for:
    /// bp_len
    /// kprobe_addr when kprobe_func == null
    /// probe_offset for perf_[k,u]probe
    config2: u64 = 0,

    /// enum perf_branch_sample_type
    branch_sample_type: u64 = 0,

    /// Defines set of user regs to dump on samples.
    /// See asm/perf_regs.h for details.
    sample_regs_user: u64 = 0,

    /// Defines size of the user stack to dump on samples.
    sample_stack_user: u32 = 0,

    clockid: i32 = 0,
    /// Defines set of regs to dump for each sample
    /// state captured on:
    ///  - precise = 0: PMU interrupt
    ///  - precise > 0: sampled instruction
    ///
    /// See asm/perf_regs.h for details.
    sample_regs_intr: u64 = 0,

    /// Wakeup watermark for AUX area
    aux_watermark: u32 = 0,
    sample_max_stack: u16 = 0,
    /// Align to u64
    __reserved_2: u16 = 0,
};

pub const PERF = struct {
    pub const TYPE = enum(u32) {
        HARDWARE,
        SOFTWARE,
        TRACEPOINT,
        HW_CACHE,
        RAW,
        BREAKPOINT,
        MAX,
    };

    pub const COUNT = struct {
        pub const HW = enum(u32) {
            CPU_CYCLES,
            INSTRUCTIONS,
            CACHE_REFERENCES,
            CACHE_MISSES,
            BRANCH_INSTRUCTIONS,
            BRANCH_MISSES,
            BUS_CYCLES,
            STALLED_CYCLES_FRONTEND,
            STALLED_CYCLES_BACKEND,
            REF_CPU_CYCLES,
            MAX,

            pub const CACHE = enum(u32) {
                L1D,
                L1I,
                LL,
                DTLB,
                ITLB,
                BPU,
                NODE,
                MAX,

                pub const OP = enum(u32) {
                    READ,
                    WRITE,
                    PREFETCH,
                    MAX,
                };

                pub const RESULT = enum(u32) {
                    ACCESS,
                    MISS,
                    MAX,
                };
            };
        };

        pub const SW = enum(u32) {
            CPU_CLOCK,
            TASK_CLOCK,
            PAGE_FAULTS,
            CONTEXT_SWITCHES,
            CPU_MIGRATIONS,
            PAGE_FAULTS_MIN,
            PAGE_FAULTS_MAJ,
            ALIGNMENT_FAULTS,
            EMULATION_FAULTS,
            DUMMY,
            BPF_OUTPUT,
            MAX,
        };
    };

    pub const SAMPLE = struct {
        pub const IP = 1;
        pub const TID = 2;
        pub const TIME = 4;
        pub const ADDR = 8;
        pub const READ = 16;
        pub const CALLCHAIN = 32;
        pub const ID = 64;
        pub const CPU = 128;
        pub const PERIOD = 256;
        pub const STREAM_ID = 512;
        pub const RAW = 1024;
        pub const BRANCH_STACK = 2048;
        pub const REGS_USER = 4096;
        pub const STACK_USER = 8192;
        pub const WEIGHT = 16384;
        pub const DATA_SRC = 32768;
        pub const IDENTIFIER = 65536;
        pub const TRANSACTION = 131072;
        pub const REGS_INTR = 262144;
        pub const PHYS_ADDR = 524288;
        pub const MAX = 1048576;

        pub const BRANCH = struct {
            pub const USER = 1 << 0;
            pub const KERNEL = 1 << 1;
            pub const HV = 1 << 2;
            pub const ANY = 1 << 3;
            pub const ANY_CALL = 1 << 4;
            pub const ANY_RETURN = 1 << 5;
            pub const IND_CALL = 1 << 6;
            pub const ABORT_TX = 1 << 7;
            pub const IN_TX = 1 << 8;
            pub const NO_TX = 1 << 9;
            pub const COND = 1 << 10;
            pub const CALL_STACK = 1 << 11;
            pub const IND_JUMP = 1 << 12;
            pub const CALL = 1 << 13;
            pub const NO_FLAGS = 1 << 14;
            pub const NO_CYCLES = 1 << 15;
            pub const TYPE_SAVE = 1 << 16;
            pub const MAX = 1 << 17;
        };
    };

    pub const FLAG = struct {
        pub const FD_NO_GROUP = 1 << 0;
        pub const FD_OUTPUT = 1 << 1;
        pub const PID_CGROUP = 1 << 2;
        pub const FD_CLOEXEC = 1 << 3;
    };

    pub const EVENT_IOC = struct {
        pub const ENABLE = 9216;
        pub const DISABLE = 9217;
        pub const REFRESH = 9218;
        pub const RESET = 9219;
        pub const PERIOD = 1074275332;
        pub const SET_OUTPUT = 9221;
        pub const SET_FILTER = 1074275334;
        pub const SET_BPF = 1074013192;
        pub const PAUSE_OUTPUT = 1074013193;
        pub const QUERY_BPF = 3221758986;
        pub const MODIFY_ATTRIBUTES = 1074275339;
    };

    pub const IOC_FLAG_GROUP = 1;
};

pub const timeval = std.os.timeval;

pub const rusage = extern struct {
    utime: timeval,
    stime: timeval,
    maxrss: isize,
    ixrss: isize,
    idrss: isize,
    isrss: isize,
    minflt: isize,
    majflt: isize,
    nswap: isize,
    inblock: isize,
    oublock: isize,
    msgsnd: isize,
    msgrcv: isize,
    nsignals: isize,
    nvcsw: isize,
    nivcsw: isize,
    __reserved: [16]isize = [1]isize{0} ** 16,

    pub const SELF = 0;
    pub const CHILDREN = -1;
    pub const THREAD = 1;
};

pub const PerfEventOpenError = error{
    /// Returned if the perf_event_attr size value is too small (smaller
    /// than PERF_ATTR_SIZE_VER0), too big (larger than the page  size),
    /// or  larger  than the kernel supports and the extra bytes are not
    /// zero.  When E2BIG is returned, the perf_event_attr size field is
    /// overwritten by the kernel to be the size of the structure it was
    /// expecting.
    TooBig,
    /// Returned when the requested event requires CAP_SYS_ADMIN permis‐
    /// sions  (or a more permissive perf_event paranoid setting).  Some
    /// common cases where an unprivileged process  may  encounter  this
    /// error:  attaching  to a process owned by a different user; moni‐
    /// toring all processes on a given CPU (i.e.,  specifying  the  pid
    /// argument  as  -1); and not setting exclude_kernel when the para‐
    /// noid setting requires it.
    /// Also:
    /// Returned on many (but not all) architectures when an unsupported
    /// exclude_hv,  exclude_idle,  exclude_user, or exclude_kernel set‐
    /// ting is specified.
    /// It can also happen, as with EACCES, when the requested event re‐
    /// quires   CAP_SYS_ADMIN   permissions   (or   a  more  permissive
    /// perf_event paranoid setting).  This includes  setting  a  break‐
    /// point on a kernel address, and (since Linux 3.13) setting a ker‐
    /// nel function-trace tracepoint.
    PermissionDenied,
    /// Returned if another event already has exclusive  access  to  the
    /// PMU.
    DeviceBusy,
    /// Each  opened  event uses one file descriptor.  If a large number
    /// of events are opened, the per-process limit  on  the  number  of
    /// open file descriptors will be reached, and no more events can be
    /// created.
    ProcessResources,
    EventRequiresUnsupportedCpuFeature,
    /// Returned if  you  try  to  add  more  breakpoint
    /// events than supported by the hardware.
    TooManyBreakpoints,
    /// Returned  if PERF_SAMPLE_STACK_USER is set in sample_type and it
    /// is not supported by hardware.
    SampleStackNotSupported,
    /// Returned if an event requiring a specific  hardware  feature  is
    /// requested  but  there is no hardware support.  This includes re‐
    /// questing low-skid events if not supported, branch tracing if  it
    /// is not available, sampling if no PMU interrupt is available, and
    /// branch stacks for software events.
    EventNotSupported,
    /// Returned  if  PERF_SAMPLE_CALLCHAIN  is   requested   and   sam‐
    /// ple_max_stack   is   larger   than   the  maximum  specified  in
    /// /proc/sys/kernel/perf_event_max_stack.
    SampleMaxStackOverflow,
    /// Returned if attempting to attach to a process that does not  exist.
    ProcessNotFound,

    Unexpected,
};

pub fn perf_event_open(
    attr: *perf_event_attr,
    pid: pid_t,
    cpu: i32,
    group_fd: fd_t,
    flags: usize,
) PerfEventOpenError!fd_t {
    const rc = system.perf_event_open(attr, pid, cpu, group_fd, flags);
    switch (std.os.errno(rc)) {
        .SUCCESS => return @intCast(fd_t, rc),
        .@"2BIG" => return error.TooBig,
        .ACCES => return error.PermissionDenied,
        .BADF => unreachable, // group_fd file descriptor is not valid.
        .BUSY => return error.DeviceBusy,
        .FAULT => unreachable, // Segmentation fault.
        .INVAL => unreachable, // Bad attr settings.
        .INTR => unreachable, // Mixed perf and ftrace handling for a uprobe.
        .MFILE => return error.ProcessResources,
        .NODEV => return error.EventRequiresUnsupportedCpuFeature,
        .NOENT => unreachable, // Invalid type setting.
        .NOSPC => return error.TooManyBreakpoints,
        .NOSYS => return error.SampleStackNotSupported,
        .OPNOTSUPP => return error.EventNotSupported,
        .OVERFLOW => return error.SampleMaxStackOverflow,
        .PERM => return error.PermissionDenied,
        .SRCH => return error.ProcessNotFound,
        else => return error.Unexpected,
    }
}

pub const system = struct {
    pub fn perf_event_open(
        attr: *perf_event_attr,
        pid: pid_t,
        cpu: i32,
        group_fd: fd_t,
        flags: usize,
    ) usize {
        return std.os.linux.syscall5(
            .perf_event_open,
            @ptrToInt(attr),
            @bitCast(usize, @as(isize, pid)),
            @bitCast(usize, @as(isize, cpu)),
            @bitCast(usize, @as(isize, group_fd)),
            flags,
        );
    }
};
