# Performance Tracking for Zig

This project exists to track various benchmarks related to the Zig project
regarding execution speed, memory usage, throughput, and other resource
utilization statistics.

The goal is to prevent performance regressions, and provide understanding
and exposure to how various code changes affect key measurements.

<h4 align="center">
    <a href="https://ziglang.org/perf/">
        See the latest results
    </a>
</h4>

<p align="center">
    <img src="images/gotta_go_fast.png">
</p>

## Strategy

This repository is cloned by a Continuous Integration script that runs on every
master branch commit to [ziglang/zig](https://github.com/ziglang/zig/) and
executes a series of benchmarks using Linux's performance measurement syscalls
(the same thing that `perf` does). The machine is a dedicated Hetzner server
with a AMD Ryzen 9 5950X 16-Core Processor, an NVMe hard drive, Linux kernel
5.14.14-arch1-1. See more details below in the [CPU Details section](README.md#cpu-details).

The measurements are stored in a CSV file which is atomically swapped with
updated records when a new benchmark completes. After a new benchmark row is added
to the dataset, it is pushed to `https://ziglang.org/perf/records.csv`. The
static HTML + JavaScript at https://ziglang.org/perf/ loads `records.csv` and
presents it in interactive graph form.

Each benchmark gets a fixed amount of time allocated: 5 seconds per benchmark.
For each measurement, there is a min, max, mean, and median value. The best and
worst runs according to Wall Clock Time are discarded to account for system
noise.

### Measurements Collected

 * Wall Clock Time
 * Peak Resident Set Size (memory usage)
 * How many times the benchmark was executed in 5 seconds
 * instructions
 * cycles
 * cache-misses
 * cache-references
 * branches
 * branch-misses

Metadata:

 * Benchmark name
 * Timestamp of when the benchmark was executed
 * Zig Git Commit SHA1
 * Zig Git Commit Message
 * Zig Git Commit Date
 * Zig Git Commit Author
 * gotta-go-fast Git Commit Sha1

### CPU Details

```
vendor_id	: AuthenticAMD
cpu family	: 25
model		: 33
model name	: AMD Ryzen 9 5950X 16-Core Processor
stepping	: 0
microcode	: 0xa201016
cpu MHz		: 3786.264
cache size	: 512 KB
physical id	: 0
siblings	: 32
cpu cores	: 16
apicid		: 31
fpu		: yes
fpu_exception	: yes
cpuid level	: 16
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm constant_tsc rep_good nopl nonstop_tsc cpuid extd_apicid aperfmperf rapl pni pclmulqdq monitor ssse3 fma cx16 sse4_1 sse4_2 movbe popcnt aes xsave avx f16c rdrand lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs skinit wdt tce topoext perfctr_core perfctr_nb bpext perfctr_llc mwaitx cpb cat_l3 cdp_l3 hw_pstate ssbd mba ibrs ibpb stibp vmmcall fsgsbase bmi1 avx2 smep bmi2 erms invpcid cqm rdt_a rdseed adx smap clflushopt clwb sha_ni xsaveopt xsavec xgetbv1 xsaves cqm_llc cqm_occup_llc cqm_mbm_total cqm_mbm_local clzero irperf xsaveerptr rdpru wbnoinvd arat npt lbrv svm_lock nrip_save tsc_scale vmcb_clean flushbyasid decodeassists pausefilter pfthreshold avic v_vmsave_vmload vgif v_spec_ctrl umip pku ospke vaes vpclmulqdq rdpid overflow_recov succor smca fsrm
bugs		: sysret_ss_attrs spectre_v1 spectre_v2 spec_store_bypass
bogomips	: 6789.81
TLB size	: 2560 4K pages
clflush size	: 64
cache_alignment	: 64
address sizes	: 48 bits physical, 48 bits virtual
power management: ts ttp tm hwpstate cpb eff_freq_ro [13] [14]
```

## Instructions for the CI Script

These measurements should only be taken for a Zig compiler that has passed the
full test suite, and the `$ZIG_EXE` command should be a release build matching the
git commit of `$COMMIT_SHA1`. `$COMMIT_TIMESTAMP` is required to be in the format
given by `--pretty=format:%at`.

After cloning this repository:

```
$ZIG_EXE build -- records.csv $ZIG_EXE $COMMIT_SHA1 $COMMIT_TIMESTAMP
```

This will add 1 row per benchmark to `records.csv` for the specified commit.
The CI script should then push `records.csv` and `manifest.json` to the server so
that the frontend HTML+JavaScript can fetch them and display the information.

## Backfilling Data

`$ZIG_GIT_SRC` must be a git clone of zig, with a `build-backfill` folder
configured with CMake already. It needs to be configured this way:

```
cmake .. -DCMAKE_BUILD_TYPE=Release -GNinja
ninja install
```

This `ninja install` creates `stage1/bin/zig` which is left untouched, and then
`ninja` (without the install argument) is used for older zig versions when going
through the commits.

`commits.txt` is a file containing whitespace-separated git commit hashes.

```
$ZIG_GIT_SRC/build-backfill/stage3/bin/zig build -Dbackfill -- records.csv $ZIG_GIT_SRC commits.txt
```

This will check out each commit one-by-one and run `collect-measurements.zig`,
updating `records.csv` with the new rows.

Here is a handy git CLI snippet for generating commits.txt:

```
git log --first-parent --format=format:%H start..end
```

This one will update commits.txt to be the next set of commits since the last
time the backfill script was run:

```
git log $(head -n1 ~/gotta-go-fast/commits.txt)..origin/master --first-parent --format=format:%H > ~/gotta-go-fast/commits.txt
```

## Adding a Benchmark

First add an entry in `manifest.json`. Next, you can test it like this:

```
$ZIG_EXE run ./src/bench.zig -O ReleaseFast --deps app --mod app::$NEW_BENCH_MAIN_PATH -- $ZIG_EXE
```

Use an absolute path for the ending `$ZIG_EXE` argument which is in a subdirectory
of the zig source tree used to build the zig binary. Some of the benchmarks
want to learn the zig source checkout path in order to test stuff.

## Empty CSV File

Handy to copy paste to start a new table.

```csv
timestamp,benchmark_name,commit_hash,commit_timestamp,zig_version,error_message,samples_taken,wall_time_median,wall_time_mean,wall_time_min,wall_time_max,utime_median,utime_mean,utime_min,utime_max,stime_median,stime_mean,stime_min,stime_max,cpu_cycles_median,cpu_cycles_mean,cpu_cycles_min,cpu_cycles_max,instructions_median,instructions_mean,instructions_min,instructions_max,cache_references_median,cache_references_mean,cache_references_min,cache_references_max,cache_misses_median,cache_misses_mean,cache_misses_min,cache_misses_max,branch_misses_median,branch_misses_mean,branch_misses_min,branch_misses_max,maxrss
```
