# Performance Tracking for Zig

This project exists to track various benchmarks related to the Zig project
regarding execution speed, memory usage, throughput, and other resource
utilization statistics.

The goal is to prevent performance regressions, and provide understanding
and exposure to how various code changes affect key measurements.

![](zigfast.png)

## Strategy

The main script does `git pull` and then runs the suite of measurements against
the latest master branch commit. When it is done, it repeats. If `git pull`
yields no new commits, it waits 60 seconds and then tries again.

The file `queue.txt` is a line-delimited list of git commit hashes which can be
manually added to be processed. The queue will be checked before doing
`git pull`.

This project is deployed on a virtual private sever and constantly running.
It is not guaranteed to have consistent hardware over the entire life of this
project, yet we want to provide a graph with meaningful changes over time.

Therefore, each time a new measurement is drawn, two benchmarks are performed:
one fixed git commit, as the reference point, and then the new commit being
tested. Both data points are stored, and any graphs will show the change in
time in relation to the fixed reference point.

Measurements are directly stored and committed to this git repository, in CSV
format. It is planned for new benchmarks to be added over time, and old
benchmarks to be retired, however the data should remain available.

## Installation

### System requirements:

This project was only written with POSIX systems in mind.

These must be installed and available in PATH:

 * git
 * ninja

### Process

For each of the `baseline` commit hashes in benchmarks/manifest.json, you must
provide a corresponding zig installation with the prefix `zig-builds/$HASH`.

You also must set up `zig-builds/src` as a git repository, and set up the build
directory using the ninja generator.

```
cd zig-builds/src
mkdir build
cmake .. -DCMAKE_BUILD_TYPE=Release -GNinja
```

You may need additional configuration to get LLVM/Clang/LLD to be detected.
You can optionally test the installation by running `ninja` in the build
directory.

This zig git source tree can't be used for anything else; the benchmarking
script modifies the state of this source tree and relies on the state not being
otherwise modified.

### Running

Run the `main.zig` program from the root source directory. It is a long running
process and will periodically poll for changes to the zig source git repo.
Extra commits to bench can be manually added to the queue.txt file.

The program will periodically modify the `records.csv` file. If you want it to
automatically commit this file to git and push it, use the command line
parameter `--auto-commit-and-push`. In this case, the program must be run as a
user that has permission to do perform `git commit` and `git push` commands.

## What About Cool Graphs And Stuff?

Out of scope. This project's entire purpose is to keep records.csv updated with
new data.

It will be the job of a separate project to periodically pull this data and
do something useful with it, such as make pretty graphs and put them on
ziglang.org.

In the meantime, some automatically updated graphs can be found [here](https://docs.google.com/spreadsheets/d/1Up7WXdC3cvuHyMq5nKNmTj6pCxH2MxSohAKGuM6zGpg/edit?usp=sharing).

## Adding a New Benchmark

Add it to `benchmarks/manifest.json`.

You can run a benchmark alone to test it like this:

```
../../zig-builds/src/build/zig run --main-pkg-path ../.. --pkg-begin app main.zig --pkg-end --release-fast -lc ../../bench.zig -- ../../zig-builds/src/build/zig
```
