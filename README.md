# Performance Tracking for Zig

This project exists to track various benchmarks related to the Zig project
regarding execution speed, memory usage, throughput, and other resource
utilization statistics.

The goal is to prevent performance regressions, and provide understanding
and exposure to how various code changes affect key measurements.

## Strategy

This project uses [SourceHut](https://sourcehut.org/) builds to run
performance testing. It is not guaranteed to have consistent hardware over
the entire life of this project, yet we want to provide a graph with meaningful
changes over time.

The main script does `git pull` and then runs the suite of measurements against
the latest master branch commit. When it is done, it repeats. If `git pull`
yields no new commits, it waits 60 seconds and then tries again.

The file `queue.txt` is a line-delimited list of git commit hashes which can be
manually added to be processed. The queue will be checked before doing
`git pull`.

It is understood that the hardware of the machine performing the benchmarks may
change over time. Therefore, each time a new measurement is drawn, two
benchmarks are performed: one fixed git commit, as the reference point, and
then the new commit being tested. Both data points are stored, and any graphs
will show the change in time in relation to the fixed reference point.

Measurements are directly stored and committed to this git repository, in CSV
format. It is planned for new benchmarks to be added over time, and old
benchmarks to be retired, however the data should remain available.
