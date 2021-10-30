# Performance Tracking for Zig

This project exists to track various benchmarks related to the Zig project
regarding execution speed, memory usage, throughput, and other resource
utilization statistics.

The goal is to prevent performance regressions, and provide understanding
and exposure to how various code changes affect key measurements.

![](zigfast.png)

## Strategy

This repository is cloned by a Continuous Integration script that runs on every
master branch commit to [ziglang/zig](https://github.com/ziglang/zig/) and
executes a series of benchmarks using Linux's performance measurement syscalls
(the same thing that `perf` does). The machine is a dedicated Hetzner server
with a AMD Ryzen 9 5950X 16-Core Processor, an NVMe hard drive, Linux kernel
5.14.14-arch1-1. See more CPU details below in the [[CPU Details]] section.

The measurements are stored in a JSON file which is atomically swapped with
updated data when a new benchmark completes. After a new benchmark row is added
to the dataset, it is pushed to `https://ziglang.org/perf/data.json`. The
static HTML + JavaScript at https://ziglang.org/perf/ loads `data.json` and
presents it in interactive graph form.

Each benchmark gets a fixed amount of time allocated: 5 seconds per benchmark.
For each measurement, there is a min, max, mean, and median value. The best and
worst runs according to Wall Clock Time are discarded to account for system
noise.

### Measurements Collected

 * Wall Clock Time
 * Peak Resident Set Size (memory usage)
 * instructions
 * cycles
 * cache-misses
 * cache-references
 * branches
 * branch-misses

Metadata:

 * Git Commit sha1
 * Git Commit Message
 * Git Commit Date
 * Git Commit Author
 * How many times the benchmark was executed in 5 seconds

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
